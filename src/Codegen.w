// Codegen — LLVM IR code generation from the With AST.
//
// Translates parsed AST nodes into LLVM IR using the LLVM-C API
// via the rt.llvm_bridge module, then emits
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
use compiler.LlvmBridge.*
use Overflow
use TargetSpec
use FnAbi
use compiler.EmbeddedBundles
use AnalysisTypes

extern fn exit(code: i32) -> Unit
extern fn with_fs_read_file(path: &str) -> str
extern fn with_vec_free(v: *mut u8) -> Unit
extern fn with_hashmap_free(map: *mut u8) -> Unit
extern fn with_eprint(s: &str) -> Unit
extern fn with_getenv_str(name: &str) -> str
extern fn with_str_hash(s: &str) -> u64
extern fn with_str_clone_ref(s: &str) -> str
extern fn str_from_byte(b: i32) -> str
extern fn with_codegen_loop_set_break(idx: i32, bb: i64) -> Unit
extern fn with_codegen_loop_set_continue(idx: i32, bb: i64) -> Unit
extern fn with_codegen_loop_set_result(idx: i32, value: i64) -> Unit
extern fn with_codegen_loop_get_break(idx: i32) -> i64
extern fn with_codegen_loop_get_continue(idx: i32) -> i64
extern fn with_codegen_loop_get_result(idx: i32) -> i64

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


// Inline assembly

// Struct name

// Param types

// Verification / emission

// Vec data pointer

// Entry alloca helper

// Debug info (DWARF)

// Runtime helpers
extern fn with_write(s: &str) -> Unit
extern fn with_sysinfo_os() -> str
extern fn with_sysinfo_arch() -> str

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
    overflow_mode: i32,
    analysis_enabled: i32,
    analysis_query: str,
    analysis_report: AnalysisReport,
    analysis_last_marshal_strategy: AnalysisMarshalStrategy,

    // Current function state
    current_ret_type: i64,
    mir_emit_mutual_tail_call: i32,
    // Async trampolines: fn_sym → LLVM trampoline function value
    async_trampolines: HashMap[i32, i64],
    current_function: i64,
    current_function_name_sym: i32,
    current_function_node: i32,
    current_method_owner_sym: i32,
    current_drop_origin_ptr: i64,
    current_drop_origin_len: i64,
    // Stage 4 (spec §2.5.2): true = emit the rt_value_is_zero guard on a user
    // Drop (the value may be reset-on-move); false = the move analysis proved
    // the dropped local is never moved, so emit an unconditional drop. Scoped
    // around each Drop statement; defaults to true (guard) everywhere else.
    current_drop_needs_guard: bool,
    // #697: >0 while emitting member drops (struct fields, tuple/array elements,
    // enum payloads, vec elements). A member can hold the reset sentinel from a
    // field blank the dropping function's move analysis cannot see (a callee
    // blanked it through a share-place pointer, or a conditional field move), so
    // member-level drops are always guarded regardless of the per-site Stage-4
    // elision. Reset to 0 inside outlined per-type drop bodies (their caller
    // guards the whole value; their own member recursion re-raises it).
    member_drop_depth: i32,

    // Pre-interned symbols for O(1) dispatch (avoid string comparisons)
    sym_vec: i32,
    sym_option: i32,
    sym_result: i32,
    sym_hashmap: i32,
    sym_hashset: i32,
    sym_btreemap: i32,
    sym_btreeset: i32,
    sym_handle: i32,
    sym_slotmap: i32,
    sym_slotmapslot: i32,
    sym_vecslot: i32,
    sym_vecrange: i32,
    sym_veciterref: i32,
    sym_veciterplace: i32,
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
    sym_cstr: i32,
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
    generated_mir_body_syms: HashMap[i32, i32],
    // C ABI: fns with struct params/returns transformed for C ABI.
    // Maps fn sym → 1 if the fn has an sret return (first param is hidden sret ptr).
    extern_fn_has_sret: HashMap[i32, i32],
    // Maps fn sym → bitmask of param indices that are byval (after sret shift).
    extern_fn_byval_params: HashMap[i32, i64],
    // Maps fn sym → original struct types for byval params (parallel arrays).
    extern_fn_byval_types: HashMap[i32, Vec[i64]],
    // Maps fn sym → original return struct type (for sret).
    extern_fn_sret_type: HashMap[i32, i64],
    // Maps fn sym → bitmask of param indices directly packed for the target C ABI.
    extern_fn_direct_params: HashMap[i32, i64],
    // Maps fn sym → original struct types for direct params (parallel arrays).
    extern_fn_direct_param_types: HashMap[i32, Vec[i64]],
    // Maps fn sym → original return struct type for direct aggregate returns.
    extern_fn_direct_ret_type: HashMap[i32, i64],

    // Struct types: sym → index into struct_type_* arrays
    struct_type_map: HashMap[i32, i32],
    // D29 scaffolding (#750): shadowed type names carry per-tier codegen
    // symbols so both layouts coexist in LLVM — the std-tier decl registers
    // under `name$std`, the user decl keeps the plain name. Populated during
    // type registration; read-only afterwards.
    shadow_alias_map: HashMap[i32, i32],
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
    generic_enum_inst_types: HashMap[i32, i64],
    generic_enum_inst_syms: HashMap[i32, i32],

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
    // #777: writable module globals with droppable types; the exit wrapper
    // drops them (reverse order) after with_runtime_run, before shutdown.
    module_drop_global_syms: Vec[i32],
    module_drop_global_tids: Vec[i32],
    // Constant integer values: parallel arrays for sym → i64 value lookup
    // #839: LLVM names declared for With-BODIED fns (interned), so the
    // extern declare path can distinguish "a With body occupies my C
    // symbol" (move it aside) from c_import's deliberate same-symbol
    // different-prototype reuse (keep, marshal via recorded transforms).
    with_fn_link_names: HashMap[i32, i32],
    const_int_syms: Vec[i32],
    const_int_vals: Vec[i64],
    decl_source_paths: Vec[str],
    current_decl_source_file: str,
    module_object_mode: i32,
    // D38: module link-name prefixes provided by embedded .wo bundles. A
    // function from such a module is declared under its module link name,
    // never defined, in this unit (docs/wo_bundles.md "Declarations only").
    bundle_prefixes: Vec[str],

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
    trait_method_flags: Vec[i32],
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
    mono_inst_name: i32 = 0,
    mono_inst_node: i32 = 0,

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
    // SlotMap type cache (elem LLVM type → SlotMap LLVM struct type)
    slotmap_cache_map: HashMap[i64, i64],

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
    tracked_input_root: str,
    tracked_input_paths: Vec[str],

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
    mir_ptr: i64,
    // #681 per-unit generation: when unit_total > 1, this cg instance
    // generates bodies only for fns assigned to unit_index; everything else
    // stays a Pass-1 declaration. Synthesized fns (runtime init, wrapped
    // main) are pinned to unit 0 (main's body is force-assigned there).
    unit_total: i32,
    unit_index: i32,
    unit_assign: HashMap[i32, i32],
    unit_rename_index: HashMap[i32, i32],
    mir_local_ptrs: HashMap[i32, i64],
    mir_local_values: HashMap[i32, i64],
    mir_memory_locals: HashMap[i32, i32],
    mir_local_types: HashMap[i32, i64],
    mir_indirect_value_local_types: HashMap[i32, i64],
    mir_ref_capture_local_types: HashMap[i32, i64],
    mir_bb_values: Vec[i64],
    mir_default_unreachable_bbs: Vec[i64],
}

type DynArgInfo {
    type_sym: i32,
    use_ptr: i32,
}

type CallArgValue {
    value: i64,
    cleanup_ptr: i64,
}

type LoopState {
    break_bbs: Vec[i64],
    continue_bbs: Vec[i64],
    result_allocas: Vec[i64],
    labels: Vec[i32],
    depth: i32,
}

// ── Codegen lifecycle ─────────────────────────────────────────────

fn Codegen.init(module_name: &str) -> Codegen:
    Codegen.init_with_opt(module_name, 0)

// D17/#697 phase take-and-return (the lower_module pattern): codegen OWNS the
// Sema during emission — the caller's binding is blank in between, never
// aliased — and hands it back via take_sema. The swap leaves a placeholder so
// every cg teardown path (explicit deinit or scope exit) stays untouched.
extend Codegen:
    mut fn take_sema() -> Sema:
        var s = move self.sema
        self.sema = Sema.placeholder(InternPool.init(), DiagnosticList.init(), AstPool.new())
        s

    // Take-and-return partners for the pools the analysis backend lends the
    // codegen run (#726): the caller restores them after take_sema, so no
    // still-viewed pool is ever dropped inside the backend seam.
    mut fn take_pool() -> AstPool:
        var p = self.pool
        self.pool = AstPool.new()
        p

    mut fn take_intern() -> InternPool:
        var i = self.intern
        self.intern = InternPool.init()
        i

fn Codegen.init_with_opt_and_intern(module_name: &str, opt_level: i32, intern: InternPool, sema: Sema) -> Codegen:
    var cg = Codegen.init_with_opt(module_name, opt_level)
    let overflow_mode = sema.overflow_mode
    cg.intern = intern
    cg.sema = sema
    cg.overflow_mode = overflow_mode
    cg.tracked_input_root = with_str_clone_ref(cg.sema.tracked_input_root)
    let tracked_paths: Vec[str] = Vec.new()
    for tpi in 0..cg.sema.tracked_input_paths.len() as i32:
        tracked_paths.push(with_str_clone_ref(cg.sema.tracked_input_paths.get(tpi as i64)))
    cg.tracked_input_paths = tracked_paths
    cg.capture_sema_symbol_texts()
    // Pre-intern dispatch symbols for O(1) comparisons
    cg.sym_vec = cg.intern.intern("Vec")
    cg.sym_option = cg.intern.intern("Option")
    cg.sym_result = cg.intern.intern("Result")
    cg.sym_hashmap = cg.intern.intern("HashMap")
    cg.sym_hashset = cg.intern.intern("HashSet")
    cg.sym_btreemap = cg.intern.intern("BTreeMap")
    cg.sym_btreeset = cg.intern.intern("BTreeSet")
    cg.sym_handle = cg.intern.intern("Handle")
    cg.sym_slotmap = cg.intern.intern("SlotMap")
    cg.sym_slotmapslot = cg.intern.intern("SlotMapSlot")
    cg.sym_vecslot = cg.intern.intern("VecSlot")
    cg.sym_vecrange = cg.intern.intern("VecRange")
    cg.sym_veciterref = cg.intern.intern("VecIterRef")
    cg.sym_veciterplace = cg.intern.intern("VecIterPlace")
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
    cg.sym_cstr = cg.intern.intern("CStr")
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

impl Codegen:
    mut fn enable_analysis(query: &str):
        self.analysis_enabled = 1
        self.analysis_query = with_str_clone_ref(query)

    fn analysis_add(fact: AnalysisFact):
        if self.analysis_enabled != 0:
            self.analysis_report.add(move fact)

    fn analysis_fail(message: &str):
        if self.analysis_enabled != 0:
            self.analysis_report.fail(message)

    fn analysis_fact_selected(fact: &AnalysisFact) -> bool:
        if self.analysis_query == "audit":
            return true
        let query = if self.analysis_query.starts_with("matrix:"): self.analysis_query.slice(7, self.analysis_query.len()) else: self.analysis_query
        analysis_fact_matches(fact, query)

    fn analysis_text() -> str:
        if self.analysis_enabled == 0:
            return ""
        if self.analysis_query == "audit":
            return self.analysis_report.render_verdict("codegen-contract-audit")
        if self.analysis_query.starts_with("matrix:"):
            let query = self.analysis_query.slice(7, self.analysis_query.len())
            return self.analysis_report.render_matrix(query) ++ self.analysis_report.render_verdict("codegen-contract-audit")
        self.analysis_report.render_facts(self.analysis_query) ++ self.analysis_report.render_verdict("codegen-contract-audit")

    fn analysis_status() -> i32:
        if self.analysis_report.ok(): 0 else: 1

    fn analysis_has_call_argument(body_sym: i32, args_id: i32, param_index: i32) -> bool:
        for i in 0..self.analysis_report.facts.len() as i32:
            let fact = self.analysis_report.facts.get(i as i64)
            if fact.stage == AnalysisStage.Codegen and fact.kind == AnalysisFactKind.CodegenArgument and
               fact.body_sym == body_sym and fact.parent == args_id and fact.index == param_index:
                return true
        false

    // Whole-module proof that the final Sema share-place contract survived LLVM
    // declaration. Generic templates without an emitted LLVM function are facts,
    // not failures; every emitted function must have both the ref-table bit and a
    // pointer-shaped incoming parameter.
    fn audit_declared_share_place_contracts():
        if self.analysis_enabled == 0:
            return
        for si in 0..self.sema.sig_names.len() as i32:
            let sema_sym = self.sema.sig_names.get(si as i64)
            // Extern "C" callees have no With prologue: the C ABI decides their
            // parameter shape, so the share-place ref-table contract does not
            // apply. value_ref_abi still records caller-retains ownership.
            if self.sema.extern_fn_names.contains(sema_sym):
                continue
            let cg_sym = self.codegen_sym_for_sema_sym(sema_sym)
            let fn_raw = self.fn_values.get(sema_sym)
            let fn_cg = self.fn_values.get(cg_sym)
            let function = if fn_raw.is_some(): fn_raw.unwrap() as i64 else if fn_cg.is_some(): fn_cg.unwrap() as i64 else: 0
            for pi in 0..self.sema.sig_get_param_count(si):
                if self.sema.sig_param_uses_value_ref_abi(si, pi) == 0:
                    continue
                let ref_table = self.is_ref_param(sema_sym, pi) or self.is_ref_param(cg_sym, pi)
                var llvm_pointer = false
                if function != 0:
                    let sret_raw = self.extern_fn_has_sret.get(sema_sym)
                    let sret_cg = self.extern_fn_has_sret.get(cg_sym)
                    let sret = if sret_raw.is_some(): sret_raw.unwrap() else if sret_cg.is_some(): sret_cg.unwrap() else: 0
                    let incoming = wl_get_param(function, pi + (if sret != 0: 1 else: 0))
                    llvm_pointer = incoming != 0 and wl_get_type_kind(wl_type_of(incoming)) == wl_pointer_type_kind()
                var fact = AnalysisFact.new(AnalysisStage.Codegen, AnalysisFactKind.Invariant)
                fact.id = si
                fact.parent = si
                fact.symbol = sema_sym
                fact.index = pi
                fact.type_id = self.sema.sig_param_type(si, pi)
                fact.effects = self.sema.sig_param_effect(si, pi)
                fact.flags = 1 | (if ref_table: 2 else: 0) | (if llvm_pointer: 4 else: 0) | (if function != 0: 8 else: 0)
                fact.name = with_str_clone_ref(self.sema.pool_resolve(sema_sym))
                fact.detail = f"share-place declaration emitted={function != 0} ref-table={ref_table} llvm-pointer={llvm_pointer}"
                let selected = self.analysis_fact_selected(&fact)
                self.analysis_add(move fact)
                if selected and function != 0 and (not ref_table or not llvm_pointer):
                    self.analysis_fail(f"declaration {self.sema.pool_resolve(sema_sym)} sig={si} param={pi}: share-place contract ref-table={ref_table} llvm-pointer={llvm_pointer}")

    // Whole-module proof that every emitted function's LLVM return shape agrees
    // with its finalized Sema signature. A value-returning Sema signature
    // emitted as LLVM void without sret means callers read a value the callee
    // never produces (#653 declaration shape). Extern, async (Task-wrapped),
    // generator, and sret signatures lower their returns deliberately.
    fn audit_return_shape_contracts():
        if self.analysis_enabled == 0:
            return
        for si in 0..self.sema.sig_names.len() as i32:
            let sema_sym = self.sema.sig_names.get(si as i64)
            if self.sema.extern_fn_names.contains(sema_sym):
                continue
            if self.sema.task_fns.contains(sema_sym) or self.sema.generator_fn_state_syms.contains(sema_sym):
                continue
            let cg_sym = self.codegen_sym_for_sema_sym(sema_sym)
            let fn_ty_raw = self.fn_fn_types.get(sema_sym)
            let fn_ty_cg = self.fn_fn_types.get(cg_sym)
            let fn_ty = if fn_ty_raw.is_some(): fn_ty_raw.unwrap() else if fn_ty_cg.is_some(): fn_ty_cg.unwrap() else: 0
            if fn_ty == 0:
                continue
            let sret_raw = self.extern_fn_has_sret.get(sema_sym)
            let sret_cg = self.extern_fn_has_sret.get(cg_sym)
            let has_sret = (if sret_raw.is_some(): sret_raw.unwrap() else if sret_cg.is_some(): sret_cg.unwrap() else: 0) != 0
            let sema_ret = self.sema.sig_return_type(si)
            if sema_ret <= 0:
                continue
            let ret_kind = self.sema.get_type_kind(self.sema.resolve_alias(sema_ret as TypeId))
            let sema_returns_value = ret_kind != TypeKind.TY_VOID and ret_kind != TypeKind.TY_NEVER
            let llvm_is_void = wl_get_type_kind(wl_get_return_type(fn_ty)) == wl_void_type_kind()
            var fact = AnalysisFact.new(AnalysisStage.Codegen, AnalysisFactKind.Invariant)
            fact.id = si
            fact.symbol = sema_sym
            fact.type_id = sema_ret
            fact.flags = 16 | (if sema_returns_value: 32 else: 0) | (if llvm_is_void: 64 else: 0) | (if has_sret: 128 else: 0)
            fact.name = with_str_clone_ref(self.sema.pool_resolve(sema_sym))
            fact.detail = f"return-shape sema-ret={sema_ret} llvm-void={llvm_is_void} sret={has_sret}"
            let selected = self.analysis_fact_selected(&fact)
            self.analysis_add(move fact)
            if selected and sema_returns_value and llvm_is_void and not has_sret:
                self.analysis_fail(f"declaration {self.sema.pool_resolve(sema_sym)} sig={si}: Sema return type {sema_ret} emitted as LLVM void without sret")

    // Coverage proof for the instrumentation itself. Every reachable ordinary MIR
    // call argument must pass through one recorded marshalling branch; otherwise an
    // uninstrumented Codegen path could hide a contract divergence.
    mut fn audit_codegen_call_coverage():
        if self.analysis_enabled == 0 or self.analysis_query != "audit":
            return
        for bi in 0..self.mir_bodies_len() as i32:
            let body = self.mir_body_at(bi as i64)
            if body.lowering_failed != 0:
                continue
            let reachable = self.mir_reachable_blocks(body)
            for bb in 0..body.block_count():
                if reachable.get(bb as i64) == 0 or body.term_kind(bb) != TermKind.TK_CALL:
                    continue
                let args_id = body.term_data1(bb)
                if args_id < 0 or args_id >= body.call_arg_counts.len() as i32:
                    self.analysis_fail(f"body {body.fn_sym} bb={bb}: call argument id {args_id} is out of range")
                    continue
                if body.call_intrinsic(args_id) != MirIntrinsic.NONE:
                    continue
                let count = body.call_arg_counts.get(args_id as i64)
                for ai in 0..count:
                    if not self.analysis_has_call_argument(body.fn_sym, args_id, ai):
                        let name = if body.call_mono_sym(args_id) != 0: with_str_clone_ref(self.sema.pool_resolve(body.call_mono_sym(args_id))) else: "<unresolved>"
                        self.analysis_fail(f"call {name} body={body.fn_sym} bb={bb} args={args_id} param={ai}: no Codegen marshalling fact")

    mut fn record_codegen_call_argument(body: &MirBody, args_id: i32, operand: i32, param_index: i32, strategy: AnalysisMarshalStrategy, raw: i64, marshaled: i64):
        if self.analysis_enabled == 0:
            return
        let sig = body.call_sig_index(args_id)
        let mono = body.call_mono_sym(args_id)
        let name = if mono != 0: with_str_clone_ref(self.sema.pool_resolve(mono)) else if sig >= 0 and sig < self.sema.sig_names.len() as i32: with_str_clone_ref(self.sema.pool_resolve(self.sema.sig_names.get(sig as i64))) else: "<unresolved>"
        let op_kind = if operand >= 0 and operand < body.operand_kinds.len() as i32: body.operand_kinds.get(operand as i64) else: -1
        let share = sig >= 0 and param_index >= 0 and param_index < self.sema.sig_get_param_count(sig) and self.sema.sig_param_uses_value_ref_abi(sig, param_index) != 0
        // Extern "C" callees marshal per the C ABI, not the With ref-table
        // contract; keep the fact but exempt them from the failure verdicts.
        let sig_sym = if sig >= 0 and sig < self.sema.sig_names.len() as i32: self.sema.sig_names.get(sig as i64) else: 0
        let callee_is_extern = sig_sym != 0 and self.sema.extern_fn_names.contains(sig_sym)
        let ref_table = mono != 0 and self.is_ref_param(mono, param_index)
        var fact = AnalysisFact.new(AnalysisStage.Codegen, AnalysisFactKind.CodegenArgument)
        fact.id = operand
        fact.parent = args_id
        fact.node = body.call_ast_node(args_id)
        fact.body_sym = body.fn_sym
        fact.symbol = mono
        fact.index = param_index
        fact.type_id = self.mir_operand_sema_type(body, operand)
        fact.effects = if sig >= 0 and param_index >= 0 and param_index < self.sema.sig_get_param_count(sig): self.sema.sig_param_effect(sig, param_index) else: 0
        fact.flags = (strategy as i32) | ((op_kind & 255) << 8) | (if share: 65536 else: 0) | (if ref_table: 131072 else: 0)
        fact.name = with_str_clone_ref(name)
        // Strategy verdicts are derived before the enum's last use below;
        // analysis_marshal_strategy_name consumes it.
        let strategy_unmarshaled = strategy == AnalysisMarshalStrategy.DirectValue or strategy == AnalysisMarshalStrategy.MissingSignature
        let strategy_temp_copy = strategy == AnalysisMarshalStrategy.TemporaryAddress and (op_kind == OperandKind.OK_COPY or op_kind == OperandKind.OK_MOVE)
        fact.detail = analysis_marshal_strategy_name(strategy) ++ f" raw={raw} marshaled={marshaled} sig={sig} sema-share={share} ref-table={ref_table}"
        let selected = self.analysis_fact_selected(&fact)
        self.analysis_add(move fact)
        if selected and share and not callee_is_extern and not ref_table:
            self.analysis_fail(f"call {name} body={body.fn_sym} args={args_id} param={param_index}: Sema share-place contract is absent from Codegen ref table")
        if selected and share and not callee_is_extern and strategy_unmarshaled:
            self.analysis_fail(f"call {name} body={body.fn_sym} args={args_id} param={param_index}: share-place parameter was not marshaled as an address")
        if selected and share and not callee_is_extern and strategy_temp_copy:
            self.analysis_fail(f"call {name} body={body.fn_sym} args={args_id} param={param_index}: addressable share-place operand was copied into a temporary")

    fn record_codegen_param_binding(body: &MirBody, fn_sym: i32, param_index: i32, strategy: AnalysisMarshalStrategy, incoming: i64, storage: i64):
        if self.analysis_enabled == 0:
            return
        let sig = self.sema.get_sig(fn_sym)
        let share = sig >= 0 and param_index < self.sema.sig_get_param_count(sig) and self.sema.sig_param_uses_value_ref_abi(sig, param_index) != 0
        let ref_table = self.is_ref_param(fn_sym, param_index)
        let incoming_ptr = incoming != 0 and wl_get_type_kind(wl_type_of(incoming)) == wl_pointer_type_kind()
        let name = self.sema.pool_resolve(fn_sym)
        var fact = AnalysisFact.new(AnalysisStage.Codegen, AnalysisFactKind.Parameter)
        fact.id = param_index
        fact.parent = sig
        fact.body_sym = body.fn_sym
        fact.symbol = fn_sym
        fact.index = param_index
        fact.type_id = if param_index + 1 < body.local_type_ids.len() as i32: body.local_type_ids.get((param_index + 1) as i64) else: 0
        fact.effects = if sig >= 0 and param_index < self.sema.sig_get_param_count(sig): self.sema.sig_param_effect(sig, param_index) else: 0
        fact.flags = (strategy as i32) | (if share: 65536 else: 0) | (if ref_table: 131072 else: 0) | (if incoming_ptr: 262144 else: 0)
        fact.name = with_str_clone_ref(name)
        // Derived before analysis_marshal_strategy_name consumes the enum.
        let strategy_not_alias = strategy != AnalysisMarshalStrategy.CalleePlaceAlias
        fact.detail = analysis_marshal_strategy_name(strategy) ++ f" incoming={incoming} storage={storage} sig={sig} sema-share={share} ref-table={ref_table} llvm-pointer={incoming_ptr}"
        let selected = self.analysis_fact_selected(&fact)
        self.analysis_add(move fact)
        if selected and share and not ref_table:
            self.analysis_fail(f"callee {name} sig={sig} param={param_index}: Sema share-place contract is absent from Codegen ref table")
        if selected and share and strategy_not_alias:
            self.analysis_fail(f"callee {name} sig={sig} param={param_index}: share-place parameter does not alias the incoming caller place")

fn Codegen.init_with_opt(module_name: &str, opt_level: i32) -> Codegen:
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
        overflow_mode: overflow_mode_default(),
        analysis_enabled: 0,
        analysis_query: "",
        analysis_report: AnalysisReport.init(),
        analysis_last_marshal_strategy: AnalysisMarshalStrategy.DirectValue,
        current_ret_type: 0,
        mir_emit_mutual_tail_call: 0,
        async_trampolines: HashMap.new(),
        current_function: 0,
        current_function_name_sym: 0,
        current_function_node: 0,
        current_method_owner_sym: 0,
        current_drop_origin_ptr: 0,
        current_drop_origin_len: 0,
        current_drop_needs_guard: true,
        member_drop_depth: 0,
        sym_vec: 0, sym_option: 0, sym_result: 0, sym_hashmap: 0,
        sym_hashset: 0, sym_btreemap: 0, sym_btreeset: 0, sym_handle: 0, sym_slotmap: 0, sym_slotmapslot: 0,
        sym_vecslot: 0, sym_vecrange: 0, sym_veciterref: 0, sym_veciterplace: 0,
        sym_box: 0, sym_context_error: 0,
        sym_Self: 0, sym_self: 0, sym_unit: 0,
        sym_bool: 0, sym_usize: 0, sym_isize: 0, sym_void: 0,
        sym_never: 0, sym_str: 0, sym_cstr: 0,
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
        generated_mir_body_syms: HashMap.new(),
        extern_fn_has_sret: HashMap.new(),
        extern_fn_byval_params: HashMap.new(),
        extern_fn_byval_types: HashMap.new(),
        extern_fn_sret_type: HashMap.new(),
        extern_fn_direct_params: HashMap.new(),
        extern_fn_direct_param_types: HashMap.new(),
        extern_fn_direct_ret_type: HashMap.new(),
        struct_type_map: HashMap.new(),
        shadow_alias_map: HashMap.new(),
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
        generic_enum_inst_types: HashMap.new(),
        generic_enum_inst_syms: HashMap.new(),
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
        module_drop_global_syms: Vec.new(),
        module_drop_global_tids: Vec.new(),
        with_fn_link_names: HashMap.new(),
        const_int_syms: Vec.new(),
        const_int_vals: Vec.new(),
        decl_source_paths: Vec.new(),
        current_decl_source_file: "<unknown>",
        module_object_mode: 0,
        bundle_prefixes: embedded_bundle_prefixes(),
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
        trait_method_flags: Vec.new(),
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
        slotmap_cache_map: HashMap.new(),
        type_binding_syms: Vec.new(),
        type_binding_types: Vec.new(),
        type_bindings_len: 0,
        fn_default_starts: HashMap.new(),
        fn_default_counts: HashMap.new(),
        source_file: "<unknown>",
        source_text: "",
        tracked_input_root: "",
        tracked_input_paths: Vec.new(),
        mir_dispatch_count: 0,
        mir_ptr: 0,
        unit_total: 0,
        unit_index: 0,
        unit_assign: HashMap.new(),
        unit_rename_index: HashMap.new(),
        mir_local_ptrs: HashMap.new(),
        mir_local_values: HashMap.new(),
        mir_memory_locals: HashMap.new(),
        mir_local_types: HashMap.new(),
        mir_indirect_value_local_types: HashMap.new(),
        mir_ref_capture_local_types: HashMap.new(),
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

impl Codegen:
    // #685 inc-2 (retired by D22/#691 drop widening): the manual
    // dispose_tables free list is gone. Codegen's own drop glue frees every
    // Vec/HashMap table exactly once when the consumed receiver drops at
    // deinit's end; a manual free list on top of it double-frees.
    // #685 inc-2: deinit CONSUMES the Codegen — dispose the LLVM resources
    // (they read self), then the consumed receiver's drop frees the tables.
    move fn deinit():
        wl_builder_dispose(self.builder)
        wl_module_dispose(self.llmod)
        wl_context_dispose(self.context)
        wl_dispose_target_machine(self.target_machine)

    // ── Public API (called by Driver) ─────────────────────────────────

    fn optimize(level: i32):
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

    fn emit_object_file(path: &str) -> i32:
        wl_emit_object(self.target_machine, self.llmod, path)

    fn print_ir():
        wl_print_ir(self.llmod)

    fn verify() -> i32:
        wl_verify_module(self.llmod)

    // ── Type fallback helper ─────────────────────────────────────────

    // Returns i32 type as a fallback when type resolution fails.
    // Sets had_error so the compilation is marked as failed.
    mut fn type_fallback() -> i64:
        self.had_error = 1
        wl_i32_type(self.context)

    // ── Debug info helpers ────────────────────────────────────────────

    mut fn debug_init_module():
        if self.debug_info == 0:
            return
        self.di_source = Source.from_string(self.source_file, self.source_text, 0)
        self.di_builder = wl_di_create_builder(self.llmod)

        // Split source path into directory and filename
        var last_slash = -1
        for i in 0..self.source_file.len() as i32:
            if self.source_file.byte_at(i as i64) == 47:
                last_slash = i

        var dir = "."
        // #747: an owned copy — plain field assignment would move source_file
        // out of self and poison the slice reads below.
        var file = with_str_clone_ref(self.source_file)
        if last_slash >= 0:
            dir = self.source_file.slice(0, last_slash as i64)
            file = self.source_file.slice((last_slash + 1) as i64, self.source_file.len())

        self.di_file = wl_di_create_file(self.di_builder, file, dir)

        wl_add_module_flag_int(self.llmod, "Debug Info Version", wl_debug_metadata_version())
        wl_add_module_flag_int(self.llmod, "Dwarf Version", 5)

        let is_opt = 0
        self.di_compile_unit = wl_di_create_compile_unit(
            self.di_builder, self.di_file, "with", is_opt, 5, wl_dwarf_lang_with())

    fn debug_finalize_module():
        if self.di_builder != 0:
            wl_di_finalize(self.di_builder)

    mut fn debug_enter_function(fn_node: i32, fn_sym: i32, function: i64):
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

    fn debug_set_location(byte_offset: i32):
        if self.di_builder == 0:
            return
        if byte_offset <= 0:
            // Synthesized code (span 0) inside a function that HAS debug
            // info must still carry a location: the LLVM verifier rejects
            // location-less calls to inlinable (defined) callees, which the
            // in-unit runtime made real (#761 — derived debug_str calling
            // with_fmt_buf_* definitions). Line 0 is LLVM's spelling for
            // compiler-generated code; clear only outside any subprogram.
            var zero_scope = self.di_current_scope
            if zero_scope == 0:
                let zsp = self.di_fn_subprograms.get(self.current_function_name_sym)
                if zsp.is_some():
                    zero_scope = zsp.unwrap() as i64
            if zero_scope != 0:
                let zero_loc = wl_di_create_debug_location(self.context, 0, 0, zero_scope)
                wl_di_set_current_location(self.builder, zero_loc)
                return
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

    fn debug_clear_location():
        if self.di_builder == 0:
            return
        wl_di_clear_current_location(self.builder)

    mut fn debug_push_lexical_block(byte_offset: i32):
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

    fn debug_get_di_type(sema_tid: i32) -> i64:
        let cached = self.di_type_cache.get(sema_tid)
        if cached.is_some():
            return cached.unwrap() as i64
        let di_ty = self.debug_create_di_type(sema_tid)
        self.di_type_cache.insert(sema_tid, di_ty)
        di_ty

    fn debug_create_di_type(sema_tid: i32) -> i64:
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

    mut fn abi_size_of(ty: i64) -> i64:
        if ty == 0:
            self.had_error = 1
            return 0
        if wl_get_type_kind(ty) == wl_void_type_kind():
            return 0
        let dl = wl_get_module_data_layout(self.llmod)
        if dl == 0:
            self.had_error = 1
            return 0
        wl_abi_size_of(dl, ty)

    // MIR is shared read-only via raw pointer: the caller retains ownership
    // and must keep the module alive through generation. Removes the per-cg
    // deep copy of all MIR bodies, and is the sharing contract per-unit
    // generation threads reuse (#681).
    mut fn gen_module_from_mir(mir_ptr: i64, pool: AstPool) -> i32:
        let mir_err = unsafe { validate_mir_module((*(mir_ptr as *const MirModule))) }
        if mir_err.len() > 0:
            with_eprint("error: invalid MIR input for LLVM backend: " ++ mir_err)
            self.had_error = 1
            return 1
        self.mir_ptr = mir_ptr
        self.gen_module(pool)

    fn mir_bodies_len() -> i64: unsafe { (*(self.mir_ptr as *const MirModule)).bodies.len() }
    // Codegen only observes bodies owned by the frozen MirModule. Returning an
    // owned MirBody here would shallow-copy every Vec field and make the local
    // copy's scope-exit drop free storage still owned by the module.
    fn mir_body_at(i: i64) -> &MirBody:
        let mir = self.mir_ptr as *const MirModule
        let body_count = unsafe { (*mir).bodies.len() }
        assert(i >= 0 and i < body_count)
        unsafe { ((*mir).bodies.ptr + (i as usize)) as &MirBody }
    fn mir_fn_syms_len() -> i64: unsafe { (*(self.mir_ptr as *const MirModule)).body_fn_syms.len() }
    fn mir_fn_sym_at(i: i64) -> i32: unsafe { (*(self.mir_ptr as *const MirModule)).body_fn_syms.get(i) }
    fn mir_find_body_idx(sym: i32) -> i32: unsafe { (*(self.mir_ptr as *const MirModule)).find_body(sym) }
    fn mir_resolve_alias_at(tid: i32) -> i32: unsafe { (*(self.mir_ptr as *const MirModule)).mir_resolve_alias(tid) }
    fn mir_type_kind_at(tid: i32) -> i32: unsafe { (*(self.mir_ptr as *const MirModule)).mir_get_type_kind(tid) }
    fn mir_type_d0_at(tid: i32) -> i32: unsafe { (*(self.mir_ptr as *const MirModule)).mir_get_type_d0(tid) }
    fn mir_type_d1_at(tid: i32) -> i32: unsafe { (*(self.mir_ptr as *const MirModule)).mir_get_type_d1(tid) }
    fn mir_type_d2_at(tid: i32) -> i32: unsafe { (*(self.mir_ptr as *const MirModule)).mir_get_type_d2(tid) }
    fn mir_type_extra_at(idx: i32) -> i32: unsafe { (*(self.mir_ptr as *const MirModule)).mir_get_type_extra(idx) }
    fn mir_type_kinds_len() -> i64: unsafe { (*(self.mir_ptr as *const MirModule)).sema_type_kinds.len() }
    fn mir_type_d0_len() -> i64: unsafe { (*(self.mir_ptr as *const MirModule)).sema_type_d0.len() }
    fn mir_type_d1_len() -> i64: unsafe { (*(self.mir_ptr as *const MirModule)).sema_type_d1.len() }
    fn mir_type_d2_len() -> i64: unsafe { (*(self.mir_ptr as *const MirModule)).sema_type_d2.len() }
    fn mir_type_extra_len() -> i64: unsafe { (*(self.mir_ptr as *const MirModule)).sema_type_extra.len() }
    fn mir_type_name_at(tid: i32) -> i32: unsafe { (*(self.mir_ptr as *const MirModule)).mir_get_type_name(tid) }
    fn mir_type_kinds_get(i: i64) -> i32: unsafe { (*(self.mir_ptr as *const MirModule)).sema_type_kinds.get(i) }
    fn mir_type_d0_get(i: i64) -> i32: unsafe { (*(self.mir_ptr as *const MirModule)).sema_type_d0.get(i) }

    fn unit_owns(sym: i32) -> bool:
        if self.unit_total <= 1:
            return true
        let u = self.unit_assign.get(sym)
        (if u.is_some(): u.unwrap() else: 0) == self.unit_index

    // Dual-key the assignment: MIR carries sema-space syms, but codegen
    // paths (and the demotion walk's name lookups) resolve in cg-intern
    // space. Both keys map to the same unit and rename index.
    mut fn unit_assign_insert(sema_sym: i32, unit: i32, ridx: i32):
        self.unit_assign.insert(sema_sym, unit)
        self.unit_rename_index.insert(sema_sym, ridx)
        let alias_text = self.sema_symbol_text(sema_sym)
        if alias_text.len() > 0:
            let cg_sym = self.intern.intern(alias_text)
            if cg_sym != sema_sym:
                self.unit_assign.insert(cg_sym, unit)
                self.unit_rename_index.insert(cg_sym, ridx)

    // Units other than the owner must not DEFINE externally-linked fns they
    // did not plan for (synthesized bodies — e.g. prelude trait defaults —
    // are emitted by passes shared across units). Deterministic module walk;
    // renamed __wcu$ fns are owner-defined already, internal/private fns are
    // legitimately per-unit (trampolines), declarations are untouched.
    mut fn unit_demote_foreign_definitions():
        if self.unit_total <= 1 or self.unit_index == 0:
            return
        var f = wl_get_first_function(self.llmod)
        while f != 0:
            if wl_fn_is_declaration(f) == 0 and wl_get_linkage(f) == wl_external_linkage():
                let nm = wl_get_value_name(f)
                if not nm.starts_with("__wcu$") and nm != "main":
                    let nm_sym = self.intern.intern(nm)
                    if not self.unit_owns(nm_sym):
                        wl_delete_function_body(f)
            f = wl_get_next_function(f)

    // Non-empty when a would-be-internal planned fn is instead promoted
    // external under a collision-proof name; identical in every unit so
    // cross-unit calls resolve at link time (#681, the __wcu$ scheme).
    fn unit_promoted_name(sym: i32, effective_name: &str) -> str:
        if self.unit_total <= 1:
            return ""
        let ridx = self.unit_rename_index.get(sym)
        if not ridx.is_some():
            return ""
        f"__wcu${ridx.unwrap()}$" ++ effective_name

    // ── Helper: is method symbol ──────────────────────────────────────

    fn is_method_symbol(sym: i32) -> bool:
        let name = self.intern.resolve(sym)
        for i in 0..name.len() as i32:
            if name.byte_at(i as i64) == 46:  // '.'
                return true
        false

    fn dyn_trait_from_type_node(type_node: i32) -> i32:
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
            if self.sema.type_symbol_is_std_box(name_sym) != 0 and g_count == 1:
                return self.dyn_trait_from_type_node(self.pool.get_extra(g_extra))
        0

fn codegen_hash_type_trait_key(type_sym: i32, trait_sym: i32) -> i32:
    type_sym * 10007 + trait_sym

impl Codegen:
    mut fn get_dyn_fat_ptr_type() -> i64:
        if self.dyn_fat_ptr_type != 0:
            return self.dyn_fat_ptr_type
        let ptr_ty = wl_ptr_type(self.context)
        let fat_types: Vec[i64] = Vec.new()
        fat_types.push(ptr_ty)
        fat_types.push(ptr_ty)
        self.dyn_fat_ptr_type = wl_struct_type(self.context, vec_data_i64(&fat_types), 2, 0)
        self.dyn_fat_ptr_type

    fn llvm_type_is_dyn_fat_ptr(ty: i64) -> i32:
        if ty == 0 or wl_get_type_kind(ty) != wl_struct_type_kind():
            return 0
        if wl_count_struct_elem_types(ty) != 2:
            return 0
        let ptr_ty = wl_ptr_type(self.context)
        if wl_struct_get_type_at(ty, 0) != ptr_ty:
            return 0
        if wl_struct_get_type_at(ty, 1) != ptr_ty:
            return 0
        1

    fn get_fn_dyn_param_trait(fn_sym: i32, param_idx: i32) -> i32:
        let base_opt = self.fn_dyn_param_starts.get(fn_sym)
        if param_idx < 0:
            return 0
        if base_opt.is_some():
            let base = base_opt.unwrap()
            let slot = base + param_idx
            if slot >= 0 and slot < self.fn_dyn_param_data.len() as i32:
                let recorded_trait = self.fn_dyn_param_data.get(slot as i64)
                if recorded_trait != 0:
                    if self.trait_map.get(recorded_trait).is_some():
                        return recorded_trait
                    let cg_trait = self.sema_sym_to_codegen_sym(recorded_trait)
                    if cg_trait != 0:
                        return cg_trait
                    return recorded_trait

        let fn_name = self.intern.resolve(fn_sym)
        let sema_fn_sym = if fn_name.len() > 0: self.sema.pool_lookup_symbol(fn_name) else: 0
        if sema_fn_sym == 0:
            return 0
        if not self.sema.fn_decl_nodes.contains(sema_fn_sym):
            return 0
        let fn_node = self.sema.fn_decl_nodes.get(sema_fn_sym).unwrap()
        let meta = self.sema.ast.find_fn_meta(fn_node)
        if meta < 0:
            return 0
        let param_count = self.sema.ast.fn_meta_param_count(meta)
        if param_idx < 0 or param_idx >= param_count:
            return 0
        let param_start = self.sema.ast.fn_meta_param_start(meta)
        let p_type_node = self.sema.ast.fn_param_type(param_start, param_idx)
        let sema_trait = self.sema.trait_object_from_type_node(p_type_node)
        if sema_trait == 0:
            return 0
        let cg_trait2 = self.sema_sym_to_codegen_sym(sema_trait)
        if cg_trait2 != 0:
            return cg_trait2
        sema_trait

    fn get_raw_fn_dyn_param_trait(raw_fn_sym: i32, param_idx: i32) -> i32:
        if raw_fn_sym == 0 or param_idx < 0:
            return 0
        var sema_fn_sym = raw_fn_sym
        if not self.sema.fn_decl_nodes.contains(sema_fn_sym):
            let fn_text = self.sema_symbol_text(raw_fn_sym)
            if fn_text.len() > 0:
                sema_fn_sym = self.sema.pool_lookup_symbol(fn_text)
        if sema_fn_sym == 0 or not self.sema.fn_decl_nodes.contains(sema_fn_sym):
            return 0
        let fn_node = self.sema.fn_decl_nodes.get(sema_fn_sym).unwrap()
        let meta = self.sema.ast.find_fn_meta(fn_node)
        if meta < 0:
            return 0
        let param_count = self.sema.ast.fn_meta_param_count(meta)
        if param_idx >= param_count:
            return 0
        let param_start = self.sema.ast.fn_meta_param_start(meta)
        let p_type_node = self.sema.ast.fn_param_type(param_start, param_idx)
        let sema_trait = self.sema.trait_object_from_type_node(p_type_node)
        if sema_trait == 0:
            return 0
        let cg_trait = self.sema_sym_to_codegen_sym(sema_trait)
        if cg_trait != 0:
            return cg_trait
        sema_trait

    fn is_const_int_value(val: i64) -> bool:
        // LLVMIsConstant is broader than integer constants; only this kind is safe
        // to pass to LLVMConstIntGetSExtValue.
        val != 0 and wl_get_value_kind(val) == 18

    mut fn coerce_value_to_type(val: i64, target_ty: i64) -> i64:
        if val == 0 or target_ty == 0:
            return val
        let val_ty = wl_type_of(val)
        if val_ty == target_ty:
            return val

        let vk = wl_get_type_kind(val_ty)
        let tk = wl_get_type_kind(target_ty)

        if vk == wl_integer_type_kind() and tk == wl_pointer_type_kind():
            if self.is_const_int_value(val) and wl_const_int_sext_val(val) == 0:
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

    mut fn gen_fn_to_fat_ptr_thunk(fn_val: i64, fat_ty: i64) -> i64:
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
        // On win64 a concrete function returning an aggregate >8B is physically
        // sret-lowered by declare_function: `void(ptr sret, real_args...)`. A
        // closure fn type (mir_build_closure_fn_type), by contrast, is by-value
        // (`AGG(ptr ctx, real_args...)`) and LLVM inserts the hidden sret pointer
        // FIRST — so the physical closure convention is `void(sret, ctx, args)`.
        // Naively prepending ctx to the sret-lowered concrete type yields
        // `void(ctx, sret, args)`, swapping ctx and sret and corrupting the
        // result (#806/#819). Rebuild the thunk by-value to match the closure
        // convention, and let LLVM sret-lower both the thunk definition and the
        // closure call site identically.
        let concrete_sret_ty = wl_get_param_sret_type(fn_val, 0)
        if concrete_sret_ty != 0:
            let thunk_params: Vec[i64] = Vec.new()
            thunk_params.push(ptr_ty)
            // Real args are the concrete params after the leading sret pointer.
            for pi in 1..orig_param_count:
                thunk_params.push(wl_get_fn_param_type(orig_fn_ty, pi))
            let thunk_fn_ty = wl_function_type(concrete_sret_ty, vec_data_i64(&thunk_params), thunk_params.len() as i32, 0)
            let thunk_id = self.closure_counter
            self.closure_counter = thunk_id + 1
            let thunk_name = f"__fn_thunk_{thunk_id}"
            let thunk_fn = wl_add_function(self.llmod, thunk_name, thunk_fn_ty)
            wl_set_linkage(thunk_fn, wl_internal_linkage())
            let saved_bb = wl_get_insert_block(self.builder)
            let entry = wl_append_bb(self.context, thunk_fn, "entry")
            wl_position_at_end(self.builder, entry)
            // Result buffer for the concrete sret call; loaded back and returned
            // by value so LLVM lowers the thunk return the same way the closure
            // call site is lowered. Target the thunk explicitly — self.current_function
            // still names the outer function that triggered the coercion.
            let result_buf = wl_create_entry_alloca(self.builder, thunk_fn, concrete_sret_ty)
            let call_args: Vec[i64] = Vec.new()
            call_args.push(result_buf)
            for pi in 1..orig_param_count:
                call_args.push(wl_get_param(thunk_fn, pi))
            let call = wl_build_call(self.builder, orig_fn_ty, fn_val, vec_data_i64(&call_args), orig_param_count)
            wl_add_call_sret_attr(self.context, call, 0, concrete_sret_ty)
            let loaded = wl_build_load(self.builder, concrete_sret_ty, result_buf)
            wl_build_ret(self.builder, loaded)
            wl_position_at_end(self.builder, saved_bb)
            var fat_s = wl_get_undef(fat_ty)
            fat_s = wl_build_insert_value(self.builder, fat_s, thunk_fn, 0)
            fat_s = wl_build_insert_value(self.builder, fat_s, wl_const_null(ptr_ty), 1)
            return fat_s
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
        // Anonymous fat-ptr coercion thunk: referenced only by-address at its
        // creation site (insert_value below), never by name across units. Give
        // it internal linkage so globaldce can drop it when the coercion is
        // dead — otherwise a dead thunk keeps its `call @callee` and breaks the
        // link on targets without default dead-strip (linux gold, no
        // --gc-sections). This is what lets a dead extern-fn alias DCE cleanly.
        wl_set_linkage(thunk_fn, wl_internal_linkage())
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

    fn coerce_struct_value(val: i64, target_ty: i64) -> i64:
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

    fn debug_call_coerce_enabled() -> bool:
        let raw = with_getenv_str("WITH_DEBUG_CALL_COERCE")
        raw.len() > 0 and raw != "0"

    fn debug_mir_codegen_enabled() -> bool:
        let raw = with_getenv_str("WITH_DEBUG_MIR_CODEGEN")
        raw.len() > 0 and raw != "0"

    fn debug_local_flow_enabled() -> bool:
        let raw = with_getenv_str("WITH_DEBUG_LOCAL_FLOW")
        raw.len() > 0 and raw != "0"

    fn debug_method_dispatch_enabled() -> bool:
        let raw = with_getenv_str("WITH_DEBUG_METHOD_DISPATCH")
        raw.len() > 0 and raw != "0"

    fn debug_pool_flow_enabled() -> bool:
        let _ = self
        let raw = with_getenv_str("WITH_DEBUG_POOL_FLOW")
        raw.len() > 0 and raw != "0"

    fn debug_type_layout_enabled() -> bool:
        let _ = self
        let raw = with_getenv_str("WITH_DEBUG_TYPE_LAYOUT")
        raw.len() > 0 and raw != "0"

    fn debug_fallback_enabled() -> bool:
        let _ = self
        let raw = with_getenv_str("WITH_DEBUG_FALLBACK")
        raw.len() > 0 and raw != "0"

    fn debug_type_layout_field(owner_name: &str, field_index: i32, field_name: i32, type_node: i32, resolved_ty: i64):
        if not self.debug_type_layout_enabled():
            return
        let node_kind = if type_node != 0: self.pool.kind(type_node) else: -1
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

    // Save/restore: the four Vec fields transfer OUT of self here and the
    // caller installs fresh ones (reset_loop_state) before restoring. That is
    // a mutation of self, so the receiver is `mut` and the transfers are
    // spelled — the same correction save_label_registry needed (#691 flip).
    mut fn capture_loop_state() -> LoopState:
        LoopState {
            break_bbs: move self.loop_break_bbs,
            continue_bbs: move self.loop_continue_bbs,
            result_allocas: move self.loop_result_allocas,
            labels: move self.loop_labels,
            depth: self.loop_depth,
        }

    mut fn reset_loop_state():
        self.loop_break_bbs = Vec.new()
        self.loop_continue_bbs = Vec.new()
        self.loop_result_allocas = Vec.new()
        self.loop_labels = Vec.new()
        self.loop_depth = 0

    // Consumes: fields move back into self (see restore_label_registry).
    // D32: field vacates need a mutable path, so the owned param rebinds
    // to a `var` first.
    mut fn restore_loop_state(state: LoopState):
        var st = state
        self.loop_break_bbs = move st.break_bbs
        self.loop_continue_bbs = move st.continue_bbs
        self.loop_result_allocas = move st.result_allocas
        self.loop_labels = move st.labels
        self.loop_depth = st.depth

    mut fn push_loop_context(break_bb: i64, continue_bb: i64, result_alloca: i64, label_sym: i32):
        let idx = self.loop_depth
        var labels: Vec[i32] = move self.loop_labels
        with_codegen_loop_set_break(idx, break_bb)
        with_codegen_loop_set_continue(idx, continue_bb)
        with_codegen_loop_set_result(idx, result_alloca)
        labels.push(label_sym)
        self.loop_labels = labels
        self.loop_depth = idx + 1

    mut fn pop_loop_context():
        var labels: Vec[i32] = move self.loop_labels
        let _ = labels.pop()
        self.loop_labels = labels
        self.loop_depth = self.loop_depth - 1

    fn loop_break_target(idx: i32) -> i64:
        with_codegen_loop_get_break(idx)

    fn loop_continue_target(idx: i32) -> i64:
        with_codegen_loop_get_continue(idx)

    fn loop_result_alloca_at(idx: i32) -> i64:
        with_codegen_loop_get_result(idx)

    fn debug_call_coerce_failure(context: &str, call_node: i32, arg_index: i32, arg_node: i32, actual_val: i64, expected_ty: i64) -> Unit:
        if not self.debug_call_coerce_enabled():
            return
        var msg = "[call-coerce] " ++ context
        if self.current_function_name_sym != 0:
            msg = msg ++ " fn=" ++ self.function_symbol_name(self.current_function_name_sym)
        msg = msg ++ f" arg={arg_index}"
        var line = -1
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

    mut fn enforce_coerced_type(value: i64, expected_ty: i64, context: &str) -> i64:
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
        var msg = "error: " ++ context
        msg = msg ++ f" actual={self.llvm_type_mangle(wl_type_of(value))}"
        msg = msg ++ f" expected={self.llvm_type_mangle(expected_ty)}"
        if self.current_function_name_sym != 0:
            msg = msg ++ f" fn={self.intern.resolve(self.current_function_name_sym)}"
        with_eprint(msg)
        self.build_default_value(expected_ty)

    fn canonical_local_sym(sym: i32) -> i32:
        if sym <= 0:
            return sym
        let text = self.intern.resolve(sym)
        if text.len() == 0:
            return sym
        self.intern.intern(text)

    fn record_local(sym: i32, local_ptr: i64, ty: i64, is_mut: i32):
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

    fn record_local_sema_type(sym: i32, sema_ty: i32):
        if sym == 0 or sema_ty == 0:
            return
        self.local_sema_types.insert(sym, sema_ty)
        let canon = self.canonical_local_sym(sym)
        if canon != 0 and canon != sym:
            self.local_sema_types.insert(canon, sema_ty)

    fn record_local_fn_sig(sym: i32, fn_sig: i64):
        self.local_fn_sigs.insert(sym, fn_sig)
        let canon = self.canonical_local_sym(sym)
        if canon != 0 and canon != sym:
            self.local_fn_sigs.insert(canon, fn_sig)

    fn record_local_pointee_struct(sym: i32, pointee_sym: i32):
        self.local_pointee_structs.insert(sym, pointee_sym)
        let canon = self.canonical_local_sym(sym)
        if canon != 0 and canon != sym:
            self.local_pointee_structs.insert(canon, pointee_sym)

    fn record_trait_local(sym: i32, trait_sym: i32):
        self.trait_locals.insert(sym, trait_sym)
        let canon = self.canonical_local_sym(sym)
        if canon != 0 and canon != sym:
            self.trait_locals.insert(canon, trait_sym)

    fn record_trait_local_concrete(sym: i32, type_sym: i32):
        self.trait_local_concrete_types.insert(sym, type_sym)
        let canon = self.canonical_local_sym(sym)
        if canon != 0 and canon != sym:
            self.trait_local_concrete_types.insert(canon, type_sym)

    fn lookup_local_alloca(sym: i32) -> i64:
        let direct = self.local_allocas.get(sym)
        if direct.is_some():
            return direct.unwrap() as i64
        let canon = self.canonical_local_sym(sym)
        if canon != 0 and canon != sym:
            let alias = self.local_allocas.get(canon)
            if alias.is_some():
                return alias.unwrap() as i64
        0

    fn lookup_local_type(sym: i32) -> i64:
        let direct = self.local_types.get(sym)
        if direct.is_some():
            return direct.unwrap() as i64
        let canon = self.canonical_local_sym(sym)
        if canon != 0 and canon != sym:
            let alias = self.local_types.get(canon)
            if alias.is_some():
                return alias.unwrap() as i64
        0

    fn lookup_capture_alloca(sym: i32) -> i64:
        let direct = self.lookup_local_alloca(sym)
        if direct != 0:
            return direct
        let cg_sym = self.sema_sym_to_codegen_sym(sym)
        if cg_sym != 0 and cg_sym != sym:
            return self.lookup_local_alloca(cg_sym)
        0

    fn lookup_capture_type(sym: i32) -> i64:
        let direct = self.lookup_local_type(sym)
        if direct != 0:
            return direct
        let cg_sym = self.sema_sym_to_codegen_sym(sym)
        if cg_sym != 0 and cg_sym != sym:
            return self.lookup_local_type(cg_sym)
        0

    fn lookup_capture_mut(sym: i32) -> i32:
        let direct = self.local_muts.get(sym)
        if direct.is_some():
            return direct.unwrap()
        let cg_sym = self.sema_sym_to_codegen_sym(sym)
        if cg_sym != 0 and cg_sym != sym:
            let cg = self.local_muts.get(cg_sym)
            if cg.is_some():
                return cg.unwrap()
        0

    fn lookup_capture_sema_type(sym: i32) -> i32:
        let direct = self.local_sema_types.get(sym)
        if direct.is_some():
            return direct.unwrap()
        let cg_sym = self.sema_sym_to_codegen_sym(sym)
        if cg_sym != 0 and cg_sym != sym:
            let cg = self.local_sema_types.get(cg_sym)
            if cg.is_some():
                return cg.unwrap()
        0

    fn lookup_local_pointee_struct(sym: i32) -> i32:
        let direct = self.local_pointee_structs.get(sym)
        if direct.is_some():
            return direct.unwrap()
        let canon = self.canonical_local_sym(sym)
        if canon != 0 and canon != sym:
            let alias = self.local_pointee_structs.get(canon)
            if alias.is_some():
                return alias.unwrap()
        0

    fn lookup_trait_local_concrete(sym: i32) -> i32:
        let direct = self.trait_local_concrete_types.get(sym)
        if direct.is_some():
            return direct.unwrap()
        let canon = self.canonical_local_sym(sym)
        if canon != 0 and canon != sym:
            let alias = self.trait_local_concrete_types.get(canon)
            if alias.is_some():
                return alias.unwrap()
        0

    fn arg_lvalue_ptr_for_autoref(arg_node: i32, arg_ty: i64, arg_val: i64) -> i64:
        if arg_node != 0 and self.pool.kind(arg_node) == NodeKind.NK_IDENT:
            let sym = self.pool.get_data0(arg_node)
            let alloca = self.lookup_local_alloca(sym)
            if alloca != 0:
                let local_ty = self.lookup_local_type(sym)
                if local_ty != 0 and wl_get_type_kind(local_ty) == wl_pointer_type_kind():
                    return wl_build_load(self.builder, local_ty, alloca)
                return alloca

        let tmp = self.create_entry_alloca(arg_ty)
        wl_build_store(self.builder, arg_val, tmp)
        tmp

    mut fn coerce_call_arg_to_param(arg_node: i32, arg_val: i64, param_ty: i64, call_context: &str, call_node: i32, arg_index: i32) -> i64:
        if arg_val == 0 or param_ty == 0:
            return arg_val

        var out = arg_val
        let arg_ty = wl_type_of(out)
        let param_kind = wl_get_type_kind(param_ty)
        if param_kind == wl_pointer_type_kind() and wl_get_type_kind(arg_ty) == wl_struct_type_kind() and not self.is_str_type(arg_ty):
            let ptr = self.arg_lvalue_ptr_for_autoref(arg_node, arg_ty, out)
            if ptr != 0:
                out = ptr

        let had_error_before = self.had_error
        let coerced = self.enforce_coerced_type(out, param_ty, "wrong argument type")
        if self.had_error != had_error_before:
            self.debug_call_coerce_failure(call_context, call_node, arg_index, arg_node, out, param_ty)
        coerced

    fn find_dyn_concrete_arg(arg_node: i32, arg_ty: i64) -> DynArgInfo:
        if wl_get_type_kind(arg_ty) == wl_struct_type_kind():
            let nominal_sym = self.find_nominal_type_by_llvm(arg_ty)
            if nominal_sym != 0:
                return DynArgInfo { type_sym: nominal_sym, use_ptr: 0 }

        if wl_get_type_kind(arg_ty) != wl_pointer_type_kind():
            return DynArgInfo { type_sym: 0, use_ptr: 0 }

        if arg_node != 0 and self.pool.kind(arg_node) == NodeKind.NK_UNARY:
            let uop = self.pool.get_data0(arg_node)
            if uop == UnaryOp.UOP_REF or uop == UnaryOp.UOP_RAW_REF_CONST or uop == UnaryOp.UOP_RAW_REF_MUT:
                let inner = self.pool.get_data1(arg_node)
                if self.pool.kind(inner) == NodeKind.NK_IDENT:
                    let base_sym = self.pool.get_data0(inner)
                    let known = self.lookup_trait_local_concrete(base_sym)
                    if known != 0:
                        return DynArgInfo { type_sym: known, use_ptr: 1 }
                    let base_ty = self.lookup_local_type(base_sym)
                    if base_ty != 0:
                        let nominal_sym = self.find_nominal_type_by_llvm(base_ty)
                        if nominal_sym != 0:
                            return DynArgInfo { type_sym: nominal_sym, use_ptr: 1 }
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
                            let nominal_sym = self.find_nominal_type_by_llvm(alt.unwrap() as i64)
                            if nominal_sym != 0:
                                return DynArgInfo { type_sym: nominal_sym, use_ptr: 1 }

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
                let nominal_sym = self.find_nominal_type_by_llvm(sym_ty)
                if nominal_sym != 0:
                    return DynArgInfo { type_sym: nominal_sym, use_ptr: 1 }
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
                    let nominal_sym = self.find_nominal_type_by_llvm(alt.unwrap() as i64)
                    if nominal_sym != 0:
                        return DynArgInfo { type_sym: nominal_sym, use_ptr: 1 }

        // Symbol lookup can miss when parser/resolver symbol IDs diverge; fall
        // back to pointee LLVM type to recover concrete dyn coercions.
        let pointee_ty = wl_get_element_type(arg_ty)
        if pointee_ty != 0:
            let nominal_sym = self.find_nominal_type_by_llvm(pointee_ty)
            if nominal_sym != 0:
                return DynArgInfo { type_sym: nominal_sym, use_ptr: 1 }

        DynArgInfo { type_sym: 0, use_ptr: 0 }

    mut fn build_dyn_trait_value(concrete_val: i64, type_sym: i32, trait_sym: i32) -> i64:
        self.ensure_monomorphized_trait_vtable(type_sym, trait_sym)
        let vg = self.lookup_trait_vtable_global(type_sym, trait_sym)
        if vg == 0:
            with_eprint("error: missing vtable for type '" ++ self.intern.resolve(type_sym) ++ "' implementing trait '" ++ self.intern.resolve(trait_sym) ++ "'")
            self.had_error = 1
            return wl_get_undef(self.get_dyn_fat_ptr_type())

        let alloca = self.create_entry_alloca(wl_type_of(concrete_val))
        wl_build_store(self.builder, concrete_val, alloca)

        let fat_ty = self.get_dyn_fat_ptr_type()
        var fat = wl_get_undef(fat_ty)
        fat = wl_build_insert_value(self.builder, fat, alloca, 0)
        fat = wl_build_insert_value(self.builder, fat, vg, 1)
        fat

    mut fn build_dyn_trait_value_from_ptr(data_ptr: i64, type_sym: i32, trait_sym: i32) -> i64:
        self.ensure_monomorphized_trait_vtable(type_sym, trait_sym)
        let vg = self.lookup_trait_vtable_global(type_sym, trait_sym)
        if vg == 0:
            with_eprint("error: missing vtable for type '" ++ self.intern.resolve(type_sym) ++ "' implementing trait '" ++ self.intern.resolve(trait_sym) ++ "'")
            self.had_error = 1
            return wl_get_undef(self.get_dyn_fat_ptr_type())

        let ptr_ty = wl_ptr_type(self.context)
        let fat_ty = self.get_dyn_fat_ptr_type()
        let erased = wl_build_bitcast(self.builder, data_ptr, ptr_ty)
        var fat = wl_get_undef(fat_ty)
        fat = wl_build_insert_value(self.builder, fat, erased, 0)
        fat = wl_build_insert_value(self.builder, fat, vg, 1)
        fat

    fn infer_local_pointee_struct(value_node: i32, declared_type_node: i32, storage_ty: i64) -> i32:
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
            if uop == UnaryOp.UOP_REF or uop == UnaryOp.UOP_RAW_REF_CONST or uop == UnaryOp.UOP_RAW_REF_MUT:
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

    fn infer_local_concrete_struct(value_node: i32, storage_ty: i64) -> i32:
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
            if uop == UnaryOp.UOP_REF or uop == UnaryOp.UOP_RAW_REF_CONST or uop == UnaryOp.UOP_RAW_REF_MUT:
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

    mut fn coerce_call_args_for_fn_value(fn_sym: i32, fn_val: i64, args_start: i32, arg_node_base_index: i32, args: &Vec[i64], arg_count: i32, call_context: &str, call_node: i32) -> Vec[i64]:
        let out: Vec[i64] = Vec.new()
        let param_count = wl_count_params(fn_val)
        let sret_opt = self.extern_fn_has_sret.get(fn_sym)
        let has_sret = if sret_opt.is_some(): sret_opt.unwrap() else: 0
        let byval_opt = self.extern_fn_byval_params.get(fn_sym)
        let byval_mask = if byval_opt.is_some(): byval_opt.unwrap() as i64 else: 0
        var byval_types: Vec[i64] = Vec.new()
        let byval_types_opt = self.extern_fn_byval_types.get(fn_sym)
        if byval_types_opt.is_some():
            byval_types = vec_copy_i64(byval_types_opt.unwrap())
        let direct_opt = self.extern_fn_direct_params.get(fn_sym)
        let direct_mask = if direct_opt.is_some(): direct_opt.unwrap() as i64 else: 0
        let param_offset = if has_sret != 0: 1 else: 0
        for ai in 0..arg_count:
            var arg_val: i64 = args.get(ai as i64)
            let actual_ai = ai + param_offset
            if actual_ai < param_count:
                var param_ty = wl_type_of(wl_get_param(fn_val, actual_ai))
                if (byval_mask & ((1 as i64) << (ai as u32))) != 0 and ai < byval_types.len() as i32 and byval_types.get(ai as i64) != 0:
                    param_ty = byval_types.get(ai as i64)
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
                // Read the ABI transform recorded when the declaration was made.
                // A @[link_name] extern can occupy the same canonical symbol as
                // an internal runtime helper. On Darwin arm64 its small aggregate
                // parameter is physically an LLVM array, so coercing the native
                // value directly would reject str -> array. Pack through the one
                // recorded C-ABI descriptor before ordinary type coercion.
                if (direct_mask & ((1 as i64) << (ai as u32))) != 0:
                    out.push(self.c_abi_pack_direct_value(arg_val, param_ty))
                    continue
                arg_val = self.coerce_call_arg_to_param(arg_node, arg_val, param_ty, call_context, call_node, ai)
                if (byval_mask & ((1 as i64) << (ai as u32))) != 0:
                    var indirect_ty = param_ty
                    if ai < byval_types.len() as i32 and byval_types.get(ai as i64) != 0:
                        indirect_ty = byval_types.get(ai as i64)
                    let tmp = self.create_entry_alloca(indirect_ty)
                    let stored = self.enforce_coerced_type(arg_val, indirect_ty, "indirect aggregate argument")
                    wl_build_store(self.builder, stored, tmp)
                    out.push(tmp)
                    continue
            out.push(arg_val)
        out

    mut fn build_call_fn_value(fn_sym: i32, fn_val: i64, fn_ty: i64, args_start: i32, arg_node_base_index: i32, args: &Vec[i64], arg_count: i32, call_context: &str, call_node: i32) -> i64:
        let sret_opt = self.extern_fn_has_sret.get(fn_sym)
        let has_sret = if sret_opt.is_some(): sret_opt.unwrap() else: 0
        var sret_ty: i64 = 0
        if has_sret != 0:
            let sret_ty_opt = self.extern_fn_sret_type.get(fn_sym)
            if sret_ty_opt.is_some():
                sret_ty = sret_ty_opt.unwrap() as i64
        let coerced = self.coerce_call_args_for_fn_value(fn_sym, fn_val, args_start, arg_node_base_index, args, arg_count, call_context, call_node)
        let final_args: Vec[i64] = Vec.new()
        var sret_buf: i64 = 0
        if has_sret != 0 and sret_ty != 0:
            sret_buf = self.create_entry_alloca(sret_ty)
            final_args.push(sret_buf)
        for i in 0..coerced.len() as i32:
            final_args.push(coerced.get(i as i64))
        let call_val = wl_build_call(self.builder, fn_ty, fn_val, vec_data_i64(&final_args), final_args.len() as i32)
        var byval_mask: i64 = 0
        var byval_types: Vec[i64] = Vec.new()
        let byval_opt = self.extern_fn_byval_params.get(fn_sym)
        if byval_opt.is_some():
            byval_mask = byval_opt.unwrap() as i64
        let byval_types_opt = self.extern_fn_byval_types.get(fn_sym)
        if byval_types_opt.is_some():
            byval_types = vec_copy_i64(byval_types_opt.unwrap())
        self.apply_c_abi_call_attrs(call_val, has_sret, sret_ty, byval_mask, byval_types, arg_count, 0)
        if has_sret != 0 and sret_buf != 0 and sret_ty != 0:
            return wl_build_load(self.builder, sret_ty, sret_buf)
        var direct_ret_ty: i64 = 0
        let direct_ret_opt = self.extern_fn_direct_ret_type.get(fn_sym)
        if direct_ret_opt.is_some():
            direct_ret_ty = direct_ret_opt.unwrap() as i64
        if direct_ret_ty != 0:
            return self.c_abi_unpack_direct_value(call_val, direct_ret_ty)
        call_val

    fn mir_call_context(body: &MirBody, callee_operand: i32) -> str:
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

    fn find_type_symbol(llvm_ty: i64) -> i32:
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

    fn find_struct_index_by_type(llvm_ty: i64) -> i32:
        for i in 0..self.struct_llvm_types.len() as i32:
            if self.struct_llvm_types.get(i as i64) == llvm_ty:
                return i
        -1

    fn is_union_struct_index(struct_idx: i32) -> bool:
        if struct_idx < 0 or struct_idx >= self.struct_index_syms.len() as i32:
            return false
        let name_sym = self.struct_index_syms.get(struct_idx as i64)
        if name_sym == 0:
            return false
        self.sema.type_layout_struct_sub_kind(name_sym) == TypeDeclKind.Union

    fn is_union_struct_type(llvm_ty: i64) -> bool:
        self.is_union_struct_index(self.find_struct_index_by_type(llvm_ty))

    fn struct_source_field_type(struct_idx: i32, source_fi: i32) -> i64:
        if struct_idx < 0 or struct_idx >= self.struct_field_counts.len() as i32:
            return 0
        let f_count = self.struct_field_counts.get(struct_idx as i64)
        if source_fi < 0 or source_fi >= f_count:
            return 0
        let f_start = self.struct_field_starts.get(struct_idx as i64)
        self.struct_field_types.get((f_start + source_fi) as i64)

    fn is_bitpacked_struct(llvm_ty: i64) -> bool:
        self.bitpacked_by_llvm_type.contains(llvm_ty)

    fn find_bitpacked_index_by_type(llvm_ty: i64) -> i32:
        let opt = self.bitpacked_by_llvm_type.get(llvm_ty)
        if opt.is_some(): return opt.unwrap() as i32
        -1

    fn get_bitpacked_field_info(llvm_ty: i64, field_idx: i32) -> i32:
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
    fn get_llvm_field_index(llvm_ty: i64, source_fi: i32) -> i32:
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

    fn vec_contains_i32(values: &Vec[i32], needle: i32) -> bool:
        for i in 0..values.len() as i32:
            if values.get(i as i64) == needle:
                return true
        false

    fn struct_reaches_type(start_idx: i32, target_ty: i64) -> bool:
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

    fn span_to_line(node: i32) -> i32:
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

    fn coerce_int(val: i64, target_ty: i64) -> i64:
        self.coerce_int_ext(val, target_ty, false)

    fn coerce_int_ext(val: i64, target_ty: i64, is_unsigned: bool) -> i64:
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

    fn build_default_value(ty: i64) -> i64:
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

    fn get_with_str_eq_fn_type() -> i64:
        let param_types: Vec[i64] = Vec.new()
        param_types.push(wl_ptr_type(self.context))
        param_types.push(wl_ptr_type(self.context))
        wl_function_type(wl_i32_type(self.context), vec_data_i64(&param_types), 2, 0)

    mut fn ensure_with_str_eq_declared() -> i64:
        let param_types: Vec[i64] = Vec.new()
        param_types.push(wl_ptr_type(self.context))
        param_types.push(wl_ptr_type(self.context))
        self.ensure_internal_runtime_fn("with_str_eq_ref", param_types, 2, wl_i32_type(self.context))

    mut fn ensure_with_str_cmp_declared() -> i64:
        let param_types: Vec[i64] = Vec.new()
        param_types.push(wl_ptr_type(self.context))
        param_types.push(wl_ptr_type(self.context))
        self.ensure_internal_runtime_fn("with_str_cmp_ref", param_types, 2, wl_i32_type(self.context))

    mut fn compare_str_eq(lhs: i64, rhs: i64, op: i32) -> i64:
        let fn_val = self.ensure_with_str_eq_declared()
        let fn_sym = self.intern.intern("with_str_eq_ref")
        let fn_ty = self.fn_fn_types.get(fn_sym).unwrap() as i64
        let args: Vec[i64] = Vec.new()
        args.push(self.build_str_ref_from_value(lhs))
        args.push(self.build_str_ref_from_value(rhs))
        let cmp = self.build_call_fn_value(fn_sym, fn_val, fn_ty, -1, 0, args, 2, "with_str_eq_ref", 0)
        let zero = wl_const_int(wl_i32_type(self.context), 0, 0)
        if op == BinaryOp.OP_EQ:
            return wl_build_icmp(self.builder, wl_int_ne(), cmp, zero)
        wl_build_icmp(self.builder, wl_int_eq(), cmp, zero)

    mut fn compare_str_order(lhs: i64, rhs: i64, op: i32) -> i64:
        let fn_val = self.ensure_with_str_cmp_declared()
        let fn_sym = self.intern.intern("with_str_cmp_ref")
        let fn_ty = self.fn_fn_types.get(fn_sym).unwrap() as i64
        let args: Vec[i64] = Vec.new()
        args.push(self.build_str_ref_from_value(lhs))
        args.push(self.build_str_ref_from_value(rhs))
        let cmp = self.build_call_fn_value(fn_sym, fn_val, fn_ty, -1, 0, args, 2, "with_str_cmp_ref", 0)
        let zero = wl_const_int(wl_i32_type(self.context), 0, 0)
        if op == BinaryOp.OP_LT:
            return wl_build_icmp(self.builder, wl_int_slt(), cmp, zero)
        if op == BinaryOp.OP_GT:
            return wl_build_icmp(self.builder, wl_int_sgt(), cmp, zero)
        if op == BinaryOp.OP_LTE:
            return wl_build_icmp(self.builder, wl_int_sle(), cmp, zero)
        if op == BinaryOp.OP_GTE:
            return wl_build_icmp(self.builder, wl_int_sge(), cmp, zero)
        wl_get_undef(wl_i1_type(self.context))

    fn get_memcmp_fn_type() -> i64:
        let i32_ty = wl_i32_type(self.context)
        let ptr_ty = wl_ptr_type(self.context)
        let i64_ty = wl_i64_type(self.context)
        let param_types: Vec[i64] = Vec.new()
        param_types.push(ptr_ty)
        param_types.push(ptr_ty)
        param_types.push(i64_ty)
        wl_function_type(i32_ty, vec_data_i64(&param_types), 3, 0)

    fn ensure_memcmp_declared() -> i64:
        let existing = wl_get_named_function(self.llmod, "memcmp")
        if existing != 0:
            return existing
        let fn_ty = self.get_memcmp_fn_type()
        wl_add_function(self.llmod, "memcmp", fn_ty)

    mut fn compare_value_eq(lhs: i64, rhs: i64, val_ty: i64, op: i32) -> i64:
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

    mut fn compare_aggregate_eq(lhs: i64, rhs: i64, op: i32) -> i64:
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

    fn create_entry_alloca(ty: i64) -> i64:
        wl_create_entry_alloca(self.builder, self.current_function, ty)

fn vec_data_i64(v: &Vec[i64]) -> i64:
    wl_vec_data_ptr(v as i64)

// Element-wise copy so a caller can hand an owned vector to a consuming
// sink (e.g. record_c_abi_transform) more than once under spec §3.8.
fn vec_copy_i64(src: &Vec[i64]) -> Vec[i64]:
    let out: Vec[i64] = Vec.new()
    for i in 0..src.len() as i32:
        out.push(src.get(i as i64))
    out

fn codegen_owned_text(text: &str) -> str:
    if text.len() == 0:
        return ""
    with_str_clone_ref(text)

impl Codegen:
    mut fn capture_sema_symbol_texts():
        let texts: Vec[str] = Vec.new()
        for i in 0..self.sema.pool.state.symbol_texts.len() as i32:
            texts.push(codegen_owned_text(self.sema.pool.state.symbol_texts.get(i as i64)))
        self.sema_symbol_texts = texts

    fn sema_symbol_text(sym: i32) -> str:
        if sym > 0 and sym < self.sema_symbol_texts.len() as i32:
            return with_str_clone_ref(self.sema_symbol_texts.get(sym as i64))
        if sym > 0 and sym < self.sema.pool.state.symbol_texts.len() as i32:
            return with_str_clone_ref(self.sema.pool.state.symbol_texts.get(sym as i64))
        with_str_clone_ref(self.sema.pool_resolve(sym))

    // ── Resolve type expression → LLVM type ───────────────────────────

    mut fn resolve_type(type_node: i32) -> i64:
        if type_node == 0: return wl_void_type(self.context)
        if type_node < 0 or type_node >= self.pool.node_count():
            with_eprint(f"error: invalid type node {type_node} during code generation")
            self.had_error = 1
            return 0
        let kind = self.pool.kind(type_node)

        // with_eprint(f"[codegen] resolve_type node={type_node} kind={kind}")

        if kind == NodeKind.NK_IDENT:
            let sym = self.pool.get_data0(type_node)
            // A bound type parameter shadows any global type of the same name;
            // the active frame carries the monomorphized instance substitution.
            for tbi in 0..self.type_bindings_len:
                if self.type_binding_syms.get(tbi as i64) == sym:
                    let bound = self.type_binding_types.get(tbi as i64)
                    if bound != 0:
                        return bound
            let named = self.resolve_named_type(sym)
            if named != 0:
                return named
            let sema_tid = self.sema.resolve_type_expr_frozen(type_node)
            if sema_tid > 0:
                let sema_ty = self.sema_type_to_llvm(sema_tid)
                if sema_ty != 0:
                    return sema_ty
            return 0

        if kind == NodeKind.NK_TYPE_NAMED:
            let sym = self.pool.get_data0(type_node)
            for tbi in 0..self.type_bindings_len:
                if self.type_binding_syms.get(tbi as i64) == sym:
                    let bound = self.type_binding_types.get(tbi as i64)
                    if bound != 0:
                        return bound
            let named = self.resolve_named_type(sym)
            if named != 0:
                return named
            let sema_tid = self.sema.resolve_type_expr_frozen(type_node)
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

        if kind == NodeKind.NK_TYPE_EXTERN_FN:
            return wl_ptr_type(self.context)

        if kind == NodeKind.NK_INDEX:
            let sema_tid = self.sema.resolve_type_level_arg_expr_frozen(type_node)
            if sema_tid > 0:
                let sema_ty = self.sema_type_to_llvm(sema_tid)
                if sema_ty != 0:
                    return sema_ty
            return 0

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
            if self.sema.type_symbol_is_std_box(name_sym) != 0 and g_count == 1:
                let inner_node = self.pool.get_extra(g_extra)
                if self.pool.kind(inner_node) == NodeKind.NK_TYPE_TRAIT_OBJ:
                    return self.get_dyn_fat_ptr_type()
                return wl_ptr_type(self.context)
            // ContextError[E] = { message: str, source: E }
            if name_sym == self.sym_context_error and g_count == 1:
                let src_node = self.pool.get_extra(g_extra)
                let src_ty = self.resolve_type(src_node)
                return self.get_or_create_context_error_type(src_ty)
            // Codegen-level resolution must run before the Sema fallback when
            // monomorphizing generic struct fields. Sema does not see Codegen's
            // active type bindings, so asking it first would turn Vec[(K, V)]
            // into a fallback type and poison codegen with had_error.
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
            // Sema-based path for other builtin containers (HashMap, HashSet)
            // and fully concrete generic instantiations.
            let sema_tid = self.sema.resolve_type_expr_frozen(type_node)
            if sema_tid > 0:
                let llvm_ty = self.sema_type_to_llvm(sema_tid)
                if llvm_ty != 0:
                    return llvm_ty
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
                    let sema_resolved = self.sema.resolve_type_expr_frozen(type_node)
                    if sema_resolved > 0:
                        let llvm_ty = self.sema_type_to_llvm(sema_resolved)
                        if llvm_ty != 0:
                            return llvm_ty
                    break
            return wl_i32_type(self.context)

        // Fallback — always warn so silent miscompilation is visible. Name the
        // enclosing function and method owner: an out-of-context node id is
        // undiagnosable (this fires for cross-pool id leaks, where the kind is
        // whatever happens to live at that id in the backend pool).
        let ctx_fn = if self.current_function_name_sym != 0: with_str_clone_ref(self.intern.resolve(self.current_function_name_sym)) else: "<module>"
        let ctx_owner = if self.current_method_owner_sym != 0: with_str_clone_ref(self.intern.resolve(self.current_method_owner_sym)) else: ""
        with_eprint(f"warning: [type-resolve] unhandled type node kind={kind} node={type_node} span={self.pool.get_start(type_node)}..{self.pool.get_end(type_node)} in={ctx_fn} owner={ctx_owner}")
        self.type_fallback()

    fn resolve_primitive_named_type(sym: i32) -> i64:
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

    fn resolve_user_named_type(sym: i32) -> i64:
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
            let binding_sym = self.type_binding_syms.get(i as i64)
            let want_text = self.intern.resolve(sym)
            let binding_text = self.intern.resolve(binding_sym)
            let sema_want_text = if want_text.len() > 0: with_str_clone_ref(want_text) else: self.sema_symbol_text(sym)
            let sema_binding_text = if binding_text.len() > 0: with_str_clone_ref(binding_text) else: self.sema_symbol_text(binding_sym)
            if binding_sym == sym or (sema_want_text.len() > 0 and sema_want_text == sema_binding_text):
                return self.type_binding_types.get(i as i64)
        // Unsupported
        0

    fn resolve_named_type(sym: i32) -> i64:
        // Resolve Self to current method owner type
        if sym == self.sym_Self and self.current_method_owner_sym != 0:
            return self.resolve_user_named_type(self.shadow_lookup_sym(self.current_method_owner_sym))
        let prim = self.resolve_primitive_named_type(sym)
        if prim != 0:
            return prim
        self.resolve_user_named_type(self.shadow_lookup_sym(sym))

    mut fn type_expr_to_sema_type(type_node: i32) -> i32:
        if type_node == 0:
            return self.sema.ty_void as i32
        let kind = self.pool.kind(type_node)
        if kind == NodeKind.NK_IDENT or kind == NodeKind.NK_TYPE_NAMED:
            let sym = self.pool.get_data0(type_node)
            let name = self.codegen_symbol_text(sym)
            let sema_sym = if name.len() > 0: self.sema.pool_lookup_symbol(name) else: 0
            let lookup_sym = if sema_sym != 0: sema_sym else: sym
            let prim = self.sema.primitive_type_by_sym(lookup_sym)
            if prim != 0:
                return prim
            if self.sema.named_types.contains(lookup_sym):
                // D29 (#750): a shadowed name inside a std-tier fn body means
                // the std decl's tid, not the flat map's newest (user) entry.
                if self.sema.type_sym_is_shadowed(lookup_sym) != 0 and self.current_fn_is_std_tier() != 0:
                    let tiered = self.sema.lookup_named_type_for_tier(lookup_sym, 1)
                    if tiered != 0:
                        return tiered
                return self.sema.named_types.get(lookup_sym).unwrap() as i32
            let llvm_ty = self.resolve_named_type(sym)
            if llvm_ty != 0:
                return self.llvm_type_to_sema_type(llvm_ty)
            return 0
        if kind == NodeKind.NK_TYPE_PTR or kind == NodeKind.NK_TYPE_REF or kind == NodeKind.NK_TYPE_SLICE or kind == NodeKind.NK_TYPE_OPTIONAL:
            let inner = self.type_expr_to_sema_type(self.pool.get_data0(type_node))
            if inner == 0:
                return 0
            if kind == NodeKind.NK_TYPE_PTR:
                return self.sema.find_exact_type(TypeKind.TY_PTR, inner, self.pool.get_data1(type_node), self.pool.get_data2(type_node)) as i32
            if kind == NodeKind.NK_TYPE_REF:
                return self.sema.find_exact_type(TypeKind.TY_REF, inner, self.pool.get_data1(type_node), 0) as i32
            if kind == NodeKind.NK_TYPE_SLICE:
                return self.sema.find_exact_type(TypeKind.TY_SLICE, inner, self.pool.get_data1(type_node), 0) as i32
            let option_sym = self.sema.pool_lookup_symbol("Option")
            if option_sym != 0:
                let args: Vec[i32] = Vec.new()
                args.push(inner)
                return self.sema.find_generic_inst_type(option_sym, args, 1) as i32
            return 0
        if kind == NodeKind.NK_TYPE_ARRAY:
            let elem = self.type_expr_to_sema_type(self.pool.get_data0(type_node))
            if elem == 0:
                return 0
            return self.sema.find_exact_type(TypeKind.TY_ARRAY, elem, self.pool.get_data1(type_node), self.pool.get_data2(type_node)) as i32
        if kind == NodeKind.NK_TYPE_TUPLE:
            let start = self.pool.get_data0(type_node)
            let count = self.pool.get_data1(type_node)
            let elems: Vec[i32] = Vec.new()
            for ei in 0..count:
                let elem = self.type_expr_to_sema_type(self.pool.get_extra(start + ei))
                if elem == 0:
                    return 0
                elems.push(elem)
            return self.sema.find_tuple_type(elems, count) as i32
        if kind == NodeKind.NK_TYPE_GENERIC:
            let raw_base = self.pool.get_data0(type_node)
            let base_name = self.codegen_symbol_text(raw_base)
            let sema_base = if base_name.len() > 0: self.sema.pool_lookup_symbol(base_name) else: 0
            let base_sym = if sema_base != 0: sema_base else: raw_base
            let arg_start = self.pool.get_data1(type_node)
            let arg_count = self.pool.get_data2(type_node)
            let args: Vec[i32] = Vec.new()
            for ai in 0..arg_count:
                let arg = self.type_expr_to_sema_type(self.pool.get_extra(arg_start + ai))
                if arg == 0:
                    return 0
                args.push(arg)
            return self.sema.find_generic_inst_type(base_sym, args, arg_count) as i32
        if kind == NodeKind.NK_INDEX:
            return self.ast_static_type_expr(type_node)
        0

    // Get sema TypeId for an expression node. Uses local_sema_types for idents.
    fn sema_type_of_node(node: i32) -> i32:
        if node == 0:
            return 0
        if self.sema.typed_expr_types.contains(node):
            let typed = self.sema.typed_expr_types.get(node).unwrap()
            if typed > 0:
                return typed
        let nk = self.pool.kind(node)
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
        if nk == NodeKind.NK_UNARY:
            let op = self.pool.get_data0(node)
            if op == UnaryOp.UOP_REF or op == UnaryOp.UOP_RAW_REF_CONST or op == UnaryOp.UOP_RAW_REF_MUT:
                let inner_ty = self.sema_type_of_node(self.pool.get_data1(node))
                if inner_ty > 0:
                    if op == UnaryOp.UOP_REF:
                        return self.sema.find_exact_type(TypeKind.TY_REF, inner_ty, 0, 0) as i32
                    let is_mut = if op == UnaryOp.UOP_RAW_REF_MUT: 1 else: 0
                    return self.sema.find_exact_type(TypeKind.TY_PTR, inner_ty, is_mut, 0) as i32
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
    mut fn sema_generic_arg_llvm(sema_tid: i32, arg_idx: i32) -> i64:
        if sema_tid <= 0:
            return 0
        if self.sema.get_type_kind(sema_tid) != TypeKind.TY_GENERIC_INST:
            return 0
        let ac = self.sema.get_generic_inst_arg_count(sema_tid)
        if arg_idx >= ac:
            return 0
        let inner_tid = self.sema.get_generic_inst_arg(sema_tid, arg_idx)
        self.sema_type_to_llvm(inner_tid)

    mut fn generic_enum_payload_llvm_type(payload_tys: &Vec[i32]) -> i64:
        let count = payload_tys.len() as i32
        if count <= 0:
            return 0
        if count == 1:
            return self.sema_type_to_llvm(payload_tys.get(0))
        let fields: Vec[i64] = Vec.new()
        for pi in 0..count:
            var field_ty = self.sema_type_to_llvm(payload_tys.get(pi as i64))
            if field_ty == 0:
                field_ty = self.type_fallback()
            fields.push(field_ty)
        wl_struct_type(self.context, vec_data_i64(&fields), count, 0)

    mut fn get_or_create_generic_enum_type(sema_tid: i32) -> i64:
        let resolved = self.sema.resolve_alias(sema_tid)
        if resolved <= 0 or self.sema.get_type_kind(resolved) != TypeKind.TY_GENERIC_INST:
            return 0
        let cached = self.generic_enum_inst_types.get(resolved)
        if cached.is_some():
            return cached.unwrap() as i64
        let base_sym = self.sema.get_generic_inst_base(resolved)
        if base_sym == 0 or not self.sema.named_types.contains(base_sym):
            return 0
        let base_tid: i32 = self.sema.named_types.get(base_sym).unwrap()
        if self.sema.get_type_kind(base_tid) != TypeKind.TY_ENUM:
            return 0
        let cg_base_sym = self.sema_sym_to_codegen_sym(base_sym)
        if cg_base_sym == 0:
            return 0

        let base_name = self.sema_symbol_text(base_sym)
        let enum_name = if base_name.len() > 0: base_name else: with_str_clone_ref(self.intern.resolve(cg_base_sym))
        let mono_name = f"{enum_name}__enuminst_{resolved}"
        let mono_sym = self.intern.intern(mono_name)
        let enum_type = wl_struct_create_named(self.context, mono_name)
        let enum_idx = self.enum_llvm_types.len() as i32
        self.enum_llvm_types.push(enum_type)
        self.enum_variant_starts.push(self.enum_variant_names.len() as i32)
        self.enum_variant_counts.push(0)
        self.enum_type_map.insert(mono_sym, enum_idx)
        self.enum_by_llvm.insert(enum_type, mono_sym)
        self.generic_enum_inst_types.insert(resolved, enum_type)
        self.generic_enum_inst_syms.insert(resolved, mono_sym)

        let owner_decl = self.generic_type_decl_node(cg_base_sym)
        if owner_decl != 0:
            self.mono_struct_base.insert(mono_sym, cg_base_sym)
            let tp_count = self.type_decl_tp_count(owner_decl)
            let tp_flat_start = self.mono_struct_tp_flat_syms.len() as i32
            var tp_pos = self.type_decl_tp_start(owner_decl)
            for ti in 0..tp_count:
                let tp_sym = self.pool.get_extra(tp_pos)
                let bound_count = self.pool.get_extra(tp_pos + 1)
                let arg_tid = if ti < self.sema.get_generic_inst_arg_count(resolved): self.sema.get_generic_inst_arg(resolved, ti) else: 0
                var arg_llvm = if arg_tid > 0: self.sema_type_to_llvm(arg_tid) else: 0
                if arg_llvm == 0:
                    arg_llvm = self.type_fallback()
                self.mono_struct_tp_flat_syms.push(tp_sym)
                self.mono_struct_tp_flat_types.push(arg_llvm)
                self.mono_struct_tp_flat_sema_types.push(arg_tid)
                tp_pos = tp_pos + 2 + bound_count
            self.mono_struct_tp_starts.insert(mono_sym, tp_flat_start)
            self.mono_struct_tp_counts.insert(mono_sym, tp_count)

        let te_start = self.sema.get_type_d1(base_tid)
        let variant_count = self.sema.get_type_d2(base_tid)
        let v_start = self.enum_variant_names.len() as i32
        var pos = te_start
        var max_payload_size: i64 = 0
        var invalid_layout = 0
        for vi in 0..variant_count:
            let variant_name: i32 = self.sema.type_extra.get(pos as i64)
            let payload_count: i32 = self.sema.type_extra.get((pos + 1) as i64)
            var payload_ty: i64 = 0
            if payload_count > 0:
                let payload_tys = self.sema.resolve_generic_enum_payload_frozen(resolved, base_sym, variant_name, payload_count)
                if payload_tys.len() as i32 == payload_count:
                    payload_ty = self.generic_enum_payload_llvm_type(&payload_tys)
                if payload_ty == 0:
                    with_eprint("error: unresolved payload type for generic enum variant '" ++ self.sema_symbol_text(variant_name) ++ "' in '" ++ mono_name ++ "'")
                    self.had_error = 1
                    invalid_layout = 1
                else:
                    let sz = self.abi_size_of(payload_ty)
                    if sz > max_payload_size:
                        max_payload_size = sz
            let cg_variant_name = self.sema_sym_to_codegen_sym(variant_name)
            self.enum_variant_names.push(if cg_variant_name != 0: cg_variant_name else: variant_name)
            self.enum_variant_payloads.push(payload_ty)
            pos = pos + 2 + payload_count

        if invalid_layout != 0:
            return 0

        let body: Vec[i64] = Vec.new()
        body.push(wl_i32_type(self.context))
        if max_payload_size > 0:
            body.push(wl_array_type(wl_i8_type(self.context), max_payload_size))
        wl_struct_set_body(enum_type, vec_data_i64(&body), body.len() as i32, 0)
        self.enum_variant_starts.set_i32(enum_idx as i64, v_start)
        self.enum_variant_counts.set_i32(enum_idx as i64, variant_count)
        enum_type

    fn mono_struct_sema_type(mono_sym: i32) -> i32:
        let mono_base_opt = self.mono_struct_base.get(mono_sym)
        let tp_start_opt = self.mono_struct_tp_starts.get(mono_sym)
        let tp_count_opt = self.mono_struct_tp_counts.get(mono_sym)
        if not mono_base_opt.is_some() or not tp_start_opt.is_some() or not tp_count_opt.is_some():
            return 0
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
        let base_sym = mono_base_opt.unwrap()
        let base_text = self.intern.resolve(base_sym)
        let sema_base_sym = if base_text.len() > 0: self.sema.pool_lookup_symbol(base_text) else: 0
        let found = self.sema.find_generic_inst_type(if sema_base_sym != 0: sema_base_sym else: base_sym, sema_args, tp_count)
        if found != 0:
            return found as i32
        0

    fn sema_sym_to_codegen_sym(sym: i32) -> i32:
        if sym <= 0:
            return 0
        let sema_text = self.sema_symbol_text(sym)
        if sema_text.len() > 0:
            return self.intern.intern(sema_text)
        0

    // Map sema TypeId to LLVM type. Handles TypeKind.TY_GENERIC_INST for builtin containers.
    mut fn sema_type_to_llvm(tid: i32) -> i64:
        if tid <= 0:
            return 0
        let resolved_tid = self.sema.resolve_alias(tid)
        let tk = self.sema.get_type_kind(resolved_tid)
        if tk == TypeKind.TY_GENERIC_INST:
            let base_sym = self.sema.get_type_d0(resolved_tid)
            let cg_base_sym = self.sema_sym_to_codegen_sym(base_sym)
            let arg_count = self.sema.get_generic_inst_arg_count(resolved_tid)
            let base_name = self.sema_symbol_text(base_sym)
            if base_name == "Sender" or base_name == "Receiver":
                let ch_fields: Vec[i64] = Vec.new()
                ch_fields.push(wl_i64_type(self.context))
                return wl_struct_type(self.context, vec_data_i64(&ch_fields), 1, 0)
            if self.sema.type_symbol_is_std_box(base_sym) != 0 and arg_count == 1:
                let elem_tid = self.sema.get_generic_inst_arg(resolved_tid, 0)
                let elem_resolved = self.sema.resolve_alias(elem_tid)
                if self.sema.get_type_kind(elem_resolved) == TypeKind.TY_TRAIT_OBJ:
                    return self.get_dyn_fat_ptr_type()
                return wl_ptr_type(self.context)
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
            if cg_base_sym == self.sym_slotmap and arg_count > 0:
                let elem_tid = self.sema.get_generic_inst_arg(resolved_tid, 0)
                let elem_ty = self.sema_type_to_llvm(elem_tid)
                if elem_ty != 0:
                    return self.get_or_create_slotmap_type(resolved_tid, elem_ty)
            if cg_base_sym == self.sym_handle:
                let h_fields: Vec[i64] = Vec.new()
                h_fields.push(wl_i32_type(self.context))
                h_fields.push(wl_i32_type(self.context))
                return wl_struct_type(self.context, vec_data_i64(&h_fields), 2, 0)
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
            // VecSlot[T] = { data_ptr: i64, index: i64 }
            if cg_base_sym == self.sym_vecslot:
                let vs_fields: Vec[i64] = Vec.new()
                vs_fields.push(wl_i64_type(self.context))
                vs_fields.push(wl_i64_type(self.context))
                return wl_struct_type(self.context, vec_data_i64(&vs_fields), 2, 0)
            // SlotMapSlot[T] = { map_ptr: i64, index: u32, generation: u32 }
            if cg_base_sym == self.sym_slotmapslot:
                let sms_fields: Vec[i64] = Vec.new()
                sms_fields.push(wl_i64_type(self.context))
                sms_fields.push(wl_i32_type(self.context))
                sms_fields.push(wl_i32_type(self.context))
                return wl_struct_type(self.context, vec_data_i64(&sms_fields), 3, 0)
            // VecRange[T] = { data_ptr: i64, offset: i64, len: i64 }
            if cg_base_sym == self.sym_vecrange:
                let vr_fields: Vec[i64] = Vec.new()
                vr_fields.push(wl_i64_type(self.context))
                vr_fields.push(wl_i64_type(self.context))
                vr_fields.push(wl_i64_type(self.context))
                return wl_struct_type(self.context, vec_data_i64(&vr_fields), 3, 0)
            // VecIterRef[T] = { data_ptr: i64, len: i64, idx: i64 }
            if cg_base_sym == self.sym_veciterref:
                let vir_fields: Vec[i64] = Vec.new()
                vir_fields.push(wl_i64_type(self.context))
                vir_fields.push(wl_i64_type(self.context))
                vir_fields.push(wl_i64_type(self.context))
                return wl_struct_type(self.context, vec_data_i64(&vir_fields), 3, 0)
            // VecIterPlace[T] = { data_ptr: i64, len: i64, idx: i64 }
            if cg_base_sym == self.sym_veciterplace:
                let vip_fields: Vec[i64] = Vec.new()
                vip_fields.push(wl_i64_type(self.context))
                vip_fields.push(wl_i64_type(self.context))
                vip_fields.push(wl_i64_type(self.context))
                return wl_struct_type(self.context, vec_data_i64(&vip_fields), 3, 0)
            if base_sym != 0 and self.sema.named_types.contains(base_sym):
                let base_tid: i32 = self.sema.named_types.get(base_sym).unwrap()
                if self.sema.get_type_kind(base_tid) == TypeKind.TY_ENUM:
                    return self.get_or_create_generic_enum_type(resolved_tid)
            // User-defined generic structs: monomorphize via type bindings
            if cg_base_sym != 0 and self.generic_structs.contains(cg_base_sym):
                let saved_len = self.type_bindings_len
                let saved_syms = self.type_binding_syms
                let saved_types = self.type_binding_types
                let tp_syms: Vec[i32] = Vec.new()
                let tp_types: Vec[i64] = Vec.new()
                let gs_node: i32 = self.generic_structs.get(cg_base_sym).unwrap()
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
        if tk == TypeKind.TY_VOID or tk == TypeKind.TY_NEVER:
            return wl_void_type(self.context)
        if tk == TypeKind.TY_STRUCT or tk == TypeKind.TY_ENUM:
            let sym = self.sema.get_type_d0(resolved_tid)
            // Distinct types are transparent: same LLVM type as inner type
            if self.sema.distinct_type_names.contains(sym):
                let inner_tid: i32 = self.sema.type_extra.get((self.sema.get_type_d1(resolved_tid) + 1) as i64)
                return self.sema_type_to_llvm(inner_tid)
            var cg_sym = self.sema_sym_to_codegen_sym(sym)
            if cg_sym == 0:
                cg_sym = sym
            // D29 (#750): a shadowed name's tid carries its tier; route the
            // std-tier tid to the aliased LLVM slot.
            if self.sema.type_sym_is_shadowed(sym) != 0 and self.sema.type_tid_std_tier(resolved_tid as i32) != 0:
                cg_sym = self.shadow_alias_for(cg_sym)
            return self.resolve_named_type(cg_sym)
        if tk == TypeKind.TY_TUPLE:
            let elem_start = self.sema.get_type_d0(resolved_tid)
            let elem_count = self.sema.get_type_d1(resolved_tid)
            let elem_types: Vec[i64] = Vec.new()
            for i in 0..elem_count:
                let elem_tid: i32 = self.sema.type_extra.get((elem_start + i) as i64)
                var elem_ty = self.sema_type_to_llvm(elem_tid)
                if elem_ty == 0:
                    elem_ty = self.type_fallback()
                elem_types.push(elem_ty)
            if elem_count > 0:
                return wl_struct_type(self.context, vec_data_i64(&elem_types), elem_count, 0)
            return wl_i32_type(self.context)
        if tk == TypeKind.TY_RANGE:
            let elem_tid = self.sema.get_type_d0(resolved_tid)
            var elem_ty = self.sema_type_to_llvm(elem_tid)
            if elem_ty == 0:
                elem_ty = wl_i32_type(self.context)
            let range_fields: Vec[i64] = Vec.new()
            range_fields.push(elem_ty)
            range_fields.push(elem_ty)
            range_fields.push(wl_i8_type(self.context))
            return wl_struct_type(self.context, vec_data_i64(&range_fields), 3, 0)
        if tk == TypeKind.TY_ARRAY:
            let elem_tid = self.sema.get_type_d0(resolved_tid)
            let arr_len = self.sema.get_type_d1(resolved_tid)
            var elem_ty = self.sema_type_to_llvm(elem_tid)
            if elem_ty == 0:
                elem_ty = self.type_fallback()
            return wl_array_type(elem_ty, arr_len as i64)
        if tk == TypeKind.TY_PTR or tk == TypeKind.TY_REF:
            let pointee_tid = self.sema.get_type_d0(resolved_tid)
            let pointee_resolved = self.sema.resolve_alias(pointee_tid)
            if self.sema.get_type_kind(pointee_resolved) == TypeKind.TY_TRAIT_OBJ:
                return self.get_dyn_fat_ptr_type()
            return wl_ptr_type(self.context)
        if tk == TypeKind.TY_FN:
            let ptr_ty = wl_ptr_type(self.context)
            let fat_types: Vec[i64] = Vec.new()
            fat_types.push(ptr_ty)
            fat_types.push(ptr_ty)
            return wl_struct_type(self.context, vec_data_i64(&fat_types), 2, 0)
        if tk == TypeKind.TY_EXTERN_FN:
            return wl_ptr_type(self.context)
        if tk == TypeKind.TY_SLICE:
            let slice_fields: Vec[i64] = Vec.new()
            slice_fields.push(wl_ptr_type(self.context))
            slice_fields.push(wl_i64_type(self.context))
            return wl_struct_type(self.context, vec_data_i64(&slice_fields), 2, 0)
        0

    // Reverse map: LLVM type → sema TypeId (for primitives and str)
    fn llvm_type_to_sema_type(ty: i64) -> i32:
        let kind = wl_get_type_kind(ty)
        if kind == wl_integer_type_kind():
            let bits = wl_get_int_type_width(ty)
            if bits == 1: return self.sema.ty_bool as i32
            if bits == 8: return self.sema.ty_i8 as i32
            if bits == 16: return self.sema.ty_i16 as i32
            if bits == 32: return self.sema.ty_i32 as i32
            if bits == 64: return self.sema.ty_i64 as i32
            if bits == 128: return self.sema.ty_i128 as i32
            if bits > 0:
                return self.sema.find_exact_type(TypeKind.TY_INT, bits, 1, 0) as i32
        if kind == wl_float_type_kind():
            return self.sema.ty_f32 as i32
        if kind == wl_double_type_kind():
            return self.sema.ty_f64 as i32
        if kind == wl_void_type_kind():
            return self.sema.ty_void as i32
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
        if kind == wl_struct_type_kind():
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
                    let found = self.sema.find_generic_inst_type(mono_base_opt.unwrap(), sema_args, tp_count)
                    if found != 0:
                        return found as i32
            let enum_sym_opt = self.enum_by_llvm.get(ty)
            if enum_sym_opt.is_some():
                let enum_sym = enum_sym_opt.unwrap()
                if self.sema.named_types.contains(enum_sym):
                    return self.sema.named_types.get(enum_sym).unwrap() as i32
                let enum_text = self.intern.resolve(enum_sym)
                let sema_enum_sym = if enum_text.len() > 0: self.sema.pool_lookup_symbol(enum_text) else: 0
                if sema_enum_sym != 0 and self.sema.named_types.contains(sema_enum_sym):
                    return self.sema.named_types.get(sema_enum_sym).unwrap() as i32
        0

    // ── Builtin str type ──────────────────────────────────────────────

    fn declare_builtin_str_type():
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

    fn declare_builtin_cstr_type():
        let cstr_sym = self.intern.intern("CStr")
        if self.struct_type_map.get(cstr_sym).is_some():
            return
        let cstr_type = wl_struct_create_named(self.context, "CStr")
        wl_struct_set_body_2(cstr_type, wl_ptr_type(self.context), wl_i64_type(self.context), 0)

        let idx = self.struct_llvm_types.len() as i32
        self.struct_llvm_types.push(cstr_type)
        self.struct_index_syms.push(cstr_sym)
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

        self.struct_type_map.insert(cstr_sym, idx)

    fn predeclare_struct_type(name_sym: i32):
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

    fn codegen_sym_for_sema_sym(sema_sym: i32) -> i32:
        let text = self.sema_symbol_text(sema_sym)
        if text.len() > 0:
            return self.intern.intern(text)
        sema_sym

    // ── D29 scaffolding (#750): shadowed-type codegen symbols ─────────

    fn codegen_sema_sym_for(sym: i32) -> i32:
        let text = self.intern.resolve(sym)
        if text.len() == 0:
            return 0
        self.sema.pool_lookup_symbol(text)

    fn type_sym_shadowed_cg(sym: i32) -> i32:
        let sema_sym = self.codegen_sema_sym_for(sym)
        if sema_sym == 0:
            return 0
        self.sema.type_sym_is_shadowed(sema_sym)

    // Registration side: the std-tier decl of a shadowed name registers under
    // `name$std`; interning here is fine (registration runs in mut context).
    fn shadow_reg_sym(name_sym: i32, decl_index: i32) -> i32:
        if self.type_sym_shadowed_cg(name_sym) == 0:
            return name_sym
        if sema_tier_path_is_std_implementation(self.sema.decl_index_source_path(decl_index)) == 0:
            return name_sym
        let alias = self.intern.intern(self.intern.resolve(name_sym) ++ "$std")
        let map = &raw const self.shadow_alias_map as *const HashMap[i32, i32] as *mut HashMap[i32, i32]
        unsafe { (*map).insert(name_sym, alias) }
        alias

    // Lookup side: reads the alias recorded at registration; never interns.
    fn shadow_alias_for(name_sym: i32) -> i32:
        if self.shadow_alias_map.contains(name_sym):
            return self.shadow_alias_map.get(name_sym).unwrap()
        name_sym

    fn current_fn_is_std_tier() -> i32:
        if self.current_function_name_sym == 0:
            return 0
        let sema_sym = self.codegen_sema_sym_for(self.current_function_name_sym)
        if sema_sym == 0:
            return 0
        if not self.sema.fn_decl_source_paths.contains(sema_sym):
            return 0
        sema_tier_path_is_std_implementation(self.sema.fn_decl_source_paths.get(sema_sym).unwrap())

    // By-name type lookups while generating a std-tier fn body must see the
    // std tier's layout for shadowed names.
    fn shadow_lookup_sym(name_sym: i32) -> i32:
        if self.type_sym_shadowed_cg(name_sym) == 0:
            return name_sym
        if self.current_fn_is_std_tier() == 0:
            return name_sym
        self.shadow_alias_for(name_sym)

    fn codegen_resolve_sema_type(tid: i32) -> i32:
        let resolved = self.mir_resolve_alias_at(tid)
        if resolved > 0 and self.mir_type_kind_at(resolved) != 0:
            return resolved
        self.sema.resolve_alias(tid as TypeId) as i32

    fn codegen_get_type_kind(tid: i32) -> i32:
        if tid >= 0 and tid < self.mir_type_kinds_len() as i32:
            return self.mir_type_kind_at(tid)
        self.sema.get_type_kind(tid)

    fn codegen_get_type_d0(tid: i32) -> i32:
        if tid >= 0 and tid < self.mir_type_d0_len() as i32:
            return self.mir_type_d0_at(tid)
        self.sema.get_type_d0(tid)

    fn codegen_get_type_d1(tid: i32) -> i32:
        if tid >= 0 and tid < self.mir_type_d1_len() as i32:
            return self.mir_type_d1_at(tid)
        self.sema.get_type_d1(tid)

    fn codegen_get_type_d2(tid: i32) -> i32:
        if tid >= 0 and tid < self.mir_type_d2_len() as i32:
            return self.mir_type_d2_at(tid)
        self.sema.get_type_d2(tid)

    fn codegen_get_type_extra(idx: i32) -> i32:
        if idx >= 0 and idx < self.mir_type_extra_len() as i32:
            return self.mir_type_extra_at(idx)
        if idx >= 0 and idx < self.sema.type_extra.len() as i32:
            return self.sema.type_extra.get(idx as i64)
        0

    fn codegen_generator_state_field_count(state_tid: i32) -> i32:
        if self.sema.generator_state_field_counts.contains(state_tid):
            return self.sema.generator_state_field_counts.get(state_tid).unwrap()
        self.codegen_get_type_d2(state_tid)

    fn codegen_generator_state_field_sym(state_tid: i32, field_i: i32, extra_start: i32) -> i32:
        let key = sema_pair_key(state_tid, field_i)
        if self.sema.generator_state_field_names.contains(key):
            return self.sema.generator_state_field_names.get(key).unwrap()
        self.codegen_get_type_extra(extra_start + field_i * 3)

    fn codegen_generator_state_field_type(state_tid: i32, field_i: i32, extra_start: i32) -> i32:
        let key = sema_pair_key(state_tid, field_i)
        if self.sema.generator_state_field_types.contains(key):
            return self.sema.generator_state_field_types.get(key).unwrap()
        self.codegen_get_type_extra(extra_start + field_i * 3 + 1)

    fn predeclare_generator_state_types():
        for si in 0..self.sema.sig_names.len() as i32:
            let fn_sym = self.sema.sig_names.get(si as i64)
            if not self.sema.generator_fn_state_types.contains(fn_sym):
                continue
            let state_tid = self.sema.generator_fn_state_types.get(fn_sym).unwrap()
            let resolved = self.codegen_resolve_sema_type(state_tid)
            if resolved <= 0 or self.codegen_get_type_kind(resolved) != TypeKind.TY_STRUCT:
                continue
            let state_sym = self.codegen_get_type_d0(resolved)
            let cg_state_sym = self.codegen_sym_for_sema_sym(state_sym)
            self.predeclare_struct_type(cg_state_sym)

    mut fn declare_generator_state_type(state_tid: i32):
        let resolved = self.codegen_resolve_sema_type(state_tid)
        if resolved <= 0 or self.codegen_get_type_kind(resolved) != TypeKind.TY_STRUCT:
            return
        let state_sym = self.codegen_get_type_d0(resolved)
        let cg_state_sym = self.codegen_sym_for_sema_sym(state_sym)
        if not self.struct_type_map.get(cg_state_sym).is_some():
            self.predeclare_struct_type(cg_state_sym)
        let idx: i32 = self.struct_type_map.get(cg_state_sym).unwrap()
        let existing_count = self.struct_field_counts.get(idx as i64)
        if existing_count > 0:
            return
        let st_type: i64 = self.struct_llvm_types.get(idx as i64)
        let extra_start = self.codegen_get_type_d1(resolved)
        let field_count = self.codegen_generator_state_field_count(resolved)
        self.struct_field_starts.set_i32(idx as i64, self.struct_field_names.len() as i32)
        self.struct_field_counts.set_i32(idx as i64, field_count)

        let field_types: Vec[i64] = Vec.new()
        for fi in 0..field_count:
            let field_sym = self.codegen_generator_state_field_sym(resolved, fi, extra_start)
            let field_tid = self.codegen_generator_state_field_type(resolved, fi, extra_start)
            var field_ty = self.mir_sema_type_to_llvm(field_tid)
            if field_ty == 0:
                field_ty = self.type_fallback()
            self.struct_field_names.push(field_sym)
            self.struct_field_types.push(field_ty)
            self.struct_field_type_nodes.push(0)
            self.struct_field_defaults.push(0)
            self.struct_llvm_field_indices.push(fi)
            field_types.push(field_ty)
        wl_struct_set_body(st_type, vec_data_i64(&field_types), field_count, 0)

    mut fn declare_generator_state_types():
        for si in 0..self.sema.sig_names.len() as i32:
            let fn_sym: i32 = self.sema.sig_names.get(si as i64)
            if self.sema.generator_fn_state_types.contains(fn_sym):
                self.declare_generator_state_type(self.sema.generator_fn_state_types.get(fn_sym).unwrap())

    fn predeclare_enum_type(name_sym: i32):
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

    fn type_decl_tp_meta_start(type_node: i32) -> i32:
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
        -1

    fn type_decl_tp_start(type_node: i32) -> i32:
        let meta_start = self.type_decl_tp_meta_start(type_node)
        if meta_start < 0:
            return 0
        if meta_start >= self.pool.extra_len():
            return 0
        self.pool.get_extra(meta_start)

    fn type_decl_tp_count(type_node: i32) -> i32:
        let meta_start = self.type_decl_tp_meta_start(type_node)
        if meta_start < 0:
            return 0
        if meta_start + 1 >= self.pool.extra_len():
            return 0
        self.pool.get_extra(meta_start + 1)

    fn generic_type_decl_node(type_sym: i32) -> i32:
        if type_sym <= 0:
            return 0
        let gs = self.generic_structs.get(type_sym)
        if gs.is_some():
            return gs.unwrap()
        for di in 0..self.pool.decl_count():
            let decl = self.pool.get_decl(di)
            if self.pool.kind(decl) != NodeKind.NK_TYPE_DECL:
                continue
            let decl_sym = self.pool.get_data0(decl)
            if decl_sym != type_sym:
                let decl_name_raw = self.intern.resolve(decl_sym)
                let decl_name = if decl_name_raw.len() > 0: with_str_clone_ref(decl_name_raw) else: self.sema_symbol_text(decl_sym)
                let type_name_raw = self.intern.resolve(type_sym)
                let type_name = if type_name_raw.len() > 0: with_str_clone_ref(type_name_raw) else: self.sema_symbol_text(type_sym)
                if decl_name.len() == 0 or type_name.len() == 0 or decl_name != type_name:
                    continue
            let sub_kind = type_decl_sub_kind(self.pool.get_data2(decl))
            if sub_kind != TypeDeclKind.Struct and sub_kind != TypeDeclKind.Enum:
                return 0
            if self.type_decl_tp_count(decl) > 0:
                return decl as i32
            return 0
        0

    // ── Declare struct type ───────────────────────────────────────────

    mut fn declare_struct_type(name_sym: i32, type_node: i32):
        // type_node is the NodeKind.NK_TYPE_DECL node with TypeDeclSubKind.TDK_STRUCT
        let extra_start = self.pool.get_data1(type_node)
        let field_count = self.pool.get_extra(extra_start)

        let name_str: str = with_str_clone_ref(self.intern.resolve(name_sym))
        if not self.struct_type_map.get(name_sym).is_some():
            self.predeclare_struct_type(name_sym)
        let idx: i32 = self.struct_type_map.get(name_sym).unwrap()
        let st_type: i64 = self.struct_llvm_types.get(idx as i64)
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

        if is_bitpacked != 0:
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

    mut fn declare_union_type(name_sym: i32, type_node: i32):
        // Union layout: {[max_size x i8]} — all fields overlap at offset 0.
        // Field access uses bitcast of pointer to field type.
        let extra_start = self.pool.get_data1(type_node)
        let field_count = self.pool.get_extra(extra_start)
        let name_str: str = with_str_clone_ref(self.intern.resolve(name_sym))

        if not self.struct_type_map.get(name_sym).is_some():
            self.predeclare_struct_type(name_sym)
        let idx: i32 = self.struct_type_map.get(name_sym).unwrap()
        let st_type: i64 = self.struct_llvm_types.get(idx as i64)
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
            let f_tid = self.sema.resolve_type_expr_frozen(f_type_node)
            let f_size = if f_tid > 0: self.sema.type_layout_size_of_frozen(f_tid) else: self.abi_size_of(f_ty)
            let f_align = if f_tid > 0: self.sema.type_layout_align_of_frozen(f_tid) else: 1
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

    mut fn declare_enum_type(name_sym: i32, type_node: i32):
        let extra_start = self.pool.get_data1(type_node)
        let variant_count = self.pool.get_extra(extra_start)
        let enum_name: str = with_str_clone_ref(self.intern.resolve(name_sym))

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
        let idx: i32 = self.enum_type_map.get(name_sym).unwrap()
        let enum_type = self.enum_llvm_types.get(idx as i64)
        let body: Vec[i64] = Vec.new()
        body.push(wl_i32_type(self.context))
        if max_payload_size > 0:
            body.push(wl_array_type(wl_i8_type(self.context), max_payload_size))
        wl_struct_set_body(enum_type, vec_data_i64(&body), body.len() as i32, 0)

        self.enum_variant_starts.set_i32(idx as i64, v_starts)
        self.enum_variant_counts.set_i32(idx as i64, variant_count)

    mut fn declare_disc_enum_type(name_sym: i32, type_node: i32):
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
            let enum_idx: i32 = self.enum_type_map.get(name_sym).unwrap()
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

    fn gen_disc_enum_from_int_val(de_idx: i32, arg_val: i64) -> i64:
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

    fn find_disc_enum_sym_by_idx(de_idx: i32) -> i32:
        if de_idx >= 0 and de_idx < self.disc_enum_name_syms.len() as i32:
            return self.disc_enum_name_syms.get(de_idx as i64)
        0

    // ── Declare function ──────────────────────────────────────────────

    fn function_symbol_name(sym: i32) -> str:
        let name = self.intern.resolve(sym)
        if name.len() > 0:
            return with_str_clone_ref(name)
        fn_abi_anonymous_symbol(sym)

// Symbol-naming rules live in src/FnAbi.w (docs/with-abi.md §5); this is
// the adapter that feeds them the codegen mode.
impl Codegen:
    // Module link names (`__with_mod_<hash>__<base>`) apply in module-object
    // mode, and in every mode to a path an embedded .wo bundle provides: the
    // bundle defined those symbols under its module prefix, so this unit's
    // declaration must spell the same name or the link never meets (D38).
    fn path_uses_module_link_names(source_path: &str) -> bool:
        self.module_object_mode != 0 or self.path_is_bundle_provided(source_path)

    fn module_link_name_for_path(source_path: &str, base_name: &str) -> str:
        let mode = if self.path_uses_module_link_names(source_path): 1 else: 0
        fn_abi_module_link_name(mode, source_path, base_name)

    // D39: the prefixes of `--link-bundle` manifests join the embedded ones,
    // so a compiler with an empty embedded index (stage1) compiles exactly
    // what a compiler with the bundle embedded compiles.
    mut fn add_bundle_prefixes(prefixes: &Vec[str]):
        for i in 0..prefixes.len() as i32:
            let prefix = prefixes.get(i as i64)
            if not self.bundle_prefixes.contains(prefix):
                self.bundle_prefixes.push(with_str_clone_ref(prefix))

    // D38: does an embedded .wo bundle provide this module? Then this unit
    // declares its functions and the bundle's object defines them.
    fn path_is_bundle_provided(source_path: &str) -> bool:
        if self.bundle_prefixes.len() == 0:
            return false
        let prefix = fn_abi_module_link_prefix(source_path)
        prefix.len() > 0 and self.bundle_prefixes.contains(prefix)

    // A function this unit declares and never defines: an interface
    // declaration (D39) or a function of a bundle-provided module (D38).
    // Its definition is the bundle's object, so it keeps external linkage.
    fn fn_node_is_declared_only(fn_node: i32) -> bool:
        self.pool.fn_decl_body_is_interface(fn_node) or self.path_is_bundle_provided(self.current_decl_source_file)

    fn fn_is_bundle_provided(sema_sym: i32) -> bool:
        let path_opt = self.sema.fn_decl_source_paths.get(sema_sym)
        if path_opt.is_none():
            return false
        self.path_is_bundle_provided(path_opt.unwrap())

    fn current_decl_module_link_name(base_name: &str) -> str:
        self.module_link_name_for_path(self.current_decl_source_file, base_name)

    fn ident_text_from_node(node: i32) -> str:
        if node == 0:
            return ""
        let start = self.pool.get_start(node)
        let end = self.pool.get_end(node)
        if start < 0 or end <= start:
            return ""
        if end > self.source_text.len() as i32:
            return ""
        self.source_text.slice(start as i64, end as i64)

    fn method_text_from_field_access(node: i32) -> str:
        if node == 0 or self.pool.kind(node) != NodeKind.NK_FIELD_ACCESS:
            return ""
        let text = self.ident_text_from_node(node)
        if text.len() == 0:
            return ""
        var dot = -1
        for i in 0..text.len() as i32:
            if text.byte_at(i as i64) == 46:
                dot = i
        if dot < 0 or dot + 1 >= text.len() as i32:
            return ""
        text.slice((dot + 1) as i64, text.len())

    fn get_hashmap_new_fn_type() -> i64:
        let params: Vec[i64] = Vec.new()
        params.push(wl_i64_type(self.context))
        params.push(wl_i64_type(self.context))
        wl_function_type(wl_ptr_type(self.context), vec_data_i64(&params), 2, 0)

    fn ensure_hashmap_new_declared() -> i64:
        let existing = wl_get_named_function(self.llmod, "with_hashmap_new")
        if existing != 0:
            return existing
        let fn_ty = self.get_hashmap_new_fn_type()
        wl_add_function(self.llmod, "with_hashmap_new", fn_ty)

    fn fn_decl_name_from_node(node: i32) -> str:
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

    fn let_binding_name_from_node(node: i32) -> str:
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

    mut fn declare_function(fn_node: i32):
        self.declare_function_at(fn_node, self.find_decl_index(fn_node))

    mut fn declare_function_at(fn_node: i32, decl_index: i32):
        // D29 (#750): signature types must resolve under this fn's own tier —
        // shadowed names in a std fn's signature mean the std layout. Body
        // generation sets the same context later; declaring without it would
        // bind the plain (user) slot and diverge from the call sites.
        let ctx_sym = self.sema.fn_decl_semantic_symbol_at(fn_node, self.pool.get_data0(fn_node), decl_index)
        if ctx_sym == 0:
            return
        let saved_decl_fn_sym = self.current_function_name_sym
        self.current_function_name_sym = ctx_sym
        self.declare_function_at_inner(fn_node, decl_index)
        self.current_function_name_sym = saved_decl_fn_sym

    mut fn declare_function_at_inner(fn_node: i32, decl_index: i32):
        let name_sym = self.sema.fn_decl_semantic_symbol_at(fn_node, self.pool.get_data0(fn_node), decl_index)
        let raw_name_str = self.intern.resolve(name_sym)
        let sema_name_str = self.sema_symbol_text(name_sym)
        let name_str = if sema_name_str.len() > 0: sema_name_str else: with_str_clone_ref(raw_name_str)
        if name_sym == 0:
            return
        let parsed_name = if sema_name_str.len() == 0 and name_str.len() == 0: self.fn_decl_name_from_node(fn_node) else: ""
        let alias_text =
            if sema_name_str.len() > 0:
                sema_name_str
            else:
                parsed_name
        let alias_sym = if alias_text.len() > 0: self.intern.intern(alias_text) else: 0
        let flags = self.pool.get_data2(fn_node)
        let meta = self.pool.find_fn_meta(fn_node)
        if meta < 0: return

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

        // Methods owned by generic types are always compiled lazily against a
        // concrete owner instantiation. Even "static" methods like Foo.wrap(x: T)
        // or methods returning Self need the owner bindings before their LLVM
        // signature can be resolved correctly.
        if method_owner_sym != 0:
            if self.generic_type_decl_node(method_owner_sym) != 0 and self.sema.fn_node_is_generic_template(fn_node, name_sym) != 0:
                self.generic_struct_methods.insert(name_sym, fn_node)
                return

        if (flags / FnFlags.GEN) % 2 == 1:
            let sig_idx = self.sema.get_sig(name_sym)
            if sig_idx >= 0:
                self.declare_function_from_sig(name_sym, sig_idx, 0)
            return

        let ret_type_node = self.pool.fn_meta_ret(meta)
        let param_start = self.pool.fn_meta_param_start(meta)
        let param_count = self.pool.fn_meta_param_count(meta)
        let sema_sig_idx = self.sema.get_sig(name_sym)

        // Resolve param types
        let param_types: Vec[i64] = Vec.new()

        // Set method owner before resolving return type so Self can resolve
        let saved_owner = self.current_method_owner_sym
        if method_owner_sym != 0:
            self.current_method_owner_sym = method_owner_sym

        var ret_ty_raw: i64 = 0
        if ret_type_node != 0:
            ret_ty_raw = self.resolve_type(ret_type_node)
        else if sema_sig_idx >= 0:
            ret_ty_raw = self.sema_type_to_llvm(self.sema.sig_return_type(sema_sig_idx))
        let ret_ty = if ret_ty_raw != 0: ret_ty_raw else: self.type_fallback()

        // Check if this returns Result
        if ret_type_node != 0 and self.is_result_return_type(ret_type_node):
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
            // #D6: final Sema pass mode is authoritative for share-place. This
            // branch must precede AST type fallbacks (including a missing type node)
            // so declaration, caller marshalling, and callee binding cannot derive
            // three different ABIs for the same signature.
            if sema_sig_idx >= 0 and pi < self.sema.sig_get_param_count(sema_sig_idx) and
               self.sema.sig_param_uses_value_ref_abi(sema_sig_idx, pi) != 0:
                param_types.push(wl_ptr_type(self.context))
                has_ref_param = true
                self.record_ref_param_aliases(name_sym, alias_sym, method_key_sym, pi, param_count)
                pi = pi + 1
                continue
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
                        self.record_ref_param_aliases(name_sym, alias_sym, method_key_sym, pi, param_count)
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
            if p_kind == NodeKind.NK_TYPE_EXTERN_FN:
                param_types.push(wl_ptr_type(self.context))
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

            // Reference params. The finalized Sema signature is canonical; the
            // AST check is only for declarations that have no signature yet.
            if (sema_sig_idx >= 0 and self.sig_param_is_explicit_ref(sema_sig_idx, pi)) or
               (sema_sig_idx < 0 and p_kind == NodeKind.NK_TYPE_REF):
                var ref_ty = self.resolve_type(p_type_node)
                if ref_ty == 0:
                    ref_ty = wl_ptr_type(self.context)
                param_types.push(ref_ty)
                has_ref_param = true
                self.record_ref_param_aliases(name_sym, alias_sym, method_key_sym, pi, param_count)
                pi = pi + 1
                continue

            var p_ty = self.resolve_type(p_type_node)
            if p_ty == 0:
                p_ty = wl_i32_type(self.context)
            if wl_get_type_kind(p_ty) == wl_void_type_kind():
                p_ty = wl_i32_type(self.context)
            param_types.push(p_ty)
            pi = pi + 1

        let cc_name = self.fn_callconv_name(meta)
        let uses_c_abi = self.fn_uses_c_abi(cc_name)
        let actual_param_types: Vec[i64] = Vec.new()
        let byval_types: Vec[i64] = Vec.new()
        let direct_types: Vec[i64] = Vec.new()
        let ptr_ty = wl_ptr_type(self.context)
        var actual_ret_ty = ret_ty
        var has_sret = 0
        var sret_ty: i64 = 0
        var byval_mask: i64 = 0
        var direct_mask: i64 = 0
        var direct_ret_ty: i64 = 0
        if uses_c_abi:
            if ret_ty != 0 and wl_get_type_kind(ret_ty) == wl_struct_type_kind():
                let direct_ret_abi_ty = self.c_abi_direct_struct_return_type(ret_ty)
                if direct_ret_abi_ty != 0:
                    direct_ret_ty = ret_ty
                    actual_ret_ty = direct_ret_abi_ty
                else if codegen_c_abi_darwin_arm64() and self.c_abi_hfa_info(ret_ty) != 0:
                    actual_ret_ty = ret_ty
                else if self.c_abi_needs_sret(ret_ty):
                    has_sret = 1
                    sret_ty = ret_ty
                    actual_ret_ty = wl_void_type(self.context)
            if has_sret != 0:
                actual_param_types.push(ptr_ty)
            for abi_pi in 0..param_count:
                let source_ty = param_types.get(abi_pi as i64)
                if wl_get_type_kind(source_ty) == wl_struct_type_kind():
                    let direct_param_ty = self.c_abi_direct_struct_param_type(source_ty)
                    if direct_param_ty != 0:
                        actual_param_types.push(direct_param_ty)
                        direct_mask = direct_mask | ((1 as i64) << (abi_pi as u32))
                        byval_types.push(0)
                        direct_types.push(source_ty)
                        continue
                    if self.c_abi_needs_indirect_param(source_ty):
                        actual_param_types.push(ptr_ty)
                        byval_mask = byval_mask | ((1 as i64) << (abi_pi as u32))
                        byval_types.push(source_ty)
                        direct_types.push(0)
                        continue
                actual_param_types.push(source_ty)
                byval_types.push(0)
                direct_types.push(0)
        else if self.internal_abi_needs_sret(ret_ty):
            has_sret = 1
            sret_ty = ret_ty
            actual_ret_ty = wl_void_type(self.context)
            actual_param_types.push(ptr_ty)
            for abi_pi2 in 0..param_count:
                let source_ty2 = param_types.get(abi_pi2 as i64)
                if self.internal_abi_needs_indirect_param(source_ty2):
                    actual_param_types.push(ptr_ty)
                    byval_mask = byval_mask | ((1 as i64) << (abi_pi2 as u32))
                    byval_types.push(source_ty2)
                    direct_types.push(0)
                else:
                    actual_param_types.push(source_ty2)
                    byval_types.push(0)
                    direct_types.push(0)
        else:
            for abi_pi in 0..param_count:
                let source_ty3 = param_types.get(abi_pi as i64)
                if self.internal_abi_needs_indirect_param(source_ty3):
                    actual_param_types.push(ptr_ty)
                    byval_mask = byval_mask | ((1 as i64) << (abi_pi as u32))
                    byval_types.push(source_ty3)
                    direct_types.push(0)
                else:
                    actual_param_types.push(source_ty3)
                    byval_types.push(0)
                    direct_types.push(0)
        let actual_param_count = actual_param_types.len() as i32
        let is_variadic = (flags / FnFlags.VARIADIC) % 2
        let fn_type = wl_function_type(actual_ret_ty, vec_data_i64(&actual_param_types), actual_param_count, is_variadic)

        // Use "main" for @[entry] functions
        var effective_name = if sema_name_str.len() > 0: sema_name_str else: self.function_symbol_name(name_sym)
        if parsed_name.len() > 0:
            effective_name = parsed_name
        if (flags / FnFlags.ENTRY) % 2 == 1:
            effective_name = "main"
        else if self.path_uses_module_link_names(self.current_decl_source_file):
            if not codegen_preserve_runtime_link_name(self.current_decl_source_file, effective_name) and
                not (cc_name.len() > 9 and cc_name.slice(0, 9) == "c_export:"):
                effective_name = self.current_decl_module_link_name(effective_name)

        // Declare-then-define unification (#761 R2c): the definition owns
        // its symbol. A same-typed existing DECLARATION (an ensure_*/extern
        // probe that ran first) is taken over so the body lands on the name
        // callers reference; a mismatched bodiless declaration moves aside
        // (e.g. ensure_async_runtime_declared's hardcoded void() vs the
        // def's Unit-return shape — physically identical, structurally
        // different) — LLVM's silent auto-uniquify otherwise split
        // with_runtime_init into an empty declaration (which the
        // synthesized wrapper called → undefined at link) and a
        // with_runtime_init.1 carrying the real body. An existing
        // DEFINITION keeps the add (auto-uniquified; flat-name duplicates).
        // Only runtime-ABI names (with_/rt_/wl_) get the unification: their
        // pre-existing declarations are the compiler's own ensure_* probes.
        // A foreign declaration (libc send/recv via @[link_name]) keeps its
        // C symbol — stealing it re-pointed rt-internal libc calls at a
        // renamed undefined decl; the With fn takes the auto-uniquified
        // name instead (whole-program resolution is value-keyed).
        var ast_existing = wl_get_named_function(self.llmod, effective_name)
        if ast_existing != 0 and not codegen_is_runtime_abi_symbol(effective_name):
            ast_existing = 0
        if ast_existing != 0 and wl_fn_is_declaration(ast_existing) != 0 and wl_global_get_value_type(ast_existing) != fn_type:
            wl_set_value_name(ast_existing, effective_name ++ "__stale_decl")
            ast_existing = 0
        let function = if ast_existing != 0 and wl_fn_is_declaration(ast_existing) != 0:
            ast_existing
        else:
            wl_add_function(self.llmod, effective_name, fn_type)
        self.with_fn_link_names.insert(self.intern.intern(effective_name), 1)
        if has_sret != 0:
            wl_add_sret_attr(self.context, function, 0, sret_ty)
        self.apply_c_abi_byval_attrs(function, byval_mask, byval_types, param_count, if has_sret != 0: 1 else: 0)
        self.apply_noalias_param_attrs_with_offset(function, param_start, param_count, if has_sret != 0: 1 else: 0)

        // Whole-program codegen internalizes non-prelude functions because imported
        // modules are duplicated into the current AST. In module-object mode we must
        // keep owner definitions externally linkable and let importers reference them.
        // A function this unit only declares stays external: its definition is
        // the bundle's object (an internal declaration without a body is invalid).
        if self.module_object_mode == 0 and not self.fn_node_is_declared_only(fn_node):
            let is_prelude = self.current_decl_source_file.contains("lib/std/")
            if effective_name != "main" and not is_prelude and
                not codegen_preserve_runtime_link_name(self.current_decl_source_file, effective_name):
                let promoted = self.unit_promoted_name(name_sym, effective_name)
                if promoted.len() > 0:
                    wl_set_value_name(function, promoted)
                else:
                    wl_set_linkage(function, wl_internal_linkage())

        // @[weak] — set weak linkage (LLVMWeakAnyLinkage = 5)
        // Must be checked before c_export which also sets linkage.
        let is_weak = self.pool.state.fn_weak_flags.contains(fn_node)
        if is_weak:
            wl_set_linkage(function, 5)

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

        if has_sret != 0 or byval_mask != 0 or direct_mask != 0 or direct_ret_ty != 0:
            self.record_c_abi_transform(name_sym, has_sret, sret_ty, byval_mask, vec_copy_i64(&byval_types), direct_mask, vec_copy_i64(&direct_types), direct_ret_ty)
            if alias_sym != 0:
                self.record_c_abi_transform(alias_sym, has_sret, sret_ty, byval_mask, vec_copy_i64(&byval_types), direct_mask, vec_copy_i64(&direct_types), direct_ret_ty)
            if method_key_sym != 0:
                self.record_c_abi_transform(method_key_sym, has_sret, sret_ty, byval_mask, move byval_types, direct_mask, move direct_types, direct_ret_ty)

        self.fn_values.insert(name_sym, function)
        self.fn_fn_types.insert(name_sym, fn_type)
        if alias_sym != 0:
            self.fn_values.insert(alias_sym, function)
            self.fn_fn_types.insert(alias_sym, fn_type)
        if method_key_sym != 0:
            self.fn_values.insert(method_key_sym, function)
            self.fn_fn_types.insert(method_key_sym, fn_type)

        self.current_method_owner_sym = saved_owner

// #D6: PassMode — the per-parameter ABI classification, the SINGLE source of
// truth; the rule and the PM_* constants live in src/FnAbi.w
// (docs/with-abi.md §4). `arg_pass_mode` feeds it Sema's share-place
// verdict and the platform's aggregate rule; both the callee prologue
// (declare_function_from_sig) and every call site read it, so caller and
// callee can never disagree on how an argument is passed (that disagreement
// is exactly the transparent T*/T** bug). Extend the classification THERE,
// never per-path. See decisions.md D6, docs/fn_abi_descriptor_design.md.

impl Codegen:
    mut fn abi_param_source_type(sig_idx: i32, pi: i32) -> i64:
        var p_ty = self.sema_type_to_llvm(self.sema.sig_param_type(sig_idx, pi))
        if p_ty == 0:
            p_ty = self.type_fallback()
        // Unit is carried as i32 at the LLVM ABI boundary. LLVM void is legal
        // only as a function result; using it as a parameter or local alloca
        // trips DataLayout while lazily emitting a generic specialization.
        if wl_get_type_kind(p_ty) == wl_void_type_kind():
            p_ty = wl_i32_type(self.context)
        p_ty

    fn sig_param_is_explicit_ref(sig_idx: i32, pi: i32) -> bool:
        if sig_idx < 0 or pi < 0 or pi >= self.sema.sig_get_param_count(sig_idx):
            return false
        let ty = self.sema.sig_param_type(sig_idx, pi)
        if ty <= 0:
            return false
        let resolved = self.sema.resolve_alias(ty as TypeId) as i32
        self.sema.get_type_kind(resolved) == TypeKind.TY_REF

    mut fn arg_pass_mode(sig_idx: i32, pi: i32) -> i32:
        let uses_value_ref_abi = self.sema.sig_param_uses_value_ref_abi(sig_idx, pi)
        if uses_value_ref_abi != 0:
            return fn_abi_pass_mode(uses_value_ref_abi, false)
        let p_ty = self.abi_param_source_type(sig_idx, pi)
        fn_abi_pass_mode(0, self.internal_abi_needs_indirect_param(p_ty))

    mut fn declare_function_from_sig(fn_sym: i32, sig_idx: i32, force_internal: i32):
        if fn_sym == 0 or sig_idx < 0:
            return
        let cg_sym = self.codegen_sym_for_sema_sym(fn_sym)
        let sema_name = self.sema_symbol_text(fn_sym)
        var effective_name =
            if sema_name.len() > 0:
                sema_name
            else:
                self.function_symbol_name(cg_sym)
        if self.path_uses_module_link_names(self.current_decl_source_file) and force_internal == 0 and
            not codegen_preserve_runtime_link_name(self.current_decl_source_file, effective_name):
            effective_name = self.current_decl_module_link_name(effective_name)

        var ret_ty = self.sema_type_to_llvm(self.sema.sig_return_type(sig_idx))
        if ret_ty == 0:
            ret_ty = self.type_fallback()
        let param_count = self.sema.sig_get_param_count(sig_idx)
        let param_types: Vec[i64] = Vec.new()
        for pi in 0..param_count:
            var p_ty = self.abi_param_source_type(sig_idx, pi)
            // #D6: the prologue reads the single ABI classifier — an IndirectPlace
            // param is a pointer to the caller's place (value_ref_abi / share-place).
            let pass_mode = self.arg_pass_mode(sig_idx, pi)
            if pass_mode == PM_INDIRECT_PLACE:
                p_ty = wl_ptr_type(self.context)
            if pass_mode == PM_INDIRECT_PLACE or self.sig_param_is_explicit_ref(sig_idx, pi):
                self.record_ref_param(cg_sym, pi, param_count)
                if cg_sym != fn_sym:
                    self.record_ref_param(fn_sym, pi, param_count)
            param_types.push(p_ty)

        var actual_ret_ty = ret_ty
        var has_sret = 0
        var sret_ty: i64 = 0
        var byval_mask: i64 = 0
        let byval_types: Vec[i64] = Vec.new()
        let direct_types: Vec[i64] = Vec.new()
        let actual_param_types: Vec[i64] = Vec.new()
        if self.internal_abi_needs_sret(ret_ty):
            has_sret = 1
            sret_ty = ret_ty
            actual_ret_ty = wl_void_type(self.context)
            actual_param_types.push(wl_ptr_type(self.context))
        for api in 0..param_count:
            let source_ty = param_types.get(api as i64)
            // #D6: byval indirection is the Indirect pass mode (callee-owned copy).
            if self.arg_pass_mode(sig_idx, api) == PM_INDIRECT:
                actual_param_types.push(wl_ptr_type(self.context))
                byval_mask = byval_mask | ((1 as i64) << (api as u32))
                byval_types.push(source_ty)
                direct_types.push(0)
            else:
                actual_param_types.push(source_ty)
                byval_types.push(0)
                direct_types.push(0)

        let fn_type = wl_function_type(actual_ret_ty, vec_data_i64(&actual_param_types), actual_param_types.len() as i32, self.sema.sig_is_variadic(sig_idx))
        // #839: reuse only a same-typed entry. A mismatched occupant (e.g. a
        // link_name extern claiming this bare name) keeps the C symbol; the
        // With fn takes an LLVM-uniquified name — resolution is value-keyed.
        var existing = wl_get_named_function(self.llmod, effective_name)
        if existing != 0 and wl_global_get_value_type(existing) != fn_type:
            existing = 0
        let function = if existing != 0: existing else: wl_add_function(self.llmod, effective_name, fn_type)
        self.with_fn_link_names.insert(self.intern.intern(effective_name), 1)
        if has_sret != 0:
            wl_add_sret_attr(self.context, function, 0, sret_ty)
        if has_sret != 0 or byval_mask != 0:
            self.record_c_abi_transform(cg_sym, has_sret, sret_ty, byval_mask, vec_copy_i64(&byval_types), 0, vec_copy_i64(&direct_types), 0)
            if cg_sym != fn_sym:
                self.record_c_abi_transform(fn_sym, has_sret, sret_ty, byval_mask, move byval_types, 0, move direct_types, 0)
        if force_internal != 0:
            let promoted_fi = self.unit_promoted_name(fn_sym, effective_name)
            if promoted_fi.len() > 0:
                wl_set_value_name(function, promoted_fi)
            else:
                wl_set_linkage(function, wl_internal_linkage())
        else if self.module_object_mode == 0 and not self.path_is_bundle_provided(self.current_decl_source_file):
            if effective_name != "main" and not self.current_decl_source_file.contains("lib/std/") and
                not codegen_preserve_runtime_link_name(self.current_decl_source_file, effective_name):
                let promoted_mo = self.unit_promoted_name(fn_sym, effective_name)
                if promoted_mo.len() > 0:
                    wl_set_value_name(function, promoted_mo)
                else:
                    wl_set_linkage(function, wl_internal_linkage())

        self.fn_values.insert(cg_sym, function)
        self.fn_fn_types.insert(cg_sym, fn_type)
        if cg_sym != fn_sym:
            self.fn_values.insert(fn_sym, function)
            self.fn_fn_types.insert(fn_sym, fn_type)

    mut fn declare_generator_next_functions():
        for si in 0..self.sema.sig_names.len() as i32:
            let fn_sym: i32 = self.sema.sig_names.get(si as i64)
            if not self.sema.generator_next_fn_syms.contains(fn_sym):
                continue
            self.declare_function_from_sig(fn_sym, si, 1)

    fn find_sema_sig_for_mir_body_sym(body_sym: i32) -> (i32, i32):
        let body_name = self.function_symbol_name(body_sym)
        if body_name.len() == 0:
            return (0, -1)
        for si in 0..self.sema.sig_names.len() as i32:
            let sig_sym = self.sema.sig_names.get(si as i64)
            if self.sema_symbol_text(sig_sym) == body_name:
                return (sig_sym, si)
        (0, -1)

    fn mir_body_is_generated_function_clause(body_sym: i32) -> bool:
        let body_name = self.function_symbol_name(body_sym)
        if body_name.contains("$clause$"):
            return true
        for gi in 0..self.sema.fn_clause_group_count():
            if self.sema_symbol_text(self.sema.fn_clause_group_name(gi)) == body_name:
                return true
        false

    mut fn declare_mir_only_functions():
        for bi in 0..self.mir_fn_syms_len() as i32:
            let body_sym = self.mir_fn_sym_at(bi as i64)
            if body_sym == 0:
                continue
            if not self.mir_body_is_generated_function_clause(body_sym):
                continue
            if self.fn_values.get(body_sym).is_some():
                continue
            let sig_pair = self.find_sema_sig_for_mir_body_sym(body_sym)
            let sig_sym = sig_pair.0
            let sig_idx = sig_pair.1
            if sig_sym != 0 and sig_idx >= 0:
                self.declare_function_from_sig(sig_sym, sig_idx, 1)

    mut fn gen_mir_only_functions():
        for bi in 0..self.mir_fn_syms_len() as i32:
            let body_sym = self.mir_fn_sym_at(bi as i64)
            if body_sym == 0:
                continue
            if not self.unit_owns(body_sym):
                continue
            if not self.mir_body_is_generated_function_clause(body_sym):
                continue
            if self.generated_mir_body_syms.contains(body_sym):
                continue
            let body = self.mir_body_at(bi as i64)
            if body.lowering_failed != 0 or body.block_count() == 0:
                continue
            self.gen_function_mir(0, body)

    fn is_method_on_generic_struct(name_sym: i32) -> bool:
        if name_sym <= 0:
            return false
        let raw_name = self.intern.resolve(name_sym)
        let name_str = if raw_name.len() > 0: with_str_clone_ref(raw_name) else: self.sema_symbol_text(name_sym)
        if name_str.len() == 0:
            return false
        for di in 0..name_str.len() as i32:
            if name_str.byte_at(di as i64) == 46:
                let owner_sym = self.intern.intern(name_str.slice(0, di as i64))
                return self.generic_type_decl_node(owner_sym) != 0
        false

    fn is_ref_param(fn_sym: i32, param_idx: i32) -> bool:
        let start_opt = self.fn_ref_param_starts.get(fn_sym)
        if not start_opt.is_some():
            return false
        let start = start_opt.unwrap()
        let slot = start + param_idx
        if slot < 0 or slot >= self.fn_ref_param_data.len() as i32:
            return false
        self.fn_ref_param_data.get(slot as i64) != 0

    fn record_ref_param(fn_sym: i32, idx: i32, count: i32):
        if not self.fn_ref_param_starts.get(fn_sym).is_some():
            let start = self.fn_ref_param_data.len() as i32
            self.fn_ref_param_starts.insert(fn_sym, start)
            for j in 0..count:
                self.fn_ref_param_data.push(0)
        let base: i32 = self.fn_ref_param_starts.get(fn_sym).unwrap()
        self.fn_ref_param_data.set_i32((base + idx) as i64, 1)

    fn record_ref_param_aliases(fn_sym: i32, alias_sym: i32, method_key_sym: i32, idx: i32, count: i32):
        self.record_ref_param(fn_sym, idx, count)
        if alias_sym != 0:
            self.record_ref_param(alias_sym, idx, count)
        if method_key_sym != 0:
            self.record_ref_param(method_key_sym, idx, count)

    fn apply_noalias_param_attrs(function: i64, param_start: i32, param_count: i32):
        self.apply_noalias_param_attrs_with_offset(function, param_start, param_count, 0)

    fn apply_noalias_param_attrs_with_offset(function: i64, param_start: i32, param_count: i32, param_offset: i32):
        if function == 0 or param_start < 0 or param_count <= 0:
            return
        let fn_type = wl_global_get_value_type(function)
        // LLVMGetParam past the declared count walks LLVM's lazy-argument
        // builder into a null deref (silent compiler SIGSEGV). An index
        // beyond the declared type is a real AST-vs-ABI divergence — skip
        // it loudly instead of crashing.
        // A handle whose value type is not a function type cannot receive
        // param attrs, and LLVMGetParam on it walks the lazy-arg builder
        // into a null deref. Loud skip: a non-function under a mono sym in
        // fn_values is a registration bug upstream, not an attr concern.
        if fn_type == 0 or wl_count_param_types(fn_type) < 0:
            if with_getenv_str("WITH_MIR_AUDIT").len() > 0:
                with_eprint(f"[noalias-nonfn] attr walk on non-function value (param_count={param_count} offset={param_offset})")
            return
        let llvm_param_count = wl_count_param_types(fn_type)
        for pi in 0..param_count:
            let actual_idx = pi + param_offset
            if actual_idx < 0 or actual_idx >= llvm_param_count:
                if with_getenv_str("WITH_MIR_AUDIT").len() > 0:
                    with_eprint(f"[noalias-oob] fn declares {llvm_param_count} LLVM params, attr walk wants index {actual_idx} (param_count={param_count} offset={param_offset})")
                continue
            var param_ty = wl_get_fn_param_type(fn_type, actual_idx)
            if param_ty == 0:
                let param = wl_get_param(function, actual_idx)
                if param == 0:
                    continue
                param_ty = wl_type_of(param)
            if wl_get_type_kind(param_ty) != wl_pointer_type_kind():
                continue
            let flags = self.pool.fn_param_flags(param_start, pi)
            if fn_param_is_noalias(flags) != 0:
                wl_add_param_attr(self.context, function, actual_idx, "noalias")

    fn record_dyn_param(fn_sym: i32, idx: i32, count: i32, trait_sym: i32):
        if not self.fn_dyn_param_starts.get(fn_sym).is_some():
            let start = self.fn_dyn_param_data.len() as i32
            self.fn_dyn_param_starts.insert(fn_sym, start)
            for j in 0..count:
                self.fn_dyn_param_data.push(0)
        let base: i32 = self.fn_dyn_param_starts.get(fn_sym).unwrap()
        self.fn_dyn_param_data.set_i32((base + idx) as i64, trait_sym)

    fn fn_callconv_name(meta: i32) -> str:
        if meta < 0:
            return ""
        let cc_sym = self.pool.fn_meta_tp_start(meta)
        if cc_sym == 0:
            return ""
        let cc_name = self.intern.resolve(cc_sym)
        if cc_name.len() >= 2 and cc_name.byte_at(0) == 34 and cc_name.byte_at(cc_name.len() - 1) == 34:
            return cc_name.slice(1, cc_name.len() - 1)
        with_str_clone_ref(cc_name)

    fn fn_uses_c_abi(cc_name: &str) -> bool:
        cc_name == "c" or (cc_name.len() > 9 and cc_name.slice(0, 9) == "c_export:")

fn codegen_extern_uses_internal_abi(name: &str, cc_name: &str) -> bool:
    if cc_name.len() > 0:
        return false
    codegen_is_runtime_abi_symbol(name)

fn codegen_c_abi_needs_byval_attr() -> bool:
    let os = target_spec_os()
    let arch = target_spec_arch()
    arch == "x86_64" and (os == "Linux" or os == "Macos")

fn codegen_c_abi_darwin_arm64() -> bool:
    let os = target_spec_os()
    let arch = target_spec_arch()
    os == "Macos" and arch == "aarch64"

fn codegen_windows_x86_64() -> bool:
    let os = target_spec_os()
    let arch = target_spec_arch()
    os == "Windows" and arch == "x86_64"

impl Codegen:
    // Both feed fn_abi_platform_aggregate_indirect (src/FnAbi.w) the facts it
    // needs: the target, whether the LLVM type is an aggregate, and its size.
    mut fn internal_abi_needs_sret(ret_ty: i64) -> bool:
        self.internal_abi_aggregate_indirect(ret_ty)

    mut fn internal_abi_needs_indirect_param(param_ty: i64) -> bool:
        self.internal_abi_aggregate_indirect(param_ty)

    mut fn internal_abi_aggregate_indirect(ty: i64) -> bool:
        if not codegen_windows_x86_64() or ty == 0:
            return false
        let kind = wl_get_type_kind(ty)
        let is_aggregate = kind == wl_struct_type_kind() or kind == wl_array_type_kind()
        if not is_aggregate:
            return false
        fn_abi_platform_aggregate_indirect(true, true, self.abi_size_of(ty))

    // #806/D6: the LLVM param type a fat-closure signature must declare for a
    // value of `val_ty`. A win64 aggregate >8B is passed indirectly (pointer):
    // the closure callee (gen_closure / mir_build_closure_fn_type) declares
    // `ptr` and loads its own copy, so every inline closure-call site must
    // declare `ptr` too or caller and callee disagree on the argument shape and
    // the aggregate arrives corrupted (#806). No-op on non-win64.
    mut fn closure_abi_param_ty(val_ty: i64) -> i64:
        if self.internal_abi_needs_indirect_param(val_ty):
            return wl_ptr_type(self.context)
        val_ty

    // #806/D6: marshal a by-value closure argument to match closure_abi_param_ty.
    // For a win64-indirect param, materialize a caller-owned copy and pass its
    // address (the callee loads its own copy from it); otherwise pass the value
    // unchanged. No-op on non-win64.
    mut fn closure_abi_arg(val_ty: i64, val: i64) -> i64:
        if self.internal_abi_needs_indirect_param(val_ty):
            let a = self.create_entry_alloca(val_ty)
            wl_build_store(self.builder, val, a)
            return a
        val

    mut fn c_abi_needs_sret(ret_ty: i64) -> bool:
        if ret_ty == 0:
            return false
        if wl_get_type_kind(ret_ty) != wl_struct_type_kind():
            return false
        if codegen_windows_x86_64():
            return self.c_abi_direct_struct_return_type(ret_ty) == 0
        self.abi_size_of(ret_ty) > 16

    mut fn c_abi_needs_indirect_param(param_ty: i64) -> bool:
        if param_ty == 0:
            return false
        if wl_get_type_kind(param_ty) != wl_struct_type_kind():
            return false
        if codegen_windows_x86_64():
            return self.c_abi_direct_struct_param_type(param_ty) == 0
        self.abi_size_of(param_ty) > 16

    fn c_abi_integer_aggregate_ok(ty: i64) -> bool:
        if ty == 0:
            return false
        let kind = wl_get_type_kind(ty)
        if kind == wl_integer_type_kind() or kind == wl_pointer_type_kind():
            return true
        if kind == wl_array_type_kind():
            return self.c_abi_integer_aggregate_ok(wl_get_element_type(ty))
        if kind == wl_struct_type_kind():
            let field_count = wl_count_struct_elem_types(ty)
            if field_count <= 0:
                return false
            for fi in 0..field_count:
                if not self.c_abi_integer_aggregate_ok(wl_struct_get_type_at(ty, fi)):
                    return false
            return true
        false

    fn c_abi_hfa_accumulate(ty: i64, state: i32) -> i32:
        if ty == 0 or state < 0:
            return -1
        let kind = wl_get_type_kind(ty)
        if kind == wl_float_type_kind() or kind == wl_double_type_kind():
            let scalar_kind = if kind == wl_float_type_kind(): 1 else: 2
            if state == 0:
                return scalar_kind * 16 + 1
            let prev_kind = state / 16
            let prev_count = state % 16
            if prev_kind != scalar_kind or prev_count >= 4:
                return -1
            return prev_kind * 16 + prev_count + 1
        if kind == wl_array_type_kind():
            let elem = wl_get_element_type(ty)
            var out = state
            let count = wl_get_array_length(ty) as i32
            for _i in 0..count:
                out = self.c_abi_hfa_accumulate(elem, out)
                if out < 0:
                    return -1
            return out
        if kind == wl_struct_type_kind():
            var out2 = state
            let field_count = wl_count_struct_elem_types(ty)
            for fi in 0..field_count:
                out2 = self.c_abi_hfa_accumulate(wl_struct_get_type_at(ty, fi), out2)
                if out2 < 0:
                    return -1
            return out2
        -1

    fn c_abi_hfa_info(ty: i64) -> i32:
        if ty == 0 or wl_get_type_kind(ty) != wl_struct_type_kind():
            return 0
        let info = self.c_abi_hfa_accumulate(ty, 0)
        if info <= 0:
            return 0
        let count = info % 16
        if count <= 0 or count > 4:
            return 0
        info

    fn c_abi_hfa_type(info: i32) -> i64:
        let kind = info / 16
        let count = info % 16
        if count <= 0:
            return 0
        let elem_ty = if kind == 1: wl_f32_type(self.context) else: wl_f64_type(self.context)
        wl_array_type(elem_ty, count as i64)

    mut fn c_abi_direct_struct_param_type(ty: i64) -> i64:
        if ty == 0 or wl_get_type_kind(ty) != wl_struct_type_kind():
            return 0
        if self.is_str_type(ty):
            return 0
        if codegen_windows_x86_64():
            let size = self.abi_size_of(ty)
            if (size == 1 or size == 2 or size == 4 or size == 8) and self.c_abi_integer_aggregate_ok(ty):
                return wl_int_type_n(self.context, (size * 8) as i32)
            return 0
        if not codegen_c_abi_darwin_arm64():
            return 0
        let hfa = self.c_abi_hfa_info(ty)
        if hfa != 0:
            return self.c_abi_hfa_type(hfa)
        let size = self.abi_size_of(ty)
        if size <= 0 or size > 16:
            return 0
        if not self.c_abi_integer_aggregate_ok(ty):
            return 0
        if size <= 8:
            return wl_i64_type(self.context)
        wl_array_type(wl_i64_type(self.context), 2)

    mut fn c_abi_direct_struct_return_type(ty: i64) -> i64:
        if ty == 0 or wl_get_type_kind(ty) != wl_struct_type_kind():
            return 0
        if self.is_str_type(ty):
            return 0
        if codegen_windows_x86_64():
            let size = self.abi_size_of(ty)
            if (size == 1 or size == 2 or size == 4 or size == 8) and self.c_abi_integer_aggregate_ok(ty):
                return wl_int_type_n(self.context, (size * 8) as i32)
            return 0
        if not codegen_c_abi_darwin_arm64():
            return 0
        if self.c_abi_hfa_info(ty) != 0:
            return 0
        let size = self.abi_size_of(ty)
        if size <= 0 or size > 16:
            return 0
        if not self.c_abi_integer_aggregate_ok(ty):
            return 0
        if size <= 8:
            return wl_int_type_n(self.context, (size * 8) as i32)
        wl_array_type(wl_i64_type(self.context), 2)

    fn ensure_llvm_memcpy_declared() -> i64:
        let mc_sym = self.intern.intern("llvm.memcpy.p0.p0.i64")
        let cached = self.fn_values.get(mc_sym)
        if cached.is_some():
            return cached.unwrap() as i64
        let params: Vec[i64] = Vec.new()
        params.push(wl_ptr_type(self.context))
        params.push(wl_ptr_type(self.context))
        params.push(wl_i64_type(self.context))
        params.push(wl_i1_type(self.context))
        let fn_ty = wl_function_type(wl_void_type(self.context), vec_data_i64(&params), 4, 0)
        let fn_val = wl_add_function(self.llmod, "llvm.memcpy.p0.p0.i64", fn_ty)
        self.fn_values.insert(mc_sym, fn_val)
        self.fn_fn_types.insert(mc_sym, fn_ty)
        fn_val

    fn emit_llvm_memcpy(dst: i64, src: i64, byte_count: i64):
        let fn_val = self.ensure_llvm_memcpy_declared()
        let fn_ty = wl_global_get_value_type(fn_val)
        let args: Vec[i64] = Vec.new()
        args.push(dst)
        args.push(src)
        args.push(wl_const_int(wl_i64_type(self.context), byte_count, 0))
        args.push(wl_const_int(wl_i1_type(self.context), 0, 0))
        let _ = wl_build_call(self.builder, fn_ty, fn_val, vec_data_i64(&args), 4)

    mut fn c_abi_pack_direct_value(value: i64, abi_ty: i64) -> i64:
        if value == 0 or abi_ty == 0:
            return value
        if wl_type_of(value) == abi_ty:
            return value
        let source_ty = wl_type_of(value)
        let source_slot = self.create_entry_alloca(source_ty)
        wl_build_store(self.builder, value, source_slot)
        let abi_slot = self.create_entry_alloca(abi_ty)
        wl_build_store(self.builder, wl_const_null(abi_ty), abi_slot)
        self.emit_llvm_memcpy(abi_slot, source_slot, self.abi_size_of(source_ty))
        wl_build_load(self.builder, abi_ty, abi_slot)

    mut fn c_abi_unpack_direct_value(value: i64, original_ty: i64) -> i64:
        if value == 0 or original_ty == 0:
            return value
        if wl_type_of(value) == original_ty:
            return value
        let abi_ty = wl_type_of(value)
        let abi_slot = self.create_entry_alloca(abi_ty)
        wl_build_store(self.builder, value, abi_slot)
        let source_slot = self.create_entry_alloca(original_ty)
        wl_build_store(self.builder, wl_const_null(original_ty), source_slot)
        self.emit_llvm_memcpy(source_slot, abi_slot, self.abi_size_of(original_ty))
        wl_build_load(self.builder, original_ty, source_slot)

    fn record_c_abi_transform(fn_sym: i32, has_sret: i32, sret_ty: i64, byval_mask: i64, byval_types: Vec[i64], direct_mask: i64, direct_types: Vec[i64], direct_ret_ty: i64):
        if fn_sym == 0:
            return
        if has_sret == 0 and byval_mask == 0 and direct_mask == 0 and direct_ret_ty == 0:
            return
        self.extern_fn_has_sret.insert(fn_sym, has_sret)
        self.extern_fn_byval_params.insert(fn_sym, byval_mask)
        self.extern_fn_byval_types.insert(fn_sym, move byval_types)
        self.extern_fn_direct_params.insert(fn_sym, direct_mask)
        self.extern_fn_direct_param_types.insert(fn_sym, move direct_types)
        if has_sret != 0:
            self.extern_fn_sret_type.insert(fn_sym, sret_ty)
        if direct_ret_ty != 0:
            self.extern_fn_direct_ret_type.insert(fn_sym, direct_ret_ty)

    fn apply_c_abi_byval_attrs(function: i64, byval_mask: i64, byval_types: &Vec[i64], param_count: i32, param_offset: i32):
        if function == 0 or byval_mask == 0:
            return
        if not codegen_c_abi_needs_byval_attr():
            return
        for pi in 0..param_count:
            if (byval_mask & ((1 as i64) << (pi as u32))) == 0:
                continue
            if pi >= byval_types.len() as i32:
                continue
            let byval_ty = byval_types.get(pi as i64)
            if byval_ty == 0:
                continue
            wl_add_param_byval_attr(self.context, function, pi + param_offset, byval_ty)

    fn apply_c_abi_call_attrs(call_val: i64, has_sret: i32, sret_ty: i64, byval_mask: i64, byval_types: &Vec[i64], original_arg_count: i32, arg_prefix_count: i32):
        if call_val == 0:
            return
        var byval_offset = arg_prefix_count
        if has_sret != 0 and sret_ty != 0:
            wl_add_call_sret_attr(self.context, call_val, arg_prefix_count, sret_ty)
            byval_offset = byval_offset + 1
        if byval_mask == 0:
            return
        if not codegen_c_abi_needs_byval_attr():
            return
        for ai in 0..original_arg_count:
            if (byval_mask & ((1 as i64) << (ai as u32))) == 0:
                continue
            if ai >= byval_types.len() as i32:
                continue
            let byval_ty = byval_types.get(ai as i64)
            if byval_ty == 0:
                continue
            wl_add_call_param_byval_attr(self.context, call_val, byval_offset + ai, byval_ty)

    // ── Declare extern fn ─────────────────────────────────────────────

    mut fn declare_extern_fn(ext_node: i32):
        let name_sym = self.pool.get_data0(ext_node)

        let ext_flags = self.pool.get_data2(ext_node)
        let is_variadic = ext_flags % 2

        let meta = self.pool.find_fn_meta(ext_node)
        if meta < 0: return

        let ret_type_node = self.pool.fn_meta_ret(meta)
        let param_start = self.pool.fn_meta_param_start(meta)
        let param_count = self.pool.fn_meta_param_count(meta)
        let sema_sig_idx = self.sema.get_sig(name_sym)

        let ret_ty = self.resolve_type(ret_type_node)
        let name_str = self.intern.resolve(name_sym)
        let cc_name = self.fn_callconv_name(meta)
        let uses_internal_abi = codegen_extern_uses_internal_abi(name_str, cc_name)

        // Resolve original param types
        let orig_param_types: Vec[i64] = Vec.new()
        for pi in 0..param_count:
            let p_type_node = self.pool.fn_param_type(param_start, pi)
            orig_param_types.push(self.resolve_type(p_type_node))
            if (sema_sig_idx >= 0 and self.sig_param_is_explicit_ref(sema_sig_idx, pi)) or
               (sema_sig_idx < 0 and self.pool.kind(p_type_node) == NodeKind.NK_TYPE_REF):
                self.record_ref_param(name_sym, pi, param_count)

        // ABI transformation for C interop on aarch64:
        // - Struct params > 16 bytes → ptr (caller passes pointer to copy)
        // - Struct returns > 16 bytes → void return + hidden sret ptr first param
        let ptr_ty = wl_ptr_type(self.context)
        var has_sret = 0
        var sret_ty: i64 = 0
        var byval_mask: i64 = 0
        let byval_types: Vec[i64] = Vec.new()
        var direct_mask: i64 = 0
        let direct_types: Vec[i64] = Vec.new()
        var direct_ret_ty: i64 = 0

        // Check return type: direct C ABI aggregate, C sret, or internal With sret.
        var actual_ret_ty = ret_ty
        if uses_internal_abi:
            if self.internal_abi_needs_sret(ret_ty):
                has_sret = 1
                sret_ty = ret_ty
                actual_ret_ty = wl_void_type(self.context)
        else if ret_ty != 0 and wl_get_type_kind(ret_ty) == wl_struct_type_kind():
            let direct_ret_abi_ty = self.c_abi_direct_struct_return_type(ret_ty)
            if direct_ret_abi_ty != 0:
                direct_ret_ty = ret_ty
                actual_ret_ty = direct_ret_abi_ty
            else if codegen_c_abi_darwin_arm64() and self.c_abi_hfa_info(ret_ty) != 0:
                actual_ret_ty = ret_ty
            else if self.c_abi_needs_sret(ret_ty):
                has_sret = 1
                sret_ty = ret_ty
                actual_ret_ty = wl_void_type(self.context)

        // Build final param list with ABI transformations
        let param_types: Vec[i64] = Vec.new()
        if has_sret != 0:
            param_types.push(ptr_ty)  // hidden sret param at index 0

        for pi in 0..param_count:
            let orig_ty = orig_param_types.get(pi as i64)
            if uses_internal_abi:
                if self.internal_abi_needs_indirect_param(orig_ty):
                    param_types.push(ptr_ty)
                    byval_mask = byval_mask | ((1 as i64) << (pi as u32))
                    byval_types.push(orig_ty)
                    direct_types.push(0)
                    continue
            else if wl_get_type_kind(orig_ty) == wl_struct_type_kind():
                let direct_param_ty = self.c_abi_direct_struct_param_type(orig_ty)
                if direct_param_ty != 0:
                    param_types.push(direct_param_ty)
                    direct_mask = direct_mask | ((1 as i64) << (pi as u32))
                    byval_types.push(0)
                    direct_types.push(orig_ty)
                    continue
                if self.c_abi_needs_indirect_param(orig_ty):
                    param_types.push(ptr_ty)
                    byval_mask = byval_mask | ((1 as i64) << (pi as u32))
                    byval_types.push(orig_ty)
                    direct_types.push(0)
                    continue
            param_types.push(orig_ty)
            byval_types.push(0)
            direct_types.push(0)

        let actual_param_count = param_types.len() as i32
        let fn_type = wl_function_type(actual_ret_ty, vec_data_i64(&param_types), actual_param_count, is_variadic)

        // @[link_name("symbol")] overrides the C symbol this extern links against
        // (stored as a "link_name:" callconv prefix). Otherwise canonicalize the
        // With name. Lets a generated wrapper take the public name while the raw
        // binding is renamed but still resolves to the real C symbol.
        var link_name = self.canonical_extern_name(name_str)
        if cc_name.len() > 10 and cc_name.slice(0, 10) == "link_name:":
            link_name = cc_name.slice(10, cc_name.len() as i64)

        // Check if already declared. #839: an extern owns its C symbol — if a
        // With-BODIED fn occupies the name with a different type
        // (whole-program mode keeps bare names; e.g. prelude `write` vs
        // @[link_name("write")]), move the occupant aside (references hold
        // the LLVM value, not the name — its body attaches through fn_values
        // in pass 2) and claim the symbol fresh. A mismatched FOREIGN
        // declaration keeps the old reuse behavior: c_import deliberately
        // declares one C symbol under multiple prototypes and marshals
        // through the recorded C-ABI transforms.
        var existing = wl_get_named_function(self.llmod, link_name)
        if existing != 0 and wl_global_get_value_type(existing) != fn_type and self.with_fn_link_names.contains(self.intern.intern(link_name)):
            wl_set_value_name(existing, link_name ++ "__with_body")
            self.with_fn_link_names.remove(self.intern.intern(link_name))
            existing = 0
        var function = existing
        if existing == 0:
            function = wl_add_function(self.llmod, link_name, fn_type)

        if has_sret != 0:
            wl_add_sret_attr(self.context, function, 0, sret_ty)
        self.apply_c_abi_byval_attrs(function, byval_mask, byval_types, param_count, if has_sret != 0: 1 else: 0)

        // Record ABI transformations for call sites
        if has_sret != 0 or byval_mask != 0 or direct_mask != 0 or direct_ret_ty != 0:
            self.record_c_abi_transform(name_sym, has_sret, sret_ty, byval_mask, vec_copy_i64(&byval_types), direct_mask, vec_copy_i64(&direct_types), direct_ret_ty)

        self.apply_noalias_param_attrs_with_offset(function, param_start, param_count, if has_sret != 0: 1 else: 0)

        // Apply calling convention or c_export if specified
        if cc_name.len() > 0:
            if cc_name.len() > 10 and cc_name.slice(0, 10) == "link_name:":
                // @[link_name(...)] — symbol already applied above; keep C ABI.
                0
            else if cc_name.len() > 9 and cc_name.slice(0, 9) == "c_export:":
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
                self.record_c_abi_transform(canonical_sym, has_sret, sret_ty, byval_mask, move byval_types, direct_mask, move direct_types, direct_ret_ty)

    fn resolve_callconv(name: &str) -> i32:
        if name == "c": return wl_cc_c()
        if name == "stdcall": return wl_cc_x86_stdcall()
        if name == "fastcall": return wl_cc_x86_fastcall()
        if name == "thiscall": return wl_cc_x86_thiscall()
        if name == "win64": return wl_cc_win64()
        if name == "vectorcall": return wl_cc_x86_fastcall()
        if name == "aarch64_vfabi": return wl_cc_aarch64_vfabi()
        if name == "fast": return wl_cc_fast()
        -1

    mut fn declare_extern_var(node: i32):
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
        var gv = existing
        if existing == 0:
            gv = wl_add_global(self.llmod, var_ty, link_name)
        // External linkage is the default — no need to set it
        if is_mut == 0:
            wl_set_global_constant(gv, 1)
        self.module_constants.insert(name_sym, gv)

    fn canonical_extern_name(name: &str) -> str:
        // c_import may suffix C symbols as "name.<n>" — strip the suffix for linking.
        var dot_pos = -1
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
        with_str_clone_ref(name)

    // ── Detect drop functions ─────────────────────────────────────────

    fn detect_drop_functions():
        for i in 0..self.pool.decl_count():
            let decl = self.pool.get_decl(i)
            if self.pool.kind(decl) != NodeKind.NK_IMPL_DECL:
                continue
            if not self.codegen_symbols_match(self.pool.get_data2(decl), self.sema.syms.drop):
                continue
            let type_sym = self.sema_sym_to_codegen_sym(self.pool.get_data0(decl))
            if type_sym == 0:
                continue
            if self.sema.type_symbol_is_std_box(type_sym) == 0 and not self.struct_type_map.get(type_sym).is_some() and not self.enum_type_map.get(type_sym).is_some():
                continue
            let drop_decl = self.impl_decl_method_named(decl as i32, "drop")
            if drop_decl == 0:
                continue
            let fn_text = self.fn_decl_semantic_text(drop_decl)
            if fn_text.len() == 0:
                continue
            let fn_sym = self.intern.intern(fn_text)
            let fv = self.fn_values.get(fn_sym)
            let ft = self.fn_fn_types.get(fn_sym)
            if fv.is_some() and ft.is_some():
                let drop_fv: i64 = fv.unwrap()
                let drop_ft: i64 = ft.unwrap()
                self.drop_fn_values.insert(type_sym, drop_fv)
                self.drop_fn_types.insert(type_sym, drop_ft)

    // ── Result return type helpers ────────────────────────────────────

    fn is_result_return_type(ret_node: i32) -> bool:
        if ret_node == 0: return false
        if self.pool.kind(ret_node) != NodeKind.NK_TYPE_GENERIC: return false
        let name_sym = self.pool.get_data0(ret_node)
        let arg_count = self.pool.get_data2(ret_node)
        if arg_count != 2: return false
        name_sym == self.sym_result

    fn result_err_symbol_from_return(ret_node: i32) -> i32:
        if not self.is_result_return_type(ret_node): return 0
        let extra_start = self.pool.get_data1(ret_node)
        let err_node = self.pool.get_extra(extra_start + 1)
        if self.pool.kind(err_node) == NodeKind.NK_TYPE_NAMED:
            return self.pool.get_data0(err_node)
        0

    fn is_result_unit_return(ret_node: i32) -> bool:
        if not self.is_result_return_type(ret_node): return false
        let extra_start = self.pool.get_data1(ret_node)
        let ok_node = self.pool.get_extra(extra_start)
        if self.pool.kind(ok_node) == NodeKind.NK_TYPE_NAMED:
            return self.pool.get_data0(ok_node) == self.sym_unit
        false

    // ── Option/Result type construction ───────────────────────────────

    fn get_or_create_option_type(sema_tid: i32, payload_ty: i64) -> i64:
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
        if payload_ty != 0 and wl_get_type_kind(payload_ty) != wl_void_type_kind():
            body.push(payload_ty)
        let opt_type = wl_struct_type(self.context, vec_data_i64(&body), body.len() as i32, 0)
        self.option_cache_map.insert(cache_key, opt_type)
        opt_type

    mut fn get_or_create_result_type(sema_tid: i32, ok_ty: i64, err_ty: i64) -> i64:
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

    mut fn get_or_create_context_error_type(source_ty: i64) -> i64:
        // ContextError[E] = { message: str, source: E }
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

    fn deterministic_type_tag(ty: i64) -> str:
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

    fn collection_wrapper_name_1(prefix: &str, t0: i64) -> str:
        prefix ++ "." ++ self.deterministic_type_tag(t0)

    fn collection_wrapper_name_2(prefix: &str, t0: i64, t1: i64) -> str:
        prefix ++ "." ++ self.deterministic_type_tag(t0) ++ "." ++ self.deterministic_type_tag(t1)

    // Dual-keyed collection type caches (#731): the sema tid preserves
    // generic identity, but duplicate insts of the same instantiation
    // (per-module tids, MIR-mapped tids) must share ONE named LLVM type —
    // caller and callee otherwise lower the same tuple to identity-distinct
    // structs and the call-site store rejects it. The structural key (the
    // element llvm type handle, a pointer, so it cannot collide with small
    // tid keys) unifies them; a tid hit stays the fast path.
    fn get_or_create_vec_type(sema_tid: i32, elem_ty: i64) -> i64:
        if sema_tid > 0:
            let tid_hit = self.vec_cache_map.get(sema_tid as i64)
            if tid_hit.is_some():
                return tid_hit.unwrap()
        let struct_hit = self.vec_cache_map.get(elem_ty)
        if struct_hit.is_some():
            let existing: i64 = struct_hit.unwrap()
            if sema_tid > 0:
                self.vec_cache_map.insert(sema_tid as i64, existing)
            return existing
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

    fn cache_vec_type(sema_tid: i32, elem_ty: i64, vec_ty: i64) -> i64:
        let struct_hit = self.vec_cache_map.get(elem_ty)
        if struct_hit.is_some():
            let existing: i64 = struct_hit.unwrap()
            if sema_tid > 0 and not self.vec_cache_map.get(sema_tid as i64).is_some():
                self.vec_cache_map.insert(sema_tid as i64, existing)
            return existing
        self.vec_cache_map.insert(elem_ty, vec_ty)
        if sema_tid > 0:
            self.vec_cache_map.insert(sema_tid as i64, vec_ty)
        self.vec_is_vec.insert(vec_ty, 1)
        vec_ty

    fn get_or_create_hashmap_type(sema_tid: i32, key_ty: i64, val_ty: i64) -> i64:
        let struct_key = (key_ty *% 65537) +% val_ty
        if sema_tid > 0:
            let tid_hit = self.hm_cache_map.get(sema_tid as i64)
            if tid_hit.is_some():
                let tid_existing = tid_hit.unwrap() as i64
                if self.hm_is_hm.contains(tid_existing):
                    return tid_existing
        let cached = self.hm_cache_map.get(struct_key)
        if cached.is_some():
            let existing: i64 = (cached.unwrap()) as i64
            if self.hm_is_hm.contains(existing):
                if sema_tid > 0:
                    self.hm_cache_map.insert(sema_tid as i64, existing)
                return existing
        // HashMap is opaque { ptr }
        let body: Vec[i64] = Vec.new()
        body.push(wl_ptr_type(self.context))
        let name = self.collection_wrapper_name_2("__with.HashMap", key_ty, val_ty)
        let hm_ty = wl_struct_create_named(self.context, name)
        wl_struct_set_body(hm_ty, vec_data_i64(&body), 1, 0)
        self.cache_hashmap_type(sema_tid, key_ty, val_ty, hm_ty)
        hm_ty

    fn cache_hashmap_type(sema_tid: i32, key_ty: i64, val_ty: i64, hm_ty: i64) -> i64:
        let struct_key = (key_ty *% 65537) +% val_ty
        let cached = self.hm_cache_map.get(struct_key)
        if cached.is_some():
            let existing: i64 = cached.unwrap()
            if self.hm_is_hm.contains(existing):
                if sema_tid > 0 and not self.hm_cache_map.get(sema_tid as i64).is_some():
                    self.hm_cache_map.insert(sema_tid as i64, existing)
                return existing
        self.hm_is_hm.insert(hm_ty, 1)
        self.hm_cache_map.insert(struct_key, hm_ty)
        if sema_tid > 0:
            self.hm_cache_map.insert(sema_tid as i64, hm_ty)
        hm_ty

    fn get_or_create_hashset_type(sema_tid: i32, elem_ty: i64) -> i64:
        if sema_tid > 0:
            let tid_hit = self.hs_cache_map.get(sema_tid as i64)
            if tid_hit.is_some():
                return tid_hit.unwrap()
        let struct_hit = self.hs_cache_map.get(elem_ty)
        if struct_hit.is_some():
            let existing: i64 = struct_hit.unwrap()
            if sema_tid > 0:
                self.hs_cache_map.insert(sema_tid as i64, existing)
            return existing
        let body: Vec[i64] = Vec.new()
        body.push(wl_ptr_type(self.context))
        let name = self.collection_wrapper_name_1("__with.HashSet", elem_ty)
        let hs_ty = wl_struct_create_named(self.context, name)
        wl_struct_set_body(hs_ty, vec_data_i64(&body), 1, 0)
        self.hs_cache_map.insert(elem_ty, hs_ty)
        if sema_tid > 0:
            self.hs_cache_map.insert(sema_tid as i64, hs_ty)
        hs_ty

    fn get_or_create_slotmap_type(sema_tid: i32, elem_ty: i64) -> i64:
        if sema_tid > 0:
            let tid_hit = self.slotmap_cache_map.get(sema_tid as i64)
            if tid_hit.is_some():
                return tid_hit.unwrap()
        let struct_hit = self.slotmap_cache_map.get(elem_ty)
        if struct_hit.is_some():
            let existing: i64 = struct_hit.unwrap()
            if sema_tid > 0:
                self.slotmap_cache_map.insert(sema_tid as i64, existing)
            return existing
        let body: Vec[i64] = Vec.new()
        body.push(wl_ptr_type(self.context))
        let name = self.collection_wrapper_name_1("__with.SlotMap", elem_ty)
        let sm_ty = wl_struct_create_named(self.context, name)
        wl_struct_set_body(sm_ty, vec_data_i64(&body), 1, 0)
        self.slotmap_cache_map.insert(elem_ty, sm_ty)
        if sema_tid > 0:
            self.slotmap_cache_map.insert(sema_tid as i64, sm_ty)
        sm_ty

    // ── Monomorphize struct (stub) ────────────────────────────────────

    mut fn monomorphize_struct(name_sym: i32, extra_start: i32, arg_count: i32) -> i64:
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
                let arg_ty = self.resolve_type(arg_node)
                let arg_sema = self.type_expr_to_sema_type(arg_node)
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

        let base_name: str = with_str_clone_ref(self.intern.resolve(name_sym))
        var mangled = with_str_clone_ref(base_name)
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
        let mono_idx: i32 = self.struct_type_map.get(mono_sym).unwrap()
        let mono_ty: i64 = self.struct_llvm_types.get(mono_idx as i64)

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

type ConcreteMirFunction {
    sym: i32,
    value: i64,
    fn_type: i64,
    sig: i32,
}

impl Codegen:
    fn invalid_concrete_mir_function() -> ConcreteMirFunction:
        ConcreteMirFunction { sym: 0, value: 0, fn_type: 0, sig: -1 }

    mut fn ensure_concrete_mir_function(call_node: i32, recorded_sig: i32, recorded_mono_sym: i32, fallback_sym: i32, label: &str) -> ConcreteMirFunction:
        var sema_sym = fallback_sym
        var sig_idx = if sema_sym != 0: self.sema.get_sig(sema_sym) else: -1
        if recorded_mono_sym != 0:
            sema_sym = recorded_mono_sym
        if recorded_sig >= 0:
            sig_idx = recorded_sig
        else if call_node != 0:
            let recorded_sym = self.sema.resolved_call_mono_syms.get(call_node)
            let fallback_recorded_sig = self.sema.resolved_call_sigs.get(call_node)
            if recorded_sym.is_some():
                sema_sym = recorded_sym.unwrap()
            if fallback_recorded_sig.is_some():
                sig_idx = fallback_recorded_sig.unwrap()
        if sema_sym == 0 or sig_idx < 0:
            with_eprint(f"error: missing concrete semantic specialization for {label}")
            self.had_error = 1
            return self.invalid_concrete_mir_function()

        let mono_sym = self.codegen_sym_for_sema_sym(sema_sym)
        let cached_value = self.fn_values.get(mono_sym)
        let cached_type = self.fn_fn_types.get(mono_sym)
        if cached_value.is_some() and cached_type.is_some():
            return ConcreteMirFunction { sym: mono_sym, value: cached_value.unwrap() as i64, fn_type: cached_type.unwrap() as i64, sig: sig_idx }

        let body_idx = self.mir_find_body_idx(sema_sym)
        if body_idx < 0:
            with_eprint(f"error: concrete specialization MIR was not lowered before freeze for {label}")
            self.had_error = 1
            return self.invalid_concrete_mir_function()
        let body = self.mir_body_at(body_idx as i64)
        let param_count = self.sema.sig_get_param_count(sig_idx)
        let signature_ret_sema = self.sema.sig_return_type(sig_idx)
        let is_async = self.sema.task_fns.contains(sema_sym)
        let ret_sema = if is_async: self.sema.unwrap_task_type(signature_ret_sema) as i32 else: signature_ret_sema
        if is_async and ret_sema == signature_ret_sema:
            with_eprint(f"error: async concrete specialization for {label} has no Task result contract")
            self.had_error = 1
            return self.invalid_concrete_mir_function()
        let ret_ty = if ret_sema != 0: self.sema_type_to_llvm(ret_sema) else: wl_void_type(self.context)
        var actual_ret_ty = ret_ty
        var has_sret = 0
        var byval_mask: i64 = 0
        let byval_types: Vec[i64] = Vec.new()
        let direct_types: Vec[i64] = Vec.new()
        let actual_params: Vec[i64] = Vec.new()
        if not is_async and self.internal_abi_needs_sret(ret_ty):
            has_sret = 1
            actual_ret_ty = wl_void_type(self.context)
            actual_params.push(wl_ptr_type(self.context))
        for pi in 0..param_count:
            let param_ty = self.abi_param_source_type(sig_idx, pi)
            if self.sema.sig_param_uses_value_ref_abi(sig_idx, pi) != 0:
                actual_params.push(wl_ptr_type(self.context))
                byval_types.push(0)
                direct_types.push(0)
            else if is_async:
                actual_params.push(param_ty)
                byval_types.push(0)
                direct_types.push(0)
            else if self.internal_abi_needs_indirect_param(param_ty):
                actual_params.push(wl_ptr_type(self.context))
                byval_mask = byval_mask | ((1 as i64) << (pi as u32))
                byval_types.push(param_ty)
                direct_types.push(0)
            else:
                actual_params.push(param_ty)
                byval_types.push(0)
                direct_types.push(0)

        let fn_type = wl_function_type(actual_ret_ty, vec_data_i64(&actual_params), actual_params.len() as i32, 0)
        let name = self.intern.resolve(mono_sym)
        let function = wl_add_function(self.llmod, name, fn_type)
        if has_sret != 0:
            wl_add_sret_attr(self.context, function, 0, ret_ty)
        if has_sret != 0 or byval_mask != 0:
            self.record_c_abi_transform(mono_sym, has_sret, ret_ty, byval_mask, move byval_types, 0, move direct_types, 0)
        for pi in 0..param_count:
            if self.sema.sig_param_uses_value_ref_abi(sig_idx, pi) != 0:
                self.record_ref_param(mono_sym, pi, param_count)
        let specialization = self.sema.concrete_specialization_by_sym.get(sema_sym)
        if specialization.is_some():
            let fn_node = self.sema.concrete_specialization_nodes.get(specialization.unwrap() as i64)
            let meta = self.pool.find_fn_meta(fn_node)
            if meta >= 0:
                self.apply_noalias_param_attrs_with_offset(function, self.pool.fn_meta_param_start(meta), param_count, if has_sret != 0: 1 else: 0)
        self.fn_values.insert(mono_sym, function)
        self.fn_fn_types.insert(mono_sym, fn_type)
        if is_async:
            self.async_fn_ret_types.insert(mono_sym, ret_ty)
        self.gen_function_mir_mono(mono_sym, 0, body)
        ConcreteMirFunction { sym: mono_sym, value: function, fn_type, sig: sig_idx }

    mut fn call_concrete_mir_function(concrete: &ConcreteMirFunction, args_start: i32, arg_node_base_index: i32, args: &Vec[i64], arg_count: i32, call_context: &str, call_node: i32) -> i64:
        if self.sema.task_fns.contains(concrete.sym):
            let task_sema = self.sema.sig_return_type(concrete.sig)
            let task_ty = self.sema_type_to_llvm(task_sema)
            if task_ty == 0:
                with_eprint(f"error: cannot lower async result type for {call_context}")
                self.had_error = 1
                return wl_get_undef(wl_i32_type(self.context))
            let coerced = self.coerce_call_args_for_fn_value(concrete.sym, concrete.value, args_start, arg_node_base_index, args, arg_count, call_context, call_node)
            return self.emit_async_fn_spawn_task_value(concrete.sym, concrete.value, concrete.fn_type, &coerced, task_ty)
        self.build_call_fn_value(concrete.sym, concrete.value, concrete.fn_type, args_start, arg_node_base_index, args, arg_count, call_context, call_node)

    mut fn monomorphize_struct_method_core(mono_type_sym: i32, method_name: &str, _decl: i32, obj: i64, obj_ptr: i64, obj_node: i32, obj_ty: i64, args_start: i32, arg_count: i32, call_node: i32, concrete_sig: i32, concrete_sym: i32, pre_args: &Vec[i64]) -> i64:
        let fallback = self.intern.intern(self.intern.resolve(mono_type_sym) ++ "." ++ method_name)
        let concrete = self.ensure_concrete_mir_function(call_node, concrete_sig, concrete_sym, fallback, "method " ++ method_name)
        if concrete.sym == 0:
            return wl_get_undef(wl_i32_type(self.context))
        let args: Vec[i64] = Vec.new()
        if self.is_ref_param(concrete.sym, 0):
            args.push(if obj_ptr != 0: obj_ptr else: self.get_mutable_receiver_ptr(obj_node, obj, obj_ty))
        else:
            args.push(obj)
        for ai in 0..arg_count:
            args.push(pre_args.get(ai as i64))
        self.call_concrete_mir_function(concrete, args_start, 1, args, arg_count + 1, "method " ++ method_name, call_node)

    mut fn monomorphize_struct_static_method_core(mono_type_sym: i32, method_name: &str, _decl: i32, args_start: i32, arg_count: i32, call_node: i32, concrete_sig: i32, concrete_sym: i32, pre_args: &Vec[i64]) -> i64:
        let fallback = self.intern.intern(self.intern.resolve(mono_type_sym) ++ "." ++ method_name)
        let concrete = self.ensure_concrete_mir_function(call_node, concrete_sig, concrete_sym, fallback, "static method " ++ method_name)
        if concrete.sym == 0:
            return wl_get_undef(wl_i32_type(self.context))
        self.call_concrete_mir_function(concrete, args_start, 0, pre_args, arg_count, "method " ++ method_name, call_node)

    // ── Build Option Some/None ────────────────────────────────────────

    mut fn build_option_some(payload: i64, opt_type: i64) -> i64:
        if wl_get_type_kind(opt_type) == wl_pointer_type_kind():
            return self.coerce_value_to_type(payload, opt_type)
        let alloca = self.create_entry_alloca(opt_type)
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

    fn build_option_none(opt_type: i64) -> i64:
        if wl_get_type_kind(opt_type) == wl_pointer_type_kind():
            return wl_const_null(opt_type)
        let alloca = self.create_entry_alloca(opt_type)
        wl_build_store(self.builder, self.build_default_value(opt_type), alloca)
        let tag_ptr = wl_build_struct_gep(self.builder, opt_type, alloca, 0)
        wl_build_store(self.builder, wl_const_int(wl_i32_type(self.context), 1, 0), tag_ptr)
        wl_build_load(self.builder, opt_type, alloca)

    fn build_result_ok(val: i64, res_type: i64) -> i64:
        let alloca = self.create_entry_alloca(res_type)
        wl_build_store(self.builder, self.build_default_value(res_type), alloca)
        let tag_ptr = wl_build_struct_gep(self.builder, res_type, alloca, 0)
        wl_build_store(self.builder, wl_const_int(wl_i32_type(self.context), 0, 0), tag_ptr)
        let elem_count = wl_count_struct_elem_types(res_type)
        if elem_count > 1:
            let payload_ptr = wl_build_struct_gep(self.builder, res_type, alloca, 1)
            let cast_ptr = wl_build_bitcast(self.builder, payload_ptr, wl_ptr_type(self.context))
            wl_build_store(self.builder, val, cast_ptr)
        wl_build_load(self.builder, res_type, alloca)

    fn build_result_err(val: i64, res_type: i64) -> i64:
        let alloca = self.create_entry_alloca(res_type)
        wl_build_store(self.builder, self.build_default_value(res_type), alloca)
        let tag_ptr = wl_build_struct_gep(self.builder, res_type, alloca, 0)
        wl_build_store(self.builder, wl_const_int(wl_i32_type(self.context), 1, 0), tag_ptr)
        let elem_count = wl_count_struct_elem_types(res_type)
        if elem_count > 1:
            let payload_ptr = wl_build_struct_gep(self.builder, res_type, alloca, 1)
            let cast_ptr = wl_build_bitcast(self.builder, payload_ptr, wl_ptr_type(self.context))
            wl_build_store(self.builder, val, cast_ptr)
        wl_build_load(self.builder, res_type, alloca)

    mut fn extract_result_payload(recv: i64, payload_ty: i64) -> i64:
        if payload_ty == 0:
            return wl_get_undef(wl_i32_type(self.context))
        if self.abi_size_of(payload_ty) == 0:
            return self.build_default_value(payload_ty)
        let recv_ty = wl_type_of(recv)
        if recv_ty == 0 or wl_get_type_kind(recv_ty) != wl_struct_type_kind():
            return self.build_default_value(payload_ty)
        if wl_count_struct_elem_types(recv_ty) <= 1:
            return self.build_default_value(payload_ty)
        let alloca = self.create_entry_alloca(recv_ty)
        wl_build_store(self.builder, recv, alloca)
        let payload_ptr = wl_build_struct_gep(self.builder, recv_ty, alloca, 1)
        let cast_ptr = wl_build_bitcast(self.builder, payload_ptr, wl_ptr_type(self.context))
        wl_build_load(self.builder, payload_ty, cast_ptr)

    // ── Emit drops / defers ───────────────────────────────────────────

    mut fn emit_drops(watermark: i32):
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

    mut fn build_fn_type_from_ast(fn_type_node: i32) -> i64:
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

    mut fn gen_module(pool: AstPool) -> i32:
        if self.debug_pool_flow_enabled():
            with_eprint(f"[llvm-cg] gen_module input.decls={pool.decl_count()} input.nodes={pool.node_count()}")
        self.pool = pool
        if self.debug_pool_flow_enabled():
            with_eprint(f"[llvm-cg] gen_module self.decls={self.pool.decl_count()} self.nodes={self.pool.node_count()}")

        self.debug_init_module()

        // Declare built-in string view types before user types.
        self.declare_builtin_str_type()
        self.declare_builtin_cstr_type()
        self.predeclare_generator_state_types()

        // Pass 0a: predeclare all struct/enum names so forward references resolve.
        for i in 0..self.pool.decl_count():
            self.sync_decl_context(i)
            let decl = self.pool.get_decl(i)
            let kind = self.pool.kind(decl)
            if kind != NodeKind.NK_TYPE_DECL:
                continue
            var name_sym = self.sema.fn_decl_semantic_symbol_at(decl as i32, self.pool.get_data0(decl), i)
            let name_str = self.intern.resolve(name_sym)
            if name_sym == 0 or name_str.len() == 0:
                continue
            name_sym = self.shadow_reg_sym(name_sym, i)
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
            var name_sym = self.pool.get_data0(decl)
            let name_str = self.intern.resolve(name_sym)
            if name_sym == 0 or name_str.len() == 0:
                continue
            name_sym = self.shadow_reg_sym(name_sym, i)
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
            if sub_kind == TypeDeclKind.Alias:
                let extra_start = self.pool.get_data1(decl)
                let aliased_node = self.pool.get_extra(extra_start)
                let resolved = self.resolve_type(aliased_node)
                self.type_aliases.insert(name_sym, resolved)

        if self.had_error != 0:
            return 1
        self.declare_generator_state_types()
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
            let parsed_name_sym = self.pool.get_data0(decl)
            let name_sym = self.sema.fn_decl_semantic_symbol_at(decl as i32, parsed_name_sym, i)
            if name_sym == 0:
                continue
            let flags = self.pool.get_data2(decl)
            let meta = self.pool.find_fn_meta(decl)
            let is_sema_generic = self.sema.generic_fn_node_for_symbol(name_sym) != 0
            let is_generic_struct_method = self.is_method_on_generic_struct(name_sym) and self.sema.fn_node_is_generic_template(decl as i32, name_sym) != 0
            // Skip sema-generic functions unless they use the generic-struct
            // lazy path in declare_function(). Blanket impl methods borrow type
            // params from impl context, so eager declaration resolves unbound names.
            if meta >= 0:
                let tp_count = self.pool.fn_meta_tp_count(meta)
                if tp_count > 0:
                    self.generic_fns.insert(name_sym, decl as i32)
                    if is_generic_struct_method:
                        self.generic_struct_methods.insert(name_sym, decl as i32)
                else if is_generic_struct_method:
                    self.declare_function_at(decl, i)
                else if is_sema_generic:
                    continue
                else if (flags / FnFlags.ASYNC) % 2 == 1:
                    self.declare_async_function(decl)
                else:
                    self.declare_function_at(decl, i)
        self.declare_generator_next_functions()
        self.declare_mir_only_functions()

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
                let name_sym = self.sema.fn_decl_semantic_symbol_at(decl as i32, self.pool.get_data0(decl), i)
                if name_sym == 0:
                    continue
                let flags = self.pool.get_data2(decl)
                let meta = self.pool.find_fn_meta(decl)
                if meta >= 0:
                    let tp_count = self.pool.fn_meta_tp_count(meta)
                    let is_generic_struct_method = self.is_method_on_generic_struct(name_sym) and self.sema.fn_node_is_generic_template(decl as i32, name_sym) != 0
                    if tp_count == 0 and self.sema.generic_fn_node_for_symbol(name_sym) == 0 and not is_generic_struct_method:
                        if self.unit_owns(name_sym):
                            self.gen_function_dispatch_at(decl, i)
        self.gen_mir_only_functions()
        self.gen_generator_next_functions_from_mir()

        if self.had_error != 0:
            return 1

        // Synthesized fns are pinned to unit 0 (main's MIR body is
        // force-assigned there by the Backend, so wrapper and wrapped body
        // land together).
        if self.unit_total <= 1 or self.unit_index == 0:
            self.emit_module_runtime_init_helpers()
        if self.had_error != 0:
            return 1

        // Wrap main for exit
        if self.unit_total <= 1 or self.unit_index == 0:
            self.wrap_main_for_exit()

        self.unit_demote_foreign_definitions()

        // Finalize debug info before verification
        self.debug_finalize_module()

        // Verify
        self.verify()

    // ── Wrap main for exit ────────────────────────────────────────────

    fn emit_runtime_fiber_config(wrapper: i64) -> Unit:
        if not self.uses_async:
            return
        let stack_size = self.sema.runtime_fiber_stack_size
        let pool_size = self.sema.runtime_fiber_pool_size
        let worker_count = self.sema.runtime_fiber_worker_count
        if stack_size <= 0 and pool_size <= 0 and worker_count <= 0:
            return

        let i32_ty = wl_i32_type(self.context)
        let i64_ty = wl_i64_type(self.context)
        var config_fn = wl_get_named_function(self.llmod, "with_runtime_configure_fibers")
        if config_fn == 0:
            let params: Vec[i64] = Vec.new()
            params.push(i64_ty)
            params.push(i32_ty)
            params.push(i32_ty)
            let ft = wl_function_type(i32_ty, vec_data_i64(&params), 3, 0)
            config_fn = wl_add_function(self.llmod, "with_runtime_configure_fibers", ft)
        let config_ft = wl_global_get_value_type(config_fn)
        let args: Vec[i64] = Vec.new()
        args.push(wl_const_int(i64_ty, stack_size, 0))
        args.push(wl_const_int(i32_ty, pool_size as i64, 0))
        args.push(wl_const_int(i32_ty, worker_count as i64, 0))
        let rc = wl_build_call(self.builder, config_ft, config_fn, vec_data_i64(&args), 3)
        let failed = wl_build_icmp(self.builder, wl_int_ne(), rc, wl_const_int(i32_ty, 0, 0))
        let panic_bb = wl_append_bb(self.context, wrapper, "runtime.config.panic")
        let ok_bb = wl_append_bb(self.context, wrapper, "runtime.config.ok")
        wl_build_cond_br(self.builder, failed, panic_bb, ok_bb)
        wl_position_at_end(self.builder, panic_bb)
        let panic_msg = "runtime fiber configuration cannot change after fibers exist"
        let panic_msg_val = self.build_str_value(wl_build_global_string_ptr(self.builder, panic_msg), wl_const_int(i64_ty, panic_msg.len(), 0))
        let panic_loc_val = self.build_str_value(wl_build_global_string_ptr(self.builder, ""), wl_const_int(i64_ty, 0, 0))
        self.emit_runtime_panic_value(panic_msg_val, panic_loc_val)
        wl_position_at_end(self.builder, ok_bb)

    mut fn wrap_main_for_exit() -> Unit:
        if self.sema.no_std != 0:
            return
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

        self.emit_runtime_fiber_config(wrapper)

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

        let main_param_count = wl_count_param_types(main_ft)
        var main_call: i64 = 0
        if main_param_count == 0:
            main_call = wl_build_call(self.builder, main_ft, main_fn, 0, 0)
        else if main_param_count == 2:
            let main_args: Vec[i64] = Vec.new()
            main_args.push(self.coerce_value_to_type(argc_val, wl_get_fn_param_type(main_ft, 0)))
            main_args.push(self.coerce_value_to_type(argv_val, wl_get_fn_param_type(main_ft, 1)))
            main_call = wl_build_call(self.builder, main_ft, main_fn, vec_data_i64(&main_args), 2)
        else:
            with_eprint("error: main must take either zero parameters or argc/argv")
            self.had_error = 1
            return

        // Drain pending fibers after main returns
        var runtime_run_fn = wl_get_named_function(self.llmod, "with_runtime_run")
        if runtime_run_fn == 0:
            let runtime_run_ft_new = wl_function_type(wl_void_type(self.context), 0, 0, 0)
            runtime_run_fn = wl_add_function(self.llmod, "with_runtime_run", runtime_run_ft_new)
        let runtime_run_ft = wl_global_get_value_type(runtime_run_fn)
        wl_build_call(self.builder, runtime_run_ft, runtime_run_fn, 0, 0)

        // #777: drop droppable module globals after the fibers drain, before
        // shutdown. A leaked global is a defect, not process-exit noise.
        // Reverse definition order matches local scope-exit order; the
        // rt_value_is_zero guard skips never-assigned zeroed storage.
        self.current_function = wrapper
        self.current_drop_needs_guard = true
        self.mir_set_current_drop_origin(0)
        var gd = self.module_drop_global_syms.len() as i32
        while gd > 0:
            gd = gd - 1
            let gd_sym = self.module_drop_global_syms.get(gd as i64)
            let gd_opt = self.module_constants.get(gd_sym)
            if gd_opt.is_some():
                let gd_global = gd_opt.unwrap() as i64
                self.mir_emit_drop_ptr_for_sema_type(gd_global, wl_global_get_value_type(gd_global), self.module_drop_global_tids.get(gd as i64))

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
