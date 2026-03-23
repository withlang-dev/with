// Sema — Semantic analysis: name resolution, type checking, and validation.
//
// Sema runs as a validation pass between parsing and codegen. It walks
// the AST, resolves all names, computes types for every expression, and
// reports type errors with source spans. Codegen continues to work as
// before — Sema is purely additive validation.

use Ast
use BorrowCfg
use Span
use Diagnostic
use InternPool
use render

extern fn print(s: str) -> void
extern fn with_eprintln(s: str) -> void
extern fn with_str_eq(a: str, b: str) -> i32
extern fn with_getenv_str(name: str) -> str
extern fn int_to_string(n: i32) -> str
extern fn with_hashmap_new(key_size: i64, val_size: i64) -> *i8

// ── Type kind constants ──────────────────────────────────────────

const TY_ERR: i32 = 0
const TY_INT: i32 = 1
const TY_FLOAT: i32 = 2
const TY_BOOL: i32 = 3
const TY_VOID: i32 = 4
const TY_STR: i32 = 5
const TY_STRUCT: i32 = 6
const TY_ENUM: i32 = 7
const TY_ARRAY: i32 = 8
const TY_SLICE: i32 = 9
const TY_TUPLE: i32 = 10
const TY_RANGE: i32 = 11
const TY_FN: i32 = 12
const TY_PTR: i32 = 13
const TY_REF: i32 = 14
const TY_ALIAS: i32 = 15
const TY_GENERIC_FN: i32 = 16
const TY_TRAIT_OBJ: i32 = 17
const TY_NEVER: i32 = 18
const TY_GENERIC_INST: i32 = 19

// Var state constants
const VS_LIVE: i32 = 0
const VS_MOVED: i32 = 1

// Borrow kind constants
const BK_SHARED: i32 = 0
const BK_EXCLUSIVE: i32 = 1

// Derive requirement constants
const DR_COPY: i32 = 0
const DR_CLONE: i32 = 1
const DR_EQ: i32 = 2

// ── Sema state ───────────────────────────────────────────────────

type Sema = {
    pool: InternPool,
    diags: DiagnosticList,
    ast: AstPool,

    // Type table (SoA parallel arrays)
    type_kinds: Vec[i32],
    type_d0: Vec[i32],
    type_d1: Vec[i32],
    type_d2: Vec[i32],
    type_extra: Vec[i32],

    // Named type lookup: sym → TypeId
    named_types: HashMap[i32, i32],
    // Type declaration AST nodes: sym → node (for cycle diagnostics)
    type_decl_nodes: HashMap[i32, i32],
    // Temporary accumulators for cycle detection (accessed through self)
    cycle_dep_syms: Vec[i32],
    cycle_dep_nodes: Vec[i32],
    // Fallback pretty names keyed by symbol id.
    pretty_symbol_names: HashMap[i32, str],

    // Function signatures (parallel arrays)
    sig_names: Vec[i32],
    sig_type_ids: Vec[i32],
    sig_ret_types: Vec[i32],
    sig_param_starts: Vec[i32],
    sig_param_counts: Vec[i32],
    sig_variadic: Vec[i32],
    sig_params: Vec[i32],
    sig_lookup: HashMap[i32, i32],

    // Extern fn names
    extern_fn_names: HashMap[i32, i32],
    // Function AST node indices by name
    fn_decl_nodes: HashMap[i32, i32],
    // Generic function node indices by name
    generic_fn_nodes: HashMap[i32, i32],

    // Methods: hash(type_sym, method_sym) → sig index
    // Variant lookup: variant_sym → variant_index
    variant_lookup: HashMap[i32, i32],
    // Variant type IDs: variant_sym → enum_tid
    variant_type_ids: HashMap[i32, i32],
    // Discriminant enum data
    disc_repr_types: HashMap[i32, i32],
    disc_values: HashMap[i32, i32],
    disc_has_payload: HashMap[i32, i32],

    // Trait declarations
    trait_method_names: Vec[i32],
    trait_method_starts: Vec[i32],
    trait_method_counts: Vec[i32],
    trait_name_syms: Vec[i32],
    trait_lookup: HashMap[i32, i32],
    // Trait type params: flat vec of type param name syms per trait
    trait_tp_starts: Vec[i32],
    trait_tp_counts: Vec[i32],
    trait_tp_syms: Vec[i32],
    // Trait associated types: flat vec of [name_sym, default_type_node]*
    trait_assoc_names: Vec[i32],
    trait_assoc_defaults: Vec[i32],
    trait_assoc_starts: Vec[i32],
    trait_assoc_counts: Vec[i32],
    // Trait assoc type bounds: flat vec of bound trait syms per assoc type
    trait_assoc_bound_syms: Vec[i32],
    trait_assoc_bound_starts: Vec[i32],
    trait_assoc_bound_counts: Vec[i32],
    // Type implementations: type_sym → list of trait syms (encoded in impl_extra)
    impl_extra: Vec[i32],
    impl_starts: Vec[i32],
    impl_counts: Vec[i32],
    impl_type_syms: Vec[i32],
    impl_lookup: HashMap[i32, i32],
    // Generic inst impls: impl Trait for Type[Args]
    // Key: "TypeId:trait_sym" → 1
    impl_generic_inst: HashMap[str, i32],
    // Blanket impls: impl[T: Bound] Trait for T
    blanket_trait_syms: Vec[i32],
    blanket_bound_syms: Vec[i32],
    blanket_bound_starts: Vec[i32],
    blanket_bound_counts: Vec[i32],
    // Blanket impl target type: 0 = bare type param, else = base_sym of generic target
    blanket_target_base_syms: Vec[i32],
    // Trait obligations + deterministic selection cache
    obligation_trait_syms: Vec[i32],
    obligation_type_syms: Vec[i32],
    obligation_nodes: Vec[i32],
    selection_cache: HashMap[str, i32],
    // Blanket impl recursion guard: keys currently being resolved
    blanket_guard: Vec[str],

    // Local trait/type names
    local_trait_names: HashMap[i32, i32],
    local_type_names: HashMap[i32, i32],
    distinct_type_names: HashMap[i32, i32],
    ephemeral_types: HashMap[i32, i32],
    sealed_traits: HashMap[i32, i32],
    // Sealed trait implementors: flat vec of type syms, with start/count per trait
    sealed_impl_types: Vec[i32],
    sealed_impl_starts: HashMap[i32, i32],
    sealed_impl_counts: HashMap[i32, i32],

    // Must-use / result-option / task fn tracking
    must_use_types: HashMap[i32, i32],
    must_use_fns: HashMap[i32, i32],
    result_option_fns: HashMap[i32, i32],
    task_fns: HashMap[i32, i32],

    // Hot intrinsic symbols used in semantic dispatch paths.
    sym_channel: i32,
    sym_send: i32,
    sym_recv: i32,
    sym_close: i32,
    sym_cancel: i32,
    sym_is_done: i32,
    sym_todo: i32,
    sym_unreachable: i32,
    sym_track: i32,
    sym_src: i32,
    sym_embed_file: i32,

    // Method origin tracking
    method_impl_nodes: HashMap[i32, i32],
    method_decl_origins: HashMap[i32, i32],
    method_has_inherent: HashMap[i32, i32],
    method_symbol_flags: HashMap[i32, i32],
    method_key_cache: HashMap[str, i32],
    drop_method_cache: HashMap[i32, i32],
    copy_visit_stack: Vec[i32],

    // Scope binding storage (stack-based with watermarks)
    bind_names: Vec[i32],
    bind_types: Vec[i32],
    bind_muts: Vec[i32],
    bind_states: Vec[i32],
    bind_is_task: Vec[i32],
    bind_is_scoped_task: Vec[i32],
    bind_is_ephemeral_task: Vec[i32],
    scope_starts: Vec[i32],
    async_scope_names: Vec[i32],

    // Borrow tracking
    borrow_kinds: Vec[i32],
    borrow_places: Vec[i32],
    borrow_fields: Vec[i32],
    borrow_refs: Vec[i32],
    // Multi-level field path data for borrow disjointness.
    // Each borrow has a path_start and path_count into this Vec.
    borrow_path_starts: Vec[i32],
    borrow_path_counts: Vec[i32],
    borrow_path_data: Vec[i32],
    // Transient storage for closure field-level capture analysis.
    capture_field_syms: Vec[i32],
    capture_field_kinds: Vec[i32],

    // Typed dump sidecar maps (keyed by span start byte offset)
    typed_expr_types: HashMap[i32, i32],
    typed_binding_types: HashMap[i32, i32],
    typed_binding_names: HashMap[i32, i32],
    typed_binding_muts: HashMap[i32, i32],
    typed_dump_seen_nodes: HashMap[i32, i32],
    typed_dump_visit_budget: i32,
    // Generic substitution map + specialization cache
    generic_subst_param_syms: Vec[i32],
    generic_subst_type_ids: Vec[i32],
    generic_specialization_cache: HashMap[str, i32],
    generic_inst_cache: HashMap[str, i32],

    // Associated type bindings from current impl (for Self.Name resolution)
    assoc_type_bindings: HashMap[i32, i32],

    // Frozen flag: set to 1 after check_module + preregister completes.
    // When frozen, add_type will error.
    types_frozen: i32,

    // Current state
    source_text: str,
    current_return_type: i32,
    current_gen_yield_type: i32,
    has_gen_yield_type: i32,
    in_pipeline_rhs: i32,
    match_in_stmt_pos: i32,
    in_comptime_fn: i32,
    no_std: i32,
    alloc: i32,
    in_defer: i32,
    break_value_type: i32,
    has_break_value_type: i32,
    loop_depth: i32,
    closure_direct_arg_depth: i32,
    expected_expr_type: i32,
    has_expected_type: i32,
    local_file_id: i32,
    collecting_types: i32,
    discard_sym: i32,
    suppress_errors: i32,

    // Canonical primitive TypeIds
    ty_i8: i32,
    ty_i16: i32,
    ty_i32: i32,
    ty_i64: i32,
    ty_i128: i32,
    ty_u8: i32,
    ty_u16: i32,
    ty_u32: i32,
    ty_u64: i32,
    ty_u128: i32,
    ty_f32: i32,
    ty_f64: i32,
    ty_bool: i32,
    ty_void: i32,
    ty_never: i32,
    ty_str: i32,
    ty_str_view: i32,
    ty_usize: i32,
    ty_isize: i32,
    ty_const_i8_ptr: i32,

    // Per-module scoping: tracks which module each declaration belongs to
    // and which symbols are visible in each module context.
    decl_source_paths: Vec[str],     // one path per decl index (from Frontend)
    decl_source_file_ids: Vec[i32],  // one file id per decl index (from Frontend)
    decl_is_c_import: Vec[i32],      // 1 if decl came from c_import, 0 otherwise
    current_module_path: str,        // module path being checked right now
    // c_import scoping: tracks which symbols are c_import-origin
    ci_syms: HashMap[i32, i32],      // sym → 1 for c_import-origin symbols
    ci_modules: HashMap[i32, i32],   // module-path-sym → 1 for modules that have c_import
    scoping_active: i32,             // 1 when multi-module c_import scoping is active
    current_module_has_ci: i32,      // 1 if current module has c_import declarations
    // Auto-defer: c_import constructor/destructor pairs
    ci_type_destructors: HashMap[i32, i32],   // type_name_sym → destructor_fn_sym
    ci_auto_defer_bindings: HashMap[i32, i32], // binding_sym → destructor_fn_sym
}

fn sema_debug_stage1_enabled -> i32:
    let raw = with_getenv_str("WITH_DEBUG_STAGE1_TRACE")
    if raw.len() == 0:
        return 0
    1

fn sema_debug_move_enabled -> i32:
    let raw = with_getenv_str("WITH_DEBUG_MOVE")
    if raw.len() == 0:
        return 0
    1

fn sema_str_eq(a: str, b: str) -> i32:
    if a.len() != b.len():
        return 0
    var i = 0
    while i < a.len() as i32:
        if a[i as i64] != b[i as i64]:
            return 0
        i = i + 1
    1

fn Sema.debug_unknown_type(self: Sema, sym: i32, node: i32, context: str):
    if sema_debug_stage1_enabled() == 0:
        return
    let name = self.pool_resolve_symbol(sym)
    let prim = self.primitive_type_by_sym(sym)
    let named = if self.named_types.contains(sym): 1 else: 0
    with_eprintln(
        "[unknown-type] " ++ context ++
        " sym=" ++ int_to_string(sym) ++
        " name=" ++ name ++
        " prim=" ++ int_to_string(prim) ++
        " named=" ++ int_to_string(named) ++
        " collecting=" ++ int_to_string(self.collecting_types) ++
        " node_kind=" ++ int_to_string(self.ast.kind(node))
    )

fn Sema.pool_resolve_symbol(self: Sema, sym: i32) -> str:
    if sym <= 0 or sym >= self.pool.symbol_texts.len() as i32:
        return ""
    self.pool.symbol_texts.get(sym as i64)

fn Sema.pool_resolve(self: Sema, sym: i32) -> str:
    self.pool_resolve_symbol(sym)

fn Sema.pool_intern(self: &mut Sema, name: str) -> i32:
    let existing = self.pool.symbol_map.get(name)
    if existing.is_some():
        return existing.unwrap()

    var i = 1
    while i < self.pool.symbol_texts.len() as i32:
        let existing_text = self.pool.symbol_texts.get(i as i64)
        if sema_str_eq(existing_text, name) != 0:
            self.pool.symbol_map.insert(existing_text, i)
            return i
        i = i + 1

    let id = self.pool.symbol_texts.len() as i32
    self.pool.symbol_texts.push(name)
    self.pool.symbol_map.insert(name, id)
    id

fn sema_new_map_i32_i32 -> HashMap[i32, i32]:
    HashMap.new()

fn sema_new_map_i32_str -> HashMap[i32, str]:
    HashMap.new()

fn sema_new_map_str_i32 -> HashMap[str, i32]:
    HashMap.new()

fn sema_empty_state(pool: InternPool, diags: DiagnosticList, ast: AstPool) -> Sema:
    let named_types = sema_new_map_i32_i32()
    let type_decl_nodes = sema_new_map_i32_i32()
    let pretty_symbol_names = sema_new_map_i32_str()
    let sig_lookup = sema_new_map_i32_i32()
    let extern_fn_names = sema_new_map_i32_i32()
    let fn_decl_nodes = sema_new_map_i32_i32()
    let generic_fn_nodes = sema_new_map_i32_i32()
    let variant_lookup = sema_new_map_i32_i32()
    let variant_type_ids = sema_new_map_i32_i32()
    let disc_repr_types = sema_new_map_i32_i32()
    let disc_values = sema_new_map_i32_i32()
    let disc_has_payload = sema_new_map_i32_i32()
    let trait_lookup = sema_new_map_i32_i32()
    let impl_lookup = sema_new_map_i32_i32()
    let selection_cache = sema_new_map_str_i32()
    let local_trait_names = sema_new_map_i32_i32()
    let local_type_names = sema_new_map_i32_i32()
    let ephemeral_types = sema_new_map_i32_i32()
    let sealed_traits = sema_new_map_i32_i32()
    let sealed_impl_types: Vec[i32] = Vec.new()
    let sealed_impl_starts = sema_new_map_i32_i32()
    let sealed_impl_counts = sema_new_map_i32_i32()
    let must_use_types = sema_new_map_i32_i32()
    let must_use_fns = sema_new_map_i32_i32()
    let result_option_fns = sema_new_map_i32_i32()
    let task_fns = sema_new_map_i32_i32()
    let method_impl_nodes = sema_new_map_i32_i32()
    let method_decl_origins = sema_new_map_i32_i32()
    let method_has_inherent = sema_new_map_i32_i32()
    let method_symbol_flags = sema_new_map_i32_i32()
    let method_key_cache = sema_new_map_str_i32()
    let drop_method_cache = sema_new_map_i32_i32()
    let typed_expr_types = sema_new_map_i32_i32()
    let typed_binding_types = sema_new_map_i32_i32()
    let typed_binding_names = sema_new_map_i32_i32()
    let typed_binding_muts = sema_new_map_i32_i32()
    let typed_dump_seen_nodes = sema_new_map_i32_i32()
    let generic_specialization_cache = sema_new_map_str_i32()
    let generic_inst_cache = sema_new_map_str_i32()
    var s = Sema {
        pool: pool,
        diags: diags,
        ast: ast,
        type_kinds: Vec.new(),
        type_d0: Vec.new(),
        type_d1: Vec.new(),
        type_d2: Vec.new(),
        type_extra: Vec.new(),
        named_types,
        type_decl_nodes,
        cycle_dep_syms: Vec.new(),
        cycle_dep_nodes: Vec.new(),
        pretty_symbol_names,
        sig_names: Vec.new(),
        sig_type_ids: Vec.new(),
        sig_ret_types: Vec.new(),
        sig_param_starts: Vec.new(),
        sig_param_counts: Vec.new(),
        sig_variadic: Vec.new(),
        sig_params: Vec.new(),
        sig_lookup,
        extern_fn_names,
        fn_decl_nodes,
        generic_fn_nodes,
        variant_lookup,
        variant_type_ids,
        disc_repr_types,
        disc_values,
        disc_has_payload,
        trait_method_names: Vec.new(),
        trait_method_starts: Vec.new(),
        trait_method_counts: Vec.new(),
        trait_name_syms: Vec.new(),
        trait_lookup,
        trait_tp_starts: Vec.new(),
        trait_tp_counts: Vec.new(),
        trait_tp_syms: Vec.new(),
        trait_assoc_names: Vec.new(),
        trait_assoc_defaults: Vec.new(),
        trait_assoc_starts: Vec.new(),
        trait_assoc_counts: Vec.new(),
        trait_assoc_bound_syms: Vec.new(),
        trait_assoc_bound_starts: Vec.new(),
        trait_assoc_bound_counts: Vec.new(),
        impl_extra: Vec.new(),
        impl_starts: Vec.new(),
        impl_counts: Vec.new(),
        impl_type_syms: Vec.new(),
        impl_lookup,
        impl_generic_inst: HashMap.new(),
        blanket_trait_syms: Vec.new(),
        blanket_bound_syms: Vec.new(),
        blanket_bound_starts: Vec.new(),
        blanket_bound_counts: Vec.new(),
        blanket_target_base_syms: Vec.new(),
        obligation_trait_syms: Vec.new(),
        obligation_type_syms: Vec.new(),
        obligation_nodes: Vec.new(),
        selection_cache,
        blanket_guard: Vec.new(),
        local_trait_names,
        local_type_names,
        distinct_type_names: sema_new_map_i32_i32(),
        ephemeral_types,
        sealed_traits,
        sealed_impl_types,
        sealed_impl_starts,
        sealed_impl_counts,
        must_use_types,
        must_use_fns,
        result_option_fns,
        task_fns,
        sym_channel: 0,
        sym_send: 0,
        sym_recv: 0,
        sym_close: 0,
        sym_cancel: 0,
        sym_is_done: 0,
        sym_todo: 0,
        sym_unreachable: 0,
        sym_track: 0,
        sym_src: 0,
        sym_embed_file: 0,
        method_impl_nodes,
        method_decl_origins,
        method_has_inherent,
        method_symbol_flags,
        method_key_cache,
        drop_method_cache,
        copy_visit_stack: Vec.new(),
        bind_names: Vec.new(),
        bind_types: Vec.new(),
        bind_muts: Vec.new(),
        bind_states: Vec.new(),
        bind_is_task: Vec.new(),
        bind_is_scoped_task: Vec.new(),
        bind_is_ephemeral_task: Vec.new(),
        scope_starts: Vec.new(),
        async_scope_names: Vec.new(),
        borrow_kinds: Vec.new(),
        borrow_places: Vec.new(),
        borrow_fields: Vec.new(),
        borrow_refs: Vec.new(),
        borrow_path_starts: Vec.new(),
        borrow_path_counts: Vec.new(),
        borrow_path_data: Vec.new(),
        capture_field_syms: Vec.new(),
        capture_field_kinds: Vec.new(),
        typed_expr_types,
        typed_binding_types,
        typed_binding_names,
        typed_binding_muts,
        typed_dump_seen_nodes,
        typed_dump_visit_budget: 0,
        generic_subst_param_syms: Vec.new(),
        generic_subst_type_ids: Vec.new(),
        generic_specialization_cache,
        generic_inst_cache,
        assoc_type_bindings: sema_new_map_i32_i32(),
        types_frozen: 0,
        source_text: "",
        current_return_type: 0,
        current_gen_yield_type: 0,
        has_gen_yield_type: 0,
        in_pipeline_rhs: 0,
        match_in_stmt_pos: 0,
        in_comptime_fn: 0,
        no_std: 0,
        alloc: 0,
        in_defer: 0,
        break_value_type: 0,
        has_break_value_type: 0,
        loop_depth: 0,
        closure_direct_arg_depth: 0,
        expected_expr_type: 0,
        has_expected_type: 0,
        local_file_id: 0,
        collecting_types: 0,
        discard_sym: 0,
        suppress_errors: 0,
        ty_i8: 0, ty_i16: 0, ty_i32: 0, ty_i64: 0, ty_i128: 0,
        ty_u8: 0, ty_u16: 0, ty_u32: 0, ty_u64: 0, ty_u128: 0,
        ty_f32: 0, ty_f64: 0, ty_bool: 0, ty_void: 0,
        ty_never: 0, ty_str: 0, ty_str_view: 0,
        ty_usize: 0, ty_isize: 0, ty_const_i8_ptr: 0,
        decl_source_paths: Vec.new(),
        decl_source_file_ids: Vec.new(),
        decl_is_c_import: Vec.new(),
        current_module_path: "",
        ci_syms: sema_new_map_i32_i32(),
        ci_modules: sema_new_map_i32_i32(),
        scoping_active: 0,
        current_module_has_ci: 0,
        ci_type_destructors: sema_new_map_i32_i32(),
        ci_auto_defer_bindings: sema_new_map_i32_i32(),
    }
    return s

fn Sema.placeholder(pool: InternPool, diags: DiagnosticList, ast: AstPool) -> Sema:
    return sema_empty_state(pool, diags, ast)

fn Sema.init(pool: InternPool, diags: DiagnosticList, ast: AstPool) -> Sema:
    var s = sema_empty_state(pool, diags, ast)

    // Index 0 = error type (sentinel).
    s.add_type(TY_ERR, 0, 0, 0)

    // Register primitive types.
    s.ty_i8 = s.add_type(TY_INT, 8, 1, 0)
    s.ty_i16 = s.add_type(TY_INT, 16, 1, 0)
    s.ty_i32 = s.add_type(TY_INT, 32, 1, 0)
    s.ty_i64 = s.add_type(TY_INT, 64, 1, 0)
    s.ty_i128 = s.add_type(TY_INT, 128, 1, 0)
    s.ty_u8 = s.add_type(TY_INT, 8, 0, 0)
    s.ty_u16 = s.add_type(TY_INT, 16, 0, 0)
    s.ty_u32 = s.add_type(TY_INT, 32, 0, 0)
    s.ty_u64 = s.add_type(TY_INT, 64, 0, 0)
    s.ty_u128 = s.add_type(TY_INT, 128, 0, 0)
    s.ty_f32 = s.add_type(TY_FLOAT, 32, 0, 0)
    s.ty_f64 = s.add_type(TY_FLOAT, 64, 0, 0)
    s.ty_bool = s.add_type(TY_BOOL, 0, 0, 0)
    s.ty_void = s.add_type(TY_VOID, 0, 0, 0)
    s.ty_never = s.add_type(TY_NEVER, 0, 0, 0)
    s.ty_str = s.add_type(TY_STR, 0, 0, 0)
    s.ty_str_view = s.add_type(TY_REF, s.ty_str, 0, 0)
    // Pointer-width integers: d2=1 marks them as usize/isize (64-bit on arm64)
    s.ty_usize = s.add_type(TY_INT, 64, 0, 1)
    s.ty_isize = s.add_type(TY_INT, 64, 1, 1)
    s.ty_const_i8_ptr = s.add_type(TY_PTR, s.ty_i8, 0, 0)

    // Register primitive names.
    s.register_prim("i8", s.ty_i8)
    s.register_prim("i16", s.ty_i16)
    s.register_prim("i32", s.ty_i32)
    s.register_prim("i64", s.ty_i64)
    s.register_prim("i128", s.ty_i128)
    s.register_prim("u8", s.ty_u8)
    s.register_prim("u16", s.ty_u16)
    s.register_prim("u32", s.ty_u32)
    s.register_prim("u64", s.ty_u64)
    s.register_prim("u128", s.ty_u128)
    s.register_prim("f32", s.ty_f32)
    s.register_prim("f64", s.ty_f64)
    s.register_prim("bool", s.ty_bool)
    s.register_prim("void", s.ty_void)
    s.register_prim("Never", s.ty_never)
    s.register_prim("str", s.ty_str)
    s.register_prim("String", s.ty_str)
    s.register_prim("StrView", s.ty_str_view)
    s.register_prim("usize", s.ty_usize)
    s.register_prim("isize", s.ty_isize)
    s.discard_sym = s.pool_intern("_")

    // Push root scope marker
    s.scope_starts.push(0)
    s.init_intrinsic_symbols()
    s

fn Sema.register_prim(self: &mut Sema, name: str, tid: i32):
    let sym = self.pool_intern(name)
    self.named_types.insert(sym, tid)
    self.pretty_symbol_names.insert(sym, name)

fn Sema.init_intrinsic_symbols(self: &mut Sema):
    self.sym_channel = self.pool_intern("Channel")
    self.sym_send = self.pool_intern("send")
    self.sym_recv = self.pool_intern("recv")
    self.sym_close = self.pool_intern("close")
    self.sym_cancel = self.pool_intern("cancel")
    self.sym_is_done = self.pool_intern("is_done")
    self.sym_todo = self.pool_intern("todo")
    self.sym_unreachable = self.pool_intern("unreachable")
    self.sym_track = self.pool_intern("track")
    self.sym_src = self.pool_intern("src")
    self.sym_embed_file = self.pool_intern("embed_file")

fn sema_is_name_char(ch: i32) -> i32:
    if ch >= 48 and ch <= 57:
        return 1
    if ch >= 65 and ch <= 90:
        return 1
    if ch >= 97 and ch <= 122:
        return 1
    if ch == 95 or ch == 46:
        return 1
    0

fn sema_is_ident_start_char(ch: i32) -> i32:
    if ch == 95:
        return 1
    if ch >= 65 and ch <= 90:
        return 1
    if ch >= 97 and ch <= 122:
        return 1
    0

fn sema_is_ident_char(ch: i32) -> i32:
    if ch >= 48 and ch <= 57:
        return 1
    sema_is_ident_start_char(ch)

fn sema_is_space_char(ch: i32) -> i32:
    if ch == 32:
        return 1
    if ch == 9:
        return 1
    if ch == 10:
        return 1
    if ch == 13:
        return 1
    return 0

fn extract_name_after_keyword_in_text(text: str, keyword: str) -> str:
    if text.len() == 0 or keyword.len() == 0:
        return ""
    var i = 0
    while i + keyword.len() <= text.len():
        if text.slice(i as i64, (i + keyword.len()) as i64) != keyword:
            i = i + 1
            continue
        if i > 0 and sema_is_ident_char(text[i - 1]) != 0:
            i = i + 1
            continue
        if i + keyword.len() < text.len() and sema_is_ident_char(text[i + keyword.len()]) != 0:
            i = i + 1
            continue

        var j = i + keyword.len()
        while j < text.len() and sema_is_space_char(text[j]) != 0:
            j = j + 1

        // let mut x = ... -> capture x
        if keyword == "let" and j + 3 <= text.len() and text.slice(j as i64, (j + 3) as i64) == "mut":
            if j + 3 == text.len() or sema_is_ident_char(text[j + 3]) == 0:
                j = j + 3
                while j < text.len() and sema_is_space_char(text[j]) != 0:
                    j = j + 1

        if j >= text.len() or sema_is_ident_start_char(text[j]) == 0:
            i = i + 1
            continue
        let start = j
        j = j + 1
        while j < text.len():
            let ch = text[j]
            if sema_is_name_char(ch) == 0:
                break
            j = j + 1
        if j > start:
            return text.slice(start as i64, j as i64)
        i = i + 1
    ""

fn extract_param_name_from_segment(segment: str) -> str:
    if segment.len() == 0:
        return ""

    var start = 0
    var end = segment.len()
    while start < end and sema_is_space_char(segment[start]) != 0:
        start = start + 1
    while end > start and sema_is_space_char(segment[end - 1]) != 0:
        end = end - 1
    if end <= start:
        return ""

    // Skip leading parameter attributes like @[noalias].
    while start + 2 <= end and segment[start] == 64 and segment[start + 1] == 91:
        var depth = 1
        start = start + 2
        while start < end and depth > 0:
            if segment[start] == 91:
                depth = depth + 1
            else if segment[start] == 93:
                depth = depth - 1
            start = start + 1
        while start < end and sema_is_space_char(segment[start]) != 0:
            start = start + 1
        if end <= start:
            return ""

    // Skip optional mut prefix.
    if start + 3 <= end and segment.slice(start as i64, (start + 3) as i64) == "mut":
        if start + 3 == end or sema_is_ident_char(segment[start + 3]) == 0:
            start = start + 3
            while start < end and sema_is_space_char(segment[start]) != 0:
                start = start + 1
            if end <= start:
                return ""

    var colon = -1
    var i = start
    while i < end:
        if segment[i] == 58:  // ':'
            colon = i
            break
        i = i + 1
    if colon <= start:
        return ""

    var name_end = colon
    while name_end > start and sema_is_space_char(segment[name_end - 1]) != 0:
        name_end = name_end - 1
    if name_end <= start:
        return ""

    if sema_is_ident_start_char(segment[start]) == 0:
        return ""
    i = start + 1
    while i < name_end:
        if sema_is_ident_char(segment[i]) == 0:
            return ""
        i = i + 1
    segment.slice(start as i64, name_end as i64)

fn extract_fn_param_name_in_text(text: str, param_index: i32) -> str:
    if text.len() == 0 or param_index < 0:
        return ""

    var open = -1
    var i = 0
    while i < text.len():
        if text[i] == 40:  // '('
            open = i
            break
        i = i + 1
    if open < 0:
        return ""

    i = open + 1
    var seg_start = i
    var depth = 0
    var current = 0
    while i <= text.len():
        let at_end = i == text.len()
        var ch = 41
        if not at_end:
            ch = text[i]
        if not at_end:
            if ch == 40 or ch == 91 or ch == 123 or ch == 60:
                depth = depth + 1
            else if ch == 41 or ch == 93 or ch == 125 or ch == 62:
                if depth > 0:
                    depth = depth - 1
                else:
                    if current == param_index:
                        return extract_param_name_from_segment(text.slice(seg_start as i64, i as i64))
                    return ""
            else if ch == 44 and depth == 0:
                if current == param_index:
                    return extract_param_name_from_segment(text.slice(seg_start as i64, i as i64))
                current = current + 1
                seg_start = i + 1
        i = i + 1
    ""

fn Sema.extract_decl_name_after(self: Sema, node: i32, keyword: str) -> str:
    if self.source_text.len() == 0:
        return ""
    let source_len = self.source_text.len() as i32
    var start = self.ast.get_start(node)
    var end = self.ast.get_end(node)
    if start < 0:
        start = 0
    if end < start:
        return ""
    if start > source_len:
        return ""
    if end > source_len:
        end = source_len
    if end <= start:
        return ""
    let snippet = self.source_text.slice(start as i64, end as i64)
    extract_name_after_keyword_in_text(snippet, keyword)

fn Sema.set_pretty_symbol(self: Sema, sym: i32, name: str):
    if sym <= 0:
        return
    if name.len() == 0:
        return
    if self.pretty_symbol_names.contains(sym):
        let existing = self.pretty_symbol_names.get(sym).unwrap()
        if existing.len() > 0 and existing != "_" and existing != "mut" and sema_str_contains_char(existing, 46) != 0:
            return
        if existing.len() > 0 and existing != "_" and existing != "mut":
            return
    // Keep textual pretty names detached from pooled symbol storage to avoid
    // lifetime issues during typed dump rendering.
    self.pretty_symbol_names.insert(sym, name ++ "")

fn Sema.extract_fn_param_name(self: Sema, node: i32, param_index: i32) -> str:
    if self.source_text.len() == 0:
        return ""
    let source_len = self.source_text.len() as i32
    var start = self.ast.get_start(node)
    var end = self.ast.get_end(node)
    if start < 0:
        start = 0
    if end > source_len:
        end = source_len
    if end <= start:
        return ""
    extract_fn_param_name_in_text(self.source_text.slice(start as i64, end as i64), param_index)

// ── Type management ──────────────────────────────────────────────

fn Sema.add_type(self: Sema, kind: i32, d0: i32, d1: i32, d2: i32) -> i32:
    if self.types_frozen != 0:
        with_eprintln("BUG: Sema.add_type called after freeze_types")
    let id = self.type_kinds.len() as i32
    self.type_kinds.push(kind)
    self.type_d0.push(d0)
    self.type_d1.push(d1)
    self.type_d2.push(d2)
    id

// Mark type tables as immutable. Any subsequent add_type will error.
fn Sema.freeze_types(self: Sema):
    self.types_frozen = 1

fn Sema.type_extra_matches(self: Sema, extra_start: i32, values: Vec[i32], count: i32) -> i32:
    for i in 0..count:
        if self.type_extra.get((extra_start + i) as i64) != values.get(i as i64):
            return 0
    1

fn Sema.find_exact_type(self: Sema, kind: i32, d0: i32, d1: i32, d2: i32) -> i32:
    let type_count = self.type_kinds.len() as i32
    for ti in 0..type_count:
        if self.type_kinds.get(ti as i64) != kind:
            continue
        if self.type_d0.get(ti as i64) != d0:
            continue
        if self.type_d1.get(ti as i64) != d1:
            continue
        if self.type_d2.get(ti as i64) != d2:
            continue
        return ti
    0

fn Sema.ensure_exact_type(self: Sema, kind: i32, d0: i32, d1: i32, d2: i32) -> i32:
    let existing = self.find_exact_type(kind, d0, d1, d2)
    if existing != 0:
        return existing
    if self.types_frozen != 0:
        return 0
    self.add_type(kind, d0, d1, d2)

fn Sema.find_tuple_type(self: Sema, elems: Vec[i32], elem_count: i32) -> i32:
    let type_count = self.type_kinds.len() as i32
    for ti in 0..type_count:
        if self.type_kinds.get(ti as i64) != TY_TUPLE:
            continue
        if self.type_d1.get(ti as i64) != elem_count:
            continue
        let te_start = self.type_d0.get(ti as i64)
        if self.type_extra_matches(te_start, elems, elem_count) != 0:
            return ti
    0

fn Sema.ensure_tuple_type(self: Sema, elems: Vec[i32], elem_count: i32) -> i32:
    let existing = self.find_tuple_type(elems, elem_count)
    if existing != 0:
        return existing
    if self.types_frozen != 0:
        return 0
    let te_start = self.type_extra.len() as i32
    for ei in 0..elem_count:
        self.type_extra.push(elems.get(ei as i64))
    self.add_type(TY_TUPLE, te_start, elem_count, 0)

fn Sema.find_fn_type(self: Sema, params: Vec[i32], param_count: i32, ret: i32) -> i32:
    let type_count = self.type_kinds.len() as i32
    for ti in 0..type_count:
        if self.type_kinds.get(ti as i64) != TY_FN:
            continue
        if self.type_d1.get(ti as i64) != param_count:
            continue
        if self.type_d2.get(ti as i64) != ret:
            continue
        let te_start = self.type_d0.get(ti as i64)
        if self.type_extra_matches(te_start, params, param_count) != 0:
            return ti
    0

fn Sema.ensure_fn_type(self: Sema, params: Vec[i32], param_count: i32, ret: i32) -> i32:
    let existing = self.find_fn_type(params, param_count, ret)
    if existing != 0:
        return existing
    if self.types_frozen != 0:
        return 0
    let te_start = self.type_extra.len() as i32
    for pi in 0..param_count:
        self.type_extra.push(params.get(pi as i64))
    self.add_type(TY_FN, te_start, param_count, ret)

fn Sema.generic_inst_cache_key(self: Sema, base_sym: i32, args: Vec[i32], arg_count: i32) -> str:
    var key = int_to_string(base_sym)
    for ai in 0..arg_count:
        key = key ++ ":" ++ int_to_string(args.get(ai as i64))
    key

fn Sema.find_generic_inst_type(self: Sema, base_sym: i32, args: Vec[i32], arg_count: i32) -> i32:
    let cache_key = self.generic_inst_cache_key(base_sym, args, arg_count)
    if self.generic_inst_cache.contains(cache_key):
        return self.generic_inst_cache.get(cache_key).unwrap()
    let type_count = self.type_kinds.len() as i32
    for ti in 0..type_count:
        if self.type_kinds.get(ti as i64) != TY_GENERIC_INST:
            continue
        if self.type_d0.get(ti as i64) != base_sym:
            continue
        if self.type_d2.get(ti as i64) != arg_count:
            continue
        let te_start = self.type_d1.get(ti as i64)
        if self.type_extra_matches(te_start, args, arg_count) != 0:
            self.generic_inst_cache.insert(cache_key, ti)
            return ti
    0

fn Sema.ensure_generic_inst_type(self: Sema, base_sym: i32, args: Vec[i32], arg_count: i32) -> i32:
    let existing = self.find_generic_inst_type(base_sym, args, arg_count)
    if existing != 0:
        return existing
    if self.types_frozen != 0:
        return 0
    let te_start = self.type_extra.len() as i32
    for ai in 0..arg_count:
        self.type_extra.push(args.get(ai as i64))
    let tid = self.add_type(TY_GENERIC_INST, base_sym, te_start, arg_count)
    let cache_key = self.generic_inst_cache_key(base_sym, args, arg_count)
    self.generic_inst_cache.insert(cache_key, tid)
    tid

// Look up an existing TY_GENERIC_INST(base_sym, [arg_tid]) in the cache.
// Returns the TypeId, or 0 if not found.
fn Sema.find_generic_inst(self: Sema, base_sym: i32, arg_tid: i32) -> i32:
    let args: Vec[i32] = Vec.new()
    args.push(arg_tid)
    self.find_generic_inst_type(base_sym, args, 1)

// Look up an existing TY_RANGE(elem_tid, inclusive) in the type tables.
// Returns the TypeId, or 0 if not found.
fn Sema.find_range_type(self: Sema, elem_tid: i32, inclusive: i32) -> i32:
    let type_count = self.type_kinds.len() as i32
    for ti in 0..type_count:
        if self.type_kinds.get(ti as i64) == TY_RANGE:
            if self.type_d0.get(ti as i64) == elem_tid:
                if self.type_d1.get(ti as i64) == inclusive:
                    return ti
    0

// Pre-register generic instantiation types needed by MirLower so that
// downstream passes never need to mutate the type tables.
// Must be called after check_module() and before freeze_types().
fn Sema.preregister_mir_types(self: Sema):
    let vec_sym = self.pool_intern("Vec")
    let vi_sym = self.pool_intern("VecIter")

    // For every Vec[T] type registered, also register VecIter[T].
    let type_count = self.type_kinds.len() as i32
    for ti in 0..type_count:
        if self.type_kinds.get(ti as i64) == TY_GENERIC_INST:
            if self.type_d0.get(ti as i64) == vec_sym:
                let extra_start = self.type_d1.get(ti as i64)
                let arg_count = self.type_d2.get(ti as i64)
                if arg_count >= 1:
                    let elem_ty = self.type_extra.get(extra_start as i64)
                    let vi_key = int_to_string(vi_sym) ++ ":" ++ int_to_string(elem_ty)
                    if not self.generic_inst_cache.contains(vi_key):
                        let te_start = self.type_extra.len() as i32
                        self.type_extra.push(elem_ty)
                        let tid = self.add_type(TY_GENERIC_INST, vi_sym, te_start, 1)
                        self.generic_inst_cache.insert(vi_key, tid)

    // Register Vec[str] for str.split() return type.
    let vec_str_key = int_to_string(vec_sym) ++ ":" ++ int_to_string(self.ty_str)
    if not self.generic_inst_cache.contains(vec_str_key):
        let te_start = self.type_extra.len() as i32
        self.type_extra.push(self.ty_str)
        let tid = self.add_type(TY_GENERIC_INST, vec_sym, te_start, 1)
        self.generic_inst_cache.insert(vec_str_key, tid)

    // Also register VecIter[str] in case Vec[str].iter() is called.
    let vi_str_key = int_to_string(vi_sym) ++ ":" ++ int_to_string(self.ty_str)
    if not self.generic_inst_cache.contains(vi_str_key):
        let te_start = self.type_extra.len() as i32
        self.type_extra.push(self.ty_str)
        let tid = self.add_type(TY_GENERIC_INST, vi_sym, te_start, 1)
        self.generic_inst_cache.insert(vi_str_key, tid)

// TY_GENERIC_INST: d0=base_sym, d1=extra_start, d2=arg_count
// Type args stored in type_extra[extra_start..extra_start+arg_count] as TypeIds.

fn Sema.resolve_generic_type(self: Sema, node: i32) -> i32:
    let gi_base_sym = self.ast.get_data0(node)
    if not self.named_types.contains(gi_base_sym):
        let gi_name = self.pool_resolve_symbol(gi_base_sym)
        self.emit_error("unknown type: " ++ gi_name, node)
        return 0
    let gi_arg_count = self.ast.get_data2(node)
    let gi_extra_start = self.ast.get_data1(node)
    let gi_args: Vec[i32] = Vec.new()
    for gi in 0..gi_arg_count:
        let gi_arg_node = self.ast.get_extra(gi_extra_start + gi)
        let gi_arg_tid = self.resolve_type_expr(gi_arg_node)
        if gi_arg_tid == 0:
            return 0
        gi_args.push(gi_arg_tid)
    self.ensure_generic_inst_type(gi_base_sym, gi_args, gi_arg_count)

fn Sema.get_generic_inst_base(self: Sema, tid: i32) -> i32:
    self.get_type_d0(tid)

fn Sema.get_generic_inst_arg_count(self: Sema, tid: i32) -> i32:
    self.get_type_d2(tid)

fn Sema.get_generic_inst_arg(self: Sema, tid: i32, index: i32) -> i32:
    let extra_start = self.get_type_d1(tid)
    self.type_extra.get((extra_start + index) as i64)

fn Sema.is_unsigned_int_type(self: Sema, tid: i32) -> bool:
    let resolved = self.resolve_alias(tid)
    if self.get_type_kind(resolved) != TY_INT:
        return false
    self.get_type_d1(resolved) == 0

fn Sema.is_numeric_type(self: Sema, tid: i32) -> bool:
    let resolved = self.resolve_alias(tid)
    let kind = self.get_type_kind(resolved)
    kind == TY_INT or kind == TY_FLOAT

fn Sema.literal_suffix_type(self: Sema, suffix: i32) -> i32:
    if suffix == LIT_SUFFIX_I8: return self.ty_i8
    if suffix == LIT_SUFFIX_I16: return self.ty_i16
    if suffix == LIT_SUFFIX_I32: return self.ty_i32
    if suffix == LIT_SUFFIX_I64: return self.ty_i64
    if suffix == LIT_SUFFIX_I128: return self.ty_i128
    if suffix == LIT_SUFFIX_ISIZE: return self.ty_isize
    if suffix == LIT_SUFFIX_U8: return self.ty_u8
    if suffix == LIT_SUFFIX_U16: return self.ty_u16
    if suffix == LIT_SUFFIX_U32: return self.ty_u32
    if suffix == LIT_SUFFIX_U64: return self.ty_u64
    if suffix == LIT_SUFFIX_U128: return self.ty_u128
    if suffix == LIT_SUFFIX_USIZE: return self.ty_usize
    if suffix == LIT_SUFFIX_F32: return self.ty_f32
    if suffix == LIT_SUFFIX_F64: return self.ty_f64
    0

fn Sema.int_literal_fits_type(self: Sema, value: i64, tid: i32) -> bool:
    let resolved = self.resolve_alias(tid)
    let kind = self.get_type_kind(resolved)
    if kind == TY_FLOAT:
        return true
    if kind != TY_INT:
        return false
    let bits = self.get_type_d0(resolved)
    let signed = self.get_type_d1(resolved)
    if bits >= 64:
        if signed != 0:
            return true
        return value >= 0
    if signed != 0:
        if bits == 8:
            return value >= -128 and value <= 127
        if bits == 16:
            return value >= -32768 and value <= 32767
        if bits == 32:
            return value >= -2147483648 and value <= 2147483647
        return true
    if value < 0:
        return false
    if bits == 8:
        return value <= 255
    if bits == 16:
        return value <= 65535
    if bits == 32:
        return value <= 4294967295
    true

fn Sema.numeric_literal_expected_type(self: Sema, node: i32, value: i64) -> i32:
    if self.has_expected_type == 0 or self.expected_expr_type == 0:
        return 0
    let expected = self.resolve_alias(self.expected_expr_type)
    if self.is_numeric_type(expected) == false:
        return 0
    if self.int_literal_fits_type(value, expected) == false:
        self.emit_error("integer literal does not fit expected type", node)
    expected

fn Sema.float_literal_expected_type(self: Sema) -> i32:
    if self.has_expected_type == 0 or self.expected_expr_type == 0:
        return 0
    let expected = self.resolve_alias(self.expected_expr_type)
    if self.get_type_kind(expected) == TY_FLOAT:
        return expected
    0

fn sema_node_is_numeric_literal(ast: AstPool, node: i32) -> bool:
    if node == 0:
        return false
    let kind = ast.kind(node)
    kind == NK_INT_LIT or kind == NK_FLOAT_LIT

fn Sema.is_option_pointer_type(self: Sema, tid: i32) -> i32:
    if tid <= 0:
        return 0
    let resolved = self.resolve_alias(tid)
    if self.get_type_kind(resolved) != TY_GENERIC_INST:
        return 0
    if self.get_type_d0(resolved) != self.pool_intern("Option"):
        return 0
    if self.get_type_d2(resolved) <= 0:
        return 0
    let payload = self.get_generic_inst_arg(resolved, 0)
    let payload_resolved = self.resolve_alias(payload)
    if self.get_type_kind(payload_resolved) == TY_PTR:
        return 1
    0

fn Sema.option_pointer_payload_type(self: Sema, tid: i32) -> i32:
    if self.is_option_pointer_type(tid) == 0:
        return 0
    let resolved = self.resolve_alias(tid)
    self.get_generic_inst_arg(resolved, 0)

fn Sema.try_unwrapped_type(self: Sema, tid: i32) -> i32:
    if tid <= 0:
        return 0
    let ok_sym = self.pool_intern("Ok")
    let ok_payloads = self.enum_variant_payload_types(tid, ok_sym)
    if ok_payloads.len() as i32 == 1:
        return ok_payloads.get(0)
    let some_sym = self.pool_intern("Some")
    let some_payloads = self.enum_variant_payload_types(tid, some_sym)
    if some_payloads.len() as i32 == 1:
        return some_payloads.get(0)
    0

// substitute_type: walk a TypeId, replacing type parameters with concrete types.
// subst_syms/subst_tids/count define the mapping: subst_syms[i] → subst_tids[i].
// Returns the substituted TypeId, or the original if no substitution applies.
fn Sema.substitute_type(self: Sema, tid: i32, subst_syms: Vec[i32], subst_tids: Vec[i32], count: i32) -> i32:
    if tid <= 0 or count == 0:
        return tid
    let kind = self.get_type_kind(tid)
    let d0 = self.get_type_d0(tid)
    // Direct match: struct/enum/alias whose name matches a type param symbol
    if kind == TY_STRUCT or kind == TY_ENUM or kind == TY_ALIAS:
        for si in 0..count:
            if subst_syms.get(si as i64) == d0:
                return subst_tids.get(si as i64)
        return tid
    // TY_GENERIC_INST: substitute each type arg
    if kind == TY_GENERIC_INST:
        let gi_ac = self.get_type_d2(tid)
        var changed = 0
        let sub_args: Vec[i32] = Vec.new()
        for ai in 0..gi_ac:
            let orig = self.get_generic_inst_arg(tid, ai)
            let subbed = self.substitute_type(orig, subst_syms, subst_tids, count)
            if subbed != orig: changed = 1
            sub_args.push(subbed)
        if changed == 0: return tid
        return self.ensure_generic_inst_type(d0, sub_args, gi_ac)
    // TY_PTR / TY_REF: substitute pointee
    if kind == TY_PTR or kind == TY_REF:
        let pointee = d0
        let subbed = self.substitute_type(pointee, subst_syms, subst_tids, count)
        if subbed == pointee: return tid
        let d1 = self.get_type_d1(tid)
        return self.ensure_exact_type(kind, subbed, d1, 0)
    // TY_ARRAY: substitute element
    if kind == TY_ARRAY:
        let elem = d0
        let subbed = self.substitute_type(elem, subst_syms, subst_tids, count)
        if subbed == elem: return tid
        let size = self.get_type_d1(tid)
        return self.ensure_exact_type(TY_ARRAY, subbed, size, 0)
    // TY_SLICE: substitute element
    if kind == TY_SLICE:
        let elem = d0
        let subbed = self.substitute_type(elem, subst_syms, subst_tids, count)
        if subbed == elem: return tid
        return self.ensure_exact_type(TY_SLICE, subbed, 0, 0)
    // TY_TUPLE: substitute each element
    if kind == TY_TUPLE:
        let te_start_orig = d0
        let elem_count = self.get_type_d1(tid)
        var t_changed = 0
        let tuple_elems: Vec[i32] = Vec.new()
        for ei in 0..elem_count:
            let orig = self.type_extra.get((te_start_orig + ei) as i64)
            let subbed = self.substitute_type(orig, subst_syms, subst_tids, count)
            if subbed != orig: t_changed = 1
            tuple_elems.push(subbed)
        if t_changed == 0: return tid
        return self.ensure_tuple_type(tuple_elems, elem_count)
    // All other kinds: return unchanged
    tid

fn Sema.get_type_kind(self: Sema, tid: i32) -> i32:
    if tid < 0 or tid >= self.type_kinds.len() as i32:
        return TY_ERR
    self.type_kinds.get(tid as i64)

fn Sema.get_type_d0(self: Sema, tid: i32) -> i32:
    if tid < 0 or tid >= self.type_d0.len() as i32:
        return 0
    self.type_d0.get(tid as i64)

fn Sema.get_type_d1(self: Sema, tid: i32) -> i32:
    if tid < 0 or tid >= self.type_d1.len() as i32:
        return 0
    self.type_d1.get(tid as i64)

fn Sema.get_type_d2(self: Sema, tid: i32) -> i32:
    if tid < 0 or tid >= self.type_d2.len() as i32:
        return 0
    self.type_d2.get(tid as i64)

fn Sema.resolve_alias(self: Sema, tid: i32) -> i32:
    var current = tid
    for depth in 0..32:
        if self.get_type_kind(current) == TY_ALIAS:
            current = self.get_type_d0(current)
        else:
            return current
    current

// ── Scope management ─────────────────────────────────────────────

fn Sema.push_scope(self: Sema):
    self.scope_starts.push(self.bind_names.len() as i32)

fn Sema.pop_scope(self: Sema):
    let len = self.scope_starts.len() as i32
    if len == 0:
        return
    let start = self.scope_starts.get((len - 1) as i64)
    // Expire borrows for bindings leaving scope
    self.expire_borrows_in_scope(start)
    // Remove bindings
    while self.bind_names.len() as i32 > start:
        self.bind_names.pop()
        self.bind_types.pop()
        self.bind_muts.pop()
        self.bind_states.pop()
        self.bind_is_task.pop()
        self.bind_is_scoped_task.pop()
        self.bind_is_ephemeral_task.pop()
    self.scope_starts.pop()

fn Sema.is_discard_binding_symbol(self: Sema, sym: i32) -> i32:
    if sym == 0:
        return 1
    if self.discard_sym != 0 and sym == self.discard_sym:
        return 1
    0

fn Sema.scope_put(self: Sema, sym: i32, tid: i32, is_mut: i32):
    self.scope_put_at(sym, tid, is_mut, 0)

fn Sema.scope_put_at(self: Sema, sym: i32, tid: i32, is_mut: i32, node: i32):
    if self.is_discard_binding_symbol(sym) != 0:
        return
    if self.scope_lookup(sym) >= 0:
        let name = self.pool_resolve(sym)
        self.emit_error("shadowing is not allowed for '" ++ name ++ "'", node)
        return
    self.bind_names.push(sym)
    self.bind_types.push(tid)
    self.bind_muts.push(is_mut)
    self.bind_states.push(VS_LIVE)
    self.bind_is_task.push(0)
    self.bind_is_scoped_task.push(0)
    self.bind_is_ephemeral_task.push(0)

fn Sema.scope_lookup(self: Sema, sym: i32) -> i32:
    var i = self.bind_names.len() as i32 - 1
    while i >= 0:
        if self.bind_names.get(i as i64) == sym:
            return self.bind_types.get(i as i64)
        i = i - 1
    0 - 1

fn Sema.scope_lookup_mut(self: Sema, sym: i32) -> i32:
    var i = self.bind_names.len() as i32 - 1
    while i >= 0:
        if self.bind_names.get(i as i64) == sym:
            return self.bind_muts.get(i as i64)
        i = i - 1
    0

fn Sema.scope_lookup_state(self: Sema, sym: i32) -> i32:
    var i = self.bind_names.len() as i32 - 1
    while i >= 0:
        if self.bind_names.get(i as i64) == sym:
            return self.bind_states.get(i as i64)
        i = i - 1
    VS_LIVE

fn Sema.scope_lookup_is_task(self: Sema, sym: i32) -> i32:
    var i = self.bind_names.len() as i32 - 1
    while i >= 0:
        if self.bind_names.get(i as i64) == sym:
            return self.bind_is_task.get(i as i64)
        i = i - 1
    0

fn Sema.scope_set_is_task(self: Sema, sym: i32, is_task: i32):
    var i = self.bind_names.len() as i32 - 1
    while i >= 0:
        if self.bind_names.get(i as i64) == sym:
            self.bind_is_task.set_i32(i as i64, is_task)
            return
        i = i - 1

fn Sema.scope_lookup_is_scoped_task(self: Sema, sym: i32) -> i32:
    var i = self.bind_names.len() as i32 - 1
    while i >= 0:
        if self.bind_names.get(i as i64) == sym:
            return self.bind_is_scoped_task.get(i as i64)
        i = i - 1
    0

fn Sema.scope_set_is_scoped_task(self: Sema, sym: i32, is_scoped_task: i32):
    var i = self.bind_names.len() as i32 - 1
    while i >= 0:
        if self.bind_names.get(i as i64) == sym:
            self.bind_is_scoped_task.set_i32(i as i64, is_scoped_task)
            return
        i = i - 1

fn Sema.scope_lookup_is_ephemeral_task(self: Sema, sym: i32) -> i32:
    var i = self.bind_names.len() as i32 - 1
    while i >= 0:
        if self.bind_names.get(i as i64) == sym:
            return self.bind_is_ephemeral_task.get(i as i64)
        i = i - 1
    0

fn Sema.scope_set_is_ephemeral_task(self: Sema, sym: i32, is_ephemeral_task: i32):
    var i = self.bind_names.len() as i32 - 1
    while i >= 0:
        if self.bind_names.get(i as i64) == sym:
            self.bind_is_ephemeral_task.set_i32(i as i64, is_ephemeral_task)
            return
        i = i - 1

fn Sema.scope_set_state(self: Sema, sym: i32, state: i32):
    var i = self.bind_names.len() as i32 - 1
    while i >= 0:
        if self.bind_names.get(i as i64) == sym:
            self.bind_states.set_i32(i as i64, state)
            return
        i = i - 1

fn Sema.scope_has(self: Sema, sym: i32) -> i32:
    var i = self.bind_names.len() as i32 - 1
    while i >= 0:
        if self.bind_names.get(i as i64) == sym:
            return 1
        i = i - 1
    0

fn Sema.is_active_async_scope_symbol(self: Sema, sym: i32) -> i32:
    var i = self.async_scope_names.len() as i32 - 1
    while i >= 0:
        if self.async_scope_names.get(i as i64) == sym:
            return 1
        i = i - 1
    0

// ── Function signature management ────────────────────────────────

fn Sema.add_sig(self: Sema, name: i32, fn_tid: i32, ret: i32, param_start: i32, param_count: i32, variadic: i32):
    let idx = self.sig_names.len() as i32
    self.sig_names.push(name)
    self.sig_type_ids.push(fn_tid)
    self.sig_ret_types.push(ret)
    self.sig_param_starts.push(param_start)
    self.sig_param_counts.push(param_count)
    self.sig_variadic.push(variadic)
    self.sig_lookup.insert(name, idx)

fn Sema.get_sig(self: Sema, name: i32) -> i32:
    if self.sig_lookup.contains(name):
        return self.sig_lookup.get(name).unwrap()
    0 - 1

fn Sema.sig_return_type(self: Sema, idx: i32) -> i32:
    self.sig_ret_types.get(idx as i64)

fn Sema.sig_param_type(self: Sema, idx: i32, param_i: i32) -> i32:
    let start = self.sig_param_starts.get(idx as i64)
    self.sig_params.get((start + param_i) as i64)

fn Sema.sig_get_param_count(self: Sema, idx: i32) -> i32:
    self.sig_param_counts.get(idx as i64)

fn Sema.sig_is_variadic(self: Sema, idx: i32) -> i32:
    self.sig_variadic.get(idx as i64)

fn Sema.sig_idx_valid(self: Sema, idx: i32) -> i32:
    if idx < 0:
        return 0
    if idx >= self.sig_names.len() as i32:
        return 0
    1

fn Sema.set_sig_return_type(self: Sema, idx: i32, ret: i32):
    if self.sig_idx_valid(idx) == 0:
        return
    self.sig_ret_types.set_i32(idx as i64, ret)
    let fn_tid = self.sig_type_ids.get(idx as i64)
    if fn_tid >= 0 and fn_tid < self.type_d2.len() as i32:
        self.type_d2.set_i32(fn_tid as i64, ret)

// ── Main entry point ─────────────────────────────────────────────

fn Sema.check_module(self: Sema):
    self.compute_method_origins()
    self.collect_declarations()
    self.build_ci_scoping()
    self.build_ci_destructor_map()
    self.validate_copy_derives()
    self.validate_generic_type_decls()
    self.check_bodies()

// ── Pass 1: Declaration collection ───────────────────────────────

fn Sema.compute_method_origins(self: Sema):
    let dc = self.ast.decl_count()
    for di in 0..dc:
        let decl = self.ast.get_decl(di)
        let kind = self.ast.kind(decl)
        if kind == NK_IMPL_DECL:
            let trait_sym = self.ast.get_data2(decl)
            var origin = 0
            if trait_sym != 0:
                origin = 1
            // Walk backwards finding method fn_decls
            let impl_extra = self.ast.get_data1(decl)
            // Methods are added as decls before the impl_decl
            var j = di
            while j > 0:
                j = j - 1
                let md = self.ast.get_decl(j)
                if self.ast.kind(md) != NK_FN_DECL:
                    break
                let fn_name = self.ast.get_data0(md)
                self.method_decl_origins.insert(j, origin)
                self.method_impl_nodes.insert(fn_name, decl)
                self.method_symbol_flags.insert(fn_name, 1)
                if origin == 0:
                    self.method_has_inherent.insert(fn_name, 1)

    // Top-level method syntax
    for di in 0..dc:
        let decl = self.ast.get_decl(di)
        if self.ast.kind(decl) == NK_FN_DECL:
            let fn_name = self.ast.get_data0(decl)
            let parsed_fn_name = self.extract_decl_name_after(decl, "fn")
            if sema_str_contains_char(parsed_fn_name, 46) != 0:
                self.method_symbol_flags.insert(fn_name, 1)
                if not self.method_decl_origins.contains(di):
                    self.method_has_inherent.insert(fn_name, 1)

fn Sema.is_method_symbol(self: Sema, sym: i32) -> i32:
    if sym <= 0:
        return 0
    if self.method_symbol_flags.contains(sym):
        return 1
    return 0

fn Sema.should_skip_trait_method(self: Sema, decl_idx: i32, fn_sym: i32) -> i32:
    if self.is_method_symbol(fn_sym) == 0:
        return 0
    if self.method_decl_origins.contains(decl_idx):
        let origin = self.method_decl_origins.get(decl_idx).unwrap()
        if origin == 1:
            if self.method_has_inherent.contains(fn_sym):
                return 1
    0

fn Sema.collect_declarations(self: Sema):
    self.collecting_types = 1
    // Pass 1: collect named types and traits first so functions can refer
    // to imported or forward-declared types regardless of declaration order.
    for di in 0..self.ast.decl_count():
        self.update_decl_source_context(di)
        let decl = self.ast.get_decl(di)
        let kind = self.ast.kind(decl)
        let is_local = self.is_local_decl(di)
        if kind == NK_TYPE_DECL:
            self.collect_type_decl(decl, is_local)
        if kind == NK_TRAIT_DECL:
            self.collect_trait_decl(decl, is_local)

    // Check for circular type dependencies before proceeding.
    self.check_type_cycles()

    // Pass 2: collect impl declarations once trait/type tables exist.
    for di in 0..self.ast.decl_count():
        self.update_decl_source_context(di)
        let decl = self.ast.get_decl(di)
        if self.ast.kind(decl) == NK_IMPL_DECL:
            self.collect_impl_decl(decl)

    self.collecting_types = 0
    self.resolve_deferred_non_generic_type_decls()

    // Pass 3: collect function signatures and top-level let decls.
    for di in 0..self.ast.decl_count():
        self.update_decl_source_context(di)
        let decl = self.ast.get_decl(di)
        let kind = self.ast.kind(decl)
        let is_local = self.is_local_decl(di)
        if kind == NK_FN_DECL:
            let fn_name = self.ast.get_data0(decl)
            if self.should_skip_trait_method(di, fn_name) == 0:
                self.collect_fn_decl(decl, is_local)
        if kind == NK_EXTERN_FN:
            self.collect_extern_fn(decl, is_local)
        if kind == NK_EXTERN_VAR:
            self.collect_extern_var(decl, is_local)
        if kind == NK_LET_DECL:
            self.collect_let_decl(decl, is_local)

    // Hardcode Result and Task as must_use types
    let sym_result = self.pool_intern("Result")
    let sym_task = self.pool_intern("Task")
    if sym_result != 0:
        self.must_use_types.insert(sym_result, 1)
    if sym_task != 0:
        self.must_use_types.insert(sym_task, 1)

fn Sema.resolve_deferred_non_generic_type_decls(self: Sema):
    for di in 0..self.ast.decl_count():
        self.update_decl_source_context(di)
        let decl = self.ast.get_decl(di)
        if self.ast.kind(decl) != NK_TYPE_DECL:
            continue
        if self.type_decl_tp_count(decl) != 0:
            continue
        self.resolve_deferred_non_generic_type_decl(decl)

fn Sema.resolve_deferred_non_generic_type_decl(self: Sema, decl: i32):
    let name = self.ast.get_data0(decl)
    if not self.named_types.contains(name):
        return

    let tid = self.named_types.get(name).unwrap()
    let extra_start = self.ast.get_data1(decl)
    let sub_kind = type_decl_sub_kind(self.ast.get_data2(decl))
    let resolved = self.resolve_alias(tid)

    if sub_kind == TDK_STRUCT or sub_kind == TDK_UNION:
        if self.get_type_kind(resolved) != TY_STRUCT:
            return
        let te_start = self.get_type_d1(resolved)
        let field_count = self.ast.get_extra(extra_start)
        for fi in 0..field_count:
            let field_slot = te_start + fi * 3 + 1
            if self.type_extra.get(field_slot as i64) != 0:
                continue
            let field_base = extra_start + 1 + fi * 3
            let field_type_node = self.ast.get_extra(field_base + 1)
            let field_tid = self.resolve_type_expr(field_type_node)
            if field_tid != 0:
                self.type_extra.set_i32(field_slot as i64, field_tid)
        return

    if sub_kind == TDK_ENUM:
        if self.get_type_kind(resolved) != TY_ENUM:
            return
        let te_start = self.get_type_d1(resolved)
        let variant_count = self.ast.get_extra(extra_start)
        var ast_pos = extra_start + 1
        var type_pos = te_start
        for _ in 0..variant_count:
            ast_pos = ast_pos + 1
            let payload_count = self.ast.get_extra(ast_pos)
            ast_pos = ast_pos + 1
            type_pos = type_pos + 2
            for pi in 0..payload_count:
                let payload_slot = type_pos + pi
                if self.type_extra.get(payload_slot as i64) == 0:
                    let payload_type_node = self.ast.get_extra(ast_pos + pi)
                    let payload_tid = self.resolve_type_expr(payload_type_node)
                    if payload_tid != 0:
                        self.type_extra.set_i32(payload_slot as i64, payload_tid)
            ast_pos = ast_pos + payload_count
            type_pos = type_pos + payload_count
        return

    if sub_kind == TDK_DISC_ENUM:
        if self.get_type_kind(resolved) != TY_ENUM:
            return
        let repr_type_node = self.ast.get_extra(extra_start)
        let repr_opt = self.disc_repr_types.get(tid)
        if not repr_opt.is_some() or repr_opt.unwrap() == 0:
            let repr_tid = self.resolve_type_expr(repr_type_node)
            if repr_tid != 0:
                self.disc_repr_types.insert(tid, repr_tid)
        let te_start = self.get_type_d1(resolved)
        let variant_count = self.ast.get_extra(extra_start + 1)
        var ast_pos = extra_start + 2
        var type_pos = te_start
        for _ in 0..variant_count:
            ast_pos = ast_pos + 2
            let payload_count = self.ast.get_extra(ast_pos)
            ast_pos = ast_pos + 1
            type_pos = type_pos + 2
            for pi in 0..payload_count:
                let payload_slot = type_pos + pi
                if self.type_extra.get(payload_slot as i64) == 0:
                    let payload_type_node = self.ast.get_extra(ast_pos + pi)
                    let payload_tid = self.resolve_type_expr(payload_type_node)
                    if payload_tid != 0:
                        self.type_extra.set_i32(payload_slot as i64, payload_tid)
            ast_pos = ast_pos + payload_count
            type_pos = type_pos + payload_count
        return

    if sub_kind == TDK_ALIAS:
        if self.get_type_d0(tid) != 0:
            return
        let aliased_node = self.ast.get_extra(extra_start)
        let target_tid = self.resolve_type_expr(aliased_node)
        if target_tid != 0:
            self.type_d0.set_i32(tid as i64, target_tid)
        return

    if sub_kind == TDK_DISTINCT:
        if self.get_type_kind(resolved) != TY_STRUCT:
            return
        let te_start = self.get_type_d1(resolved)
        let value_slot = te_start + 1
        if self.type_extra.get(value_slot as i64) != 0:
            return
        let inner_node = self.ast.get_extra(extra_start)
        let inner_tid = self.resolve_type_expr(inner_node)
        if inner_tid != 0:
            self.type_extra.set_i32(value_slot as i64, inner_tid)

fn Sema.is_local_decl(self: Sema, decl_index: i32) -> i32:
    let limit = self.ast.local_decl_count()
    if limit < 0:
        return 1
    // After import merging, decl order is: prelude → user imports → root.
    // Root (local) decls are the last `limit` entries in the merged pool.
    let total = self.ast.decl_count()
    if decl_index >= total - limit:
        return 1
    0

fn Sema.build_ci_scoping(self: Sema):
    // Build c_import scoping data. Scoping is active when there are multiple
    // distinct module paths AND at least one c_import-origin declaration exists.
    if self.decl_source_paths.len() == 0 or self.decl_is_c_import.len() == 0:
        return
    var has_ci = 0
    var module_count = 0
    var prev_path_sym = 0 - 1
    for di in 0..self.ast.decl_count():
        let decl = self.ast.get_decl(di)
        if self.ast.kind(decl) == NK_C_IMPORT and di < self.decl_source_paths.len() as i32:
            let mp_direct = self.pool_intern(self.decl_source_paths.get(di as i64))
            self.ci_modules.insert(mp_direct, 1)
            has_ci = 1
        if di < self.decl_is_c_import.len() as i32 and self.decl_is_c_import.get(di as i64) != 0:
            has_ci = 1
            // Record which module owns this c_import declaration
            if di < self.decl_source_paths.len() as i32:
                let mp = self.pool_intern(self.decl_source_paths.get(di as i64))
                self.ci_modules.insert(mp, 1)
        if di < self.decl_source_paths.len() as i32:
            let ps = self.pool_intern(self.decl_source_paths.get(di as i64))
            if ps != prev_path_sym:
                module_count = module_count + 1
                prev_path_sym = ps
    if has_ci == 0:
        return
    // Scoping (visibility filtering) only activates with multiple modules.
    if module_count >= 2:
        self.scoping_active = 1
    // Always record c_import-origin symbols (needed for auto-coercion).
    for di in 0..self.ast.decl_count():
        if di >= self.decl_is_c_import.len() as i32:
            break
        if self.decl_is_c_import.get(di as i64) == 0:
            continue
        let decl = self.ast.get_decl(di)
        let kind = self.ast.kind(decl)
        if kind == NK_TYPE_DECL or kind == NK_TRAIT_DECL or kind == NK_FN_DECL or kind == NK_EXTERN_FN or kind == NK_EXTERN_VAR or kind == NK_LET_DECL:
            let sym = self.ast.get_data0(decl)
            self.ci_syms.insert(sym, 1)
        // For enum types, also record variant symbols
        if kind == NK_TYPE_DECL:
            let packed_kind = self.ast.get_data2(decl)
            let sub_kind = type_decl_sub_kind(packed_kind)
            if sub_kind == TDK_DISC_ENUM:
                let extra_start = self.ast.get_data1(decl)
                let variant_count = self.ast.get_extra(extra_start)
                for vi in 0..variant_count:
                    let base = extra_start + 1 + vi * 3
                    let v_sym = self.ast.get_extra(base)
                    self.ci_syms.insert(v_sym, 1)

fn Sema.is_ci_visible(self: Sema, sym: i32) -> i32:
    // Check if a symbol is visible from the current module context.
    // Returns 1 if visible, 0 if hidden by c_import scoping.
    if self.scoping_active == 0:
        return 1
    if not self.ci_syms.contains(sym):
        return 1
    // Symbol is c_import-origin. It's visible only if the current module
    // itself has c_import declarations (meaning it directly uses c_import).
    if self.current_module_has_ci != 0:
        return 1
    // Also visible if the user explicitly declared it (extern fn, fn, type, etc.)
    // in a non-c_import context. User declarations override c_import scoping.
    var di = 0
    while di < self.ast.decl_count():
        if di < self.decl_is_c_import.len() as i32:
            if self.decl_is_c_import.get(di as i64) != 0:
                di = di + 1
                continue
        let decl = self.ast.get_decl(di)
        let kind = self.ast.kind(decl)
        if kind == NK_FN_DECL or kind == NK_EXTERN_FN or kind == NK_EXTERN_VAR or kind == NK_LET_DECL or kind == NK_TYPE_DECL:
            if self.ast.get_data0(decl) == sym:
                return 1
        di = di + 1
    0

fn Sema.build_ci_destructor_map(self: Sema):
    // Scan function signatures for c_import destructor patterns.
    // A destructor is a method "Type.free" / "Type.destroy" / etc.
    // where the function is c_import-origin.
    for si in 0..self.sig_names.len() as i32:
        let fn_sym = self.sig_names.get(si as i64)
        if not self.ci_syms.contains(fn_sym):
            continue
        let fn_name = self.pool_resolve_symbol(fn_sym)
        // Find dot position
        var dot_pos = -1
        for ci in 0..fn_name.len() as i32:
            if fn_name.byte_at(ci as i64) == 46:
                dot_pos = ci
                break
        if dot_pos <= 0:
            continue
        let method = fn_name.slice((dot_pos + 1) as i64, fn_name.len())
        if method == "free" or method == "destroy" or method == "close" or method == "unref" or method == "release":
            let type_name = fn_name.slice(0, dot_pos as i64)
            let type_sym = self.pool_intern(type_name)
            if self.type_decl_nodes.contains(type_sym):
                if not self.ci_type_destructors.contains(type_sym):
                    self.ci_type_destructors.insert(type_sym, fn_sym)

fn Sema.collect_type_decl(self: Sema, node: i32, is_local: i32):
    let name = self.ast.get_data0(node)
    if is_local != 0:
        self.set_pretty_symbol(name, self.extract_decl_name_after(node, "type"))
    self.type_decl_nodes.insert(name, node)
    let extra_start = self.ast.get_data1(node)
    let packed_kind = self.ast.get_data2(node)
    let sub_kind = type_decl_sub_kind(packed_kind)
    let is_ephemeral = type_decl_is_ephemeral(packed_kind)

    if sub_kind == TDK_STRUCT:
        let field_count = self.ast.get_extra(extra_start)
        // Resolve all field types first — resolve_type_expr can push to type_extra
        // (e.g. for generic instances), so we must capture te_start AFTER resolving.
        let field_names: Vec[i32] = Vec.new()
        let field_tids: Vec[i32] = Vec.new()
        let field_defaults: Vec[i32] = Vec.new()
        for fi in 0..field_count:
            let base = extra_start + 1 + fi * 3
            let f_name = self.ast.get_extra(base)
            let f_type_node = self.ast.get_extra(base + 1)
            let f_default = self.ast.get_extra(base + 2)
            if not is_ephemeral:
                if self.type_expr_contains_ref(f_type_node) != 0:
                    self.emit_error("ephemeral references cannot be stored in structs", f_type_node)
                if self.type_expr_is_collection_with_ref(f_type_node) != 0:
                    self.emit_error("ephemeral references cannot be stored in generic containers", f_type_node)
                // Check if field type is a user-defined ephemeral type
                if self.ast.kind(f_type_node) == NK_IDENT or self.ast.kind(f_type_node) == NK_TYPE_NAMED:
                    let f_type_sym = self.ast.get_data0(f_type_node)
                    if self.ephemeral_types.contains(f_type_sym):
                        self.emit_error("ephemeral type '" ++ self.pool_resolve(f_type_sym) ++ "' cannot be stored in non-ephemeral struct", f_type_node)
            let f_tid = self.resolve_type_expr(f_type_node)
            field_names.push(f_name)
            field_tids.push(f_tid)
            field_defaults.push(f_default)
        let te_start = self.type_extra.len() as i32
        for fi in 0..field_count:
            self.type_extra.push(field_names.get(fi as i64))
            self.type_extra.push(field_tids.get(fi as i64))
            self.type_extra.push(field_defaults.get(fi as i64))
        // Alignment array: stored after field triples in AST
        let align_base = extra_start + 1 + field_count * 3
        for fi in 0..field_count:
            self.type_extra.push(self.ast.get_extra(align_base + fi))
        let tid = self.add_type(TY_STRUCT, name, te_start, field_count)
        self.named_types.insert(name, tid)

    if sub_kind == TDK_ENUM:
        let variant_count = self.ast.get_extra(extra_start)
        let te_start = self.type_extra.len() as i32
        var epos = extra_start + 1
        for vi in 0..variant_count:
            let v_name = self.ast.get_extra(epos)
            epos = epos + 1
            let payload_count = self.ast.get_extra(epos)
            epos = epos + 1
            self.type_extra.push(v_name)
            self.type_extra.push(payload_count)
            for pi in 0..payload_count:
                let pt_node = self.ast.get_extra(epos)
                epos = epos + 1
                let pt_tid = self.resolve_type_expr(pt_node)
                self.type_extra.push(pt_tid)
            // Register variant lookup
            self.variant_lookup.insert(v_name, vi)
        let tid = self.add_type(TY_ENUM, name, te_start, variant_count)
        self.named_types.insert(name, tid)
        // Re-register variants with actual enum TypeId
        var vpos = te_start
        for vi in 0..variant_count:
            let v_name = self.type_extra.get(vpos as i64)
            self.variant_lookup.insert(v_name, vi)
            self.variant_type_ids.insert(v_name, tid)
            let pc = self.type_extra.get((vpos + 1) as i64)
            vpos = vpos + 2 + pc

    if sub_kind == TDK_DISC_ENUM:
        let repr_type_node = self.ast.get_extra(extra_start)
        let repr_type_tid = self.resolve_type_expr(repr_type_node)
        let variant_count = self.ast.get_extra(extra_start + 1)
        let te_start = self.type_extra.len() as i32
        var epos = extra_start + 2
        var disc_vals: Vec[i32] = Vec.new()
        for vi in 0..variant_count:
            let v_name = self.ast.get_extra(epos)
            epos = epos + 1
            let disc_value = self.ast.get_extra(epos)
            epos = epos + 1
            let payload_count = self.ast.get_extra(epos)
            epos = epos + 1
            self.type_extra.push(v_name)
            self.type_extra.push(payload_count)
            // Check for duplicate discriminant values
            for prev in 0..disc_vals.len() as i32:
                if disc_vals.get(prev as i64) == disc_value:
                    self.emit_error("duplicate discriminant value " ++ int_to_string(disc_value), node)
            // Check discriminant fits in repr type range
            if repr_type_tid == self.ty_i8:
                if disc_value < (0 - 128) or disc_value > 127:
                    self.emit_error("discriminant value " ++ int_to_string(disc_value) ++ " out of range for i8", node)
            if repr_type_tid == self.ty_i16:
                if disc_value < (0 - 32768) or disc_value > 32767:
                    self.emit_error("discriminant value " ++ int_to_string(disc_value) ++ " out of range for i16", node)
            disc_vals.push(disc_value)
            for pi in 0..payload_count:
                let pt_node = self.ast.get_extra(epos)
                epos = epos + 1
                let pt_tid = self.resolve_type_expr(pt_node)
                self.type_extra.push(pt_tid)
            self.variant_lookup.insert(v_name, vi)
        let tid = self.add_type(TY_ENUM, name, te_start, variant_count)
        self.named_types.insert(name, tid)
        self.disc_repr_types.insert(tid, repr_type_tid)
        // Check if any variant has payloads
        var any_payload = 0
        var check_pos = te_start
        for cv in 0..variant_count:
            check_pos = check_pos + 1  // v_name
            let pc = self.type_extra.get(check_pos as i64)
            check_pos = check_pos + 1 + pc
            if pc > 0:
                any_payload = 1
        if any_payload != 0:
            self.disc_has_payload.insert(tid, 1)
        // Re-register variants with actual enum TypeId and store disc values
        var vpos = te_start
        for vi in 0..variant_count:
            let v_name = self.type_extra.get(vpos as i64)
            self.variant_lookup.insert(v_name, vi)
            self.variant_type_ids.insert(v_name, tid)
            self.disc_values.insert(v_name, disc_vals.get(vi as i64))
            let pc = self.type_extra.get((vpos + 1) as i64)
            vpos = vpos + 2 + pc

    if sub_kind == TDK_ALIAS:
        let aliased_node = self.ast.get_extra(extra_start)
        let target = self.resolve_type_expr(aliased_node)
        let tid = self.add_type(TY_ALIAS, target, 0, 0)
        self.named_types.insert(name, tid)

    if sub_kind == TDK_DISTINCT:
        let inner_node = self.ast.get_extra(extra_start)
        let inner = self.resolve_type_expr(inner_node)
        // Distinct type: treat as single-field struct
        let te_start = self.type_extra.len() as i32
        let val_sym = self.pool_intern("value")
        self.type_extra.push(val_sym)
        self.type_extra.push(inner)
        self.type_extra.push(0)
        let tid = self.add_type(TY_STRUCT, name, te_start, 1)
        self.named_types.insert(name, tid)
        self.distinct_type_names.insert(name, tid)

    if sub_kind == TDK_OPAQUE:
        // Opaque type: register as struct with 0 fields
        let te_start = self.type_extra.len() as i32
        let tid = self.add_type(TY_STRUCT, name, te_start, 0)
        self.named_types.insert(name, tid)

    if sub_kind == TDK_UNION:
        // Union type: register fields like a struct (codegen handles layout)
        let field_count = self.ast.get_extra(extra_start)
        let field_names: Vec[i32] = Vec.new()
        let field_tids: Vec[i32] = Vec.new()
        let field_defaults: Vec[i32] = Vec.new()
        for fi in 0..field_count:
            let base = extra_start + 1 + fi * 3
            let f_name = self.ast.get_extra(base)
            let f_type_node = self.ast.get_extra(base + 1)
            let f_default = self.ast.get_extra(base + 2)
            let f_tid = self.resolve_type_expr(f_type_node)
            field_names.push(f_name)
            field_tids.push(f_tid)
            field_defaults.push(f_default)
        let te_start = self.type_extra.len() as i32
        for fi in 0..field_count:
            self.type_extra.push(field_names.get(fi as i64))
            self.type_extra.push(field_tids.get(fi as i64))
            self.type_extra.push(field_defaults.get(fi as i64))
        // Alignment array for unions
        let align_base = extra_start + 1 + field_count * 3
        for fi in 0..field_count:
            self.type_extra.push(self.ast.get_extra(align_base + fi))
        let tid = self.add_type(TY_STRUCT, name, te_start, field_count)
        self.named_types.insert(name, tid)

    if is_ephemeral != 0:
        self.ephemeral_types.insert(name, 1)

    if self.ast.is_must_use_type_node(node) != 0:
        self.must_use_types.insert(name, 1)

    if is_local != 0:
        self.local_type_names.insert(name, 1)

// ── Type dependency cycle detection ──────────────────────────────

// Collect named types that a type expression directly embeds (by value).
// Pointers, references, and slices are indirections — not followed.
// Collect named types that a type expression directly embeds (by value).
// Results are accumulated in self.cycle_dep_syms / self.cycle_dep_nodes.
// Pointers, references, and slices are indirections — not followed.
fn Sema.collect_value_type_deps(self: Sema, type_node: i32):
    if type_node == 0:
        return
    let kind = self.ast.kind(type_node)
    if kind == NK_TYPE_NAMED:
        let sym = self.ast.get_data0(type_node)
        // Only track user-declared types, not primitives.
        if self.type_decl_nodes.contains(sym):
            self.cycle_dep_syms.push(sym)
            self.cycle_dep_nodes.push(type_node)
        return
    if kind == NK_TYPE_ARRAY:
        // Arrays embed their element type by value.
        self.collect_value_type_deps(self.ast.get_data0(type_node))
        return
    if kind == NK_TYPE_TUPLE:
        let extra_start = self.ast.get_data0(type_node)
        let elem_count = self.ast.get_data1(type_node)
        for ei in 0..elem_count:
            let e_node = self.ast.get_extra(extra_start + ei)
            self.collect_value_type_deps(e_node)
        return
    if kind == NK_TYPE_OPTIONAL:
        // Option embeds the inner type by value.
        self.collect_value_type_deps(self.ast.get_data0(type_node))
        return
    // NK_TYPE_PTR, NK_TYPE_REF, NK_TYPE_SLICE, NK_TYPE_GENERIC,
    // NK_TYPE_FN: all provide indirection — do not follow.

fn Sema.check_type_cycles(self: Sema):
    // Build directed graph: for each type decl, find value-type deps.
    // Use self.cycle_dep_syms/cycle_dep_nodes as accumulators (must go through
    // self for mutation to be visible — Vec params are pass-by-value).

    // Accumulate all edges into cycle_dep_syms (flat: [from, to, from, to, ...])
    // and cycle_dep_nodes (flat: [edge_node, edge_node, ...]) using a stride of 2.
    // Actually, use three separate Sema-level Vecs to avoid complexity.
    // Re-purpose cycle_dep_syms for dep_from and cycle_dep_nodes for dep_to.
    // Add edge node info separately.

    // Instead, accumulate edges directly. For each field type, call
    // collect_value_type_deps which pushes to self.cycle_dep_syms/nodes,
    // then read them back.
    self.cycle_dep_syms = Vec.new()
    self.cycle_dep_nodes = Vec.new()

    // Phase 1: collect all edges. Each edge is 3 consecutive entries:
    // cycle_dep_syms: [from_sym, to_sym, from_sym, to_sym, ...]
    // cycle_dep_nodes: [0, edge_node, 0, edge_node, ...]
    // We'll use a simpler scheme: collect into flat arrays indexed by edge.
    // dep_edge_count tracks how many edges we've collected.

    // Actually simplest: save len before collect, push owner info after.
    var edge_from: Vec[i32] = Vec.new()
    var edge_to: Vec[i32] = Vec.new()
    var edge_node: Vec[i32] = Vec.new()

    for di in 0..self.ast.decl_count():
        let decl = self.ast.get_decl(di)
        if self.ast.kind(decl) != NK_TYPE_DECL:
            continue
        let name = self.ast.get_data0(decl)
        let extra_start = self.ast.get_data1(decl)
        let packed_kind = self.ast.get_data2(decl)
        let sub_kind = type_decl_sub_kind(packed_kind)

        if sub_kind == TDK_STRUCT:
            let field_count = self.ast.get_extra(extra_start)
            for fi in 0..field_count:
                let base = extra_start + 1 + fi * 3
                let f_type_node = self.ast.get_extra(base + 1)
                let before = self.cycle_dep_syms.len() as i32
                self.collect_value_type_deps(f_type_node)
                let after = self.cycle_dep_syms.len() as i32
                for di2 in before..after:
                    edge_from.push(name)
                    edge_to.push(self.cycle_dep_syms.get(di2 as i64))
                    edge_node.push(self.cycle_dep_nodes.get(di2 as i64))

        if sub_kind == TDK_ENUM or sub_kind == TDK_DISC_ENUM:
            let variant_start = if sub_kind == TDK_DISC_ENUM: extra_start + 2 else: extra_start + 1
            let variant_count = if sub_kind == TDK_DISC_ENUM: self.ast.get_extra(extra_start + 1) else: self.ast.get_extra(extra_start)
            var epos = variant_start
            for vi in 0..variant_count:
                epos = epos + 1  // v_name
                if sub_kind == TDK_DISC_ENUM:
                    epos = epos + 1  // disc_value
                let payload_count = self.ast.get_extra(epos)
                epos = epos + 1
                for pi in 0..payload_count:
                    let pt_node = self.ast.get_extra(epos)
                    epos = epos + 1
                    let before = self.cycle_dep_syms.len() as i32
                    self.collect_value_type_deps(pt_node)
                    let after = self.cycle_dep_syms.len() as i32
                    for di2 in before..after:
                        edge_from.push(name)
                        edge_to.push(self.cycle_dep_syms.get(di2 as i64))
                        edge_node.push(self.cycle_dep_nodes.get(di2 as i64))

        if sub_kind == TDK_ALIAS:
            let aliased_node = self.ast.get_extra(extra_start)
            let before = self.cycle_dep_syms.len() as i32
            self.collect_value_type_deps(aliased_node)
            let after = self.cycle_dep_syms.len() as i32
            for di2 in before..after:
                edge_from.push(name)
                edge_to.push(self.cycle_dep_syms.get(di2 as i64))
                edge_node.push(self.cycle_dep_nodes.get(di2 as i64))

        if sub_kind == TDK_DISTINCT:
            let inner_node = self.ast.get_extra(extra_start)
            let before = self.cycle_dep_syms.len() as i32
            self.collect_value_type_deps(inner_node)
            let after = self.cycle_dep_syms.len() as i32
            for di2 in before..after:
                edge_from.push(name)
                edge_to.push(self.cycle_dep_syms.get(di2 as i64))
                edge_node.push(self.cycle_dep_nodes.get(di2 as i64))

    if edge_from.len() == 0:
        return

    // DFS cycle detection with coloring.
    // 0=white, 1=gray (in path), 2=black (done)
    var color: HashMap[i32, i32] = sema_new_map_i32_i32()
    // Parent tracking for cycle path reconstruction.
    var parent_sym: HashMap[i32, i32] = sema_new_map_i32_i32()
    var parent_edge: HashMap[i32, i32] = sema_new_map_i32_i32()

    for di in 0..self.ast.decl_count():
        let decl = self.ast.get_decl(di)
        if self.ast.kind(decl) != NK_TYPE_DECL:
            continue
        let name = self.ast.get_data0(decl)
        if color.contains(name) and color.get(name).unwrap() != 0:
            continue
        // Iterative DFS using explicit stack.
        var stack: Vec[i32] = Vec.new()
        stack.push(name)
        while stack.len() > 0:
            let cur = stack.get(stack.len() - 1)
            let cur_color = if color.contains(cur): color.get(cur).unwrap() else: 0
            if cur_color == 0:
                // First visit: mark gray.
                color.insert(cur, 1)
                // Push neighbors.
                for ei in 0..edge_from.len() as i32:
                    if edge_from.get(ei as i64) != cur:
                        continue
                    let neighbor = edge_to.get(ei as i64)
                    let n_color = if color.contains(neighbor): color.get(neighbor).unwrap() else: 0
                    if n_color == 0:
                        parent_sym.insert(neighbor, cur)
                        parent_edge.insert(neighbor, edge_node.get(ei as i64))
                        stack.push(neighbor)
                    if n_color == 1:
                        // Cycle found! Reconstruct the loop.
                        self.emit_type_cycle_error(neighbor, cur, edge_node.get(ei as i64), parent_sym, parent_edge)
                        return
            else:
                // Already visited (gray revisit or black). Pop and mark black.
                let _ = stack.pop()
                color.insert(cur, 2)

fn Sema.emit_type_cycle_error(self: Sema, cycle_start: i32, cycle_end: i32, closing_edge_node: i32, parent_sym: HashMap[i32, i32], parent_edge: HashMap[i32, i32]):
    // Reconstruct cycle path: cycle_start → ... → cycle_end → cycle_start
    var path_syms: Vec[i32] = Vec.new()
    var path_edges: Vec[i32] = Vec.new()

    // Walk from cycle_end back to cycle_start via parent chain.
    var cur = cycle_end
    while cur != cycle_start:
        path_syms.push(cur)
        if parent_edge.contains(cur):
            path_edges.push(parent_edge.get(cur).unwrap())
        else:
            path_edges.push(0)
        if not parent_sym.contains(cur):
            break
        cur = parent_sym.get(cur).unwrap()
    path_syms.push(cycle_start)

    // Reverse to get forward order: cycle_start → ... → cycle_end
    var fwd_syms: Vec[i32] = Vec.new()
    var fwd_edges: Vec[i32] = Vec.new()
    for i in 0..path_syms.len() as i32:
        fwd_syms.push(path_syms.get((path_syms.len() as i32 - 1 - i) as i64))
    for i in 0..path_edges.len() as i32:
        fwd_edges.push(path_edges.get((path_edges.len() as i32 - 1 - i) as i64))
    // Add closing edge: cycle_end → cycle_start
    fwd_edges.push(closing_edge_node)

    let loop_len = fwd_syms.len() as i32

    // Build diagnostic with primary span at first type decl.
    let first_sym = fwd_syms.get(0)
    let first_node = if self.type_decl_nodes.contains(first_sym): self.type_decl_nodes.get(first_sym).unwrap() else: 0
    let primary_start = self.ast.get_start(first_node)
    let primary_end = self.ast.get_end(first_node)
    var diag = Diagnostic.err("dependency loop with length " ++ int_to_string(loop_len), Span { file: self.local_file_id, start: primary_start, end: primary_end })

    // Add a label for each edge in the loop.
    for i in 0..loop_len:
        let from_sym = fwd_syms.get(i as i64)
        let to_sym = if i + 1 < loop_len: fwd_syms.get((i + 1) as i64) else: fwd_syms.get(0)
        let edge_node = fwd_edges.get(i as i64)
        if edge_node != 0:
            let from_name = self.pool_resolve_symbol(from_sym)
            let to_name = self.pool_resolve_symbol(to_sym)
            let e_start = self.ast.get_start(edge_node)
            let e_end = self.ast.get_end(edge_node)
            diag.add_label(Span { file: self.local_file_id, start: e_start, end: e_end }, "type `" ++ from_name ++ "` depends on `" ++ to_name ++ "` here")

    diag.add_help("break the cycle by using a pointer (`*" ++ self.pool_resolve_symbol(fwd_syms.get(0)) ++ "`) or reference (`&" ++ self.pool_resolve_symbol(fwd_syms.get(0)) ++ "`) for one field")
    self.diags.emit(diag)

fn Sema.collect_fn_decl(self: Sema, node: i32, is_local: i32):
    let fn_name = self.ast.get_data0(node)
    if is_local != 0:
        self.set_pretty_symbol(fn_name, self.extract_decl_name_after(node, "fn"))
    self.fn_decl_nodes.insert(fn_name, node)

    // Look up fn_meta for parameter info
    let meta = self.ast.find_fn_meta(node)
    if meta < 0:
        // No meta available — register with no params
        let fn_tid = self.add_type(TY_FN, 0, 0, self.ty_void)
        self.add_sig(fn_name, fn_tid, self.ty_void, 0, 0, 0)
        return

    let flags = self.ast.fn_meta_flags(meta)
    let ret_node = self.ast.fn_meta_ret(meta)
    let param_start = self.ast.fn_meta_param_start(meta)
    let param_count = self.ast.fn_meta_param_count(meta)
    let tp_count = self.ast.fn_meta_tp_count(meta)

    // Bind Self to method owner type for dot-name methods
    let self_sym = self.pool_intern("Self")
    var self_type_id = 0
    let fn_name_str = self.pool_resolve(fn_name)
    for ci in 0..fn_name_str.len() as i32:
        if fn_name_str.byte_at(ci as i64) == 46:
            let owner_name = fn_name_str.slice(0, ci as i64)
            let owner_sym = self.pool_intern(owner_name)
            if self.named_types.contains(owner_sym):
                self_type_id = self.named_types.get(owner_sym).unwrap()
                self.named_types.insert(self_sym, self_type_id)
            break

    // Set up associated type bindings if inside a trait impl
    self.assoc_type_bindings.clear()
    if self.method_impl_nodes.contains(fn_name):
        let impl_nd = self.method_impl_nodes.get(fn_name).unwrap()
        let impl_ex = self.ast.get_data1(impl_nd)
        let impl_ac = self.ast.get_extra(impl_ex)
        for iai in 0..impl_ac:
            let at_name = self.ast.get_extra(impl_ex + 1 + iai * 2)
            let at_type_nd = self.ast.get_extra(impl_ex + 1 + iai * 2 + 1)
            let at_tid = self.resolve_type_expr(at_type_nd)
            if at_tid != 0:
                self.assoc_type_bindings.insert(at_name, at_tid)

    // Methods in blanket impls: treat as generic (type params come from impl)
    if tp_count == 0 and self.method_impl_nodes.contains(fn_name):
        let bi_impl = self.method_impl_nodes.get(fn_name).unwrap()
        let bi_tp_meta = self.ast.find_impl_type_params(bi_impl)
        if bi_tp_meta >= 0:
            self.generic_fn_nodes.insert(fn_name, node)
            if self_type_id != 0:
                self.named_types.remove(self_sym)
            return

    // Methods on generic structs: treat as generic (type params come from struct)
    if tp_count == 0 and self_type_id != 0:
        for cfi in 0..fn_name_str.len() as i32:
            if fn_name_str.byte_at(cfi as i64) == 46:
                let cf_owner = fn_name_str.slice(0, cfi as i64)
                let cf_owner_sym = self.pool_intern(cf_owner)
                if self.type_decl_nodes.contains(cf_owner_sym):
                    let cf_td = self.type_decl_nodes.get(cf_owner_sym).unwrap()
                    if self.type_decl_tp_count(cf_td) > 0:
                        self.generic_fn_nodes.insert(fn_name, node)
                        self.named_types.remove(self_sym)
                        return
                break

    // Generic functions: store for later monomorphization
    if tp_count > 0:
        self.generic_fn_nodes.insert(fn_name, node)
        for pi in 0..param_count:
            let p_type_node = self.ast.fn_param_type(param_start, pi)
            self.validate_type_expr_with_type_params(p_type_node, self.ast.fn_meta_tp_start(meta), tp_count)
        self.validate_type_expr_with_type_params(ret_node, self.ast.fn_meta_tp_start(meta), tp_count)
        // Validate where clause references
        self.validate_where_clause(node, self.ast.fn_meta_tp_start(meta), tp_count)
        if self_type_id != 0:
            self.named_types.remove(self_sym)
        return

    // Resolve param types
    let sig_param_start = self.sig_params.len() as i32
    for pi in 0..param_count:
        let p_name_sym = self.ast.fn_param_name(param_start, pi)
        if is_local != 0:
            self.set_pretty_symbol(p_name_sym, self.extract_fn_param_name(node, pi))
        let p_type_node = self.ast.fn_param_type(param_start, pi)
        let p_tid = self.resolve_type_expr(p_type_node)
        self.sig_params.push(p_tid)

    let ret_type = self.resolve_type_expr(ret_node)
    if ret_node != 0:
        if self.type_expr_contains_ref(ret_node) != 0:
            self.emit_error("ephemeral references cannot be returned from functions", ret_node)
        let ret_kind = self.ast.kind(ret_node)
        if ret_kind == NK_TYPE_NAMED:
            let ret_sym = self.ast.get_data0(ret_node)
            if self.ephemeral_types.contains(ret_sym):
                self.emit_error("ephemeral types cannot be returned from functions", ret_node)
    let actual_ret = ret_type
    if actual_ret == 0 and ret_node == 0:
        // no return type annotation → void
        let _ = 0

    // Build fn type
    let fn_extra_start = self.type_extra.len() as i32
    for pi in 0..param_count:
        self.type_extra.push(self.sig_params.get((sig_param_start + pi) as i64))
    let fn_tid = self.add_type(TY_FN, fn_extra_start, param_count, ret_type)

    self.add_sig(fn_name, fn_tid, ret_type, sig_param_start, param_count, 0)
    let fn_sig_idx = self.get_sig(fn_name)
    self.register_method_sig_alias(node, fn_name, fn_sig_idx)

    // Track must_use
    if (flags / FN_FLAG_MUST_USE) % 2 == 1:
        self.must_use_fns.insert(fn_name, 1)
    // Track async fns
    if (flags / FN_FLAG_ASYNC) % 2 == 1:
        self.task_fns.insert(fn_name, 1)

    // Unbind Self
    if self_type_id != 0:
        self.named_types.remove(self_sym)

fn Sema.collect_extern_fn(self: Sema, node: i32, is_local: i32):
    let name = self.ast.get_data0(node)
    if is_local != 0:
        self.set_pretty_symbol(name, self.extract_decl_name_after(node, "fn"))
    let flags = self.ast.get_data2(node)
    let is_variadic = flags % 2

    let meta = self.ast.find_fn_meta(node)
    if meta < 0:
        let fn_tid = self.add_type(TY_FN, 0, 0, self.ty_void)
        self.add_sig(name, fn_tid, self.ty_void, 0, 0, is_variadic)
        self.extern_fn_names.insert(name, 1)
        return

    let ret_node = self.ast.fn_meta_ret(meta)
    let param_start = self.ast.fn_meta_param_start(meta)
    let param_count = self.ast.fn_meta_param_count(meta)

    let sig_param_start = self.sig_params.len() as i32
    for pi in 0..param_count:
        let p_name_sym = self.ast.fn_param_name(param_start, pi)
        let p_type_node = self.ast.fn_param_type(param_start, pi)
        if is_local != 0:
            self.set_pretty_symbol(p_name_sym, self.extract_fn_param_name(node, pi))
        let p_tid = self.resolve_type_expr(p_type_node)
        self.sig_params.push(p_tid)

    let ret_type = self.resolve_type_expr(ret_node)

    let fn_extra_start = self.type_extra.len() as i32
    for pi in 0..param_count:
        self.type_extra.push(self.sig_params.get((sig_param_start + pi) as i64))
    let fn_tid = self.add_type(TY_FN, fn_extra_start, param_count, ret_type)

    self.add_sig(name, fn_tid, ret_type, sig_param_start, param_count, is_variadic)
    self.extern_fn_names.insert(name, 1)

fn Sema.collect_extern_var(self: Sema, node: i32, is_local: i32):
    let name = self.ast.get_data0(node)
    let type_node = self.ast.get_data1(node)
    let tid = self.resolve_type_expr(type_node)
    // Register the extern var for scope lookup
    let is_mut = if self.ast.get_data2(node) != 0: 1 else: 0
    self.scope_put_at(name, tid, is_mut, node)

fn sema_str_find_char(text: str, needle: i32) -> i32:
    for i in 0..text.len() as i32:
        if text[i] == needle:
            return i
    return 0 - 1

fn Sema.impl_owner_type_sym_for_decl(self: Sema, decl: i32) -> i32:
    let start = self.ast.get_start(decl)
    let end = self.ast.get_end(decl)
    var best_span = 0
    var best_sym = 0
    for di in 0..self.ast.decl_count():
        let cand = self.ast.get_decl(di)
        if self.ast.kind(cand) != NK_IMPL_DECL:
            continue
        let impl_start = self.ast.get_start(cand)
        let impl_end = self.ast.get_end(cand)
        if impl_start <= start and end <= impl_end:
            let span = impl_end - impl_start
            if best_sym == 0 or span < best_span:
                best_span = span
                best_sym = self.ast.get_data0(cand)
    best_sym

fn Sema.register_method_sig_alias(self: Sema, node: i32, fn_sym: i32, sig_idx: i32):
    if sig_idx < 0:
        return

    let qualified = self.pool_resolve(fn_sym)
    if qualified.len() == 0:
        return
    let dot = sema_str_find_char(qualified, 46)
    if dot < 0:
        return
    let owner_name = qualified.slice(0, dot as i64)
    let method_name = qualified.slice((dot + 1) as i64, qualified.len() as i64)
    if owner_name.len() == 0 or method_name.len() == 0:
        return

    let owner_sym = self.pool_intern(owner_name)
    let method_sym = self.pool_intern(method_name)
    let key_sym = self.method_key(owner_sym, method_sym)
    self.sig_lookup.insert(key_sym, sig_idx)
    self.method_symbol_flags.insert(fn_sym, 1)

fn Sema.top_level_let_type_ann_extra(self: Sema, flags: i32) -> i32:
    let packed = flags / 4
    if packed <= 0:
        return -1
    packed - 1

fn Sema.local_let_type_ann_extra(self: Sema, flags: i32) -> i32:
    let packed = flags / 2
    if packed <= 0:
        return -1
    packed - 1

fn Sema.collect_let_decl(self: Sema, node: i32, is_local: i32):
    let name = self.ast.get_data0(node)
    if is_local != 0:
        var bind_name = self.extract_decl_name_after(node, "let")
        if bind_name.len() == 0:
            bind_name = self.extract_decl_name_after(node, "var")
        self.set_pretty_symbol(name, bind_name)
    let flags = self.ast.get_data2(node)
    let is_mut = flags % 2
    var bind_ty = 0
    let type_extra = self.top_level_let_type_ann_extra(flags)
    if type_extra >= 0:
        let type_node = self.ast.get_extra(type_extra)
        bind_ty = self.resolve_type_expr(type_node)
        if self.type_expr_is_collection_with_ref(type_node) != 0:
            self.emit_error("ephemeral references cannot be stored in generic containers", node)
    self.scope_put_at(name, bind_ty, is_mut, node)
    self.typed_binding_types.insert(node, bind_ty)
    self.typed_binding_names.insert(node, name)
    self.typed_binding_muts.insert(node, is_mut)

fn Sema.collect_trait_decl(self: Sema, node: i32, is_local: i32):
    let name = self.ast.get_data0(node)
    if is_local != 0:
        self.set_pretty_symbol(name, self.extract_decl_name_after(node, "trait"))
    let extra_start = self.ast.get_data1(node)
    // Store trait info
    let trait_idx = self.trait_name_syms.len() as i32
    self.trait_name_syms.push(name)
    self.trait_method_starts.push(self.trait_method_names.len() as i32)
    // Trait extra layout:
    // [tp_count, tp_start,
    //  assoc_count,
    //   [assoc_name, bound_count, bounds..., default_type]*,
    //  method_count,
    //   [method_name, method_flags, param_start, param_count, ret_type, default_body]*]
    var pos = extra_start
    let tp_count = self.ast.get_extra(pos)
    let tp_start_ast = self.ast.get_extra(pos + 1)
    pos = pos + 2
    self.trait_tp_starts.push(self.trait_tp_syms.len() as i32)
    self.trait_tp_counts.push(tp_count)
    var tp_pos = tp_start_ast
    for tpi in 0..tp_count:
        self.trait_tp_syms.push(self.ast.get_extra(tp_pos))
        let bc = self.ast.get_extra(tp_pos + 1)
        tp_pos = tp_pos + 2 + bc
    let assoc_count = self.ast.get_extra(pos)
    pos = pos + 1
    // Store associated type declarations for this trait
    self.trait_assoc_starts.push(self.trait_assoc_names.len() as i32)
    self.trait_assoc_counts.push(assoc_count)
    for ai in 0..assoc_count:
        let at_name = self.ast.get_extra(pos)
        let bound_count = self.ast.get_extra(pos + 1)
        self.trait_assoc_bound_starts.push(self.trait_assoc_bound_syms.len() as i32)
        self.trait_assoc_bound_counts.push(bound_count)
        for bi in 0..bound_count:
            self.trait_assoc_bound_syms.push(self.ast.get_extra(pos + 2 + bi))
        pos = pos + 2 + bound_count
        let default_type = self.ast.get_extra(pos)
        pos = pos + 1
        self.trait_assoc_names.push(at_name)
        self.trait_assoc_defaults.push(default_type)

    let method_count = self.ast.get_extra(pos)
    pos = pos + 1
    for i in 0..method_count:
        self.trait_method_names.push(self.ast.get_extra(pos))
        pos = pos + 6
    self.trait_method_counts.push(method_count)
    self.trait_lookup.insert(name, trait_idx)
    if self.ast.is_sealed_trait_node(node) != 0:
        self.sealed_traits.insert(name, 1)
    if is_local != 0:
        self.local_trait_names.insert(name, 1)

fn sema_is_builtin_trait_name(name: str) -> bool:
    name == "Copy" or
    name == "Drop" or
    name == "Scoped" or
    name == "ScopedMut" or
    name == "Debug" or
    name == "Display" or
    name == "Default" or
    name == "Iter" or
    name == "IntoIter" or
    name == "Eq" or
    name == "Hash" or
    name == "Ord" or
    name == "Contains" or
    name == "Index" or
    name == "IndexMut" or
    name == "Send" or
    name == "ScopedSend"

// Check if a new direct impl overlaps with any existing blanket impl
fn Sema.check_direct_overlap(self: Sema, type_name: i32, trait_sym: i32, node: i32):
    for bi in 0..self.blanket_trait_syms.len() as i32:
        if self.blanket_trait_syms.get(bi as i64) != trait_sym:
            continue
        let b_start = self.blanket_bound_starts.get(bi as i64)
        let b_count = self.blanket_bound_counts.get(bi as i64)
        var all_ok = 1
        for bj in 0..b_count:
            let bound_trait = self.blanket_bound_syms.get((b_start + bj) as i64)
            if self.select_trait_impl(type_name, bound_trait) == 0:
                all_ok = 0
        if all_ok != 0:
            let tn = self.pool_resolve(trait_sym)
            self.emit_error("overlapping implementations of '" ++ tn ++ "'", node)

// Check if a new blanket impl overlaps with any existing direct impl
fn Sema.check_blanket_overlap(self: Sema, trait_sym: i32, bound_start: i32, bound_count: i32, node: i32):
    for ti in 0..self.impl_type_syms.len() as i32:
        let t_sym = self.impl_type_syms.get(ti as i64)
        let t_start = self.impl_starts.get(ti as i64)
        let t_count = self.impl_counts.get(ti as i64)
        var has_trait = 0
        for i in 0..t_count:
            if self.impl_extra.get((t_start + i) as i64) == trait_sym:
                has_trait = 1
        if has_trait == 0:
            continue
        // This type has a direct impl of the same trait — check bounds
        var all_ok = 1
        for bj in 0..bound_count:
            let bound_trait = self.blanket_bound_syms.get((bound_start + bj) as i64)
            if self.select_trait_impl(t_sym, bound_trait) == 0:
                all_ok = 0
        if all_ok != 0:
            let tn = self.pool_resolve(trait_sym)
            self.emit_error("overlapping implementations of '" ++ tn ++ "'", node)

fn Sema.collect_impl_decl(self: Sema, node: i32):
    let type_name = self.ast.get_data0(node)
    let trait_sym = self.ast.get_data2(node)
    if trait_sym == 0:
        return

    let trait_name = self.pool_resolve(trait_sym)
    let is_builtin_trait = sema_is_builtin_trait_name(trait_name)
    if not is_builtin_trait and not self.trait_lookup.contains(trait_sym):
        self.emit_error("unknown trait", node)
        return

    let trait_is_local = self.local_trait_names.contains(trait_sym) or is_builtin_trait
    let type_is_local = self.local_type_names.contains(type_name)
    if not trait_is_local and not type_is_local:
        self.emit_error("orphan rule violation: impl requires a local trait or local type", node)
        return

    // Sealed trait check: only the defining module can impl
    if self.sealed_traits.contains(trait_sym) and not trait_is_local:
        self.emit_error("cannot implement sealed trait '" ++ self.pool_resolve(trait_sym) ++ "' outside its defining module", node)
        return

    // Copy trait validation: all fields must be Copy, type must not implement Drop
    if trait_name == "Copy":
        // Check if this type already has a Drop impl (via impl_extra, since
        // Drop methods aren't collected yet at this point in Pass 2)
        let drop_sym = self.pool_intern("Drop")
        if self.impl_lookup.contains(type_name):
            let drop_idx = self.impl_lookup.get(type_name).unwrap()
            let drop_start = self.impl_starts.get(drop_idx as i64)
            let drop_count = self.impl_counts.get(drop_idx as i64)
            for di in 0..drop_count:
                if self.impl_extra.get((drop_start + di) as i64) == drop_sym:
                    self.emit_error("type '" ++ self.pool_resolve(type_name) ++ "' cannot implement Copy because it implements Drop", node)
                    return
        let type_tid = if self.named_types.contains(type_name): self.named_types.get(type_name).unwrap() else: 0
        if type_tid > 0:
            let tk = self.get_type_kind(self.resolve_alias(type_tid))
            if tk == TY_STRUCT:
                let resolved = self.resolve_alias(type_tid)
                let te_start = self.get_type_d1(resolved)
                let field_count = self.get_type_d2(resolved)
                for fi in 0..field_count:
                    let ft = self.type_extra.get((te_start + fi * 3 + 1) as i64)
                    if self.is_copy(ft) == 0:
                        let field_name = self.type_extra.get((te_start + fi * 3) as i64)
                        self.emit_error("type '" ++ self.pool_resolve(type_name) ++ "' cannot implement Copy: field '" ++ self.pool_resolve(field_name) ++ "' is not Copy", node)
                        return

    // Validate associated types: impl must provide all required (no-default) associated types
    if not is_builtin_trait and self.trait_lookup.contains(trait_sym):
        let trait_idx = self.trait_lookup.get(trait_sym).unwrap()
        let at_start = self.trait_assoc_starts.get(trait_idx as i64)
        let at_count = self.trait_assoc_counts.get(trait_idx as i64)
        if at_count > 0:
            // Read impl's associated type bindings from AST extra
            let impl_extra_start = self.ast.get_data1(node)
            let impl_at_count = self.ast.get_extra(impl_extra_start)
            for ati in 0..at_count:
                let required_name = self.trait_assoc_names.get((at_start + ati) as i64)
                let default_type = self.trait_assoc_defaults.get((at_start + ati) as i64)
                if default_type != 0:
                    continue
                // Check if impl provides this associated type
                var found = 0
                for iai in 0..impl_at_count:
                    let impl_at_name = self.ast.get_extra(impl_extra_start + 1 + iai * 2)
                    if impl_at_name == required_name:
                        found = 1
                if found == 0:
                    self.emit_error("impl missing required associated type '" ++ self.pool_resolve(required_name) ++ "'", node)
                    return
            // Validate associated type bounds
            for ati in 0..at_count:
                let at_global_idx = at_start + ati
                if at_global_idx < self.trait_assoc_bound_starts.len() as i32:
                    let ab_start = self.trait_assoc_bound_starts.get(at_global_idx as i64)
                    let ab_count = self.trait_assoc_bound_counts.get(at_global_idx as i64)
                    if ab_count > 0:
                        let at_name_sym = self.trait_assoc_names.get(at_global_idx as i64)
                        // Find the concrete type from impl's associated type bindings
                        var impl_at_type_node = 0
                        for iai in 0..impl_at_count:
                            let impl_at_name = self.ast.get_extra(impl_extra_start + 1 + iai * 2)
                            if impl_at_name == at_name_sym:
                                impl_at_type_node = self.ast.get_extra(impl_extra_start + 1 + iai * 2 + 1)
                        if impl_at_type_node != 0:
                            let impl_at_tid = self.resolve_type_expr(impl_at_type_node)
                            if impl_at_tid > 0:
                                let impl_at_type_sym = self.get_type_d0(impl_at_tid)
                                if impl_at_type_sym != 0:
                                    for bi in 0..ab_count:
                                        let bound_sym = self.trait_assoc_bound_syms.get((ab_start + bi) as i64)
                                        if self.select_trait_impl(impl_at_type_sym, bound_sym) == 0:
                                            let tname = self.pool_resolve(at_name_sym)
                                            let bname = self.pool_resolve(bound_sym)
                                            self.emit_error("associated type '" ++ tname ++ "' does not satisfy bound '" ++ bname ++ "'", node)
                                            return

    // Check for blanket impl (impl-level type params)
    let tp_meta_idx = self.ast.find_impl_type_params(node)
    if tp_meta_idx >= 0:
        // Blanket impl: collect bounds and register
        let tp_start = self.ast.impl_type_params.get((tp_meta_idx + 1) as i64)
        let tp_count = self.ast.impl_type_params.get((tp_meta_idx + 2) as i64)
        let bound_start = self.blanket_bound_syms.len() as i32
        var total_bounds = 0
        var tp_off = tp_start
        for tpi in 0..tp_count:
            let bound_count = self.ast.get_extra(tp_off + 1)
            tp_off = tp_off + 2
            for bi in 0..bound_count:
                let bound_sym = self.ast.get_extra(tp_off + bi)
                self.blanket_bound_syms.push(bound_sym)
                total_bounds = total_bounds + 1
            tp_off = tp_off + bound_count
        self.blanket_trait_syms.push(trait_sym)
        self.blanket_bound_starts.push(bound_start)
        self.blanket_bound_counts.push(total_bounds)
        // Store target base sym for generic blanket impls (e.g., impl[T] Trait for Vec[T])
        let target_type_nd = self.ast.find_impl_target_type_node(node)
        if target_type_nd != 0 and self.ast.kind(target_type_nd) == NK_TYPE_GENERIC:
            self.blanket_target_base_syms.push(self.ast.get_data0(target_type_nd))
        else:
            self.blanket_target_base_syms.push(0)
        // Overlap check: blanket vs existing direct impls
        self.check_blanket_overlap(trait_sym, bound_start, total_bounds, node)
        return

    // If the impl target is a generic type (e.g., impl Trait for Vec[i32]),
    // resolve the full type and record it for exact-match trait selection.
    let target_type_node = self.ast.find_impl_target_type_node(node)
    if target_type_node != 0:
        let target_tid = self.resolve_type_expr(target_type_node)
        if target_tid != 0 and self.get_type_kind(target_tid) == TY_GENERIC_INST:
            let gi_key = i64_to_string(target_tid as i64) ++ ":" ++ i64_to_string(trait_sym as i64)
            self.impl_generic_inst.insert(gi_key, 1)

    // Overlap check: direct impl vs existing blanket impls
    self.check_direct_overlap(type_name, trait_sym, node)

    // Record direct impl
    // When appending to an existing type, relocate all entries to keep them
    // contiguous (the flat impl_extra vec is shared across all types).
    if self.impl_lookup.contains(type_name):
        let idx = self.impl_lookup.get(type_name).unwrap()
        let old_start = self.impl_starts.get(idx as i64)
        let old_count = self.impl_counts.get(idx as i64)
        for i in 0..old_count:
            if self.impl_extra.get((old_start + i) as i64) == trait_sym:
                self.emit_error("duplicate implementation of trait for type", node)
                return
        // Copy existing entries to end for contiguity
        let new_start = self.impl_extra.len() as i32
        for i in 0..old_count:
            self.impl_extra.push(self.impl_extra.get((old_start + i) as i64))
        self.impl_extra.push(trait_sym)
        self.impl_starts.set_i32(idx as i64, new_start)
        self.impl_counts.set_i32(idx as i64, old_count + 1)
    else:
        let idx = self.impl_type_syms.len() as i32
        self.impl_type_syms.push(type_name)
        self.impl_starts.push(self.impl_extra.len() as i32)
        self.impl_counts.push(1)
        self.impl_extra.push(trait_sym)
        self.impl_lookup.insert(type_name, idx)

    // Track sealed trait implementors
    if self.sealed_traits.contains(trait_sym):
        if self.sealed_impl_starts.contains(trait_sym):
            let si_start = self.sealed_impl_starts.get(trait_sym).unwrap()
            let si_count = self.sealed_impl_counts.get(trait_sym).unwrap()
            // Check for duplicate
            var already = false
            for si in 0..si_count:
                if self.sealed_impl_types.get((si_start + si) as i64) == type_name:
                    already = true
                    break
            if not already:
                // Relocate to end for contiguity
                let new_start = self.sealed_impl_types.len() as i32
                for si in 0..si_count:
                    self.sealed_impl_types.push(self.sealed_impl_types.get((si_start + si) as i64))
                self.sealed_impl_types.push(type_name)
                self.sealed_impl_starts.insert(trait_sym, new_start)
                self.sealed_impl_counts.insert(trait_sym, si_count + 1)
        else:
            self.sealed_impl_starts.insert(trait_sym, self.sealed_impl_types.len() as i32)
            self.sealed_impl_counts.insert(trait_sym, 1)
            self.sealed_impl_types.push(type_name)

fn sema_trait_method_flag_generic -> i32: 4

fn Sema.type_is_dyn_object(self: Sema, tid: i32) -> i32:
    if tid == 0:
        return 0
    let resolved = self.resolve_alias(tid)
    let tk = self.get_type_kind(resolved)
    if tk == TY_TRAIT_OBJ:
        return 1
    if tk == TY_REF or tk == TY_PTR:
        return self.type_is_dyn_object(self.get_type_d0(resolved))
    0

fn Sema.find_trait_decl_node(self: Sema, trait_sym: i32) -> i32:
    for di in 0..self.ast.decl_count():
        let decl = self.ast.get_decl(di)
        if self.ast.kind(decl) == NK_TRAIT_DECL and self.ast.get_data0(decl) == trait_sym:
            return decl
    0

fn Sema.emit_trait_object_safety_error(self: Sema, trait_sym: i32, method_sym: i32, reason: str, node: i32):
    let trait_name = self.pool_resolve(trait_sym)
    let method_name = self.pool_resolve(method_sym)
    self.emit_error("trait '" ++ trait_name ++ "' is not object-safe: method '" ++ method_name ++ "' " ++ reason, node)

fn Sema.ensure_trait_object_safe(self: Sema, trait_sym: i32, node: i32) -> i32:
    let trait_node = self.find_trait_decl_node(trait_sym)
    if trait_node == 0:
        return 1

    let extra_start = self.ast.get_data1(trait_node)
    var pos = extra_start
    pos = pos + 2  // skip tp_count and tp_start
    let assoc_count = self.ast.get_extra(pos)
    pos = pos + 1
    for ai in 0..assoc_count:
        let bound_count = self.ast.get_extra(pos + 1)
        pos = pos + 2 + bound_count + 1

    let method_count = self.ast.get_extra(pos)
    pos = pos + 1

    let self_name_sym = self.pool_intern("self")
    let self_type_sym = self.pool_intern("Self")
    for mi in 0..method_count:
        let method_sym = self.ast.get_extra(pos)
        pos = pos + 1
        let method_flags = self.ast.get_extra(pos)
        pos = pos + 1
        let param_start = self.ast.get_extra(pos)
        pos = pos + 1
        let param_count = self.ast.get_extra(pos)
        pos = pos + 1
        let ret_node = self.ast.get_extra(pos)
        pos = pos + 1
        pos = pos + 1 // default body

        if param_count <= 0:
            self.emit_trait_object_safety_error(trait_sym, method_sym, "has no self parameter", node)
            return 0

        let first_param_name = self.ast.fn_param_name(param_start, 0)
        if first_param_name != self_name_sym:
            self.emit_trait_object_safety_error(trait_sym, method_sym, "has no self parameter", node)
            return 0

        if (method_flags / sema_trait_method_flag_generic()) % 2 == 1:
            self.emit_trait_object_safety_error(trait_sym, method_sym, "is generic", node)
            return 0

        if ret_node != 0 and self.ast.kind(ret_node) == NK_TYPE_NAMED and self.ast.get_data0(ret_node) == self_type_sym:
            self.emit_trait_object_safety_error(trait_sym, method_sym, "returns Self", node)
            return 0

    1

fn Sema.validate_type_expr_with_type_params(self: Sema, node: i32, tp_start: i32, tp_count: i32):
    if node == 0:
        return

    let kind = self.ast.kind(node)
    if kind == NK_TYPE_NAMED:
        let sym = self.ast.get_data0(node)
        if self.primitive_type_by_sym(sym) != 0:
            return
        if self.named_types.contains(sym):
            return
        if self.type_param_exists(tp_start, tp_count, sym) != 0:
            return
        // Allow Self in method contexts (resolved at codegen time)
        if self.pool_resolve(sym) == "Self":
            return
        self.debug_unknown_type(sym, node, "validate_type_expr")
        self.emit_unknown_type_error(sym, node)
        return

    if kind == NK_TYPE_PTR or kind == NK_TYPE_REF or kind == NK_TYPE_OPTIONAL or kind == NK_TYPE_SLICE or kind == NK_TYPE_ARRAY:
        self.validate_type_expr_with_type_params(self.ast.get_data0(node), tp_start, tp_count)
        return

    if kind == NK_TYPE_FN:
        let extra_start = self.ast.get_data0(node)
        let param_count = self.ast.get_data1(node)
        let ret_node = self.ast.get_data2(node)
        for pi in 0..param_count:
            self.validate_type_expr_with_type_params(self.ast.get_extra(extra_start + pi), tp_start, tp_count)
        self.validate_type_expr_with_type_params(ret_node, tp_start, tp_count)
        return

    if kind == NK_TYPE_TUPLE:
        let extra_start = self.ast.get_data0(node)
        let elem_count = self.ast.get_data1(node)
        for ei in 0..elem_count:
            self.validate_type_expr_with_type_params(self.ast.get_extra(extra_start + ei), tp_start, tp_count)
        return

    if kind == NK_TYPE_GENERIC:
        let base_sym = self.ast.get_data0(node)
        let base_prim = self.primitive_type_by_sym(base_sym)
        if base_prim == 0 and not self.named_types.contains(base_sym) and self.type_param_exists(tp_start, tp_count, base_sym) == 0:
            self.debug_unknown_type(base_sym, node, "validate_type_generic")
            self.emit_unknown_type_error(base_sym, node)
        let extra_start = self.ast.get_data1(node)
        let arg_count = self.ast.get_data2(node)
        for ai in 0..arg_count:
            self.validate_type_expr_with_type_params(self.ast.get_extra(extra_start + ai), tp_start, tp_count)
        return

    if kind == NK_TYPE_TRAIT_OBJ:
        let trait_sym = self.ast.get_data0(node)
        let trait_name = self.pool_resolve(trait_sym)
        let is_builtin_trait = sema_is_builtin_trait_name(trait_name)
        if not is_builtin_trait and not self.trait_lookup.contains(trait_sym):
            self.emit_error("unknown trait", node)
            return
        let _ok = self.ensure_trait_object_safe(trait_sym, node)
        return

fn Sema.validate_where_clause(self: Sema, fn_node: i32, tp_start: i32, tp_count: i32):
    let where_idx = self.ast.find_where_meta(fn_node)
    if where_idx < 0:
        return
    let where_start = self.ast.where_meta.get((where_idx + 1) as i64)
    let where_count = self.ast.where_meta.get((where_idx + 2) as i64)
    var pos = where_start
    for wi in 0..where_count:
        let wp_name = self.ast.get_extra(pos)
        let bound_count = self.ast.get_extra(pos + 1)
        // Validate type param references a known type parameter
        if self.type_param_exists(tp_start, tp_count, wp_name) == 0:
            let wp_str = self.pool_resolve(wp_name)
            self.emit_error("where clause references unknown type parameter '" ++ wp_str ++ "'", fn_node)
        // Validate each bound references a known trait
        for bi in 0..bound_count:
            let trait_sym = self.ast.get_extra(pos + 2 + bi)
            let trait_name = self.pool_resolve(trait_sym)
            if trait_name == "type":
                continue
            let is_builtin = sema_is_builtin_trait_name(trait_name)
            if not is_builtin and not self.trait_lookup.contains(trait_sym):
                self.emit_error("where clause references unknown trait '" ++ trait_name ++ "'", fn_node)
        pos = pos + 2 + bound_count

fn Sema.type_decl_enum_tail_index(self: Sema, extra_start: i32) -> i32:
    var pos = extra_start
    let variant_count = self.ast.get_extra(pos)
    pos = pos + 1
    for vi in 0..variant_count:
        pos = pos + 1 // variant name
        let payload_count = self.ast.get_extra(pos)
        pos = pos + 1 + payload_count
    pos

fn Sema.type_decl_disc_enum_tail_index(self: Sema, extra_start: i32) -> i32:
    var pos = extra_start + 1 // skip repr_type_node
    let variant_count = self.ast.get_extra(pos)
    pos = pos + 1
    for vi in 0..variant_count:
        pos = pos + 1 // variant name
        pos = pos + 1 // disc value
        let payload_count = self.ast.get_extra(pos)
        pos = pos + 1 + payload_count
    pos

fn Sema.type_decl_tp_start(self: Sema, node: i32) -> i32:
    let extra_start = self.ast.get_data1(node)
    let sub_kind = type_decl_sub_kind(self.ast.get_data2(node))
    if sub_kind == TDK_STRUCT:
        let field_count = self.ast.get_extra(extra_start)
        return self.ast.get_extra(extra_start + 1 + field_count * 4 + 1)
    if sub_kind == TDK_ENUM:
        let tail = self.type_decl_enum_tail_index(extra_start)
        return self.ast.get_extra(tail + 1)
    if sub_kind == TDK_DISC_ENUM:
        let tail = self.type_decl_disc_enum_tail_index(extra_start)
        return self.ast.get_extra(tail + 1)
    if sub_kind == TDK_ALIAS or sub_kind == TDK_DISTINCT:
        return self.ast.get_extra(extra_start + 2)
    0

fn Sema.type_decl_tp_count(self: Sema, node: i32) -> i32:
    let extra_start = self.ast.get_data1(node)
    let sub_kind = type_decl_sub_kind(self.ast.get_data2(node))
    if sub_kind == TDK_STRUCT:
        let field_count = self.ast.get_extra(extra_start)
        return self.ast.get_extra(extra_start + 1 + field_count * 4 + 2)
    if sub_kind == TDK_ENUM:
        let tail = self.type_decl_enum_tail_index(extra_start)
        return self.ast.get_extra(tail + 2)
    if sub_kind == TDK_DISC_ENUM:
        let tail = self.type_decl_disc_enum_tail_index(extra_start)
        return self.ast.get_extra(tail + 2)
    if sub_kind == TDK_ALIAS or sub_kind == TDK_DISTINCT:
        return self.ast.get_extra(extra_start + 3)
    0

fn Sema.type_decl_has_derive(self: Sema, node: i32, trait_sym: i32) -> i32:
    let meta = self.ast.find_type_meta(node)
    if meta < 0:
        return 0
    let derive_start = self.ast.type_meta_derive_start(meta)
    let derive_count = self.ast.type_meta_derive_count(meta)
    for i in 0..derive_count:
        if self.ast.get_extra(derive_start + i) == trait_sym:
            return 1
    0

fn Sema.validate_copy_derives(self: Sema):
    let copy_sym = self.pool_intern("Copy")
    for di in 0..self.ast.decl_count():
        let decl = self.ast.get_decl(di)
        if self.ast.kind(decl) != NK_TYPE_DECL:
            continue
        if self.type_decl_has_derive(decl, copy_sym) == 0:
            continue

        let type_name = self.ast.get_data0(decl)
        if self.has_drop_method(type_name) != 0:
            self.emit_error("type cannot be both Copy and Drop", decl)
            continue

        if not self.named_types.contains(type_name):
            continue
        let tid = self.named_types.get(type_name).unwrap()
        let resolved = self.resolve_alias(tid)
        if self.get_type_kind(resolved) != TY_STRUCT:
            continue

        let te_start = self.get_type_d1(resolved)
        let field_count = self.get_type_d2(resolved)
        var has_noncopy_field = 0
        for fi in 0..field_count:
            let field_tid = self.type_extra.get((te_start + fi * 3 + 1) as i64)
            if field_tid == 0 or self.is_copy(field_tid) == 0:
                has_noncopy_field = 1
                break
        if has_noncopy_field != 0:
            self.emit_error("cannot derive Copy for a type with non-Copy fields", decl)

fn Sema.validate_generic_type_decls(self: Sema):
    for di in 0..self.ast.decl_count():
        let decl = self.ast.get_decl(di)
        if self.ast.kind(decl) != NK_TYPE_DECL:
            continue

        let tp_count = self.type_decl_tp_count(decl)
        if tp_count <= 0:
            continue
        let tp_start = self.type_decl_tp_start(decl)
        let extra_start = self.ast.get_data1(decl)
        let sub_kind = type_decl_sub_kind(self.ast.get_data2(decl))

        if sub_kind == TDK_STRUCT:
            let field_count = self.ast.get_extra(extra_start)
            for fi in 0..field_count:
                let field_type = self.ast.get_extra(extra_start + 1 + fi * 3 + 1)
                self.validate_type_expr_with_type_params(field_type, tp_start, tp_count)
            continue

        if sub_kind == TDK_ENUM:
            var pos = extra_start
            let variant_count = self.ast.get_extra(pos)
            pos = pos + 1
            for vi in 0..variant_count:
                pos = pos + 1 // variant name
                let payload_count = self.ast.get_extra(pos)
                pos = pos + 1
                for pi in 0..payload_count:
                    let payload_ty = self.ast.get_extra(pos + pi)
                    self.validate_type_expr_with_type_params(payload_ty, tp_start, tp_count)
                pos = pos + payload_count
            continue

        if sub_kind == TDK_DISC_ENUM:
            var pos = extra_start + 1 // skip repr_type_node
            let variant_count = self.ast.get_extra(pos)
            pos = pos + 1
            for vi in 0..variant_count:
                pos = pos + 1 // variant name
                pos = pos + 1 // disc value
                let payload_count = self.ast.get_extra(pos)
                pos = pos + 1
                for pi in 0..payload_count:
                    let payload_ty = self.ast.get_extra(pos + pi)
                    self.validate_type_expr_with_type_params(payload_ty, tp_start, tp_count)
                pos = pos + payload_count
            continue

        if sub_kind == TDK_ALIAS or sub_kind == TDK_DISTINCT:
            self.validate_type_expr_with_type_params(self.ast.get_extra(extra_start), tp_start, tp_count)

fn Sema.type_expr_mentions_type_param(self: Sema, type_node: i32, tp_sym: i32) -> i32:
    if type_node == 0:
        return 0
    let kind = self.ast.kind(type_node)
    if kind == NK_TYPE_NAMED:
        return if self.ast.get_data0(type_node) == tp_sym: 1 else: 0
    if kind == NK_TYPE_GENERIC:
        if self.ast.get_data0(type_node) == tp_sym:
            return 1
        let extra_start = self.ast.get_data1(type_node)
        let arg_count = self.ast.get_data2(type_node)
        for ai in 0..arg_count:
            if self.type_expr_mentions_type_param(self.ast.get_extra(extra_start + ai), tp_sym) != 0:
                return 1
        return 0
    if kind == NK_TYPE_PTR or kind == NK_TYPE_REF or kind == NK_TYPE_OPTIONAL or kind == NK_TYPE_SLICE or kind == NK_TYPE_ARRAY:
        return self.type_expr_mentions_type_param(self.ast.get_data0(type_node), tp_sym)
    if kind == NK_TYPE_TUPLE:
        let extra_start = self.ast.get_data0(type_node)
        let elem_count = self.ast.get_data1(type_node)
        for ei in 0..elem_count:
            if self.type_expr_mentions_type_param(self.ast.get_extra(extra_start + ei), tp_sym) != 0:
                return 1
        return 0
    if kind == NK_TYPE_FN:
        let extra_start = self.ast.get_data0(type_node)
        let param_count = self.ast.get_data1(type_node)
        for pi in 0..param_count:
            if self.type_expr_mentions_type_param(self.ast.get_extra(extra_start + pi), tp_sym) != 0:
                return 1
        return self.type_expr_mentions_type_param(self.ast.get_data2(type_node), tp_sym)
    0

fn Sema.type_param_mentions_any_param_type(self: Sema, tp_sym: i32, param_start: i32, param_count: i32) -> i32:
    for pi in 0..param_count:
        let p_type_node = self.ast.fn_param_type(param_start, pi)
        if self.type_expr_mentions_type_param(p_type_node, tp_sym) != 0:
            return 1
    0

fn Sema.ensure_generic_substitutions(self: Sema, tp_start: i32, tp_count: i32, param_start: i32, param_count: i32, call_node: i32):
    var pos = tp_start
    for ti in 0..tp_count:
        let tp_name = self.ast.get_extra(pos)
        let bound_count = self.ast.get_extra(pos + 1)
        if self.lookup_generic_subst(tp_name) == 0:
            if self.type_param_mentions_any_param_type(tp_name, param_start, param_count) != 0:
                self.put_generic_subst(tp_name, self.ty_i32, call_node)
            else:
                self.emit_error("unknown type", call_node)
                return
        pos = pos + 2 + bound_count

fn Sema.primitive_type_by_sym(self: Sema, sym: i32) -> i32:
    let name = self.pool_resolve_symbol(sym)
    if with_str_eq(name, "i8") != 0: return self.ty_i8
    if with_str_eq(name, "i16") != 0: return self.ty_i16
    if with_str_eq(name, "i32") != 0: return self.ty_i32
    if with_str_eq(name, "i64") != 0: return self.ty_i64
    if with_str_eq(name, "i128") != 0: return self.ty_i128
    if with_str_eq(name, "u8") != 0: return self.ty_u8
    if with_str_eq(name, "u16") != 0: return self.ty_u16
    if with_str_eq(name, "u32") != 0: return self.ty_u32
    if with_str_eq(name, "u64") != 0: return self.ty_u64
    if with_str_eq(name, "u128") != 0: return self.ty_u128
    if with_str_eq(name, "f32") != 0: return self.ty_f32
    if with_str_eq(name, "f64") != 0: return self.ty_f64
    if with_str_eq(name, "bool") != 0: return self.ty_bool
    if with_str_eq(name, "void") != 0: return self.ty_void
    if with_str_eq(name, "Never") != 0: return self.ty_never
    if with_str_eq(name, "str") != 0: return self.ty_str
    if with_str_eq(name, "String") != 0: return self.ty_str
    if with_str_eq(name, "StrView") != 0: return self.ty_str_view
    if with_str_eq(name, "usize") != 0: return self.ty_usize
    if with_str_eq(name, "isize") != 0: return self.ty_isize
    0

// ── Type expression resolution ───────────────────────────────────

fn Sema.resolve_type_expr(self: Sema, node: i32) -> i32:
    if node == 0:
        return 0

    let kind = self.ast.kind(node)

    if kind == NK_TYPE_NAMED:
        let sym = self.ast.get_data0(node)
        let prim = self.primitive_type_by_sym(sym)
        if prim != 0:
            return prim
        if self.named_types.contains(sym) and (self.collecting_types != 0 or self.is_ci_visible(sym) != 0):
            return self.named_types.get(sym).unwrap()
        // Self is resolved at codegen time
        let sym_name = self.pool_resolve(sym)
        if sym_name == "Self":
            return 0
        if self.collecting_types != 0:
            return 0
        self.debug_unknown_type(sym, node, "resolve_type_expr")
        self.emit_unknown_type_error(sym, node)
        return 0

    if kind == NK_TYPE_ASSOC:
        let base_sym = self.ast.get_data0(node)
        let assoc_sym = self.ast.get_data1(node)
        if self.pool_resolve(base_sym) == "Self":
            if self.assoc_type_bindings.contains(assoc_sym):
                return self.assoc_type_bindings.get(assoc_sym).unwrap()
        // Type parameter: look up concrete type via generic substitution
        let concrete = self.lookup_generic_subst(base_sym)
        if concrete != 0:
            let concrete_sym = self.get_type_d0(concrete)
            if concrete_sym != 0:
                // Find which trait provides assoc_sym for concrete_sym
                for ti in 0..self.trait_name_syms.len() as i32:
                    let at_start_t = self.trait_assoc_starts.get(ti as i64)
                    let at_count_t = self.trait_assoc_counts.get(ti as i64)
                    for ai in 0..at_count_t:
                        if self.trait_assoc_names.get((at_start_t + ai) as i64) == assoc_sym:
                            let trait_sym_t = self.trait_name_syms.get(ti as i64)
                            if self.select_trait_impl(concrete_sym, trait_sym_t) != 0:
                                let resolved_at = self.resolve_impl_assoc_type(concrete_sym, trait_sym_t, assoc_sym)
                                if resolved_at != 0:
                                    return resolved_at
        return 0

    if kind == NK_TYPE_GENERIC:
        return self.resolve_generic_type(node)

    if kind == NK_TYPE_PTR:
        let pointee = self.resolve_type_expr(self.ast.get_data0(node))
        let is_mut = self.ast.get_data1(node)
        let is_volatile = self.ast.get_data2(node)
        return self.ensure_exact_type(TY_PTR, pointee, is_mut, is_volatile)

    if kind == NK_TYPE_REF:
        let pointee = self.resolve_type_expr(self.ast.get_data0(node))
        let is_mut = self.ast.get_data1(node)
        return self.ensure_exact_type(TY_REF, pointee, is_mut, 0)

    if kind == NK_TYPE_FN:
        let extra_start = self.ast.get_data0(node)
        let param_count = self.ast.get_data1(node)
        let ret_node = self.ast.get_data2(node)
        let param_types: Vec[i32] = Vec.new()
        for pi in 0..param_count:
            let p_node = self.ast.get_extra(extra_start + pi)
            param_types.push(self.resolve_type_expr(p_node))
        let ret = self.resolve_type_expr(ret_node)
        return self.ensure_fn_type(param_types, param_count, ret)

    if kind == NK_TYPE_ARRAY:
        let elem = self.resolve_type_expr(self.ast.get_data0(node))
        let size = self.ast.get_data1(node)
        return self.ensure_exact_type(TY_ARRAY, elem, size, 0)

    if kind == NK_TYPE_SLICE:
        let elem = self.resolve_type_expr(self.ast.get_data0(node))
        return self.ensure_exact_type(TY_SLICE, elem, 0, 0)

    if kind == NK_TYPE_TUPLE:
        let extra_start = self.ast.get_data0(node)
        let elem_count = self.ast.get_data1(node)
        let tuple_elems: Vec[i32] = Vec.new()
        for ei in 0..elem_count:
            let e_node = self.ast.get_extra(extra_start + ei)
            tuple_elems.push(self.resolve_type_expr(e_node))
        return self.ensure_tuple_type(tuple_elems, elem_count)

    if kind == NK_TYPE_OPTIONAL:
        let inner = self.resolve_type_expr(self.ast.get_data0(node))
        // Optional lowering remains deferred in bootstrap sema path.
        return 0

    if kind == NK_TYPE_TRAIT_OBJ:
        let trait_sym = self.ast.get_data0(node)
        let trait_name = self.pool_resolve(trait_sym)
        let is_builtin_trait = sema_is_builtin_trait_name(trait_name)
        if not is_builtin_trait and not self.trait_lookup.contains(trait_sym):
            self.emit_error("unknown trait", node)
            return 0
        if self.ensure_trait_object_safe(trait_sym, node) == 0:
            return 0
        return self.ensure_exact_type(TY_TRAIT_OBJ, trait_sym, 0, 0)

    if kind == NK_TYPE_INFERRED:
        return 0

    // @TypeOf(expr) — in generic functions, resolved at monomorphization time
    // via resolve_generic_return_type_node. Return a placeholder here.
    if kind == NK_TYPE_TYPEOF:
        return self.ty_i32

    0

// ── Pass 2: Check function bodies ────────────────────────────────

fn Sema.update_module_context(self: Sema, di: i32):
    if self.scoping_active == 0:
        return
    if di < self.decl_source_paths.len() as i32:
        let path = self.decl_source_paths.get(di as i64)
        if path != self.current_module_path:
            self.current_module_path = path
            let path_sym = self.pool_intern(path)
            self.current_module_has_ci = if self.ci_modules.contains(path_sym): 1 else: 0

fn Sema.update_decl_source_context(self: Sema, di: i32):
    self.local_file_id = 0
    if di >= 0 and di < self.decl_source_file_ids.len() as i32:
        self.local_file_id = self.decl_source_file_ids.get(di as i64)
    self.update_module_context(di)

fn Sema.check_bodies(self: Sema):
    for di in 0..self.ast.decl_count():
        self.update_decl_source_context(di)
        let decl = self.ast.get_decl(di)
        if self.ast.kind(decl) == NK_FN_DECL:
            let fn_name = self.ast.get_data0(decl)
            if self.should_skip_trait_method(di, fn_name) == 0:
                // Skip shadowed functions: if a later decl registered with
                // the same name, this decl's body would be checked against
                // the wrong signature. The shadowed function is unreachable.
                if self.fn_decl_nodes.contains(fn_name):
                    let active_node = self.fn_decl_nodes.get(fn_name).unwrap()
                    if active_node != decl:
                        continue
                // Skip generic functions
                let meta = self.ast.find_fn_meta(decl)
                var tp_count = 0
                if meta >= 0:
                    tp_count = self.ast.fn_meta_tp_count(meta)
                if tp_count == 0:
                    // Skip methods on generic structs (monomorphized lazily)
                    let fn_name_sym = self.ast.get_data0(decl)
                    let fn_name_str = self.pool_resolve_symbol(fn_name_sym)
                    var is_generic_struct_method = false
                    for gsm_i in 0..fn_name_str.len() as i32:
                        if fn_name_str.byte_at(gsm_i as i64) == 46:
                            let owner_name = fn_name_str.slice(0, gsm_i as i64)
                            let owner_sym = self.pool_intern(owner_name)
                            if self.type_decl_nodes.contains(owner_sym):
                                let td_node = self.type_decl_nodes.get(owner_sym).unwrap()
                                if self.type_decl_tp_count(td_node) > 0:
                                    let gsm_p_start = self.ast.fn_meta_param_start(meta)
                                    let gsm_p_count = self.ast.fn_meta_param_count(meta)
                                    if gsm_p_count > 0:
                                        let p0_tn = self.ast.fn_param_type(gsm_p_start, 0)
                                        if p0_tn != 0 and self.ast.kind(p0_tn) == NK_TYPE_GENERIC:
                                            is_generic_struct_method = true
                            break
                    if not is_generic_struct_method:
                        self.update_module_context(di)
                        self.check_fn_body(decl)

fn Sema.check_fn_body(self: Sema, node: i32):
    let fn_name = self.ast.get_data0(node)
    let body = self.ast.get_data1(node)
    let flags = self.ast.get_data2(node)
    let sig_idx = self.get_sig(fn_name)
    if sig_idx < 0:
        return

    let ret_type = self.sig_return_type(sig_idx)

    // Active borrows are per-function state.
    while self.borrow_kinds.len() > 0:
        self.borrow_kinds.pop()
        self.borrow_places.pop()
        self.borrow_fields.pop()
        self.borrow_refs.pop()
        self.borrow_path_starts.pop()
        self.borrow_path_counts.pop()

    // Push function scope
    self.push_scope()

    // Set up associated type bindings if inside a trait impl
    self.assoc_type_bindings.clear()
    if self.method_impl_nodes.contains(fn_name):
        let impl_nd = self.method_impl_nodes.get(fn_name).unwrap()
        let impl_ex = self.ast.get_data1(impl_nd)
        let impl_ac = self.ast.get_extra(impl_ex)
        for iai in 0..impl_ac:
            let at_name = self.ast.get_extra(impl_ex + 1 + iai * 2)
            let at_type_nd = self.ast.get_extra(impl_ex + 1 + iai * 2 + 1)
            let at_tid = self.resolve_type_expr(at_type_nd)
            if at_tid != 0:
                self.assoc_type_bindings.insert(at_name, at_tid)

    // Add parameters to scope
    let meta = self.ast.find_fn_meta(node)
    if meta >= 0:
        let param_start = self.ast.fn_meta_param_start(meta)
        let param_count = self.ast.fn_meta_param_count(meta)
        for pi in 0..param_count:
            let p_name = self.ast.fn_param_name(param_start, pi)
            let p_tid = self.sig_param_type(sig_idx, pi)
            self.scope_put(p_name, p_tid, 0)
        let pmeta = self.ast.find_fn_param_pattern_meta(node)
        if pmeta >= 0:
            let ppat_start = self.ast.fn_param_pattern_meta_start(pmeta)
            let ppat_count = self.ast.fn_param_pattern_meta_count(pmeta)
            let apply_count = if ppat_count < param_count: ppat_count else: param_count
            for pi in 0..apply_count:
                let ppat = self.ast.fn_param_pattern_value(ppat_start + pi)
                if ppat != 0:
                    self.check_pattern(ppat, self.sig_param_type(sig_idx, pi))

    // Set current return type
    let saved_ret = self.current_return_type
    let saved_gen_yield_type = self.current_gen_yield_type
    let saved_has_gen_yield_type = self.has_gen_yield_type
    let is_gen = (flags / FN_FLAG_GEN) % 2
    if is_gen == 1:
        self.current_return_type = self.ty_void
        self.current_gen_yield_type = ret_type
        self.has_gen_yield_type = 1
    else:
        self.current_return_type = ret_type
        self.current_gen_yield_type = 0
        self.has_gen_yield_type = 0
    let saved_comptime = self.in_comptime_fn
    if (flags / FN_FLAG_COMPTIME) % 2 == 1:
        self.in_comptime_fn = 1

    // Check body — set expected type to return type for tail expression resolution
    let saved_expected_et = self.expected_expr_type
    let saved_has_et = self.has_expected_type
    if ret_type != 0 and ret_type != self.ty_void:
        self.expected_expr_type = ret_type
        self.has_expected_type = 1
    let body_ty = self.check_expr(body)
    self.expected_expr_type = saved_expected_et
    self.has_expected_type = saved_has_et
    self.typed_expr_types.insert(body, body_ty)
    let has_ret_annotation = meta >= 0 and self.ast.fn_meta_ret(meta) != 0
    if not has_ret_annotation:
        let inferred_ret = if body_ty != 0: body_ty else: self.ty_void
        self.set_sig_return_type(sig_idx, inferred_ret)
    else if ret_type != 0 and body_ty != 0 and body_ty != self.ty_void and ret_type != self.ty_void:
        // Check tail expression type against declared return type
        let compat = self.types_compatible(ret_type, body_ty)
        if compat == 0:
            let arith = self.arithmetic_result_type(ret_type, body_ty)
            if arith == 0:
                // Implicit Ok wrapping: if ret_type is Result[T, E] and body_ty is compatible with T
                var ok_wrapped = false
                let ret_resolved = self.resolve_alias(ret_type)
                if self.get_type_kind(ret_resolved) == TY_GENERIC_INST:
                    let base_sym = self.get_generic_inst_base(ret_resolved)
                    if self.pool_resolve(base_sym) == "Result" and self.get_generic_inst_arg_count(ret_resolved) == 2:
                        let ok_type = self.get_generic_inst_arg(ret_resolved, 0)
                        if self.types_compatible(ok_type, body_ty) != 0 or self.arithmetic_result_type(ok_type, body_ty) != 0:
                            ok_wrapped = true
                if not ok_wrapped:
                    self.emit_error("return type mismatch", body)

    // Restore state
    self.current_return_type = saved_ret
    self.current_gen_yield_type = saved_gen_yield_type
    self.has_gen_yield_type = saved_has_gen_yield_type
    self.in_comptime_fn = saved_comptime
    self.pop_scope()

// ── Concrete type-checking for monomorphized generic functions ───
// Type-checks a generic function body with concrete type substitutions,
// populating typed_expr_types so MirLower has type information.
// Returns the sig index for the concrete signature.

fn Sema.check_fn_body_concrete(self: Sema, fn_node: i32, tp_syms: Vec[i32], tp_sema_tys: Vec[i32], mono_sym: i32) -> i32:
    let fn_name = self.ast.get_data0(fn_node)
    let body = self.ast.get_data1(fn_node)
    let meta = self.ast.find_fn_meta(fn_node)
    if meta < 0:
        return 0 - 1

    let tp_count = tp_syms.len() as i32

    // Save named_types entries for type params and install concrete types
    let saved_named: Vec[i32] = Vec.new()
    let saved_had: Vec[i32] = Vec.new()
    for ti in 0..tp_count:
        let tp_sym = tp_syms.get(ti as i64)
        if self.named_types.contains(tp_sym):
            saved_had.push(1)
            saved_named.push(self.named_types.get(tp_sym).unwrap())
        else:
            saved_had.push(0)
            saved_named.push(0)
        let tp_sema_ty = tp_sema_tys.get(ti as i64)
        self.named_types.insert(tp_sym, tp_sema_ty)

    // Resolve param types with concrete substitutions
    let param_start = self.ast.fn_meta_param_start(meta)
    let param_count = self.ast.fn_meta_param_count(meta)
    let ret_type_node = self.ast.fn_meta_ret(meta)

    let ps = self.sig_params.len() as i32
    for pi in 0..param_count:
        let p_type_node = self.ast.fn_param_type(param_start, pi)
        let p_tid = if p_type_node != 0: self.resolve_type_expr(p_type_node) else: 0
        self.sig_params.push(p_tid)

    let ret_tid = if ret_type_node != 0: self.resolve_type_expr(ret_type_node) else: self.ty_void

    // Save existing sig for fn_name (if any) and register mono sig temporarily
    let had_sig = self.sig_lookup.contains(fn_name)
    var saved_sig_idx = 0 - 1
    if had_sig:
        saved_sig_idx = self.sig_lookup.get(fn_name).unwrap()

    self.add_sig(fn_name, 0, ret_tid, ps, param_count, 0)
    let sig_idx = self.get_sig(fn_name)

    // Also register under mono_sym for later lookup
    self.sig_lookup.insert(mono_sym, sig_idx)

    // Suppress errors — generic bodies were validated at definition time
    let saved_suppress = self.suppress_errors
    self.suppress_errors = 1

    // Type-check body
    self.check_fn_body(fn_node)

    self.suppress_errors = saved_suppress

    // Restore sig_lookup for fn_name
    if had_sig:
        self.sig_lookup.insert(fn_name, saved_sig_idx)
    else:
        // Remove fn_name from sig_lookup — we keep it under mono_sym
        // Can't remove from HashMap, so insert a sentinel
        self.sig_lookup.insert(fn_name, sig_idx)

    // Restore named_types
    for ti in 0..tp_count:
        let tp_sym = tp_syms.get(ti as i64)
        if saved_had.get(ti as i64) == 1:
            self.named_types.insert(tp_sym, saved_named.get(ti as i64))
        // Note: can't remove from HashMap, leave as-is if wasn't present before

    sig_idx

// ── Expression type checking ─────────────────────────────────────

fn Sema.is_call_expr_task(self: Sema, node: i32) -> i32:
    if node == 0 or self.ast.kind(node) != NK_CALL:
        return 0
    let callee = self.ast.get_data0(node)
    if self.ast.kind(callee) == NK_IDENT:
        let fn_sym = self.ast.get_data0(callee)
        if self.task_fns.contains(fn_sym):
            return 1
    if self.ast.kind(callee) == NK_FIELD_ACCESS:
        let recv = self.ast.get_data0(callee)
        let method = self.ast.get_data1(callee)
        if self.ast.kind(recv) == NK_IDENT and self.is_active_async_scope_symbol(self.ast.get_data0(recv)) != 0 and self.pool_resolve(method) == "track":
            return 1
    0

fn Sema.expr_is_tuple_of_tasks(self: Sema, node: i32) -> i32:
    if node == 0 or self.ast.kind(node) != NK_TUPLE:
        return 0
    let extra_start = self.ast.get_data0(node)
    let elem_count = self.ast.get_data1(node)
    if elem_count < 2 or elem_count > 12:
        return 0
    for ei in 0..elem_count:
        if self.expr_is_task_value(self.ast.get_extra(extra_start + ei)) == 0:
            return 0
    1

fn Sema.expr_is_task_value(self: Sema, node: i32) -> i32:
    if node == 0:
        return 0
    let kind = self.ast.kind(node)
    if kind == NK_GROUPED:
        return self.expr_is_task_value(self.ast.get_data0(node))
    if kind == NK_ASYNC_BLOCK:
        return 1
    if kind == NK_CALL:
        return self.is_call_expr_task(node)
    if kind == NK_IDENT:
        return self.scope_lookup_is_task(self.ast.get_data0(node))
    if kind == NK_INDEX or kind == NK_FIELD_ACCESS or kind == NK_OPTIONAL_CHAIN:
        // Conservative task-container handling.
        return 1
    if kind == NK_TUPLE:
        return self.expr_is_tuple_of_tasks(node)
    0

fn Sema.expr_is_scoped_task_value(self: Sema, node: i32) -> i32:
    if node == 0:
        return 0
    let kind = self.ast.kind(node)
    if kind == NK_GROUPED:
        return self.expr_is_scoped_task_value(self.ast.get_data0(node))
    if kind == NK_IDENT:
        return self.scope_lookup_is_scoped_task(self.ast.get_data0(node))
    if kind == NK_CALL:
        let callee = self.ast.get_data0(node)
        if self.ast.kind(callee) == NK_FIELD_ACCESS:
            let recv = self.ast.get_data0(callee)
            let method = self.ast.get_data1(callee)
            if self.ast.kind(recv) == NK_IDENT and self.is_active_async_scope_symbol(self.ast.get_data0(recv)) != 0 and self.pool_resolve(method) == "track":
                return 1
    0

fn Sema.has_live_await_guard(self: Sema) -> i32:
    var i = self.bind_names.len() as i32 - 1
    while i >= 0:
        if self.bind_states.get(i as i64) == VS_LIVE:
            let name = self.pool_resolve(self.bind_names.get(i as i64))
            if name.ends_with("_guard"):
                return 1
        i = i - 1
    0

fn Sema.param_is_by_reference(self: Sema, tid: i32) -> i32:
    if tid == 0:
        return 0
    let resolved = self.resolve_alias(tid)
    let tk = self.get_type_kind(resolved)
    if tk == TY_REF or tk == TY_PTR:
        return 1
    0

fn Sema.expr_is_ephemeral_task(self: Sema, node: i32) -> i32:
    if node == 0:
        return 0
    let kind = self.ast.kind(node)
    if kind == NK_GROUPED:
        return self.expr_is_ephemeral_task(self.ast.get_data0(node))
    if kind == NK_IDENT:
        return self.scope_lookup_is_ephemeral_task(self.ast.get_data0(node))
    if kind == NK_ASYNC_BLOCK:
        return self.expr_is_ephemeral_value(self.ast.get_data0(node))
    if kind == NK_CALL:
        let callee = self.ast.get_data0(node)
        if self.ast.kind(callee) == NK_IDENT:
            let fn_sym = self.ast.get_data0(callee)
            if self.task_fns.contains(fn_sym):
                let args_start = self.ast.get_data1(node)
                let arg_count = self.ast.get_data2(node)
                for ai in 0..arg_count:
                    if self.expr_is_ephemeral_value(self.ast.get_extra(args_start + ai)) != 0:
                        return 1
        return 0
    0

fn Sema.expr_is_ephemeral_value(self: Sema, node: i32) -> i32:
    if node == 0:
        return 0
    let kind = self.ast.kind(node)
    if kind == NK_GROUPED:
        return self.expr_is_ephemeral_value(self.ast.get_data0(node))
    if kind == NK_IDENT:
        let sym = self.ast.get_data0(node)
        if self.scope_lookup_is_ephemeral_task(sym) != 0:
            return 1
        let tid = self.scope_lookup(sym)
        if tid >= 0:
            return self.type_is_ephemeral_value(tid)
        return 0
    if kind == NK_UNARY:
        let op = self.ast.get_data0(node)
        if op == UOP_REF or op == UOP_MUT_REF:
            return 1
        return self.expr_is_ephemeral_value(self.ast.get_data1(node))
    if kind == NK_SLICE:
        return 1
    if kind == NK_CALL:
        return self.expr_is_ephemeral_task(node)
    0

fn Sema.check_expr(self: Sema, node: i32) -> i32:
    if node == 0:
        return 0

    let kind = self.ast.kind(node)

    if kind == NK_INT_LIT:
        let value = self.ast.int_lit_value(node)
        let suffix_ty = self.literal_suffix_type(self.ast.literal_suffix(node))
        if suffix_ty != 0:
            if self.int_literal_fits_type(value, suffix_ty) == false:
                self.emit_error("integer literal does not fit suffix type", node)
            self.typed_expr_types.insert(node, suffix_ty)
            return suffix_ty
        let expected_ty = self.numeric_literal_expected_type(node, value)
        if expected_ty != 0:
            self.typed_expr_types.insert(node, expected_ty)
            return expected_ty
        let ty = if value < -2147483648 or value > 2147483647: self.ty_i64 else: self.ty_i32
        self.typed_expr_types.insert(node, ty)
        return ty

    if kind == NK_FLOAT_LIT:
        let suffix = self.ast.literal_suffix(node)
        let suffix_ty = self.literal_suffix_type(suffix)
        if suffix_ty != 0:
            let resolved_suffix = self.resolve_alias(suffix_ty)
            if self.get_type_kind(resolved_suffix) != TY_FLOAT:
                self.emit_error("float literal requires an f32 or f64 suffix", node)
            self.typed_expr_types.insert(node, suffix_ty)
            return suffix_ty
        let expected_ty = self.float_literal_expected_type()
        if expected_ty != 0:
            self.typed_expr_types.insert(node, expected_ty)
            return expected_ty
        self.typed_expr_types.insert(node, self.ty_f64)
        return self.ty_f64

    if kind == NK_BOOL_LIT:
        return self.ty_bool

    if kind == NK_STRING_LIT:
        return self.ty_str

    if kind == NK_C_STRING_LIT:
        return self.ty_const_i8_ptr

    if kind == NK_NULL_LIT:
        if self.has_expected_type != 0 and self.expected_expr_type != 0:
            let expected = self.resolve_alias(self.expected_expr_type)
            let expected_kind = self.get_type_kind(expected)
            if expected_kind == TY_PTR or expected_kind == TY_REF or self.is_option_pointer_type(expected) != 0:
                return expected
        return self.ty_const_i8_ptr

    if kind == NK_IDENT:
        return self.check_ident(self.ast.get_data0(node), node)

    if kind == NK_BINARY:
        return self.check_binary(node)

    if kind == NK_UNARY:
        return self.check_unary(node)

    if kind == NK_GROUPED:
        return self.check_expr(self.ast.get_data0(node))

    if kind == NK_BLOCK:
        return self.check_block(node)

    if kind == NK_LET_BINDING:
        return self.check_let_binding(node)

    if kind == NK_IF_EXPR:
        return self.check_if_expr(node)

    if kind == NK_CALL:
        return self.check_call(node)

    if kind == NK_RETURN:
        return self.check_return(node)

    if kind == NK_ASSIGN:
        return self.check_assign(node)

    if kind == NK_WHILE:
        let cond = self.ast.get_data0(node)
        let body = self.ast.get_data1(node)
        self.check_expr(cond)
        self.loop_depth = self.loop_depth + 1
        self.check_expr(body)
        self.loop_depth = self.loop_depth - 1
        return self.ty_void

    if kind == NK_LOOP:
        let saved_break = self.break_value_type
        let saved_has = self.has_break_value_type
        self.break_value_type = 0
        self.has_break_value_type = 0
        self.loop_depth = self.loop_depth + 1
        self.check_expr(self.ast.get_data0(node))
        self.loop_depth = self.loop_depth - 1
        var result = self.ty_void
        if self.has_break_value_type != 0:
            result = self.break_value_type
        self.break_value_type = saved_break
        self.has_break_value_type = saved_has
        return result

    if kind == NK_FOR:
        return self.check_for(node)

    if kind == NK_BREAK:
        if self.in_defer != 0:
            self.emit_error("break not allowed in defer", node)
        if self.loop_depth == 0:
            self.emit_error("break outside of loop", node)
        let val = self.ast.get_data0(node)
        if val != 0:
            let vt = self.check_expr(val)
            if vt != 0:
                if self.has_break_value_type == 0:
                    self.break_value_type = vt
                    self.has_break_value_type = 1
                else:
                    if self.types_compatible(self.break_value_type, vt) == 0:
                        let widened = self.arithmetic_result_type(self.break_value_type, vt)
                        if widened == 0:
                            self.emit_error("type mismatch in break value", node)
                        else:
                            self.break_value_type = widened
                    else:
                        self.break_value_type = vt
        return self.ty_void

    if kind == NK_CONTINUE:
        if self.in_defer != 0:
            self.emit_error("continue not allowed in defer", node)
        if self.loop_depth == 0:
            self.emit_error("continue outside of loop", node)
        return self.ty_void

    if kind == NK_FIELD_ACCESS:
        return self.check_field_access(node)

    if kind == NK_INDEX:
        return self.check_index(node)

    if kind == NK_SLICE:
        return self.check_slice(node)

    if kind == NK_ARRAY_LIT:
        return self.check_array_literal(node)

    if kind == NK_STRUCT_LIT:
        return self.check_struct_literal(node)

    if kind == NK_MATCH:
        return self.check_match_expr(node)

    if kind == NK_ENUM_VARIANT:
        return self.check_enum_variant(node)

    if kind == NK_CLOSURE:
        return self.check_closure(node)

    if kind == NK_CAST:
        self.check_expr_with_expected(self.ast.get_data0(node), 0)
        let cast_tid = self.resolve_type_expr(self.ast.get_data1(node))
        // Store resolved cast type so MIR lowering can read it without
        // calling resolve_type_expr (which would add_type on a shallow-copied Sema).
        self.typed_expr_types.insert(node, cast_tid)
        return cast_tid

    if kind == NK_PIPELINE:
        return self.check_pipeline(node)

    if kind == NK_UNSAFE_BLOCK:
        return self.check_expr(self.ast.get_data0(node))

    if kind == NK_COMPTIME_ERROR:
        return TY_NEVER

    if kind == NK_DEFER or kind == NK_ERRDEFER:
        let saved = self.in_defer
        self.in_defer = 1
        self.check_expr(self.ast.get_data0(node))
        self.in_defer = saved
        return self.ty_void

    if kind == NK_TUPLE:
        return self.check_tuple(node)

    if kind == NK_RANGE:
        return self.check_range(node)

    if kind == NK_VARIANT_SHORTHAND:
        let name = self.ast.get_data0(node)
        let expected_variant_ty = self.expected_variant_constructor_type(name)
        if expected_variant_ty != 0:
            self.typed_expr_types.insert(node, expected_variant_ty)
            return expected_variant_ty
        // Fall through to variant_lookup if expected type is not an enum
        // (e.g., function return type leaking through). Only error if the
        // expected type IS an enum that doesn't have this variant.
        if self.has_expected_type != 0 and self.expected_expr_type != 0:
            let exp_resolved = self.resolve_alias(self.expected_expr_type)
            let exp_kind = self.get_type_kind(exp_resolved)
            if exp_kind == TY_ENUM:
                self.emit_error("enum variant shorthand does not match expected enum type", node)
                return 0
        if self.variant_lookup.contains(name):
            let vs_tid = self.variant_type_ids.get(name).unwrap()
            self.typed_expr_types.insert(node, vs_tid)
            return vs_tid
        return 0

    if kind == NK_WITH_EXPR:
        return self.check_with_expr(node)

    if kind == NK_RECORD_UPDATE:
        return self.check_record_update(node)

    if kind == NK_LET_ELSE:
        return self.check_let_else(node)

    if kind == NK_TUPLE_DESTRUCTURE:
        return self.check_tuple_destructure(node)

    if kind == NK_AWAIT:
        if self.has_live_await_guard() != 0:
            self.emit_error("E0701: may_suspend call while no_await_guard value is live", node)
        let inner = self.ast.get_data0(node)
        let inner_ty = self.check_expr(inner)
        if self.ast.kind(inner) == NK_TUPLE:
            let elem_count = self.ast.get_data1(inner)
            if elem_count < 2 or elem_count > 12:
                self.emit_error("await tuple requires between 2 and 12 tasks", node)
                return inner_ty
            if self.expr_is_tuple_of_tasks(inner) == 0:
                self.emit_error("await tuple requires Task values", node)
                return inner_ty
            return inner_ty
        if self.expr_is_task_value(inner) == 0:
            self.emit_error("await requires a Task value", node)
        return inner_ty

    if kind == NK_ASYNC_BLOCK:
        return self.check_expr(self.ast.get_data0(node))

    if kind == NK_SPAWN:
        let inner = self.ast.get_data0(node)
        self.check_expr(inner)
        if self.expr_is_task_value(inner) == 0:
            self.emit_error("spawn requires a Task value", node)
        return self.ty_void

    if kind == NK_YIELD:
        let inner = self.check_expr(self.ast.get_data0(node))
        if self.has_gen_yield_type == 0:
            self.emit_error("yield used outside generator function", node)
        return self.ty_void

    if kind == NK_COMPTIME:
        return self.check_expr(self.ast.get_data0(node))

    if kind == NK_ASYNC_SCOPE:
        let body = self.ast.get_data1(node)
        let name = self.ast.get_data0(node)
        self.push_scope()
        self.scope_put(name, self.ty_void, 0)
        self.async_scope_names.push(name)
        let result = self.check_expr(body)
        self.async_scope_names.pop()
        self.pop_scope()
        return result

    if kind == NK_SELECT_AWAIT:
        if self.has_live_await_guard() != 0:
            self.emit_error("E0701: may_suspend call while no_await_guard value is live", node)
        let extra_start = self.ast.get_data0(node)
        let arm_count = self.ast.get_data1(node)
        if arm_count <= 0:
            self.emit_error("select await requires at least one arm", node)
            return self.ty_void
        var result = self.ty_void
        for ai in 0..arm_count:
            // Each select arm is encoded as: name_sym, task_node, body_node.
            let arm_name = self.ast.get_extra(extra_start + ai * 3)
            let task = self.ast.get_extra(extra_start + ai * 3 + 1)
            let arm_body = self.ast.get_extra(extra_start + ai * 3 + 2)
            let task_ty = self.check_expr(task)
            if self.expr_is_task_value(task) == 0:
                self.emit_error("select await arm requires a Task value", task)
            self.push_scope()
            self.scope_put(arm_name, task_ty, 0)
            self.scope_set_is_task(arm_name, 0)
            result = self.check_expr(arm_body)
            self.pop_scope()
        return result

    if kind == NK_ARRAY_COMPREHENSION:
        let expr = self.ast.get_data0(node)
        let binding = self.ast.get_data1(node)
        let iterable = self.ast.get_data2(node)
        self.push_scope()
        let iter_ty = self.check_expr(iterable)
        let elem_ty = self.infer_for_element_type(iter_ty)
        self.scope_put(binding, elem_ty, 0)
        let result_elem = self.check_expr(expr)
        self.pop_scope()
        return self.add_type(TY_ARRAY, result_elem, 0, 0)

    if kind == NK_OPTIONAL_CHAIN:
        let base = self.check_expr(self.ast.get_data0(node))
        return base

    if kind == NK_POISONED_EXPR:
        return 0

    0

// ── Expression checking helpers ──────────────────────────────────

fn Sema.check_ident(self: Sema, sym: i32, node: i32) -> i32:
    // Check local/param scope (always visible — local bindings are never c_import)
    let tid = self.scope_lookup(sym)
    if tid >= 0:
        let state = self.scope_lookup_state(sym)
        if state == VS_MOVED:
            if sema_debug_move_enabled() != 0:
                let name = self.pool_resolve(sym)
                with_eprintln(
                    "[moved-use] sym=" ++ name ++
                    " tid=" ++ int_to_string(tid) ++
                    " node_kind=" ++ int_to_string(self.ast.kind(node))
                )
            self.emit_error("use of moved value", node)
        self.typed_expr_types.insert(node, tid)
        return tid

    // Check function names
    let sig_idx = self.get_sig(sym)
    if sig_idx >= 0 and self.is_ci_visible(sym) != 0:
        return self.sig_type_ids.get(sig_idx as i64)

    // Check generic functions
    if self.generic_fn_nodes.contains(sym) and self.is_ci_visible(sym) != 0:
        return 0

    // Check type names
    let prim = self.primitive_type_by_sym(sym)
    if prim != 0:
        return prim
    if self.named_types.contains(sym) and self.is_ci_visible(sym) != 0:
        return self.named_types.get(sym).unwrap()

    // Check enum variants
    if self.variant_lookup.contains(sym) and self.is_ci_visible(sym) != 0:
        return self.variant_type_ids.get(sym).unwrap()

    // Unknown identifier
    self.emit_error("undefined variable", node)
    0

fn Sema.check_binary(self: Sema, node: i32) -> i32:
    let op = self.ast.get_data0(node)
    let lhs_node = self.ast.get_data1(node)
    let rhs_node = self.ast.get_data2(node)
    let lhs_is_num_lit = sema_node_is_numeric_literal(self.ast, lhs_node)
    let rhs_is_num_lit = sema_node_is_numeric_literal(self.ast, rhs_node)
    var lhs = 0
    var rhs = 0
    // Variant shorthand in comparisons must be typed against the opposite side,
    // not whatever outer expected type is active (for example `bool` from assert()).
    if op == OP_EQ or op == OP_NEQ or op == OP_LT or op == OP_GT or op == OP_LTE or op == OP_GTE:
        if self.ast.kind(lhs_node) == NK_VARIANT_SHORTHAND:
            rhs = self.check_expr(rhs_node)
            lhs = self.check_expr_with_expected(lhs_node, rhs)
        else:
            if lhs_is_num_lit and rhs_is_num_lit:
                lhs = self.check_expr(lhs_node)
                rhs = self.check_expr(rhs_node)
            else if lhs_is_num_lit and self.ast.kind(rhs_node) != NK_VARIANT_SHORTHAND:
                rhs = self.check_expr(rhs_node)
                lhs = self.check_expr_with_expected(lhs_node, rhs)
            else:
                lhs = self.check_expr(lhs_node)
            if self.ast.kind(rhs_node) == NK_VARIANT_SHORTHAND:
                rhs = self.check_expr_with_expected(rhs_node, lhs)
            else if rhs == 0 and rhs_is_num_lit and lhs_is_num_lit == false:
                rhs = self.check_expr_with_expected(rhs_node, lhs)
            else:
                if rhs == 0:
                    rhs = self.check_expr(rhs_node)
    else if op == OP_ADD or op == OP_SUB or op == OP_MUL or op == OP_DIV or op == OP_MOD or
       op == OP_ADD_WRAP or op == OP_SUB_WRAP or op == OP_MUL_WRAP or
       op == OP_BIT_AND or op == OP_BIT_OR or op == OP_BIT_XOR or
       op == OP_SHL or op == OP_SHR:
        if lhs_is_num_lit and rhs_is_num_lit:
            lhs = self.check_expr(lhs_node)
            rhs = self.check_expr(rhs_node)
        else:
            if lhs_is_num_lit:
                rhs = self.check_expr(rhs_node)
                if self.is_numeric_type(rhs):
                    lhs = self.check_expr_with_expected(lhs_node, rhs)
                else:
                    lhs = self.check_expr(lhs_node)
            else:
                lhs = self.check_expr(lhs_node)
            if rhs == 0:
                if rhs_is_num_lit and self.is_numeric_type(lhs):
                    rhs = self.check_expr_with_expected(rhs_node, lhs)
                else:
                    rhs = self.check_expr(rhs_node)
            if lhs == 0:
                lhs = self.check_expr(lhs_node)
    else:
        lhs = self.check_expr(lhs_node)
        rhs = self.check_expr(rhs_node)

    if lhs == 0 or rhs == 0:
        return 0

    // Comparison operators return bool
    if op == OP_EQ or op == OP_NEQ or op == OP_LT or op == OP_GT or op == OP_LTE or op == OP_GTE or op == OP_IN or op == OP_NOT_IN:
        return self.ty_bool

    // Logical operators
    if op == OP_AND or op == OP_OR:
        if lhs != self.ty_bool:
            self.emit_error("left operand of logical operator must be bool", node)
        if rhs != self.ty_bool:
            self.emit_error("right operand of logical operator must be bool", node)
        return self.ty_bool

    // Arithmetic — unsigned types wrap by default (rewrite to wrapping ops)
    if (op == OP_ADD or op == OP_SUB or op == OP_MUL) and self.is_unsigned_int_type(lhs) and self.is_unsigned_int_type(rhs):
        let wrap_op = if op == OP_ADD: OP_ADD_WRAP else: if op == OP_SUB: OP_SUB_WRAP else: OP_MUL_WRAP
        self.ast.set_data0(node, wrap_op)
        return self.arithmetic_result_type(lhs, rhs)

    if op == OP_ADD or op == OP_SUB or op == OP_MUL or op == OP_DIV or op == OP_MOD:
        if op == OP_ADD and lhs == self.ty_str and rhs == self.ty_str:
            return self.ty_str
        // Pointer arithmetic: ptr + int → ptr, ptr - int → ptr
        let lhs_k = self.get_type_kind(self.resolve_alias(lhs))
        let rhs_k = self.get_type_kind(self.resolve_alias(rhs))
        if (op == OP_ADD or op == OP_SUB) and lhs_k == TY_PTR and (rhs_k == TY_INT or rhs == self.ty_i32 or rhs == self.ty_i64 or rhs == self.ty_usize or rhs == self.ty_isize):
            return lhs
        let result = self.arithmetic_result_type(lhs, rhs)
        if result != 0:
            return result
        let lhs_resolved = self.resolve_alias(lhs)
        let lhs_name = self.get_type_name(lhs_resolved)
        if lhs_name != 0:
            let method_name = if op == OP_ADD: "add" else:
                if op == OP_SUB: "sub" else:
                if op == OP_MUL: "mul" else:
                if op == OP_DIV: "div" else:
                "mod"
            let method_sym = self.pool_intern(method_name)
            let method_key = self.method_key(lhs_name, method_sym)
            let method_sig = self.get_sig(method_key)
            if method_sig >= 0:
                return self.sig_return_type(method_sig)
        self.emit_error("arithmetic operator requires numeric operands", node)
        return 0

    // Bitwise
    if op == OP_BIT_AND or op == OP_BIT_OR or op == OP_BIT_XOR or op == OP_SHL or op == OP_SHR:
        return lhs

    // Wrapping arithmetic
    if op == OP_ADD_WRAP or op == OP_SUB_WRAP or op == OP_MUL_WRAP:
        return lhs

    // Default (??)
    if op == OP_DEFAULT:
        return lhs

    // Concat (++)
    if op == OP_CONCAT:
        return self.ty_str

    0

fn Sema.check_unary(self: Sema, node: i32) -> i32:
    let op = self.ast.get_data0(node)
    let operand_node = self.ast.get_data1(node)
    let operand = self.check_expr(operand_node)
    if operand == 0:
        return 0

    if op == UOP_NEGATE:
        if self.is_unsigned_int_type(operand):
            self.emit_error("cannot negate an unsigned value", node)
        return operand
    if op == UOP_BIT_NOT:
        return operand
    if op == UOP_NOT:
        return self.ty_bool
    if op == UOP_REF:
        self.check_borrow_create(operand_node, BK_SHARED, node)
        return self.add_type(TY_REF, operand, 0, 0)
    if op == UOP_MUT_REF:
        self.check_borrow_create(operand_node, BK_EXCLUSIVE, node)
        return self.add_type(TY_REF, operand, 1, 0)
    if op == UOP_DEREF:
        let resolved = self.resolve_alias(operand)
        let tk = self.get_type_kind(resolved)
        if tk == TY_REF:
            return self.get_type_d0(resolved)
        if tk == TY_PTR:
            return self.get_type_d0(resolved)
        return 0
    if op == UOP_TRY:
        if self.in_defer != 0:
            self.emit_error("? operator not allowed in defer", node)
            return 0
        let unwrapped = self.try_unwrapped_type(operand)
        if unwrapped == 0:
            self.emit_error("? operator requires an Option or Result with a single success payload", node)
            return 0
        self.typed_expr_types.insert(node, unwrapped)
        return unwrapped

    0

fn Sema.check_block(self: Sema, node: i32) -> i32:
    let extra_start = self.ast.get_data0(node)
    let stmt_count = self.ast.get_data1(node)
    let tail = self.ast.get_data2(node)

    self.push_scope()

    for i in 0..stmt_count:
        let stmt = self.ast.get_extra(extra_start + i)
        let saved_stmt_pos = self.match_in_stmt_pos
        self.match_in_stmt_pos = 1
        let stmt_ty = self.check_expr(stmt)
        self.match_in_stmt_pos = saved_stmt_pos
        self.typed_expr_types.insert(stmt, stmt_ty)
        let stmt_kind = self.ast.kind(stmt)
        let can_discard_task = stmt_kind == NK_CALL or stmt_kind == NK_IDENT or stmt_kind == NK_GROUPED or stmt_kind == NK_ASYNC_BLOCK or stmt_kind == NK_TUPLE
        let is_discarded_task = can_discard_task and stmt_kind != NK_SPAWN and self.expr_is_task_value(stmt) != 0 and self.expr_is_scoped_task_value(stmt) == 0
        if is_discarded_task:
            self.emit_warning("E0801: unused Task value", stmt)
        self.expire_dead_borrows_in_block(extra_start, stmt_count, i + 1, tail)

    var result = self.ty_void
    if tail != 0:
        // If the tail is a match in a void/unspecified-return context, treat as statement
        // position so partial enum match is allowed (value is not used).
        let saved_stmt_pos = self.match_in_stmt_pos
        let ret_is_void = self.current_return_type == self.ty_void or self.current_return_type == 0
        if ret_is_void and self.ast.kind(tail) == NK_MATCH:
            self.match_in_stmt_pos = 1
        result = self.check_expr(tail)
        self.match_in_stmt_pos = saved_stmt_pos
        self.typed_expr_types.insert(tail, result)
    self.expire_dead_borrows_in_block(extra_start, stmt_count, stmt_count, 0)

    self.pop_scope()
    if result != 0 and result != self.ty_void:
        self.typed_expr_types.insert(node, result)
    result

fn Sema.check_let_binding(self: Sema, node: i32) -> i32:
    let name = self.ast.get_data0(node)
    var bind_name = self.extract_decl_name_after(node, "let")
    if bind_name.len() == 0:
        bind_name = self.extract_decl_name_after(node, "var")
    self.set_pretty_symbol(name, bind_name)
    let value = self.ast.get_data1(node)
    let flags = self.ast.get_data2(node)
    let is_mut = flags % 2

    let ann_extra = self.local_let_type_ann_extra(flags)
    var ann_type = 0
    var ann_type_node = 0
    if ann_extra >= 0:
        ann_type_node = self.ast.get_extra(ann_extra)
        ann_type = self.resolve_type_expr(ann_type_node)

    // Let binding value is expression position — match inside must be exhaustive.
    let saved_match_stmt = self.match_in_stmt_pos
    self.match_in_stmt_pos = 0
    let val_type = if ann_type != 0: self.check_expr_with_expected(value, ann_type) else: self.check_expr(value)
    self.match_in_stmt_pos = saved_match_stmt
    var bind_type = val_type
    if ann_type != 0:
        bind_type = ann_type
        if val_type != 0:
            if self.types_compatible(ann_type, val_type) == 0:
                if self.arithmetic_result_type(ann_type, val_type) == 0:
                    self.emit_error("type mismatch in binding", node)

    // Move semantics
    self.mark_moved_if_consumed(value)

    if ann_type_node != 0 and self.type_expr_is_collection_with_ref(ann_type_node) != 0:
        self.emit_error("ephemeral references cannot be stored in generic containers", node)

    self.scope_put_at(name, bind_type, is_mut, node)
    self.typed_binding_types.insert(node, bind_type)
    self.typed_binding_names.insert(node, name)
    self.typed_binding_muts.insert(node, is_mut)
    self.scope_set_is_task(name, self.expr_is_task_value(value))
    self.scope_set_is_scoped_task(name, self.expr_is_scoped_task_value(value))
    self.scope_set_is_ephemeral_task(name, self.expr_is_ephemeral_task(value))

    // Auto-defer: if this is an immutable let binding of a c_import type with a
    // destructor (e.g. let v = MyVec.new(...)), record it for auto-defer at scope exit.
    if is_mut == 0 and self.ci_type_destructors.len() > 0:
        let resolved_bt = self.resolve_alias(bind_type)
        let bt_kind = self.get_type_kind(resolved_bt)
        // For pointer types (*mut T), check the pointee type name
        var type_name_sym = 0
        if bt_kind == TY_PTR or bt_kind == TY_REF:
            let pointee = self.get_type_d0(resolved_bt)
            if pointee > 0:
                let pt_resolved = self.resolve_alias(pointee)
                type_name_sym = self.get_type_d0(pt_resolved)
        else if bt_kind == TY_STRUCT:
            type_name_sym = self.get_type_d0(resolved_bt)
        if type_name_sym != 0 and self.ci_type_destructors.contains(type_name_sym):
            let dtor_sym = self.ci_type_destructors.get(type_name_sym).unwrap()
            self.ci_auto_defer_bindings.insert(name, dtor_sym)

    // If this let binds a borrow, tie the newest active borrow to this binding.
    if self.ast.kind(value) == NK_UNARY:
        let uop = self.ast.get_data0(value)
        if uop == UOP_REF or uop == UOP_MUT_REF:
            let blen = self.borrow_refs.len() as i32
            if blen > 0:
                self.borrow_refs.set_i32((blen - 1) as i64, name)

    self.ty_void

fn Sema.check_if_expr(self: Sema, node: i32) -> i32:
    let cond = self.ast.get_data0(node)
    let then_body = self.ast.get_data1(node)
    let else_body = self.ast.get_data2(node)

    self.check_expr(cond)
    let then_type = self.check_expr(then_body)

    var result_type = self.ty_void
    if else_body != 0:
        let else_type = self.check_expr(else_body)
        if then_type != 0 and else_type != 0:
            if self.types_compatible(then_type, else_type):
                result_type = then_type
            else:
                result_type = self.arithmetic_result_type(then_type, else_type)
        else if then_type != 0:
            result_type = then_type
        else:
            result_type = else_type
    if result_type != 0 and result_type != self.ty_void:
        self.typed_expr_types.insert(node, result_type)
    result_type

fn Sema.check_return(self: Sema, node: i32) -> i32:
    if self.in_defer != 0:
        self.emit_error("return not allowed in defer", node)
    let value = self.ast.get_data0(node)
    if value != 0:
        let val_type = if self.current_return_type != 0: self.check_expr_with_expected(value, self.current_return_type) else: self.check_expr(value)
        if self.current_return_type != 0 and val_type != 0:
            let compat = self.types_compatible(self.current_return_type, val_type)
            let arith = if compat == 0: self.arithmetic_result_type(self.current_return_type, val_type) else: 1
            if compat == 0:
                if arith == 0:
                    self.emit_error("return type mismatch", node)
    self.ty_void

fn Sema.check_assign(self: Sema, node: i32) -> i32:
    let target = self.ast.get_data0(node)
    let value = self.ast.get_data1(node)

    let target_type = self.check_expr(target)
    let value_type = if target_type != 0: self.check_expr_with_expected(value, target_type) else: self.check_expr(value)

    // Check mutability
    if self.ast.kind(target) == NK_IDENT:
        let target_sym = self.ast.get_data0(target)
        if self.scope_has(target_sym) != 0:
            if self.scope_lookup_mut(target_sym) == 0:
                self.emit_error("cannot assign to immutable variable", node)

    // Check type compatibility
    if target_type != 0 and value_type != 0:
        if self.types_compatible(target_type, value_type) == 0:
            if self.arithmetic_result_type(target_type, value_type) == 0:
                self.emit_error("type mismatch in assignment", node)

    // Move semantics
    self.mark_moved_if_consumed(value)

    // Reinitialize target
    if self.ast.kind(target) == NK_IDENT:
        let target_sym = self.ast.get_data0(target)
        self.scope_set_state(target_sym, VS_LIVE)
        self.scope_set_is_task(target_sym, self.expr_is_task_value(value))
        self.scope_set_is_scoped_task(target_sym, self.expr_is_scoped_task_value(value))
        self.scope_set_is_ephemeral_task(target_sym, self.expr_is_ephemeral_task(value))

    self.ty_void

fn Sema.check_for(self: Sema, node: i32) -> i32:
    let binding = self.ast.get_data0(node)
    let iterable = self.ast.get_data1(node)
    let body = self.ast.get_data2(node)

    let iter_type = self.check_expr(iterable)
    let elem_type = self.infer_for_element_type(iter_type)

    self.push_scope()
    self.scope_put(binding, elem_type, 0)
    let for_meta = self.ast.find_for_meta(node)
    if for_meta >= 0:
        let index_binding = self.ast.for_meta_index_binding(for_meta)
        if index_binding != 0:
            self.scope_put(index_binding, self.ty_i64, 0)
    self.loop_depth = self.loop_depth + 1
    self.check_expr(body)
    self.loop_depth = self.loop_depth - 1
    self.pop_scope()
    self.ty_void

fn Sema.struct_field_type(self: Sema, struct_type: i32, field: i32) -> i32:
    if struct_type == 0:
        return 0

    let resolved = self.resolve_alias(struct_type)
    let tk = self.get_type_kind(resolved)

    if tk == TY_STRUCT:
        let te_start = self.get_type_d1(resolved)
        let field_count = self.get_type_d2(resolved)
        for fi in 0..field_count:
            let f_name = self.type_extra.get((te_start + fi * 3) as i64)
            if f_name == field:
                return self.type_extra.get((te_start + fi * 3 + 1) as i64)
        return 0

    if tk == TY_GENERIC_INST:
        let gi_base_sym = self.get_type_d0(resolved)
        if self.type_decl_nodes.contains(gi_base_sym):
            let td_node = self.type_decl_nodes.get(gi_base_sym).unwrap()
            let td_extra = self.ast.get_data1(td_node)
            let td_packed = self.ast.get_data2(td_node)
            if type_decl_sub_kind(td_packed) == TDK_STRUCT:
                let fc = self.ast.get_extra(td_extra)
                let after = td_extra + 1 + fc * 4
                let tp_start = self.ast.get_extra(after + 1)
                let tp_count = self.ast.get_extra(after + 2)
                if self.setup_generic_inst_substitution(resolved, gi_base_sym) != 0:
                    for gi_fi in 0..fc:
                        let base = td_extra + 1 + gi_fi * 3
                        let f_name = self.ast.get_extra(base)
                        if f_name == field:
                            let f_type_node = self.ast.get_extra(base + 1)
                            return self.resolve_generic_return_type_node(f_type_node, tp_start, tp_count)
                else:
                    if self.named_types.contains(gi_base_sym):
                        let gi_struct_tid = self.named_types.get(gi_base_sym).unwrap()
                        let gi_te_start = self.get_type_d1(gi_struct_tid)
                        for gi_fi in 0..fc:
                            let gi_f_name = self.type_extra.get((gi_te_start + gi_fi * 3) as i64)
                            if gi_f_name == field:
                                return self.type_extra.get((gi_te_start + gi_fi * 3 + 1) as i64)
        return 0

    0

fn Sema.check_field_access(self: Sema, node: i32) -> i32:
    let expr = self.ast.get_data0(node)
    let field = self.ast.get_data1(node)

    // comptime cfg.field → resolve to compile-time constant type
    // Only apply when 'cfg' is not a local variable
    if self.ast.kind(expr) == NK_IDENT:
        let cfg_sym = self.ast.get_data0(expr)
        if self.pool_resolve(cfg_sym) == "cfg" and self.scope_lookup(cfg_sym) < 0:
            let field_name = self.pool_resolve(field)
            if field_name == "is_debug" or field_name == "is_release":
                return self.ty_bool
            return self.ty_str

    let obj_type = self.check_expr(expr)

    if obj_type == 0:
        return 0

    let resolved = self.resolve_alias(obj_type)
    let tk = self.get_type_kind(resolved)

    // Auto-deref through ptrs and refs
    var field_base = resolved
    if tk == TY_PTR or tk == TY_REF:
        field_base = self.resolve_alias(self.get_type_d0(resolved))

    let ftk = self.get_type_kind(field_base)

    if ftk == TY_STRUCT:
        let _ = self.get_type_d0(field_base)
        return self.struct_field_type(field_base, field)

    if ftk == TY_GENERIC_INST:
        return self.struct_field_type(field_base, field)

    if ftk == TY_TUPLE:
        let te_start = self.get_type_d0(field_base)
        let elem_count = self.get_type_d1(field_base)
        let field_name = self.pool_resolve(field)
        // Parse field index
        var idx = 0
        for vi in 0..field_name.len() as i32:
            let ch = field_name[vi]
            if ch >= 48 and ch <= 57:
                idx = idx * 10 + ch - 48
        if idx < elem_count:
            return self.type_extra.get((te_start + idx) as i64)
        return 0

    if ftk == TY_ARRAY or ftk == TY_SLICE or ftk == TY_STR:
        let field_name = self.pool_resolve(field)
        if field_name == "len":
            return self.ty_i64
        return 0

    if ftk == TY_ENUM:
        // Discriminant enums: with payloads return enum type, without return repr type
        let repr_opt = self.disc_repr_types.get(field_base)
        if repr_opt.is_some():
            let hp = self.disc_has_payload.get(field_base)
            if hp.is_some() and hp.unwrap() != 0:
                return field_base
            return repr_opt.unwrap()
        return field_base

    0

fn Sema.index_expr_is_type_level(self: Sema, expr: i32) -> bool:
    if expr == 0:
        return false
    let kind = self.ast.kind(expr)
    if kind == NK_IDENT:
        let sym = self.ast.get_data0(expr)
        return self.named_types.contains(sym)
    if kind == NK_INDEX or kind == NK_GROUPED:
        return self.index_expr_is_type_level(self.ast.get_data0(expr))
    false

fn Sema.check_vec_literal_elem(self: Sema, elem_ty: i32, elem_node: i32, arg_index: i32):
    if elem_node == 0:
        return
    let actual_ty = self.check_expr_with_expected(elem_node, elem_ty)
    if elem_ty != 0 and actual_ty != 0:
        if self.types_compatible(elem_ty, actual_ty) == 0:
            if self.arithmetic_result_type(elem_ty, actual_ty) == 0:
                self.emit_argument_type_mismatch("Vec.literal", 0, arg_index, arg_index, elem_ty, actual_ty, elem_node)

fn Sema.check_index(self: Sema, node: i32) -> i32:
    let expr = self.ast.get_data0(node)
    let index = self.ast.get_data1(node)
    let index2 = self.ast.get_data2(node)
    let arr_type = self.check_expr(expr)

    if arr_type == 0:
        self.check_expr(index)
        if index2 != 0:
            self.check_expr(index2)
        return 0

    let resolved = self.resolve_alias(arr_type)
    let tk = self.get_type_kind(resolved)
    if tk == TY_ARRAY:
        self.check_expr(index)
        return self.get_type_d0(resolved)
    if tk == TY_SLICE:
        self.check_expr(index)
        return self.get_type_d0(resolved)
    if tk == TY_GENERIC_INST:
        let base_name = self.pool_resolve(self.get_type_d0(resolved))
        let is_type_level_index = self.index_expr_is_type_level(expr)
        if is_type_level_index and base_name == "Vec" and self.get_generic_inst_arg_count(resolved) > 0:
            let elem_ty = self.get_generic_inst_arg(resolved, 0)
            self.check_vec_literal_elem(elem_ty, index, 0)
            if index2 != 0:
                self.check_vec_literal_elem(elem_ty, index2, 1)
            self.typed_expr_types.insert(node, resolved)
            return resolved
        if not is_type_level_index and base_name == "Vec" and self.get_generic_inst_arg_count(resolved) > 0:
            self.check_expr(index)
            let elem_ty = self.get_generic_inst_arg(resolved, 0)
            self.typed_expr_types.insert(node, elem_ty)
            return elem_ty

    // Type-level NK_INDEX: Vec[i32], HashMap[str, i32], etc.
    // Create TY_GENERIC_INST so MirLower can find it in the sema snapshot.
    if tk == TY_STRUCT:
        if self.ast.kind(expr) == NK_IDENT:
            let ci_base_sym = self.ast.get_data0(expr)
            if self.named_types.contains(ci_base_sym):
                let arg_kind = self.ast.kind(index)
                var ci_arg_type = 0
                if arg_kind == NK_IDENT or arg_kind == NK_TYPE_NAMED:
                    let arg_sym = self.ast.get_data0(index)
                    let prim = self.primitive_type_by_sym(arg_sym)
                    if prim != 0:
                        ci_arg_type = prim
                    else if self.named_types.contains(arg_sym):
                        ci_arg_type = self.named_types.get(arg_sym).unwrap()
                if ci_arg_type > 0:
                    // Check for second type arg (d2 of NK_INDEX) — HashMap[K, V]
                    let ci_index2 = self.ast.get_data2(node)
                    var ci_arg2_type = 0
                    if ci_index2 != 0:
                        let a2_kind = self.ast.kind(ci_index2)
                        if a2_kind == NK_IDENT or a2_kind == NK_TYPE_NAMED:
                            let a2_sym = self.ast.get_data0(ci_index2)
                            let a2_prim = self.primitive_type_by_sym(a2_sym)
                            if a2_prim != 0:
                                ci_arg2_type = a2_prim
                            else if self.named_types.contains(a2_sym):
                                ci_arg2_type = self.named_types.get(a2_sym).unwrap()
                    var ci_cache_key = int_to_string(ci_base_sym) ++ ":" ++ int_to_string(ci_arg_type)
                    var ci_arg_count = 1
                    if ci_arg2_type > 0:
                        ci_cache_key = ci_cache_key ++ ":" ++ int_to_string(ci_arg2_type)
                        ci_arg_count = 2
                    if self.generic_inst_cache.contains(ci_cache_key):
                        let ci_result = self.generic_inst_cache.get(ci_cache_key).unwrap()
                        self.typed_expr_types.insert(node, ci_result)
                        return ci_result
                    let ci_te_start = self.type_extra.len() as i32
                    self.type_extra.push(ci_arg_type)
                    if ci_arg2_type > 0:
                        self.type_extra.push(ci_arg2_type)
                    let ci_tid = self.add_type(TY_GENERIC_INST, ci_base_sym, ci_te_start, ci_arg_count)
                    self.generic_inst_cache.insert(ci_cache_key, ci_tid)
                    self.typed_expr_types.insert(node, ci_tid)
                    return ci_tid
    0

fn Sema.check_slice(self: Sema, node: i32) -> i32:
    let expr = self.ast.get_data0(node)
    let start = self.ast.get_data1(node)
    let end = self.ast.get_data2(node)
    let arr_type = self.check_expr(expr)
    if start != 0:
        self.check_expr(start)
    if end != 0:
        self.check_expr(end)

    if arr_type == 0:
        return 0

    let resolved = self.resolve_alias(arr_type)
    let tk = self.get_type_kind(resolved)
    if tk == TY_ARRAY:
        let elem = self.get_type_d0(resolved)
        return self.add_type(TY_SLICE, elem, 0, 0)
    if tk == TY_SLICE:
        return resolved
    0

fn Sema.check_array_literal(self: Sema, node: i32) -> i32:
    let extra_start = self.ast.get_data0(node)
    let elem_count = self.ast.get_data1(node)
    var expected_elem = 0
    if self.has_expected_type != 0 and self.expected_expr_type != 0:
        let expected = self.resolve_alias(self.expected_expr_type)
        let expected_kind = self.get_type_kind(expected)
        if expected_kind == TY_ARRAY or expected_kind == TY_SLICE:
            expected_elem = self.get_type_d0(expected)
    if elem_count == 0:
        if self.has_expected_type != 0 and self.expected_expr_type != 0:
            self.typed_expr_types.insert(node, self.expected_expr_type)
            return self.expected_expr_type
        return 0

    var elem_type = 0
    for i in 0..elem_count:
        let elem = self.ast.get_extra(extra_start + i)
        let et = if expected_elem != 0:
            self.check_expr_with_expected(elem, expected_elem)
        else if elem_type != 0 and sema_node_is_numeric_literal(self.ast, elem):
            self.check_expr_with_expected(elem, elem_type)
        else:
            self.check_expr(elem)
        if elem_type == 0:
            elem_type = et

    if expected_elem != 0:
        elem_type = expected_elem
    let result = if self.has_expected_type != 0 and self.expected_expr_type != 0 and expected_elem != 0:
        self.expected_expr_type
    else:
        self.add_type(TY_ARRAY, elem_type, elem_count, 0)
    self.typed_expr_types.insert(node, result)
    result

fn Sema.check_struct_literal(self: Sema, node: i32) -> i32:
    let name = self.ast.get_data0(node)
    let extra_start = self.ast.get_data1(node)
    let field_count = self.ast.get_data2(node)

    if self.named_types.contains(name):
        let tid = self.named_types.get(name).unwrap()
        let resolved = self.resolve_alias(tid)
        if self.get_type_kind(resolved) == TY_STRUCT:
            var expected_struct_ty = 0
            if self.has_expected_type != 0 and self.expected_expr_type != 0:
                let expected_resolved = self.resolve_alias(self.expected_expr_type)
                let expected_tk = self.get_type_kind(expected_resolved)
                if expected_tk == TY_STRUCT and self.get_type_d0(expected_resolved) == name:
                    expected_struct_ty = expected_resolved
                else if expected_tk == TY_GENERIC_INST and self.get_type_d0(expected_resolved) == name:
                    expected_struct_ty = expected_resolved
            if expected_struct_ty == 0 and self.type_decl_nodes.contains(name):
                let td_node = self.type_decl_nodes.get(name).unwrap()
                if self.type_decl_tp_count(td_node) == 0:
                    expected_struct_ty = resolved
            // Check field initializers and collect value types
            let val_types: Vec[i32] = Vec.new()
            for fi in 0..field_count:
                let f_name = self.ast.get_extra(extra_start + fi * 2)
                let f_value = self.ast.get_extra(extra_start + fi * 2 + 1)
                let field_expected = if expected_struct_ty != 0: self.struct_field_type(expected_struct_ty, f_name) else: 0
                let val_ty = if field_expected != 0: self.check_expr_with_expected(f_value, field_expected) else: self.check_expr(f_value)
                val_types.push(val_ty)
            // Check if struct has type params — infer GenericInst
            if self.type_decl_nodes.contains(name):
                let td_node = self.type_decl_nodes.get(name).unwrap()
                let td_extra = self.ast.get_data1(td_node)
                let td_packed = self.ast.get_data2(td_node)
                if type_decl_sub_kind(td_packed) == TDK_STRUCT:
                    let fc = self.ast.get_extra(td_extra)
                    let after = td_extra + 1 + fc * 4
                    let tp_start = self.ast.get_extra(after + 1)
                    let tp_count = self.ast.get_extra(after + 2)
                    if tp_count > 0:
                        // Infer type args from field values
                        var ga0 = 0
                        var ga1 = 0
                        var ga2 = 0
                        var ga3 = 0
                        var inferred = 0
                        var tp_pos = tp_start
                        for ti in 0..tp_count:
                            let tp_name = self.ast.get_extra(tp_pos)
                            let bc = self.ast.get_extra(tp_pos + 1)
                            // Find a field whose type is this param
                            for fi in 0..fc:
                                let base = td_extra + 1 + fi * 3
                                let f_name_sym = self.ast.get_extra(base)
                                let f_type_node = self.ast.get_extra(base + 1)
                                if self.ast.kind(f_type_node) == NK_TYPE_NAMED:
                                    if self.ast.get_data0(f_type_node) == tp_name:
                                        // Match field name in literal to get value type
                                        for li in 0..field_count:
                                            let lit_f = self.ast.get_extra(extra_start + li * 2)
                                            if lit_f == f_name_sym:
                                                let vt = val_types.get(li as i64)
                                                if vt > 0:
                                                    if ti == 0: ga0 = vt
                                                    if ti == 1: ga1 = vt
                                                    if ti == 2: ga2 = vt
                                                    if ti == 3: ga3 = vt
                                                    inferred = inferred + 1
                                                break
                                        break
                            tp_pos = tp_pos + 2 + bc
                        if inferred == tp_count:
                            let te = self.type_extra.len() as i32
                            if tp_count > 0: self.type_extra.push(ga0)
                            if tp_count > 1: self.type_extra.push(ga1)
                            if tp_count > 2: self.type_extra.push(ga2)
                            if tp_count > 3: self.type_extra.push(ga3)
                            let gi = self.add_type(TY_GENERIC_INST, name, te, tp_count)
                            self.typed_expr_types.insert(node, gi)
                            return gi
            self.typed_expr_types.insert(node, resolved)
            return resolved
    0

fn Sema.check_match_expr(self: Sema, node: i32) -> i32:
    let subject = self.ast.get_data0(node)
    let extra_start = self.ast.get_data1(node)
    let arm_count = self.ast.get_data2(node)

    let subject_type = self.check_expr(subject)
    var result_type = 0
    let match_expected = if self.has_expected_type != 0: self.expected_expr_type else: 0

    for ai in 0..arm_count:
        let arm_node = self.ast.get_extra(extra_start + ai)
        let pat = self.ast.get_data0(arm_node)
        let arm_body = self.ast.get_data1(arm_node)
        let guard = self.ast.get_data2(arm_node)

        self.push_scope()
        self.check_pattern(pat, subject_type)
        if guard != 0:
            self.check_expr(guard)
        let arm_expected = if result_type != 0: result_type else: match_expected
        let arm_type = if arm_expected != 0: self.check_expr_with_expected(arm_body, arm_expected) else: self.check_expr(arm_body)
        self.pop_scope()

        if result_type == 0:
            result_type = arm_type
        else if result_type == self.ty_never and arm_type != 0:
            // Bottom-type merge: allow concrete arm types after Never arms.
            result_type = arm_type

    // Exhaustiveness checking for enum and bool subjects.
    // Expression-position match always requires exhaustiveness.
    // Statement-position match allows partial match (unmatched variants are no-op),
    // UNLESS the subject type is @[must_use] (Result, Task).
    var require_exhaustive = 0
    if self.match_in_stmt_pos == 0:
        require_exhaustive = 1
    else:
        // Must-use types require exhaustive match even in statement position
        let type_sym = self.get_type_d0(self.resolve_alias(subject_type))
        if type_sym != 0 and self.must_use_types.contains(type_sym):
            require_exhaustive = 1
    self.check_match_exhaustiveness(node, subject_type, extra_start, arm_count, require_exhaustive)

    if result_type != 0:
        self.typed_expr_types.insert(node, result_type)
    result_type

fn Sema.check_match_exhaustiveness(self: Sema, node: i32, subject_type: i32, extra_start: i32, arm_count: i32, require_exhaustive: i32):
    if subject_type == 0:
        return
    let resolved = self.resolve_alias(subject_type)
    let tk = self.get_type_kind(resolved)

    // Check if any arm is a catch-all (wildcard or binding pattern without guard)
    var has_catchall = 0
    for ai in 0..arm_count:
        let arm_node = self.ast.get_extra(extra_start + ai)
        let pat = self.ast.get_data0(arm_node)
        let guard = self.ast.get_data2(arm_node)
        if guard != 0:
            continue
        if sema_pattern_is_catchall(self.ast, pat):
            has_catchall = 1
            break
    if has_catchall != 0:
        return

    // Bool exhaustiveness
    if tk == TY_BOOL:
        if require_exhaustive == 0:
            return
        var has_true = 0
        var has_false = 0
        for ai in 0..arm_count:
            let arm_node = self.ast.get_extra(extra_start + ai)
            let pat = self.ast.get_data0(arm_node)
            let guard = self.ast.get_data2(arm_node)
            if guard != 0:
                continue
            let pk = self.ast.kind(pat)
            if pk == NK_PAT_BOOL:
                let v = self.ast.get_data0(pat)
                if v != 0:
                    has_true = 1
                else:
                    has_false = 1
        if has_true == 0 or has_false == 0:
            self.emit_warning("non-exhaustive match on bool", node)
        return

    // Sealed trait object exhaustiveness
    if tk == TY_TRAIT_OBJ:
        let trait_sym = self.get_type_d0(resolved)
        if self.sealed_traits.contains(trait_sym) and self.sealed_impl_counts.contains(trait_sym):
            let si_count = self.sealed_impl_counts.get(trait_sym).unwrap()
            let si_start = self.sealed_impl_starts.get(trait_sym).unwrap()
            // Check that each implementor is covered by an arm
            for si in 0..si_count:
                let impl_sym = self.sealed_impl_types.get((si_start + si) as i64)
                var covered = 0
                for ai in 0..arm_count:
                    let arm_node = self.ast.get_extra(extra_start + ai)
                    let pat = self.ast.get_data0(arm_node)
                    let guard = self.ast.get_data2(arm_node)
                    if guard != 0:
                        continue
                    if sema_pattern_covers_variant(self.ast, pat, impl_sym):
                        covered = 1
                        break
                if covered == 0:
                    let impl_name = self.pool_resolve(impl_sym)
                    self.emit_error("non-exhaustive match on sealed trait: missing implementor '" ++ impl_name ++ "'", node)
                    return
        return

    // Enum exhaustiveness
    if tk != TY_ENUM:
        return
    if require_exhaustive == 0:
        return
    let te_start = self.get_type_d1(resolved)
    let variant_count = self.get_type_d2(resolved)
    // Collect all variant name syms
    var pos = te_start
    for vi in 0..variant_count:
        let v_name_sym = self.type_extra.get(pos as i64)
        let pc = self.type_extra.get((pos + 1) as i64)
        // Check if this variant is covered by any arm
        var covered = 0
        for ai in 0..arm_count:
            let arm_node = self.ast.get_extra(extra_start + ai)
            let pat = self.ast.get_data0(arm_node)
            let guard = self.ast.get_data2(arm_node)
            if guard != 0:
                continue
            if sema_pattern_covers_variant(self.ast, pat, v_name_sym):
                covered = 1
                break
        if covered == 0:
            self.emit_warning("non-exhaustive match: missing variant", node)
            return
        pos = pos + 2 + pc

fn sema_pattern_is_catchall(ast: AstPool, pat: i32) -> bool:
    if pat == 0:
        return true
    let kind = ast.kind(pat)
    if kind == NK_PAT_WILDCARD:
        return true
    if kind == NK_PAT_IDENT:
        return true
    false

fn sema_pattern_covers_variant(ast: AstPool, pat: i32, variant_sym: i32) -> bool:
    if pat == 0:
        return false
    let kind = ast.kind(pat)
    if kind == NK_PAT_WILDCARD or kind == NK_PAT_IDENT:
        return true
    if kind == NK_PAT_VARIANT or kind == NK_PAT_ENUM_SHORTHAND:
        return ast.get_data0(pat) == variant_sym
    if kind == NK_PAT_TYPED_BIND:
        return ast.get_data1(pat) == variant_sym
    if kind == NK_PAT_OR:
        let or_start = ast.get_data0(pat)
        let or_count = ast.get_data1(pat)
        for oi in 0..or_count:
            let inner = ast.get_extra(or_start + oi)
            if sema_pattern_covers_variant(ast, inner, variant_sym):
                return true
    false

// Resolve payload types for a variant of a generic enum (e.g., Option[i32].Some → [i32]).
// Walks the AST type declaration with type param substitution active.
fn Sema.resolve_generic_enum_payload(self: Sema, gi_tid: i32, base_sym: i32, variant_name: i32, expected_count: i32) -> Vec[i32]:
    var result: Vec[i32] = Vec.new()
    if not self.type_decl_nodes.contains(base_sym):
        return result
    if self.setup_generic_inst_substitution(gi_tid, base_sym) == 0:
        return result
    // Walk AST type decl to find variant and re-resolve payload type nodes
    let td_node = self.type_decl_nodes.get(base_sym).unwrap()
    let td_extra_start = self.ast.get_data1(td_node)
    let td_packed = self.ast.get_data2(td_node)
    let td_sub_kind = type_decl_sub_kind(td_packed)
    if td_sub_kind != TDK_ENUM:
        return result
    // Get type param info for resolve_generic_return_type_node
    let vc = self.ast.get_extra(td_extra_start)
    var tp_epos = td_extra_start + 1
    for tvi in 0..vc:
        tp_epos = tp_epos + 1
        let tpc = self.ast.get_extra(tp_epos)
        tp_epos = tp_epos + 1
        tp_epos = tp_epos + tpc
    let tp_start = self.ast.get_extra(tp_epos + 1)
    let tp_count = self.ast.get_extra(tp_epos + 2)
    // Now walk variants again to find the matching one
    var epos = td_extra_start + 1
    for vi in 0..vc:
        let v_name = self.ast.get_extra(epos)
        epos = epos + 1
        let pc = self.ast.get_extra(epos)
        epos = epos + 1
        if v_name == variant_name:
            for pi in 0..pc:
                let pt_node = self.ast.get_extra(epos + pi)
                let pt_tid = self.resolve_generic_return_type_node(pt_node, tp_start, tp_count)
                result.push(pt_tid)
            return result
        epos = epos + pc
    result

fn Sema.enum_variant_payload_types(self: Sema, enum_tid: i32, variant_name: i32) -> Vec[i32]:
    var result: Vec[i32] = Vec.new()
    let resolved = self.resolve_alias(enum_tid)
    let kind = self.get_type_kind(resolved)
    if kind == TY_ENUM:
        let te_start = self.get_type_d1(resolved)
        let variant_count = self.get_type_d2(resolved)
        var pos = te_start
        for vi in 0..variant_count:
            let name_sym = self.type_extra.get(pos as i64)
            let payload_count = self.type_extra.get((pos + 1) as i64)
            if name_sym == variant_name:
                for pi in 0..payload_count:
                    result.push(self.type_extra.get((pos + 2 + pi) as i64))
                return result
            pos = pos + 2 + payload_count
        return result
    if kind == TY_GENERIC_INST:
        let base_sym = self.get_generic_inst_base(resolved)
        if not self.named_types.contains(base_sym):
            return result
        let base_tid = self.named_types.get(base_sym).unwrap()
        if self.get_type_kind(base_tid) != TY_ENUM:
            return result
        let te_start = self.get_type_d1(base_tid)
        let variant_count = self.get_type_d2(base_tid)
        var pos = te_start
        for vi in 0..variant_count:
            let name_sym = self.type_extra.get(pos as i64)
            let payload_count = self.type_extra.get((pos + 1) as i64)
            if name_sym == variant_name:
                let generic_payloads = self.resolve_generic_enum_payload(resolved, base_sym, variant_name, payload_count)
                if generic_payloads.len() as i32 > 0:
                    return generic_payloads
                for pi in 0..payload_count:
                    result.push(self.type_extra.get((pos + 2 + pi) as i64))
                return result
            pos = pos + 2 + payload_count
    result

fn Sema.expected_variant_constructor_type(self: Sema, variant_name: i32) -> i32:
    if self.has_expected_type == 0 or self.expected_expr_type == 0:
        return 0
    let expected = self.resolve_alias(self.expected_expr_type)
    let exp_kind = self.get_type_kind(expected)
    if exp_kind == TY_ENUM:
        if self.enum_has_variant(expected, variant_name) != 0:
            return expected
        return 0
    if exp_kind == TY_GENERIC_INST:
        let gi_base = self.get_type_d0(expected)
        if self.named_types.contains(gi_base):
            let base_tid = self.named_types.get(gi_base).unwrap()
            if self.get_type_kind(base_tid) == TY_ENUM:
                if self.enum_has_variant(base_tid, variant_name) != 0:
                    return expected
    0

fn Sema.check_pattern(self: Sema, node: i32, subject_type: i32):
    if node == 0:
        return

    let kind = self.ast.kind(node)

    if kind == NK_PAT_WILDCARD:
        return

    if kind == NK_PAT_IDENT:
        let sym = self.ast.get_data0(node)
        self.scope_put(sym, subject_type, 0)
        return

    if kind == NK_PAT_INT or kind == NK_PAT_BOOL or kind == NK_PAT_STRING:
        return

    if kind == NK_PAT_TYPED_BIND:
        let bind_sym = self.ast.get_data0(node)
        let type_sym = self.ast.get_data1(node)
        var concrete_type = 0
        if self.named_types.contains(type_sym):
            concrete_type = self.named_types.get(type_sym).unwrap()
        if concrete_type != 0:
            self.scope_put(bind_sym, concrete_type, 0)
        else:
            self.scope_put(bind_sym, subject_type, 0)
        return

    if kind == NK_PAT_VARIANT:
        let v_name = self.ast.get_data0(node)
        let v_extra = self.ast.get_data1(node)
        let bind_count = self.ast.get_data2(node)
        var payload_start = 0
        var payload_count = 0
        let resolved = self.resolve_alias(subject_type)
        let resolved_kind = self.get_type_kind(resolved)
        if resolved_kind == TY_ENUM:
            let te_start = self.get_type_d1(resolved)
            let variant_count = self.get_type_d2(resolved)
            var pos = te_start
            for vi in 0..variant_count:
                let name_sym = self.type_extra.get(pos as i64)
                let pc = self.type_extra.get((pos + 1) as i64)
                if name_sym == v_name:
                    payload_start = pos + 2
                    payload_count = pc
                    break
                pos = pos + 2 + pc
        else if resolved_kind == TY_GENERIC_INST:
            let gi_base = self.get_generic_inst_base(resolved)
            if self.named_types.contains(gi_base):
                let base_tid = self.named_types.get(gi_base).unwrap()
                if self.get_type_kind(base_tid) == TY_ENUM:
                    let te_start = self.get_type_d1(base_tid)
                    let variant_count = self.get_type_d2(base_tid)
                    var pos = te_start
                    for vi in 0..variant_count:
                        let name_sym = self.type_extra.get(pos as i64)
                        let pc = self.type_extra.get((pos + 1) as i64)
                        if name_sym == v_name:
                            payload_start = pos + 2
                            payload_count = pc
                            break
                        pos = pos + 2 + pc
        // Recursively check each payload pattern (extra stores pattern nodes).
        // For TY_GENERIC_INST, re-resolve payload types from AST with substitution.
        var gi_payload_types: Vec[i32] = Vec.new()
        if resolved_kind == TY_GENERIC_INST and payload_count > 0:
            let gi_base = self.get_generic_inst_base(resolved)
            gi_payload_types = self.resolve_generic_enum_payload(resolved, gi_base, v_name, payload_count)
        for bi in 0..bind_count:
            let inner_pat = self.ast.get_extra(v_extra + bi)
            var inner_ty = if bi < payload_count: self.type_extra.get((payload_start + bi) as i64) else: 0
            if bi < gi_payload_types.len() as i32:
                let gi_ty = gi_payload_types.get(bi as i64)
                if gi_ty != 0:
                    inner_ty = gi_ty
            self.check_pattern(inner_pat, inner_ty)
        return

    if kind == NK_PAT_ENUM_SHORTHAND:
        let v_name = self.ast.get_data0(node)
        let v_extra = self.ast.get_data1(node)
        let bind_count = self.ast.get_data2(node)
        var payload_start = 0
        var payload_count = 0
        let resolved = self.resolve_alias(subject_type)
        let resolved_kind = self.get_type_kind(resolved)
        if resolved_kind == TY_ENUM:
            let te_start = self.get_type_d1(resolved)
            let variant_count = self.get_type_d2(resolved)
            var pos = te_start
            for vi in 0..variant_count:
                let name_sym = self.type_extra.get(pos as i64)
                let pc = self.type_extra.get((pos + 1) as i64)
                if name_sym == v_name:
                    payload_start = pos + 2
                    payload_count = pc
                    break
                pos = pos + 2 + pc
        else if resolved_kind == TY_GENERIC_INST:
            let gi_base = self.get_generic_inst_base(resolved)
            if self.named_types.contains(gi_base):
                let base_tid = self.named_types.get(gi_base).unwrap()
                if self.get_type_kind(base_tid) == TY_ENUM:
                    let te_start = self.get_type_d1(base_tid)
                    let variant_count = self.get_type_d2(base_tid)
                    var pos = te_start
                    for vi in 0..variant_count:
                        let name_sym = self.type_extra.get(pos as i64)
                        let pc = self.type_extra.get((pos + 1) as i64)
                        if name_sym == v_name:
                            payload_start = pos + 2
                            payload_count = pc
                            break
                        pos = pos + 2 + pc
        // For TY_GENERIC_INST, re-resolve payload types from AST with substitution.
        var gi_payload_types_sh: Vec[i32] = Vec.new()
        if resolved_kind == TY_GENERIC_INST and payload_count > 0:
            let gi_base = self.get_generic_inst_base(resolved)
            gi_payload_types_sh = self.resolve_generic_enum_payload(resolved, gi_base, v_name, payload_count)
        for bi in 0..bind_count:
            let inner = self.ast.get_extra(v_extra + bi)
            // Extras may be NK_PAT_IDENT nodes (from parser); extract symbol.
            var bind_sym = inner
            if inner > 0 and inner < self.ast.node_count() and self.ast.kind(inner) == NK_PAT_IDENT:
                bind_sym = self.ast.get_data0(inner)
            var bind_ty = if bi < payload_count: self.type_extra.get((payload_start + bi) as i64) else: 0
            if bi < gi_payload_types_sh.len() as i32:
                let gi_ty = gi_payload_types_sh.get(bi as i64)
                if gi_ty != 0:
                    bind_ty = gi_ty
            self.scope_put(bind_sym, bind_ty, 0)
        return

    if kind == NK_PAT_OR:
        let p_extra = self.ast.get_data0(node)
        let p_count = self.ast.get_data1(node)
        for pi in 0..p_count:
            self.check_pattern(self.ast.get_extra(p_extra + pi), subject_type)
        return

    if kind == NK_PAT_AT_BINDING:
        let at_name = self.ast.get_data0(node)
        let inner = self.ast.get_data1(node)
        self.scope_put(at_name, subject_type, 0)
        self.check_pattern(inner, subject_type)
        return

    if kind == NK_PAT_TUPLE:
        let t_extra = self.ast.get_data0(node)
        let t_count = self.ast.get_data1(node)
        var elem_start = 0
        var elem_count = 0
        let resolved = self.resolve_alias(subject_type)
        if self.get_type_kind(resolved) == TY_TUPLE:
            elem_start = self.get_type_d0(resolved)
            elem_count = self.get_type_d1(resolved)
        for ti in 0..t_count:
            let elem_ty = if ti < elem_count: self.type_extra.get((elem_start + ti) as i64) else: 0
            self.check_pattern(self.ast.get_extra(t_extra + ti), elem_ty)
        return

    if kind == NK_PAT_SLICE:
        let s_extra = self.ast.get_data0(node)
        let head_count = self.ast.get_data1(node)
        let rest_sym = self.ast.get_data2(node)
        var elem_type = 0
        let resolved = self.resolve_alias(subject_type)
        let stk = self.get_type_kind(resolved)
        if stk == TY_ARRAY:
            elem_type = self.get_type_d0(resolved)
        if stk == TY_SLICE:
            elem_type = self.get_type_d0(resolved)
        let has_rest = self.ast.get_extra(s_extra)
        for hi in 0..head_count:
            let h_sym = self.ast.get_extra(s_extra + 1 + hi)
            if h_sym != 0:
                self.scope_put(h_sym, elem_type, 0)
        if has_rest != 0 and rest_sym != 0:
            self.scope_put(rest_sym, self.ty_i64, 0)
        let tail_count = self.ast.get_extra(s_extra + 1 + head_count)
        for ti in 0..tail_count:
            let t_sym = self.ast.get_extra(s_extra + 2 + head_count + ti)
            if t_sym != 0:
                self.scope_put(t_sym, elem_type, 0)
        return

    if kind == NK_PAT_STRUCT:
        let sp_extra = self.ast.get_data1(node)
        let sp_count = self.ast.get_data2(node)
        let has_rest = self.ast.get_extra(sp_extra)
        var field_start = 0
        var field_count = 0
        let resolved = self.resolve_alias(subject_type)
        if self.get_type_kind(resolved) == TY_STRUCT:
            field_start = self.get_type_d1(resolved)
            field_count = self.get_type_d2(resolved)
        for spi in 0..sp_count:
            let f_name = self.ast.get_extra(sp_extra + 1 + spi * 2)
            let f_pat = self.ast.get_extra(sp_extra + 1 + spi * 2 + 1)
            var field_ty = 0
            for fi in 0..field_count:
                let name_sym = self.type_extra.get((field_start + fi * 3) as i64)
                if name_sym == f_name:
                    field_ty = self.type_extra.get((field_start + fi * 3 + 1) as i64)
                    break
            if f_pat != 0:
                self.check_pattern(f_pat, field_ty)
            else:
                self.scope_put(f_name, field_ty, 0)
        return

fn Sema.check_enum_variant(self: Sema, node: i32) -> i32:
    let type_name = self.ast.get_data0(node)
    let variant_name = self.ast.get_data1(node)
    let extra_start = self.ast.get_data2(node)
    let arg_count = self.ast.get_extra(extra_start)
    for ai in 0..arg_count:
        self.check_expr(self.ast.get_extra(extra_start + 1 + ai))
    if self.named_types.contains(type_name):
        return self.resolve_alias(self.named_types.get(type_name).unwrap())
    0

fn Sema.check_closure(self: Sema, node: i32) -> i32:
    let body = self.ast.get_data0(node)
    let extra_start = self.ast.get_data1(node)
    let param_count = self.ast.get_data2(node)
    let outer_count = self.bind_names.len() as i32

    // `it` arity validation: if this is an implicit `it` closure (param_count==1,
    // param name is "__it") and the expected type is a fn with != 1 params, error.
    if param_count == 1 and self.has_expected_type != 0:
        let p_sym = self.ast.get_extra(extra_start)
        let p_name = self.pool_resolve(p_sym)
        if p_name == "__it":
            let expected = self.resolve_alias(self.expected_expr_type)
            if self.get_type_kind(expected) == TY_FN:
                let expected_params = self.get_type_d1(expected)
                if expected_params != 1:
                    self.emit_error("`it` used in context expecting " ++ int_to_string(expected_params) ++ " parameter(s)", node)

    // Save borrow state — closure body borrows are local to the closure.
    let saved_borrow_len = self.borrow_kinds.len() as i32

    self.push_scope()
    let te_start = self.type_extra.len() as i32
    for pi in 0..param_count:
        let p_sym = self.ast.get_extra(extra_start + pi * 2)
        self.scope_put(p_sym, self.ty_i32, 0)
        self.type_extra.push(self.ty_i32)
    self.check_expr(body)

    // Phase 1 ephemerality rule: closures cannot capture ephemeral refs/values.
    var bi = 0
    while bi < outer_count:
        let cap_sym = self.bind_names.get(bi as i64)
        if self.expr_uses_symbol(body, cap_sym) != 0:
            let cap_ty = self.bind_types.get(bi as i64)
            if self.type_is_ephemeral_value(cap_ty) != 0:
                self.emit_error("closures cannot capture ephemeral references", node)
                break
        bi = bi + 1
    self.pop_scope()

    // Restore borrow state — discard borrows created inside closure body.
    while self.borrow_kinds.len() as i32 > saved_borrow_len:
        self.borrow_kinds.pop()
        self.borrow_places.pop()
        self.borrow_fields.pop()
        self.borrow_refs.pop()
        self.borrow_path_starts.pop()
        self.borrow_path_counts.pop()

    // Mark non-escaping if this closure is a direct call argument
    let is_non_escaping = self.closure_direct_arg_depth > 0 and self.ast.is_move_closure(node) == 0
    if is_non_escaping:
        self.ast.mark_non_escaping_closure(node)
        // Register borrows for captured variables.
        // Non-escaping closures capture by reference — register as borrows
        // so the borrow checker can detect conflicts with other borrows.
        // If the variable is only accessed through field paths, register
        // field-level borrows for disjoint capture checking.
        var ci = 0
        while ci < outer_count:
            let cap_sym = self.bind_names.get(ci as i64)
            if self.expr_uses_symbol(body, cap_sym) != 0:
                if self.capture_is_field_only(body, cap_sym) != 0:
                    // Field-level capture: register borrow per field path
                    // Clear transient capture field storage
                    while self.capture_field_syms.len() > 0:
                        self.capture_field_syms.pop()
                        self.capture_field_kinds.pop()
                    self.collect_capture_fields(body, cap_sym)
                    var fi = 0
                    while fi < self.capture_field_syms.len() as i32:
                        let field_sym = self.capture_field_syms.get(fi as i64)
                        let bk = self.capture_field_kinds.get(fi as i64)
                        let path_start = self.borrow_path_data.len() as i32
                        self.borrow_path_data.push(field_sym)
                        self.check_borrow_create_direct(cap_sym, bk, field_sym, path_start, 1, node)
                        fi = fi + 1
                else:
                    // Whole-variable capture
                    let bk = if self.expr_mutates_place(body, cap_sym) != 0: BK_EXCLUSIVE else: BK_SHARED
                    let path_start = self.borrow_path_data.len() as i32
                    self.check_borrow_create_direct(cap_sym, bk, 0, path_start, 0, node)
            ci = ci + 1

    // Escaping closures (including move closures) consume non-Copy captures.
    // Mark captured non-Copy variables as moved so subsequent uses error.
    let is_escaping = not is_non_escaping
    if is_escaping:
        var ci = 0
        while ci < outer_count:
            let cap_sym = self.bind_names.get(ci as i64)
            if self.expr_uses_symbol(body, cap_sym) != 0:
                let cap_ty = self.bind_types.get(ci as i64)
                if not self.is_copy(cap_ty):
                    self.scope_set_state(cap_sym, VS_MOVED)
            ci = ci + 1

    self.add_type(TY_FN, te_start, param_count, self.ty_i32)

fn Sema.check_pipeline(self: Sema, node: i32) -> i32:
    let lhs = self.ast.get_data0(node)
    let rhs = self.ast.get_data1(node)
    self.check_expr(lhs)
    let saved = self.in_pipeline_rhs
    self.in_pipeline_rhs = 1
    let rhs_ty = self.check_expr(rhs)
    self.in_pipeline_rhs = saved
    if rhs_ty != 0:
        let resolved = self.resolve_alias(rhs_ty)
        if self.get_type_kind(resolved) == TY_FN:
            return self.get_type_d2(resolved)
    rhs_ty

fn Sema.check_tuple(self: Sema, node: i32) -> i32:
    let extra_start = self.ast.get_data0(node)
    let elem_count = self.ast.get_data1(node)
    let te_start = self.type_extra.len() as i32
    for ei in 0..elem_count:
        let elem = self.ast.get_extra(extra_start + ei)
        let et = self.check_expr(elem)
        self.type_extra.push(et)
    let result = self.add_type(TY_TUPLE, te_start, elem_count, 0)
    self.typed_expr_types.insert(node, result)
    result

fn Sema.check_range(self: Sema, node: i32) -> i32:
    let start = self.ast.get_data0(node)
    let end = self.ast.get_data1(node)
    let inclusive = self.ast.get_data2(node)
    var elem_type = self.ty_i32
    if start != 0:
        elem_type = self.check_expr(start)
    if end != 0:
        let end_ty = self.check_expr(end)
        if start == 0:
            elem_type = end_ty
    self.add_type(TY_RANGE, elem_type, inclusive, 0)

fn Sema.check_with_expr(self: Sema, node: i32) -> i32:
    let source = self.ast.get_data0(node)
    let body = self.ast.get_data1(node)
    let encoded_name = self.ast.get_data2(node)
    let name = decode_with_binding_sym(encoded_name)
    let is_mut = decode_with_binding_is_mut(encoded_name)
    let source_ty = self.check_expr(source)
    self.push_scope()
    self.scope_put(name, source_ty, is_mut)
    let body_ty = self.check_expr(body)
    self.pop_scope()
    // Form 2 builder rule: `with <expr> as mut x:` returns `x` when body
    // ends in Unit; otherwise returns the final expression value.
    if is_mut != 0 and body_ty == self.ty_void:
        return source_ty
    body_ty

fn Sema.check_record_update(self: Sema, node: i32) -> i32:
    let source = self.ast.get_data0(node)
    let extra_start = self.ast.get_data1(node)
    let field_count = self.ast.get_data2(node)
    let source_ty = self.check_expr(source)
    for fi in 0..field_count:
        let f_name = self.ast.get_extra(extra_start + fi * 2)
        let f_value = self.ast.get_extra(extra_start + fi * 2 + 1)
        self.check_expr(f_value)
    if source_ty != 0 and source_ty != self.ty_void:
        self.typed_expr_types.insert(node, source_ty)
    source_ty

fn Sema.check_let_else(self: Sema, node: i32) -> i32:
    let pattern = self.ast.get_data0(node)
    let value = self.ast.get_data1(node)
    let else_body = self.ast.get_data2(node)
    let val_type = self.check_expr(value)
    self.check_pattern(pattern, val_type)
    self.check_expr(else_body)
    self.ty_void

fn Sema.check_tuple_destructure(self: Sema, node: i32) -> i32:
    let extra_start = self.ast.get_data0(node)
    let name_count = self.ast.get_data1(node)
    let value = self.ast.get_data2(node)
    let val_type = self.check_expr(value)
    let resolved = self.resolve_alias(val_type)
    let is_tuple = self.get_type_kind(resolved) == TY_TUPLE
    if is_tuple == 0:
        self.emit_error("tuple destructuring requires tuple type", node)
    let elem_start = if is_tuple != 0: self.get_type_d0(resolved) else: 0
    let elem_count = if is_tuple != 0: self.get_type_d1(resolved) else: 0
    // Check for rest pattern (negative sym value)
    var has_rest = false
    var rest_pos = -1
    for ni in 0..name_count:
        let n_sym = self.ast.get_extra(extra_start + ni)
        if n_sym < 0:
            has_rest = true
            rest_pos = ni
    if has_rest:
        // Bind elements before rest
        for ni in 0..rest_pos:
            let n_sym = self.ast.get_extra(extra_start + ni)
            var bind_ty = 0
            if ni < elem_count:
                bind_ty = self.type_extra.get((elem_start + ni) as i64)
            if n_sym > 0:
                self.scope_put(n_sym, bind_ty, 0)
        // Rest binding: bind to sub-tuple of remaining elements
        let rest_sym = 0 - self.ast.get_extra(extra_start + rest_pos)
        let after_rest = name_count - rest_pos - 1
        let rest_elem_count = elem_count - rest_pos - after_rest
        if rest_sym > 0 and rest_elem_count > 0:
            // Build sub-tuple type
            let te_start = self.type_extra.len() as i32
            for ri in 0..rest_elem_count:
                let idx = rest_pos + ri
                if idx < elem_count:
                    self.type_extra.push(self.type_extra.get((elem_start + idx) as i64))
                else:
                    self.type_extra.push(0)
            let rest_ty = self.add_type(TY_TUPLE, 0, te_start, rest_elem_count)
            self.scope_put(rest_sym, rest_ty, 0)
        else if rest_sym > 0:
            self.scope_put(rest_sym, self.ty_void, 0)
        // Bind elements after rest
        for ni in 0..after_rest:
            let n_sym = self.ast.get_extra(extra_start + rest_pos + 1 + ni)
            let elem_idx = elem_count - after_rest + ni
            var bind_ty = 0
            if elem_idx >= 0 and elem_idx < elem_count:
                bind_ty = self.type_extra.get((elem_start + elem_idx) as i64)
            if n_sym > 0:
                self.scope_put(n_sym, bind_ty, 0)
    else:
        var emitted_arity_error = 0
        for ni in 0..name_count:
            let n_sym = self.ast.get_extra(extra_start + ni)
            var bind_ty = 0
            if ni < elem_count:
                bind_ty = self.type_extra.get((elem_start + ni) as i64)
            else:
                if emitted_arity_error == 0 and is_tuple != 0:
                    self.emit_error("tuple destructuring arity mismatch", node)
                    emitted_arity_error = 1
            if n_sym > 0:
                self.scope_put(n_sym, bind_ty, 0)
    self.ty_void

fn Sema.is_sizeof_or_alignof(self: Sema, callee: i32) -> i32:
    let kind = self.ast.kind(callee)
    if kind != NK_TYPE_GENERIC and kind != NK_INDEX:
        return 0
    let gi_base = self.ast.get_data0(callee)
    if self.ast.kind(gi_base) != NK_IDENT:
        return 0
    let gi_name = self.pool_resolve(self.ast.get_data0(gi_base))
    if gi_name == "sizeof" or gi_name == "size_of":
        return 1
    if gi_name == "alignof" or gi_name == "align_of":
        return 1
    0

fn Sema.is_nameof_call(self: Sema, callee: i32) -> i32:
    let kind = self.ast.kind(callee)
    if kind != NK_TYPE_GENERIC and kind != NK_INDEX:
        return 0
    let gi_base = self.ast.get_data0(callee)
    if self.ast.kind(gi_base) != NK_IDENT:
        return 0
    let gi_name = self.pool_resolve(self.ast.get_data0(gi_base))
    if gi_name == "nameof" or gi_name == "type_name":
        return 1
    0

fn Sema.is_transmute_call(self: Sema, callee: i32) -> i32:
    let kind = self.ast.kind(callee)
    if kind != NK_TYPE_GENERIC and kind != NK_INDEX:
        return 0
    let gi_base = self.ast.get_data0(callee)
    if self.ast.kind(gi_base) != NK_IDENT:
        return 0
    let gi_name = self.pool_resolve(self.ast.get_data0(gi_base))
    if gi_name == "transmute":
        return 1
    0

fn Sema.transmute_target_type(self: Sema, callee: i32) -> i32:
    let tp_node = if self.ast.kind(callee) == NK_TYPE_GENERIC:
        let tp_start = self.ast.get_data1(callee)
        let tp_count = self.ast.get_data2(callee)
        if tp_count == 0:
            return 0
        self.ast.get_extra(tp_start)
    else:
        self.ast.get_data1(callee)
    self.resolve_type_expr(tp_node)

fn Sema.check_call(self: Sema, node: i32) -> i32:
    let callee = self.ast.get_data0(node)
    let extra_start = self.ast.get_data1(node)
    let arg_count = self.ast.get_data2(node)

    // sizeof[T]() / alignof[T]() / transmute[T]() / nameof[T]() builtins
    if self.is_sizeof_or_alignof(callee) != 0:
        return self.ty_i64
    if self.is_nameof_call(callee) != 0:
        return self.ty_str
    if self.is_transmute_call(callee) != 0:
        return self.transmute_target_type(callee)

    // Method call: callee is field_access
    if self.ast.kind(callee) == NK_FIELD_ACCESS:
        return self.check_method_call(callee, extra_start, arg_count, node)

    // Direct call: callee should be ident
    var fn_sym = 0
    if self.ast.kind(callee) == NK_IDENT:
        fn_sym = self.ast.get_data0(callee)
    else:
        self.check_expr(callee)
        for ai in 0..arg_count:
            self.check_expr(self.ast.get_extra(extra_start + ai))
        return 0

    let param_offset = if self.in_pipeline_rhs != 0: 1 else: 0
    let sig_idx_raw = self.get_sig(fn_sym)
    let sig_idx = if sig_idx_raw >= 0 and self.is_ci_visible(fn_sym) == 0: 0 - 1 else: sig_idx_raw
    let variant_expected_ty = if self.variant_lookup.contains(fn_sym) and self.is_ci_visible(fn_sym) != 0: self.expected_variant_constructor_type(fn_sym) else: 0
    let variant_payload_tys = if variant_expected_ty != 0: self.enum_variant_payload_types(variant_expected_ty, fn_sym) else: Vec.new()

    // Check all arguments (with contextual expected-type propagation when
    // calling a known function signature).
    let arg_types: Vec[i32] = Vec.new()
    for ai in 0..arg_count:
        let arg_node = self.ast.get_extra(extra_start + ai)
        var expected_ty = 0
        if sig_idx >= 0:
            let param_i = ai + param_offset
            if param_i < self.sig_get_param_count(sig_idx):
                expected_ty = self.sig_param_type(sig_idx, param_i)
        else if ai < variant_payload_tys.len() as i32:
            expected_ty = variant_payload_tys.get(ai as i64)
        let is_closure_arg = self.ast.kind(arg_node) == NK_CLOSURE
        if is_closure_arg:
            self.closure_direct_arg_depth = self.closure_direct_arg_depth + 1
        let arg_ty = if expected_ty != 0: self.check_expr_with_expected(arg_node, expected_ty) else: self.check_expr(arg_node)
        if is_closure_arg:
            self.closure_direct_arg_depth = self.closure_direct_arg_depth - 1
        arg_types.push(arg_ty)

    // Mark non-Copy args as moved
    for ai in 0..arg_count:
        self.mark_moved_if_consumed(self.ast.get_extra(extra_start + ai))

    // Known function
    if sig_idx >= 0:
        let ret = self.sig_return_type(sig_idx)
        // Check arg count (supports default parameters via required-count
        // metadata packed into fn_meta flags by the parser).
        let expected = self.sig_get_param_count(sig_idx)
        let min_expected = self.fn_min_expected_arg_count(fn_sym, expected)
        let actual = arg_count + param_offset
        if self.sig_is_variadic(sig_idx) == 0:
            if actual < min_expected or actual > expected:
                let fn_name = self.pool_resolve(fn_sym)
                if min_expected == expected:
                    self.emit_error("function '" ++ fn_name ++ "' expects " ++ int_to_string(expected) ++ " argument(s), found " ++ int_to_string(actual), node)
                else:
                    self.emit_error("function '" ++ fn_name ++ "' expects " ++ int_to_string(min_expected) ++ "-" ++ int_to_string(expected) ++ " argument(s), found " ++ int_to_string(actual), node)

        for ai in 0..arg_count:
            let param_i = ai + param_offset
            if param_i >= expected:
                break
            let expected_ty = self.sig_param_type(sig_idx, param_i)
            let arg_ty = arg_types.get(ai as i64)
            if expected_ty != 0 and arg_ty != 0:
                let exp_resolved = self.resolve_alias(expected_ty)
                if self.type_is_dyn_object(exp_resolved) == 0:
                    if self.types_compatible(expected_ty, arg_ty) == 0:
                        if self.arithmetic_result_type(expected_ty, arg_ty) == 0:
                            if not (self.ci_syms.contains(fn_sym) and self.try_ci_coercion(arg_ty, expected_ty) != 0):
                                self.emit_argument_type_mismatch(self.safe_symbol_text(fn_sym), fn_sym, ai, param_i, expected_ty, arg_ty, self.ast.get_extra(extra_start + ai))
            let arg_node = self.ast.get_extra(extra_start + ai)
            if self.expr_is_ephemeral_task(arg_node) != 0 and self.param_is_by_reference(expected_ty) == 0:
                self.emit_warning("ephemeral Task passed by value may escape", arg_node)

        self.check_dyn_trait_call_compat(fn_sym, extra_start, arg_types, arg_count, param_offset)
        return ret

    // Local variable (function pointer)
    let local_tid = self.scope_lookup(fn_sym)
    if local_tid >= 0:
        let resolved = self.resolve_alias(local_tid)
        if self.get_type_kind(resolved) == TY_FN:
            return self.get_type_d2(resolved)
        self.emit_error("value is not callable", callee)
        return 0

    // Generic function
    if self.generic_fn_nodes.contains(fn_sym):
        let fn_node = self.generic_fn_nodes.get(fn_sym).unwrap()
        return self.check_generic_call(fn_sym, fn_node, arg_types, arg_count, node)

    // Enum variant constructor
    if self.variant_lookup.contains(fn_sym):
        if variant_expected_ty != 0:
            return variant_expected_ty
        return self.variant_type_ids.get(fn_sym).unwrap()

    // Distinct type constructor: Meters(42) → Meters { value: 42 }
    if self.distinct_type_names.contains(fn_sym):
        let dt_tid = self.distinct_type_names.get(fn_sym).unwrap()
        if arg_count != 1:
            self.emit_error("distinct type constructor requires exactly 1 argument", node)
            return 0
        return dt_tid

    // Callable type syntax: TypeName(args) → TypeName.new(args)
    if self.type_decl_nodes.contains(fn_sym):
        let new_name = self.pool_resolve(fn_sym) ++ ".new"
        let new_sym = self.pool_intern(new_name)
        let new_sig = self.get_sig(new_sym)
        if new_sig >= 0:
            let new_ret = self.sig_return_type(new_sig)
            let new_expected = self.sig_get_param_count(new_sig)
            if arg_count > new_expected:
                self.emit_error("too many arguments for " ++ self.pool_resolve(fn_sym) ++ "()", node)
            return new_ret

    // Intrinsic function
    if self.is_intrinsic_fn_sym(fn_sym) != 0:
        return self.check_intrinsic_call(fn_sym, node, arg_types, arg_count)

    let callee_ty = self.check_ident(fn_sym, callee)
    if callee_ty != 0:
        self.emit_error("value is not callable", callee)
    0

fn Sema.fn_min_expected_arg_count(self: Sema, fn_sym: i32, fallback_expected: i32) -> i32:
    if fallback_expected <= 0:
        return fallback_expected
    if not self.fn_decl_nodes.contains(fn_sym):
        return fallback_expected
    let fn_node = self.fn_decl_nodes.get(fn_sym).unwrap()
    let meta = self.ast.find_fn_meta(fn_node)
    if meta < 0:
        return fallback_expected
    let meta_flags = self.ast.fn_meta_flags(meta)
    let required = meta_flags / FN_META_REQUIRED_UNIT
    if required < 0:
        return fallback_expected
    if required > fallback_expected:
        return fallback_expected
    required

fn Sema.check_expr_with_expected(self: Sema, node: i32, expected: i32) -> i32:
    let saved_expected = self.expected_expr_type
    let saved_has = self.has_expected_type
    self.expected_expr_type = expected
    self.has_expected_type = if expected != 0: 1 else: 0
    let out = self.check_expr(node)
    self.expected_expr_type = saved_expected
    self.has_expected_type = saved_has
    out

fn Sema.enum_has_variant(self: Sema, enum_tid: i32, variant_sym: i32) -> i32:
    let resolved = self.resolve_alias(enum_tid)
    if self.get_type_kind(resolved) != TY_ENUM:
        return 0
    let te_start = self.get_type_d1(resolved)
    let variant_count = self.get_type_d2(resolved)
    var pos = te_start
    for vi in 0..variant_count:
        let v_name = self.type_extra.get(pos as i64)
        let payload_count = self.type_extra.get((pos + 1) as i64)
        if v_name == variant_sym:
            return 1
        pos = pos + 2 + payload_count
    0

fn Sema.check_dyn_trait_call_compat(self: Sema, fn_sym: i32, call_extra_start: i32, arg_types: Vec[i32], arg_count: i32, param_offset: i32):
    if not self.fn_decl_nodes.contains(fn_sym):
        return
    let fn_node = self.fn_decl_nodes.get(fn_sym).unwrap()
    let meta = self.ast.find_fn_meta(fn_node)
    if meta < 0:
        return

    let param_start = self.ast.fn_meta_param_start(meta)
    let param_count = self.ast.fn_meta_param_count(meta)
    for ai in 0..arg_count:
        let param_i = ai + param_offset
        if param_i >= param_count:
            break

        let p_type_node = self.ast.fn_param_type(param_start, param_i)
        let trait_sym = self.trait_object_from_type_node(p_type_node)
        if trait_sym == 0:
            continue

        let arg_ty = arg_types.get(ai as i64)
        let concrete_sym = self.dyn_arg_concrete_type_symbol(arg_ty)
        if concrete_sym == 0:
            self.emit_error("argument cannot be converted to dyn trait object", self.ast.get_extra(call_extra_start + ai))
            continue

        if self.select_trait_impl(concrete_sym, trait_sym) == 0:
            let type_str = self.pool_resolve(concrete_sym)
            let trait_str = self.pool_resolve(trait_sym)
            self.emit_error("type '" ++ type_str ++ "' does not implement trait '" ++ trait_str ++ "' required for dyn parameter", self.ast.get_extra(call_extra_start + ai))
            continue

        self.obligation_trait_syms.push(trait_sym)
        self.obligation_type_syms.push(concrete_sym)
        self.obligation_nodes.push(self.ast.get_extra(call_extra_start + ai))

fn Sema.check_generic_call(self: Sema, fn_sym: i32, fn_node: i32, arg_types: Vec[i32], arg_count: i32, call_node: i32) -> i32:
    let meta = self.ast.find_fn_meta(fn_node)
    if meta < 0:
        if arg_count > 0:
            return arg_types.get(0)
        return 0

    let param_start = self.ast.fn_meta_param_start(meta)
    let param_count = self.ast.fn_meta_param_count(meta)
    let tp_start = self.ast.fn_meta_tp_start(meta)
    let tp_count = self.ast.fn_meta_tp_count(meta)
    let ret_node = self.ast.fn_meta_ret(meta)

    if arg_count != param_count:
        self.emit_error("wrong argument count", call_node)

    self.clear_generic_substitution()

    // Infer type parameter substitutions from call argument types.
    for pi in 0..param_count:
        if pi >= arg_count:
            break
        let p_type_node = self.ast.fn_param_type(param_start, pi)
        let arg_ty = arg_types.get(pi as i64)
        self.bind_type_params_from_type_expr(p_type_node, arg_ty, tp_start, tp_count, call_node)

    // Obligation model: collect and solve trait bounds for each bound type parameter.
    self.check_generic_trait_bounds(tp_start, tp_count, call_node)
    // Also check where clause bounds if present
    let where_idx = self.ast.find_where_meta(fn_node)
    if where_idx >= 0:
        let where_start = self.ast.where_meta.get((where_idx + 1) as i64)
        let where_count = self.ast.where_meta.get((where_idx + 2) as i64)
        self.check_generic_trait_bounds(where_start, where_count, call_node)
    self.ensure_generic_substitutions(tp_start, tp_count, param_start, param_count, call_node)

    let spec_key = self.generic_specialization_key(fn_sym, tp_start, tp_count)
    if self.generic_specialization_cache.contains(spec_key):
        return self.generic_specialization_cache.get(spec_key).unwrap()

    let resolved_ret = self.resolve_generic_return_type_node(ret_node, tp_start, tp_count)
    self.generic_specialization_cache.insert(spec_key, resolved_ret)
    resolved_ret

fn Sema.clear_generic_substitution(self: Sema):
    while self.generic_subst_param_syms.len() > 0:
        self.generic_subst_param_syms.pop()
        self.generic_subst_type_ids.pop()

fn Sema.lookup_generic_subst(self: Sema, param_sym: i32) -> i32:
    var i = self.generic_subst_param_syms.len() as i32 - 1
    while i >= 0:
        if self.generic_subst_param_syms.get(i as i64) == param_sym:
            return self.generic_subst_type_ids.get(i as i64)
        i = i - 1
    0

fn Sema.put_generic_subst(self: Sema, param_sym: i32, tid: i32, node: i32):
    if tid == 0:
        return
    let existing = self.lookup_generic_subst(param_sym)
    if existing != 0:
        if self.types_compatible(existing, tid) == 0:
            if self.arithmetic_result_type(existing, tid) == 0:
                let tp_name = self.pool_resolve(param_sym)
                let a = self.type_name(existing)
                let b = self.type_name(tid)
                self.emit_error("cannot infer a single type for '" ++ tp_name ++ "': saw '" ++ a ++ "' and '" ++ b ++ "'", node)
        return

    self.generic_subst_param_syms.push(param_sym)
    self.generic_subst_type_ids.push(tid)

fn Sema.type_param_exists(self: Sema, tp_start: i32, tp_count: i32, sym: i32) -> i32:
    var pos = tp_start
    for ti in 0..tp_count:
        let tp_name = self.ast.get_extra(pos)
        let bound_count = self.ast.get_extra(pos + 1)
        if tp_name == sym:
            return 1
        pos = pos + 2 + bound_count
    0

fn Sema.bind_type_params_from_type_expr(self: Sema, type_node: i32, arg_tid: i32, tp_start: i32, tp_count: i32, err_node: i32):
    if type_node == 0 or arg_tid == 0:
        return

    let kind = self.ast.kind(type_node)

    if kind == NK_TYPE_NAMED:
        let sym = self.ast.get_data0(type_node)
        if self.type_param_exists(tp_start, tp_count, sym) != 0:
            self.put_generic_subst(sym, arg_tid, err_node)
        return

    if kind == NK_TYPE_REF:
        let inner_node = self.ast.get_data0(type_node)
        let resolved = self.resolve_alias(arg_tid)
        if self.get_type_kind(resolved) == TY_REF:
            self.bind_type_params_from_type_expr(inner_node, self.get_type_d0(resolved), tp_start, tp_count, err_node)
        return

    if kind == NK_TYPE_PTR:
        let inner_node = self.ast.get_data0(type_node)
        let resolved = self.resolve_alias(arg_tid)
        if self.get_type_kind(resolved) == TY_PTR:
            self.bind_type_params_from_type_expr(inner_node, self.get_type_d0(resolved), tp_start, tp_count, err_node)
        return

    if kind == NK_TYPE_ARRAY:
        let inner_node = self.ast.get_data0(type_node)
        let resolved = self.resolve_alias(arg_tid)
        if self.get_type_kind(resolved) == TY_ARRAY:
            self.bind_type_params_from_type_expr(inner_node, self.get_type_d0(resolved), tp_start, tp_count, err_node)
        return

    if kind == NK_TYPE_SLICE:
        let inner_node = self.ast.get_data0(type_node)
        let resolved = self.resolve_alias(arg_tid)
        if self.get_type_kind(resolved) == TY_SLICE:
            self.bind_type_params_from_type_expr(inner_node, self.get_type_d0(resolved), tp_start, tp_count, err_node)
        return

    if kind == NK_TYPE_TUPLE:
        let inner_start = self.ast.get_data0(type_node)
        let inner_count = self.ast.get_data1(type_node)
        let resolved = self.resolve_alias(arg_tid)
        if self.get_type_kind(resolved) != TY_TUPLE:
            return
        let te_start = self.get_type_d0(resolved)
        let elem_count = self.get_type_d1(resolved)
        let pair_count = if inner_count < elem_count: inner_count else: elem_count
        for ei in 0..pair_count:
            let inner_node = self.ast.get_extra(inner_start + ei)
            let arg_elem = self.type_extra.get((te_start + ei) as i64)
            self.bind_type_params_from_type_expr(inner_node, arg_elem, tp_start, tp_count, err_node)
        return

fn Sema.generic_specialization_key(self: Sema, fn_sym: i32, tp_start: i32, tp_count: i32) -> str:
    var key = int_to_string(fn_sym)
    var pos = tp_start
    for ti in 0..tp_count:
        let tp_name = self.ast.get_extra(pos)
        let bound_count = self.ast.get_extra(pos + 1)
        key = key ++ ":" ++ int_to_string(tp_name) ++ "=" ++ int_to_string(self.lookup_generic_subst(tp_name))
        pos = pos + 2 + bound_count
    key

fn Sema.check_generic_trait_bounds(self: Sema, tp_start: i32, tp_count: i32, call_node: i32):
    var pos = tp_start
    for ti in 0..tp_count:
        let tp_name = self.ast.get_extra(pos)
        let bound_count = self.ast.get_extra(pos + 1)
        let concrete_tid = self.lookup_generic_subst(tp_name)
        for bi in 0..bound_count:
            let trait_sym = self.ast.get_extra(pos + 2 + bi)
            let trait_name = self.pool_resolve(trait_sym)
            if trait_name == "type":
                continue
            if concrete_tid == 0:
                continue
            let concrete_sym = self.type_symbol_for_bounds(concrete_tid)
            if concrete_sym == 0:
                continue
            self.obligation_trait_syms.push(trait_sym)
            self.obligation_type_syms.push(concrete_sym)
            self.obligation_nodes.push(call_node)
            if self.select_trait_impl(concrete_sym, trait_sym) == 0:
                let type_str = self.pool_resolve(concrete_sym)
                let tp_str = self.pool_resolve(tp_name)
                self.emit_error("type '" ++ type_str ++ "' does not implement trait '" ++ trait_name ++ "' required by bound '" ++ tp_str ++ ": " ++ trait_name ++ "'", call_node)
        pos = pos + 2 + bound_count

fn Sema.resolve_generic_return_type_node(self: Sema, ret_node: i32, tp_start: i32, tp_count: i32) -> i32:
    if ret_node == 0:
        return self.ty_void

    let kind = self.ast.kind(ret_node)

    if kind == NK_TYPE_NAMED:
        let sym = self.ast.get_data0(ret_node)
        if self.type_param_exists(tp_start, tp_count, sym) != 0:
            return self.lookup_generic_subst(sym)
        return self.resolve_type_expr(ret_node)

    if kind == NK_TYPE_REF:
        let pointee = self.resolve_generic_return_type_node(self.ast.get_data0(ret_node), tp_start, tp_count)
        let is_mut = self.ast.get_data1(ret_node)
        return self.ensure_exact_type(TY_REF, pointee, is_mut, 0)

    if kind == NK_TYPE_PTR:
        let pointee = self.resolve_generic_return_type_node(self.ast.get_data0(ret_node), tp_start, tp_count)
        let is_mut = self.ast.get_data1(ret_node)
        return self.ensure_exact_type(TY_PTR, pointee, is_mut, 0)

    if kind == NK_TYPE_ARRAY:
        let elem = self.resolve_generic_return_type_node(self.ast.get_data0(ret_node), tp_start, tp_count)
        let size = self.ast.get_data1(ret_node)
        return self.ensure_exact_type(TY_ARRAY, elem, size, 0)

    if kind == NK_TYPE_SLICE:
        let elem = self.resolve_generic_return_type_node(self.ast.get_data0(ret_node), tp_start, tp_count)
        return self.ensure_exact_type(TY_SLICE, elem, 0, 0)

    if kind == NK_TYPE_TUPLE:
        let extra_start = self.ast.get_data0(ret_node)
        let elem_count = self.ast.get_data1(ret_node)
        let tuple_elems: Vec[i32] = Vec.new()
        for ei in 0..elem_count:
            let e_node = self.ast.get_extra(extra_start + ei)
            tuple_elems.push(self.resolve_generic_return_type_node(e_node, tp_start, tp_count))
        return self.ensure_tuple_type(tuple_elems, elem_count)

    if kind == NK_TYPE_GENERIC:
        let gi_base = self.ast.get_data0(ret_node)
        let gi_extra = self.ast.get_data1(ret_node)
        let gi_argc = self.ast.get_data2(ret_node)
        let gi_args: Vec[i32] = Vec.new()
        for gi in 0..gi_argc:
            let ga_node = self.ast.get_extra(gi_extra + gi)
            let ga_tid = self.resolve_generic_return_type_node(ga_node, tp_start, tp_count)
            if ga_tid == 0:
                return 0
            gi_args.push(ga_tid)
        return self.ensure_generic_inst_type(gi_base, gi_args, gi_argc)

    if kind == NK_TYPE_OPTIONAL:
        let inner = self.resolve_generic_return_type_node(self.ast.get_data0(ret_node), tp_start, tp_count)
        let opt_args: Vec[i32] = Vec.new()
        opt_args.push(inner)
        return self.ensure_generic_inst_type(self.pool_intern("Option"), opt_args, 1)

    // @TypeOf(expr) — resolve the inner expression's type.
    // In generic context, if the inner expr is an identifier matching a type param,
    // resolve to the substituted type.
    if kind == NK_TYPE_TYPEOF:
        let inner_node = self.ast.get_data0(ret_node)
        let inner_kind = self.ast.kind(inner_node)
        if inner_kind == NK_IDENT:
            let sym = self.ast.get_data0(inner_node)
            if self.type_param_exists(tp_start, tp_count, sym) != 0:
                return self.lookup_generic_subst(sym)
        // Fall through: try to type-check the expression in current scope
        let expr_type = self.check_expr(inner_node)
        if expr_type > 0:
            return expr_type
        return 0

    self.resolve_type_expr(ret_node)

fn Sema.selection_cache_key(self: Sema, type_sym: i32, trait_sym: i32) -> str:
    int_to_string(type_sym) ++ ":" ++ int_to_string(trait_sym)

fn Sema.blanket_guard_contains(self: Sema, key: str) -> i32:
    var i = 0
    while i < self.blanket_guard.len() as i32:
        if self.blanket_guard.get(i as i64) == key:
            return 1
        i = i + 1
    0

fn Sema.select_trait_impl(self: Sema, type_sym: i32, trait_sym: i32) -> i32:
    let key = self.selection_cache_key(type_sym, trait_sym)
    if self.selection_cache.contains(key):
        return self.selection_cache.get(key).unwrap()

    // Cycle guard: if already resolving this pair, assume not found
    if self.blanket_guard_contains(key) != 0:
        return 0

    var found = 0
    // Check direct impls
    if self.impl_lookup.contains(type_sym):
        let idx = self.impl_lookup.get(type_sym).unwrap()
        let start = self.impl_starts.get(idx as i64)
        let count = self.impl_counts.get(idx as i64)
        for i in 0..count:
            if self.impl_extra.get((start + i) as i64) == trait_sym:
                found = 1

    // Check blanket impls: impl[T: Bound] Trait for T
    if found == 0:
        self.blanket_guard.push(key)
        for bi in 0..self.blanket_trait_syms.len() as i32:
            if self.blanket_trait_syms.get(bi as i64) != trait_sym:
                continue
            // For generic blanket impls (impl[T] Trait for Vec[T]),
            // only match if query type's base sym matches the target.
            let target_base = self.blanket_target_base_syms.get(bi as i64)
            if target_base != 0 and target_base != type_sym:
                continue
            // Check if type_sym satisfies all bounds
            let b_start = self.blanket_bound_starts.get(bi as i64)
            let b_count = self.blanket_bound_counts.get(bi as i64)
            var all_satisfied = 1
            for bj in 0..b_count:
                let bound_trait = self.blanket_bound_syms.get((b_start + bj) as i64)
                let bound_ok = self.select_trait_impl(type_sym, bound_trait)
                if bound_ok == 0:
                    all_satisfied = 0
            if all_satisfied != 0:
                found = 1
        self.blanket_guard.pop()

    self.selection_cache.insert(key, found)
    found

// Check if a TY_GENERIC_INST type implements a trait via exact-match impls.
fn Sema.select_trait_impl_for_generic_inst(self: Sema, tid: i32, trait_sym: i32) -> i32:
    let gi_key = i64_to_string(tid as i64) ++ ":" ++ i64_to_string(trait_sym as i64)
    if self.impl_generic_inst.contains(gi_key):
        return 1
    // Fall back to base symbol lookup (handles impl Trait for Vec without args)
    let base_sym = self.get_type_d0(tid)
    self.select_trait_impl(base_sym, trait_sym)

// Resolve an associated type from a specific impl: find the impl block for (type_sym, trait_sym)
// and look up the associated type binding for assoc_sym.
fn Sema.resolve_impl_assoc_type(self: Sema, type_sym: i32, trait_sym: i32, assoc_sym: i32) -> i32:
    // Search all impl decls for matching (type_sym, trait_sym)
    for di in 0..self.ast.decl_count():
        let decl = self.ast.get_decl(di)
        if self.ast.kind(decl) != NK_IMPL_DECL:
            continue
        let impl_type = self.ast.get_data0(decl)
        let impl_trait = self.ast.get_data2(decl)
        if impl_type != type_sym or impl_trait != trait_sym:
            continue
        // Found the impl — read its associated type bindings
        let impl_extra_start = self.ast.get_data1(decl)
        let impl_at_count = self.ast.get_extra(impl_extra_start)
        for iai in 0..impl_at_count:
            let at_name = self.ast.get_extra(impl_extra_start + 1 + iai * 2)
            if at_name == assoc_sym:
                let at_type_node = self.ast.get_extra(impl_extra_start + 1 + iai * 2 + 1)
                return self.resolve_type_expr(at_type_node)
        return 0
    0

fn Sema.type_symbol_for_bounds(self: Sema, tid: i32) -> i32:
    let resolved = self.resolve_alias(tid)
    let tk = self.get_type_kind(resolved)
    if tk == TY_STRUCT or tk == TY_ENUM or tk == TY_GENERIC_INST:
        return self.get_type_d0(resolved)
    if tk == TY_INT:
        let bits = self.get_type_d0(resolved)
        let signed = self.get_type_d1(resolved)
        if bits == 8:
            if signed != 0:
                return self.pool_intern("i8")
            return self.pool_intern("u8")
        if bits == 16:
            if signed != 0:
                return self.pool_intern("i16")
            return self.pool_intern("u16")
        if bits == 32:
            if signed != 0:
                return self.pool_intern("i32")
            return self.pool_intern("u32")
        if bits == 64:
            if signed != 0:
                return self.pool_intern("i64")
            return self.pool_intern("u64")
        if bits == 128:
            if signed != 0:
                return self.pool_intern("i128")
            return self.pool_intern("u128")
        return 0
    if tk == TY_FLOAT:
        if self.get_type_d0(resolved) == 32:
            return self.pool_intern("f32")
        return self.pool_intern("f64")
    if tk == TY_BOOL:
        return self.pool_intern("bool")
    if tk == TY_STR:
        return self.pool_intern("str")
    0

fn Sema.trait_object_from_type_node(self: Sema, type_node: i32) -> i32:
    if type_node == 0:
        return 0
    let kind = self.ast.kind(type_node)
    if kind == NK_TYPE_TRAIT_OBJ:
        return self.ast.get_data0(type_node)
    if kind == NK_TYPE_REF or kind == NK_TYPE_PTR:
        return self.trait_object_from_type_node(self.ast.get_data0(type_node))
    if kind == NK_TYPE_GENERIC:
        let base = self.ast.get_data0(type_node)
        if self.pool_resolve(base) != "Box":
            return 0
        let extra_start = self.ast.get_data1(type_node)
        let arg_count = self.ast.get_data2(type_node)
        if arg_count != 1:
            return 0
        return self.trait_object_from_type_node(self.ast.get_extra(extra_start))
    0

fn Sema.dyn_arg_concrete_type_symbol(self: Sema, tid: i32) -> i32:
    let resolved = self.resolve_alias(tid)
    let tk = self.get_type_kind(resolved)
    if tk == TY_REF or tk == TY_PTR:
        return self.type_symbol_for_bounds(self.get_type_d0(resolved))
    self.type_symbol_for_bounds(resolved)

// Set up generic substitution for a TY_GENERIC_INST type.
// Maps each type param name → concrete type arg from the generic instance.
// Returns 1 on success, 0 on failure (missing type decl, param mismatch, etc).
fn Sema.setup_generic_inst_substitution(self: Sema, gi_tid: i32, type_sym: i32) -> i32:
    if not self.type_decl_nodes.contains(type_sym):
        return 0
    let td_node = self.type_decl_nodes.get(type_sym).unwrap()
    let td_extra_start = self.ast.get_data1(td_node)
    let td_packed = self.ast.get_data2(td_node)
    let td_sub_kind = type_decl_sub_kind(td_packed)
    var td_tp_start = 0
    var td_tp_count = 0
    if td_sub_kind == TDK_STRUCT:
        let fc = self.ast.get_extra(td_extra_start)
        let after = td_extra_start + 1 + fc * 4
        td_tp_start = self.ast.get_extra(after + 1)
        td_tp_count = self.ast.get_extra(after + 2)
    else if td_sub_kind == TDK_ALIAS or td_sub_kind == TDK_DISTINCT:
        td_tp_start = self.ast.get_extra(td_extra_start + 2)
        td_tp_count = self.ast.get_extra(td_extra_start + 3)
    else if td_sub_kind == TDK_ENUM:
        // For enum: extra=[variant_count, [var_name, payload_count, payload_type...]*, vis, tp_start, tp_count]
        let vc = self.ast.get_extra(td_extra_start)
        var epos = td_extra_start + 1
        for vi in 0..vc:
            epos = epos + 1  // var_name
            let pc = self.ast.get_extra(epos)
            epos = epos + 1  // payload_count
            epos = epos + pc  // skip payload type nodes
        // epos now points at vis
        td_tp_start = self.ast.get_extra(epos + 1)
        td_tp_count = self.ast.get_extra(epos + 2)
    if td_tp_count == 0:
        return 0
    let gi_arg_count = self.get_generic_inst_arg_count(gi_tid)
    if gi_arg_count != td_tp_count:
        return 0
    self.clear_generic_substitution()
    var tp_pos = td_tp_start
    for ti in 0..td_tp_count:
        let tp_name = self.ast.get_extra(tp_pos)
        let bound_count = self.ast.get_extra(tp_pos + 1)
        let arg_tid = self.get_generic_inst_arg(gi_tid, ti)
        self.put_generic_subst(tp_name, arg_tid, 0)
        tp_pos = tp_pos + 2 + bound_count
    1

fn Sema.substitute_method_return_for_generic_inst(self: Sema, gi_tid: i32, type_sym: i32, method_sym: i32, sig_ret: i32) -> i32:
    // Set up type param → concrete arg substitution
    if self.setup_generic_inst_substitution(gi_tid, type_sym) == 0:
        return 0
    // Try substitute_type on the stored sig_ret first
    if sig_ret > 0:
        let subst_count = self.generic_subst_param_syms.len() as i32
        let result = self.substitute_type(sig_ret, self.generic_subst_param_syms, self.generic_subst_type_ids, subst_count)
        if result > 0:
            return result
    // Fallback: re-resolve from the method's return type AST node
    let method_name = self.pool_resolve(type_sym) ++ "." ++ self.pool_resolve(method_sym)
    let method_fn_sym = self.pool_intern(method_name)
    if not self.fn_decl_nodes.contains(method_fn_sym):
        return 0
    let fn_node = self.fn_decl_nodes.get(method_fn_sym).unwrap()
    let meta = self.ast.find_fn_meta(fn_node)
    if meta < 0:
        return 0
    let ret_node = self.ast.fn_meta_ret(meta)
    if ret_node == 0:
        return 0
    let td_node = self.type_decl_nodes.get(type_sym).unwrap()
    let td_extra_start = self.ast.get_data1(td_node)
    let td_packed = self.ast.get_data2(td_node)
    let td_sub_kind = type_decl_sub_kind(td_packed)
    var td_tp_start = 0
    var td_tp_count = 0
    if td_sub_kind == TDK_STRUCT:
        let fc = self.ast.get_extra(td_extra_start)
        let after = td_extra_start + 1 + fc * 4
        td_tp_start = self.ast.get_extra(after + 1)
        td_tp_count = self.ast.get_extra(after + 2)
    else if td_sub_kind == TDK_ALIAS or td_sub_kind == TDK_DISTINCT:
        td_tp_start = self.ast.get_extra(td_extra_start + 2)
        td_tp_count = self.ast.get_extra(td_extra_start + 3)
    else if td_sub_kind == TDK_ENUM:
        let vc = self.ast.get_extra(td_extra_start)
        var epos = td_extra_start + 1
        for vi in 0..vc:
            epos = epos + 1
            let pc = self.ast.get_extra(epos)
            epos = epos + 1
            epos = epos + pc
        td_tp_start = self.ast.get_extra(epos + 1)
        td_tp_count = self.ast.get_extra(epos + 2)
    self.resolve_generic_return_type_node(ret_node, td_tp_start, td_tp_count)

fn Sema.check_method_call(self: Sema, callee: i32, extra_start: i32, arg_count: i32, node: i32) -> i32:
    let expr = self.ast.get_data0(callee)
    let field = self.ast.get_data1(callee)
    let obj_type = self.check_expr(expr)
    let static_type_sym = self.static_receiver_base_sym(expr)

    // Check all arguments
    let arg_types: Vec[i32] = Vec.new()
    for ai in 0..arg_count:
        let mc_arg_node = self.ast.get_extra(extra_start + ai)
        let mc_is_closure = self.ast.kind(mc_arg_node) == NK_CLOSURE
        if mc_is_closure:
            self.closure_direct_arg_depth = self.closure_direct_arg_depth + 1
        arg_types.push(self.check_expr(mc_arg_node))
        if mc_is_closure:
            self.closure_direct_arg_depth = self.closure_direct_arg_depth - 1

    // Task/ScopedTask surface methods (spec §14.7): cancel(), is_done().
    if field == self.sym_cancel or field == self.sym_is_done:
        if self.expr_is_task_value(expr) == 0 and self.expr_is_scoped_task_value(expr) == 0:
            return 0
        if arg_count != 0:
            self.emit_error("task method expects zero arguments", node)
            return 0
        if field == self.sym_cancel:
            return self.ty_void
        return self.ty_bool

    if field == self.sym_track:
        if self.ast.kind(expr) != NK_IDENT or self.is_active_async_scope_symbol(self.ast.get_data0(expr)) == 0:
            self.emit_error("track() is only available inside async scope", node)
            return 0
        if arg_count <= 0:
            self.emit_error("track() requires a Task value", node)
            return 0
        let task_arg = self.ast.get_extra(extra_start)
        if self.expr_is_task_value(task_arg) == 0:
            self.emit_error("track() requires a Task value", task_arg)
        return arg_types.get(0)

    if obj_type == 0:
        return 0

    let resolved = self.resolve_alias(obj_type)
    let type_name_sym = self.get_type_name(resolved)

    if type_name_sym != 0:
        let method_key = self.method_key(type_name_sym, field)
        let sig_idx = self.get_sig(method_key)
        if sig_idx >= 0:
            let mc_ret = self.sig_return_type(sig_idx)
            // For TY_GENERIC_INST receivers, check arg types and substitute return type
            let mc_resolved_tk = self.get_type_kind(resolved)
            if mc_resolved_tk == TY_GENERIC_INST:
                // Check argument types against substituted parameter types
                let mc_method_name = self.pool_resolve(type_name_sym) ++ "." ++ self.pool_resolve(field)
                let mc_method_fn_sym = self.pool_intern(mc_method_name)
                if self.setup_generic_inst_substitution(resolved, type_name_sym) != 0:
                    let mc_subst_count = self.generic_subst_param_syms.len() as i32
                    // Check argument types via substitute_type on stored sig param types
                    let mc_sig_pc = self.sig_get_param_count(sig_idx)
                    // sig params include self as first param; user args start at index 1
                    let mc_sig_poff = if mc_sig_pc > 0: 1 else 0
                    for mc_ai in 0..arg_count:
                        let mc_sig_pi = mc_ai + mc_sig_poff
                        if mc_sig_pi >= mc_sig_pc:
                            break
                        let mc_stored_ty = self.sig_param_type(sig_idx, mc_sig_pi)
                        if mc_stored_ty <= 0:
                            continue
                        let exp_ty = self.substitute_type(mc_stored_ty, self.generic_subst_param_syms, self.generic_subst_type_ids, mc_subst_count)
                        let arg_ty = arg_types.get(mc_ai as i64)
                        if exp_ty != 0 and arg_ty != 0:
                            let exp_r = self.resolve_alias(exp_ty)
                            if self.type_is_dyn_object(exp_r) == 0:
                                if self.types_compatible(exp_ty, arg_ty) == 0:
                                    if self.arithmetic_result_type(exp_ty, arg_ty) == 0:
                                        self.emit_argument_type_mismatch(mc_method_name, mc_method_fn_sym, mc_ai, mc_sig_pi, exp_ty, arg_ty, self.ast.get_extra(extra_start + mc_ai))
                let mc_subst_ret = self.substitute_method_return_for_generic_inst(resolved, type_name_sym, field, mc_ret)
                if mc_subst_ret != 0:
                    return mc_subst_ret
            return mc_ret

    // For TY_GENERIC_INST receivers without a registered signature,
    // check argument types and return types for builtin generic methods
    if self.get_type_kind(resolved) == TY_GENERIC_INST:
        let mc_base_name = self.pool_resolve(type_name_sym)
        let mc_method = self.pool_resolve(field)
        let mc_call_name = mc_base_name ++ "." ++ mc_method
        let mc_push_sym = self.pool_intern("push")
        let mc_insert_sym = self.pool_intern("insert")
        let mc_vec_sym = self.pool_intern("Vec")
        let mc_veciter_sym = self.pool_intern("VecIter")
        let mc_option_sym = self.pool_intern("Option")
        if field == mc_push_sym:
            // Vec.push(value: T) / HashSet.insert(value: T) — arg[0] must be T
            if arg_count >= 1:
                let elem_ty = self.get_generic_inst_arg(resolved, 0)
                let a0_ty = arg_types.get(0)
                if elem_ty != 0 and a0_ty != 0:
                    if self.types_compatible(elem_ty, a0_ty) == 0:
                        if self.arithmetic_result_type(elem_ty, a0_ty) == 0:
                            self.emit_argument_type_mismatch(mc_call_name, 0, 0, 0, elem_ty, a0_ty, self.ast.get_extra(extra_start))
        else if field == mc_insert_sym:
            // HashMap.insert(key: K, value: V) — arg[0] must be K, arg[1] must be V
            let gi_argc = self.get_generic_inst_arg_count(resolved)
            if gi_argc >= 2 and arg_count >= 2:
                let key_ty = self.get_generic_inst_arg(resolved, 0)
                let val_ty = self.get_generic_inst_arg(resolved, 1)
                let a0_ty = arg_types.get(0)
                let a1_ty = arg_types.get(1)
                if key_ty != 0 and a0_ty != 0:
                    if self.types_compatible(key_ty, a0_ty) == 0:
                        if self.arithmetic_result_type(key_ty, a0_ty) == 0:
                            self.emit_argument_type_mismatch(mc_call_name, 0, 0, 0, key_ty, a0_ty, self.ast.get_extra(extra_start))
                if val_ty != 0 and a1_ty != 0:
                    if self.types_compatible(val_ty, a1_ty) == 0:
                        if self.arithmetic_result_type(val_ty, a1_ty) == 0:
                            self.emit_argument_type_mismatch(mc_call_name, 0, 1, 1, val_ty, a1_ty, self.ast.get_extra(extra_start + 1))
        // Return types for builtin generic methods
        if mc_base_name == "Vec":
            if mc_method == "push" or mc_method == "set_i32" or mc_method == "clear":
                return self.ty_void
            if mc_method == "get" or mc_method == "pop" or mc_method == "remove":
                return self.get_generic_inst_arg(resolved, 0)
            if mc_method == "len":
                return self.ty_i64
            if mc_method == "contains":
                return self.ty_bool
            if mc_method == "join":
                return self.ty_str
            if mc_method == "iter":
                let iter_elem_ty = self.get_generic_inst_arg(resolved, 0)
                let iter_tid = self.find_generic_inst(mc_veciter_sym, iter_elem_ty)
                if iter_tid != 0:
                    return iter_tid
                let iter_args: Vec[i32] = Vec.new()
                iter_args.push(iter_elem_ty)
                return self.ensure_generic_inst_type(mc_veciter_sym, iter_args, 1)
            if mc_method == "filter":
                return resolved
            if mc_method == "map":
                if arg_count >= 1:
                    let mapper_ty = self.resolve_alias(arg_types.get(0))
                    if self.get_type_kind(mapper_ty) == TY_FN:
                        let mapped_elem_ty = self.get_type_d2(mapper_ty)
                        let mapped_tid = self.find_generic_inst(mc_vec_sym, mapped_elem_ty)
                        if mapped_tid != 0:
                            return mapped_tid
                        let mapped_args: Vec[i32] = Vec.new()
                        mapped_args.push(mapped_elem_ty)
                        return self.ensure_generic_inst_type(mc_vec_sym, mapped_args, 1)
                return resolved
            if mc_method == "fold":
                if arg_count >= 1:
                    return arg_types.get(0)
                return self.get_generic_inst_arg(resolved, 0)
        if mc_base_name == "VecIter":
            if mc_method == "next":
                let next_elem_ty = self.get_generic_inst_arg(resolved, 0)
                let next_tid = self.find_generic_inst(mc_option_sym, next_elem_ty)
                if next_tid != 0:
                    return next_tid
                let next_args: Vec[i32] = Vec.new()
                next_args.push(next_elem_ty)
                return self.ensure_generic_inst_type(mc_option_sym, next_args, 1)
        if mc_base_name == "HashMap":
            if mc_method == "insert" or mc_method == "clear":
                return self.ty_void
            if mc_method == "get":
                return self.get_generic_inst_arg(resolved, 1)
            if mc_method == "contains":
                return self.ty_bool
            if mc_method == "remove":
                return self.get_generic_inst_arg(resolved, 1)
            if mc_method == "len":
                return self.ty_i64
        if mc_base_name == "HashSet":
            if mc_method == "insert" or mc_method == "clear":
                return self.ty_void
            if mc_method == "contains" or mc_method == "remove":
                return self.ty_bool
            if mc_method == "len":
                return self.ty_i64
        if mc_base_name == "Option":
            if mc_method == "unwrap":
                return self.get_generic_inst_arg(resolved, 0)
            if mc_method == "is_some" or mc_method == "is_none":
                return self.ty_bool
        if mc_base_name == "Result":
            if mc_method == "unwrap":
                return self.get_generic_inst_arg(resolved, 0)
            if mc_method == "is_ok" or mc_method == "is_err":
                return self.ty_bool

    // Return types for primitive type methods
    let resolved_tk = self.get_type_kind(resolved)
    if resolved_tk == TY_STR:
        let prim_method = self.pool_resolve(field)
        if prim_method == "len":
            return self.ty_i32
        if prim_method == "contains" or prim_method == "starts_with" or prim_method == "ends_with":
            return self.ty_bool
        if prim_method == "trim" or prim_method == "to_lower" or prim_method == "to_upper" or prim_method == "replace" or prim_method == "slice":
            return self.ty_str
    if resolved_tk == TY_ARRAY:
        let arr_method = self.pool_resolve(field)
        if arr_method == "len":
            return self.ty_i32

    // Static method call on a named type expression.
    if static_type_sym != 0 and self.static_receiver_type_is_known(expr) != 0:
        let method_key = self.method_key(static_type_sym, field)
        let sig_idx = self.get_sig(method_key)
        if sig_idx >= 0:
            return self.sig_return_type(sig_idx)

    0

fn Sema.is_intrinsic_fn_sym(self: Sema, fn_sym: i32) -> i32:
    if fn_sym == self.sym_channel or fn_sym == self.sym_send or fn_sym == self.sym_recv or fn_sym == self.sym_close:
        return 1
    if fn_sym == self.sym_todo or fn_sym == self.sym_unreachable:
        return 1
    if fn_sym == self.sym_src:
        return 1
    if fn_sym == self.sym_embed_file:
        return 1
    0

fn Sema.check_intrinsic_call(self: Sema, fn_sym: i32, node: i32, arg_types: Vec[i32], arg_count: i32) -> i32:
    let args_start = self.ast.get_data1(node)
    if fn_sym == self.sym_channel:
        if arg_count > 1:
            self.emit_error("Channel() expects zero or one capacity argument", node)
            return 0
        if arg_count == 1:
            let cap_ty = arg_types.get(0)
            if cap_ty != 0:
                let cap_kind = self.get_type_kind(self.resolve_alias(cap_ty))
                if cap_kind != TY_INT:
                    self.emit_error("Channel() capacity must be an integer", self.ast.get_extra(args_start))
                    return 0
        return self.ty_i64
    if fn_sym == self.sym_send:
        if arg_count != 2:
            self.emit_error("send() expects exactly two arguments", node)
            return 0
        let ch_ty = arg_types.get(0)
        if ch_ty != 0:
            let ch_kind = self.get_type_kind(self.resolve_alias(ch_ty))
            if ch_kind != TY_INT:
                self.emit_error("send() expects channel handle as integer value", self.ast.get_extra(args_start))
                return 0
        let payload_node = self.ast.get_extra(args_start + 1)
        if self.expr_is_ephemeral_value(payload_node) != 0 or self.expr_is_ephemeral_task(payload_node) != 0:
            self.emit_error("channel send requires Send value", payload_node)
            return 0
        let payload_ty = arg_types.get(1)
        if payload_ty != 0:
            let payload_kind = self.get_type_kind(self.resolve_alias(payload_ty))
            if payload_kind != TY_INT:
                self.emit_error("send() currently supports integer payloads", payload_node)
                return 0
        return self.ty_void
    if fn_sym == self.sym_recv:
        if arg_count != 1:
            self.emit_error("recv() expects exactly one argument", node)
            return 0
        let ch_ty = arg_types.get(0)
        if ch_ty != 0:
            let ch_kind = self.get_type_kind(self.resolve_alias(ch_ty))
            if ch_kind != TY_INT:
                self.emit_error("recv() expects channel handle as integer value", self.ast.get_extra(args_start))
                return 0
        return self.ty_i32
    if fn_sym == self.sym_close:
        if arg_count != 1:
            self.emit_error("close() expects exactly one argument", node)
            return 0
        let ch_ty = arg_types.get(0)
        if ch_ty != 0:
            let ch_kind = self.get_type_kind(self.resolve_alias(ch_ty))
            if ch_kind != TY_INT:
                self.emit_error("close() expects channel handle as integer value", self.ast.get_extra(args_start))
                return 0
        return self.ty_void
    if fn_sym == self.sym_todo or fn_sym == self.sym_unreachable:
        if arg_count > 1:
            self.emit_error("todo()/unreachable() expect zero or one message argument", node)
            return 0
        if arg_count == 1:
            let msg_ty = arg_types.get(0)
            if msg_ty != 0:
                if self.types_compatible(self.ty_str, msg_ty) == 0:
                    self.emit_error("todo()/unreachable() message must be str-compatible", self.ast.get_extra(self.ast.get_data1(node)))
                    return 0
        return self.ty_never
    if fn_sym == self.sym_src:
        if arg_count != 0:
            self.emit_error("src() takes no arguments", node)
        return self.ty_str
    if fn_sym == self.sym_embed_file:
        if arg_count != 1:
            self.emit_error("embed_file() takes exactly one string argument", node)
            return self.ty_str
        return self.ty_str
    0

fn Sema.static_receiver_base_sym(self: Sema, expr: i32) -> i32:
    let _ = self
    if expr == 0:
        return 0
    let kind = self.ast.kind(expr)
    if kind == NK_IDENT or kind == NK_TYPE_NAMED or kind == NK_TYPE_GENERIC:
        return self.ast.get_data0(expr)
    // Handle Vec[i32].method() — NK_INDEX(NK_IDENT("Vec"), ...)
    if kind == NK_INDEX:
        let base = self.ast.get_data0(expr)
        if self.ast.kind(base) == NK_IDENT:
            return self.ast.get_data0(base)
    0

fn Sema.static_receiver_type_is_known(self: Sema, expr: i32) -> i32:
    let base_sym = self.static_receiver_base_sym(expr)
    if base_sym == 0:
        return 0
    if self.primitive_type_by_sym(base_sym) != 0:
        return 1
    if self.named_types.contains(base_sym):
        return 1
    0

fn Sema.type_expr_contains_ref(self: Sema, node: i32) -> i32:
    if node == 0:
        return 0
    let kind = self.ast.kind(node)
    if kind == NK_TYPE_REF:
        return 1
    if kind == NK_TYPE_GENERIC:
        let extra_start = self.ast.get_data1(node)
        let arg_count = self.ast.get_data2(node)
        for ai in 0..arg_count:
            if self.type_expr_contains_ref(self.ast.get_extra(extra_start + ai)) != 0:
                return 1
        return 0
    if kind == NK_TYPE_PTR or kind == NK_TYPE_OPTIONAL:
        return self.type_expr_contains_ref(self.ast.get_data0(node))
    if kind == NK_TYPE_FN:
        let extra_start = self.ast.get_data0(node)
        let param_count = self.ast.get_data1(node)
        for pi in 0..param_count:
            if self.type_expr_contains_ref(self.ast.get_extra(extra_start + pi)) != 0:
                return 1
        return self.type_expr_contains_ref(self.ast.get_data2(node))
    if kind == NK_TYPE_TUPLE:
        let extra_start = self.ast.get_data0(node)
        let elem_count = self.ast.get_data1(node)
        for ei in 0..elem_count:
            if self.type_expr_contains_ref(self.ast.get_extra(extra_start + ei)) != 0:
                return 1
        return 0
    if kind == NK_TYPE_ARRAY or kind == NK_TYPE_SLICE:
        return self.type_expr_contains_ref(self.ast.get_data0(node))
    0

fn Sema.type_expr_is_collection_with_ref(self: Sema, node: i32) -> i32:
    if node == 0:
        return 0
    let kind = self.ast.kind(node)
    if kind == NK_TYPE_GENERIC:
        let extra_start = self.ast.get_data1(node)
        let arg_count = self.ast.get_data2(node)
        for ai in 0..arg_count:
            let arg_node = self.ast.get_extra(extra_start + ai)
            if self.type_expr_contains_ref(arg_node) != 0:
                return 1
            if self.type_expr_is_collection_with_ref(arg_node) != 0:
                return 1
        return 0
    if kind == NK_TYPE_PTR or kind == NK_TYPE_OPTIONAL:
        return self.type_expr_is_collection_with_ref(self.ast.get_data0(node))
    if kind == NK_TYPE_FN:
        let extra_start = self.ast.get_data0(node)
        let param_count = self.ast.get_data1(node)
        for pi in 0..param_count:
            if self.type_expr_is_collection_with_ref(self.ast.get_extra(extra_start + pi)) != 0:
                return 1
        return self.type_expr_is_collection_with_ref(self.ast.get_data2(node))
    if kind == NK_TYPE_TUPLE:
        let extra_start = self.ast.get_data0(node)
        let elem_count = self.ast.get_data1(node)
        for ei in 0..elem_count:
            if self.type_expr_is_collection_with_ref(self.ast.get_extra(extra_start + ei)) != 0:
                return 1
        return 0
    if kind == NK_TYPE_ARRAY or kind == NK_TYPE_SLICE:
        return self.type_expr_is_collection_with_ref(self.ast.get_data0(node))
    0

fn Sema.borrow_root_place(self: Sema, node: i32) -> i32:
    if node == 0:
        return 0
    let kind = self.ast.kind(node)
    if kind == NK_IDENT:
        return self.ast.get_data0(node)
    if kind == NK_FIELD_ACCESS:
        return self.borrow_root_place(self.ast.get_data0(node))
    if kind == NK_INDEX:
        return self.borrow_root_place(self.ast.get_data0(node))
    if kind == NK_GROUPED:
        return self.borrow_root_place(self.ast.get_data0(node))
    0

// Collect full field path from an expression into borrow_path_data.
// Returns (path_start, path_count) by storing the path and returning
// the start index. Fields are stored root-to-leaf order.
fn Sema.borrow_collect_path(self: Sema, node: i32) -> i32:
    let start = self.borrow_path_data.len() as i32
    self.borrow_collect_path_inner(node)
    self.borrow_path_data.len() as i32 - start

fn Sema.borrow_collect_path_inner(self: Sema, node: i32):
    if node == 0:
        return
    let kind = self.ast.kind(node)
    if kind == NK_FIELD_ACCESS:
        // Recurse into base first (root-to-leaf ordering)
        self.borrow_collect_path_inner(self.ast.get_data0(node))
        self.borrow_path_data.push(self.ast.get_data1(node))
    // NK_IDENT, NK_INDEX, NK_GROUPED: no field to add

fn Sema.borrow_field(self: Sema, node: i32) -> i32:
    if node == 0:
        return 0
    if self.ast.kind(node) == NK_FIELD_ACCESS:
        return self.ast.get_data1(node)
    0

// Two borrows are disjoint if their field paths diverge at some level.
// A zero-length path (whole variable) overlaps with everything.
fn Sema.are_borrows_disjoint_paths(self: Sema, start_a: i32, count_a: i32, start_b: i32, count_b: i32) -> i32:
    if count_a == 0 or count_b == 0:
        return 0
    let min_count = if count_a < count_b: count_a else: count_b
    var i = 0
    while i < min_count:
        let fa = self.borrow_path_data.get((start_a + i) as i64)
        let fb = self.borrow_path_data.get((start_b + i) as i64)
        if fa != fb:
            return 1
        i = i + 1
    // One is a prefix of the other — overlapping
    0

fn Sema.are_borrows_disjoint(self: Sema, new_field: i32, existing_field: i32) -> i32:
    let _ = self
    if new_field == 0 or existing_field == 0:
        return 0
    if new_field != existing_field:
        return 1
    0

fn Sema.check_borrow_create(self: Sema, operand_node: i32, kind: i32, err_node: i32):
    let place = self.borrow_root_place(operand_node)
    if place == 0:
        return
    let new_field = self.borrow_field(operand_node)
    let path_start = self.borrow_path_data.len() as i32
    let path_count = self.borrow_collect_path(operand_node)

    var i = 0
    while i < self.borrow_kinds.len() as i32:
        let existing_place = self.borrow_places.get(i as i64)
        if existing_place != place:
            i = i + 1
            continue

        // Check disjointness using full field paths
        let ex_path_start = self.borrow_path_starts.get(i as i64)
        let ex_path_count = self.borrow_path_counts.get(i as i64)
        if self.are_borrows_disjoint_paths(path_start, path_count, ex_path_start, ex_path_count) != 0:
            i = i + 1
            continue

        let existing_kind = self.borrow_kinds.get(i as i64)
        if kind == BK_SHARED:
            if existing_kind == BK_EXCLUSIVE:
                self.emit_error("cannot borrow: already mutably borrowed", err_node)
                return
            i = i + 1
            continue

        // New exclusive borrow conflicts with any existing borrow.
        // Allow reborrowing: when the same place is reborrowed exclusively
        // for a nested call (e.g., &mut self passed to a helper taking &mut Self),
        // suppress the conflict. The original borrow is suspended during the call.
        if existing_kind == BK_EXCLUSIVE:
            // Reborrow: same place, both exclusive → allow (suspend original)
            i = i + 1
            continue
        self.emit_error("cannot borrow mutably: already borrowed", err_node)
        return

    self.borrow_kinds.push(kind)
    self.borrow_places.push(place)
    self.borrow_fields.push(new_field)
    self.borrow_refs.push(0)
    self.borrow_path_starts.push(path_start)
    self.borrow_path_counts.push(path_count)

// Register a borrow with pre-computed place/kind/field/path.
// Used by closure capture registration.
fn Sema.check_borrow_create_direct(self: Sema, place: i32, kind: i32, field: i32, path_start: i32, path_count: i32, err_node: i32):
    var i = 0
    while i < self.borrow_kinds.len() as i32:
        let existing_place = self.borrow_places.get(i as i64)
        if existing_place != place:
            i = i + 1
            continue
        let ex_path_start = self.borrow_path_starts.get(i as i64)
        let ex_path_count = self.borrow_path_counts.get(i as i64)
        if self.are_borrows_disjoint_paths(path_start, path_count, ex_path_start, ex_path_count) != 0:
            i = i + 1
            continue
        let existing_kind = self.borrow_kinds.get(i as i64)
        if kind == BK_SHARED:
            if existing_kind == BK_EXCLUSIVE:
                self.emit_error("cannot borrow: already mutably borrowed", err_node)
                return
            i = i + 1
            continue
        if existing_kind == BK_EXCLUSIVE:
            self.emit_error("cannot borrow mutably: already mutably borrowed", err_node)
        else:
            self.emit_error("cannot borrow mutably: already borrowed", err_node)
        return
    self.borrow_kinds.push(kind)
    self.borrow_places.push(place)
    self.borrow_fields.push(field)
    self.borrow_refs.push(0)
    self.borrow_path_starts.push(path_start)
    self.borrow_path_counts.push(path_count)

fn Sema.remove_borrow_at(self: Sema, idx: i32):
    let last = self.borrow_refs.len() as i32 - 1
    if idx < 0 or idx > last:
        return
    if idx < last:
        self.borrow_kinds.set_i32(idx as i64, self.borrow_kinds.get(last as i64))
        self.borrow_places.set_i32(idx as i64, self.borrow_places.get(last as i64))
        self.borrow_fields.set_i32(idx as i64, self.borrow_fields.get(last as i64))
        self.borrow_refs.set_i32(idx as i64, self.borrow_refs.get(last as i64))
        self.borrow_path_starts.set_i32(idx as i64, self.borrow_path_starts.get(last as i64))
        self.borrow_path_counts.set_i32(idx as i64, self.borrow_path_counts.get(last as i64))
    self.borrow_kinds.pop()
    self.borrow_places.pop()
    self.borrow_fields.pop()
    self.borrow_refs.pop()
    self.borrow_path_starts.pop()
    self.borrow_path_counts.pop()

fn Sema.expr_uses_symbol(self: Sema, node: i32, sym: i32) -> i32:
    if node == 0:
        return 0
    let kind = self.ast.kind(node)
    if kind == NK_IDENT:
        if self.ast.get_data0(node) == sym:
            return 1
        return 0
    if kind == NK_BINARY:
        if self.expr_uses_symbol(self.ast.get_data1(node), sym) != 0:
            return 1
        return self.expr_uses_symbol(self.ast.get_data2(node), sym)
    if kind == NK_UNARY:
        return self.expr_uses_symbol(self.ast.get_data1(node), sym)
    if kind == NK_GROUPED or kind == NK_AWAIT or kind == NK_ASYNC_BLOCK or kind == NK_SPAWN or kind == NK_DEFER or kind == NK_ERRDEFER or kind == NK_YIELD or kind == NK_COMPTIME:
        return self.expr_uses_symbol(self.ast.get_data0(node), sym)
    if kind == NK_CALL:
        if self.expr_uses_symbol(self.ast.get_data0(node), sym) != 0:
            return 1
        let extra_start = self.ast.get_data1(node)
        let arg_count = self.ast.get_data2(node)
        for ai in 0..arg_count:
            if self.expr_uses_symbol(self.ast.get_extra(extra_start + ai), sym) != 0:
                return 1
        return 0
    if kind == NK_FIELD_ACCESS:
        return self.expr_uses_symbol(self.ast.get_data0(node), sym)
    if kind == NK_OPTIONAL_CHAIN:
        if self.expr_uses_symbol(self.ast.get_data0(node), sym) != 0:
            return 1
        let extra_start = self.ast.get_data2(node)
        if extra_start != 0:
            let has_args = self.ast.get_extra(extra_start)
            if has_args != 0:
                let arg_count = self.ast.get_extra(extra_start + 1)
                for ai in 0..arg_count:
                    if self.expr_uses_symbol(self.ast.get_extra(extra_start + 2 + ai), sym) != 0:
                        return 1
        return 0
    if kind == NK_INDEX:
        if self.expr_uses_symbol(self.ast.get_data0(node), sym) != 0:
            return 1
        return self.expr_uses_symbol(self.ast.get_data1(node), sym)
    if kind == NK_SLICE:
        if self.expr_uses_symbol(self.ast.get_data0(node), sym) != 0:
            return 1
        if self.expr_uses_symbol(self.ast.get_data1(node), sym) != 0:
            return 1
        return self.expr_uses_symbol(self.ast.get_data2(node), sym)
    if kind == NK_BLOCK:
        let extra_start = self.ast.get_data0(node)
        let stmt_count = self.ast.get_data1(node)
        let tail = self.ast.get_data2(node)
        for si in 0..stmt_count:
            if self.expr_uses_symbol(self.ast.get_extra(extra_start + si), sym) != 0:
                return 1
        return self.expr_uses_symbol(tail, sym)
    if kind == NK_IF_EXPR:
        if self.expr_uses_symbol(self.ast.get_data0(node), sym) != 0:
            return 1
        if self.expr_uses_symbol(self.ast.get_data1(node), sym) != 0:
            return 1
        return self.expr_uses_symbol(self.ast.get_data2(node), sym)
    if kind == NK_RETURN:
        return self.expr_uses_symbol(self.ast.get_data0(node), sym)
    if kind == NK_LET_BINDING:
        return self.expr_uses_symbol(self.ast.get_data1(node), sym)
    if kind == NK_LET_ELSE:
        if self.expr_uses_symbol(self.ast.get_data1(node), sym) != 0:
            return 1
        return self.expr_uses_symbol(self.ast.get_data2(node), sym)
    if kind == NK_TUPLE_DESTRUCTURE:
        return self.expr_uses_symbol(self.ast.get_data2(node), sym)
    if kind == NK_ASSIGN:
        if self.expr_uses_symbol(self.ast.get_data0(node), sym) != 0:
            return 1
        return self.expr_uses_symbol(self.ast.get_data1(node), sym)
    if kind == NK_TUPLE or kind == NK_ARRAY_LIT:
        let extra_start = self.ast.get_data0(node)
        let elem_count = self.ast.get_data1(node)
        for ei in 0..elem_count:
            if self.expr_uses_symbol(self.ast.get_extra(extra_start + ei), sym) != 0:
                return 1
        return 0
    if kind == NK_RANGE:
        if self.expr_uses_symbol(self.ast.get_data0(node), sym) != 0:
            return 1
        return self.expr_uses_symbol(self.ast.get_data1(node), sym)
    if kind == NK_MATCH:
        if self.expr_uses_symbol(self.ast.get_data0(node), sym) != 0:
            return 1
        let extra_start = self.ast.get_data1(node)
        let arm_count = self.ast.get_data2(node)
        for ai in 0..arm_count:
            let arm = self.ast.get_extra(extra_start + ai)
            let guard = self.ast.get_data2(arm)
            if self.expr_uses_symbol(guard, sym) != 0:
                return 1
            if self.expr_uses_symbol(self.ast.get_data1(arm), sym) != 0:
                return 1
        return 0
    if kind == NK_STRUCT_LIT:
        let extra_start = self.ast.get_data1(node)
        let field_count = self.ast.get_data2(node)
        for fi in 0..field_count:
            if self.expr_uses_symbol(self.ast.get_extra(extra_start + fi * 2 + 1), sym) != 0:
                return 1
        return 0
    if kind == NK_FOR:
        if self.expr_uses_symbol(self.ast.get_data1(node), sym) != 0:
            return 1
        return self.expr_uses_symbol(self.ast.get_data2(node), sym)
    if kind == NK_WHILE:
        if self.expr_uses_symbol(self.ast.get_data0(node), sym) != 0:
            return 1
        return self.expr_uses_symbol(self.ast.get_data1(node), sym)
    if kind == NK_LOOP:
        return self.expr_uses_symbol(self.ast.get_data0(node), sym)
    if kind == NK_BREAK:
        return self.expr_uses_symbol(self.ast.get_data0(node), sym)
    if kind == NK_PIPELINE:
        if self.expr_uses_symbol(self.ast.get_data0(node), sym) != 0:
            return 1
        return self.expr_uses_symbol(self.ast.get_data1(node), sym)
    if kind == NK_WITH_EXPR:
        if self.expr_uses_symbol(self.ast.get_data0(node), sym) != 0:
            return 1
        return self.expr_uses_symbol(self.ast.get_data1(node), sym)
    if kind == NK_RECORD_UPDATE:
        if self.expr_uses_symbol(self.ast.get_data0(node), sym) != 0:
            return 1
        let extra_start = self.ast.get_data1(node)
        let field_count = self.ast.get_data2(node)
        for fi in 0..field_count:
            if self.expr_uses_symbol(self.ast.get_extra(extra_start + fi * 2 + 1), sym) != 0:
                return 1
        return 0
    if kind == NK_ENUM_VARIANT:
        let extra_start = self.ast.get_data2(node)
        let arg_count = self.ast.get_extra(extra_start)
        for ai in 0..arg_count:
            if self.expr_uses_symbol(self.ast.get_extra(extra_start + 1 + ai), sym) != 0:
                return 1
        return 0
    if kind == NK_CLOSURE or kind == NK_CAST:
        return self.expr_uses_symbol(self.ast.get_data0(node), sym)
    if kind == NK_ARRAY_COMPREHENSION:
        if self.expr_uses_symbol(self.ast.get_data0(node), sym) != 0:
            return 1
        if self.expr_uses_symbol(self.ast.get_data2(node), sym) != 0:
            return 1
        return 0
    if kind == NK_ASYNC_SCOPE:
        return self.expr_uses_symbol(self.ast.get_data1(node), sym)
    if kind == NK_SELECT_AWAIT:
        let extra_start = self.ast.get_data0(node)
        let arm_count = self.ast.get_data1(node)
        for ai in 0..arm_count:
            if self.expr_uses_symbol(self.ast.get_extra(extra_start + ai * 3 + 1), sym) != 0:
                return 1
            if self.expr_uses_symbol(self.ast.get_extra(extra_start + ai * 3 + 2), sym) != 0:
                return 1
        return 0
    0

// Check if an expression mutates a variable rooted at `sym`.
// Returns 1 if any subexpression assigns to or takes &mut of the variable.
fn Sema.expr_mutates_place(self: Sema, node: i32, sym: i32) -> i32:
    if node == 0:
        return 0
    let kind = self.ast.kind(node)
    // Assignment: check if target is rooted at sym
    if kind == NK_ASSIGN:
        let target = self.ast.get_data0(node)
        if self.place_root_sym(target) == sym:
            return 1
        // Also check value side for nested mutations
        return self.expr_mutates_place(self.ast.get_data1(node), sym)
    // &mut borrow of sym
    if kind == NK_UNARY:
        let op = self.ast.get_data0(node)
        if op == UOP_MUT_REF:
            let operand = self.ast.get_data1(node)
            if self.place_root_sym(operand) == sym:
                return 1
        return self.expr_mutates_place(self.ast.get_data1(node), sym)
    // Recursive cases
    if kind == NK_BINARY:
        if self.expr_mutates_place(self.ast.get_data1(node), sym) != 0:
            return 1
        return self.expr_mutates_place(self.ast.get_data2(node), sym)
    if kind == NK_BLOCK:
        let extra_start = self.ast.get_data0(node)
        let stmt_count = self.ast.get_data1(node)
        let tail = self.ast.get_data2(node)
        for si in 0..stmt_count:
            if self.expr_mutates_place(self.ast.get_extra(extra_start + si), sym) != 0:
                return 1
        return self.expr_mutates_place(tail, sym)
    if kind == NK_IF_EXPR:
        if self.expr_mutates_place(self.ast.get_data0(node), sym) != 0:
            return 1
        if self.expr_mutates_place(self.ast.get_data1(node), sym) != 0:
            return 1
        return self.expr_mutates_place(self.ast.get_data2(node), sym)
    if kind == NK_CALL:
        if self.expr_mutates_place(self.ast.get_data0(node), sym) != 0:
            return 1
        let ea = self.ast.get_data1(node)
        let ac = self.ast.get_data2(node)
        for ai in 0..ac:
            if self.expr_mutates_place(self.ast.get_extra(ea + ai), sym) != 0:
                return 1
        return 0
    if kind == NK_LET_BINDING:
        return self.expr_mutates_place(self.ast.get_data1(node), sym)
    if kind == NK_RETURN:
        return self.expr_mutates_place(self.ast.get_data0(node), sym)
    if kind == NK_FIELD_ACCESS:
        return self.expr_mutates_place(self.ast.get_data0(node), sym)
    if kind == NK_INDEX:
        if self.expr_mutates_place(self.ast.get_data0(node), sym) != 0:
            return 1
        return self.expr_mutates_place(self.ast.get_data1(node), sym)
    if kind == NK_GROUPED:
        return self.expr_mutates_place(self.ast.get_data0(node), sym)
    if kind == NK_WHILE:
        if self.expr_mutates_place(self.ast.get_data0(node), sym) != 0:
            return 1
        return self.expr_mutates_place(self.ast.get_data1(node), sym)
    if kind == NK_FOR:
        if self.expr_mutates_place(self.ast.get_data1(node), sym) != 0:
            return 1
        return self.expr_mutates_place(self.ast.get_data2(node), sym)
    0

// Get the root symbol of a place expression (ident, field access chain, index).
fn Sema.place_root_sym(self: Sema, node: i32) -> i32:
    if node == 0:
        return 0
    let kind = self.ast.kind(node)
    if kind == NK_IDENT:
        return self.ast.get_data0(node)
    if kind == NK_FIELD_ACCESS or kind == NK_INDEX or kind == NK_GROUPED:
        return self.place_root_sym(self.ast.get_data0(node))
    0

// Check if a captured variable is used only through field accesses, never whole.
// Returns 1 if all uses of `sym` in `node` are of the form `sym.field`.
// Returns 0 if `sym` is used directly (passed as arg, assigned, etc).
fn Sema.capture_is_field_only(self: Sema, node: i32, sym: i32) -> i32:
    if node == 0:
        return 1
    let kind = self.ast.kind(node)
    if kind == NK_IDENT:
        // Direct use of sym — not field-only
        if self.ast.get_data0(node) == sym:
            return 0
        return 1
    if kind == NK_FIELD_ACCESS:
        // sym.field — check if base is sym (OK) or recurse
        let base = self.ast.get_data0(node)
        if self.ast.kind(base) == NK_IDENT and self.ast.get_data0(base) == sym:
            return 1
        return self.capture_is_field_only(base, sym)
    if kind == NK_BINARY:
        if self.capture_is_field_only(self.ast.get_data1(node), sym) == 0:
            return 0
        return self.capture_is_field_only(self.ast.get_data2(node), sym)
    if kind == NK_UNARY:
        let operand = self.ast.get_data1(node)
        // &mut sym.field or &sym.field — check the operand
        return self.capture_is_field_only(operand, sym)
    if kind == NK_CALL:
        if self.capture_is_field_only(self.ast.get_data0(node), sym) == 0:
            return 0
        let ea = self.ast.get_data1(node)
        let ac = self.ast.get_data2(node)
        for ai in 0..ac:
            if self.capture_is_field_only(self.ast.get_extra(ea + ai), sym) == 0:
                return 0
        return 1
    if kind == NK_BLOCK:
        let ea = self.ast.get_data0(node)
        let sc = self.ast.get_data1(node)
        let tail = self.ast.get_data2(node)
        for si in 0..sc:
            if self.capture_is_field_only(self.ast.get_extra(ea + si), sym) == 0:
                return 0
        return self.capture_is_field_only(tail, sym)
    if kind == NK_ASSIGN:
        if self.capture_is_field_only(self.ast.get_data0(node), sym) == 0:
            return 0
        return self.capture_is_field_only(self.ast.get_data1(node), sym)
    if kind == NK_IF_EXPR:
        if self.capture_is_field_only(self.ast.get_data0(node), sym) == 0:
            return 0
        if self.capture_is_field_only(self.ast.get_data1(node), sym) == 0:
            return 0
        return self.capture_is_field_only(self.ast.get_data2(node), sym)
    if kind == NK_LET_BINDING:
        return self.capture_is_field_only(self.ast.get_data1(node), sym)
    if kind == NK_RETURN:
        return self.capture_is_field_only(self.ast.get_data0(node), sym)
    if kind == NK_INDEX:
        if self.capture_is_field_only(self.ast.get_data0(node), sym) == 0:
            return 0
        return self.capture_is_field_only(self.ast.get_data1(node), sym)
    if kind == NK_GROUPED:
        return self.capture_is_field_only(self.ast.get_data0(node), sym)
    1

// Collect top-level field syms accessed on a captured variable in a closure body.
// Pushes (field_sym, borrow_kind) pairs into capture_field_syms/capture_field_kinds.
// These are parallel Vecs used transiently during closure checking.
fn Sema.collect_capture_fields(self: Sema, node: i32, sym: i32):
    if node == 0:
        return
    let kind = self.ast.kind(node)
    if kind == NK_FIELD_ACCESS:
        let base = self.ast.get_data0(node)
        if self.ast.kind(base) == NK_IDENT and self.ast.get_data0(base) == sym:
            let field_sym = self.ast.get_data1(node)
            // Check if this field is already collected
            var found = 0
            var fi = 0
            while fi < self.capture_field_syms.len() as i32:
                if self.capture_field_syms.get(fi as i64) == field_sym:
                    found = 1
                    break
                fi = fi + 1
            if found == 0:
                self.capture_field_syms.push(field_sym)
                self.capture_field_kinds.push(BK_SHARED)
            return
        self.collect_capture_fields(base, sym)
        return
    if kind == NK_ASSIGN:
        // Check if target is sym.field — if so, mark that field as exclusive
        let target = self.ast.get_data0(node)
        if self.ast.kind(target) == NK_FIELD_ACCESS:
            let tbase = self.ast.get_data0(target)
            if self.ast.kind(tbase) == NK_IDENT and self.ast.get_data0(tbase) == sym:
                let field_sym = self.ast.get_data1(target)
                var found = 0
                var fi = 0
                while fi < self.capture_field_syms.len() as i32:
                    if self.capture_field_syms.get(fi as i64) == field_sym:
                        found = 1
                        self.capture_field_kinds.set_i32(fi as i64, BK_EXCLUSIVE)
                        break
                    fi = fi + 1
                if found == 0:
                    self.capture_field_syms.push(field_sym)
                    self.capture_field_kinds.push(BK_EXCLUSIVE)
        self.collect_capture_fields(self.ast.get_data0(node), sym)
        self.collect_capture_fields(self.ast.get_data1(node), sym)
        return
    if kind == NK_UNARY:
        let op = self.ast.get_data0(node)
        let operand = self.ast.get_data1(node)
        if op == UOP_MUT_REF:
            // &mut sym.field — mark field as exclusive
            if self.ast.kind(operand) == NK_FIELD_ACCESS:
                let fbase = self.ast.get_data0(operand)
                if self.ast.kind(fbase) == NK_IDENT and self.ast.get_data0(fbase) == sym:
                    let field_sym = self.ast.get_data1(operand)
                    var found = 0
                    var fi = 0
                    while fi < self.capture_field_syms.len() as i32:
                        if self.capture_field_syms.get(fi as i64) == field_sym:
                            found = 1
                            self.capture_field_kinds.set_i32(fi as i64, BK_EXCLUSIVE)
                            break
                        fi = fi + 1
                    if found == 0:
                        self.capture_field_syms.push(field_sym)
                        self.capture_field_kinds.push(BK_EXCLUSIVE)
                    return
        self.collect_capture_fields(operand, sym)
        return
    // Recursive cases
    if kind == NK_BINARY:
        self.collect_capture_fields(self.ast.get_data1(node), sym)
        self.collect_capture_fields(self.ast.get_data2(node), sym)
        return
    if kind == NK_BLOCK:
        let ea = self.ast.get_data0(node)
        let sc = self.ast.get_data1(node)
        let tail = self.ast.get_data2(node)
        for si in 0..sc:
            self.collect_capture_fields(self.ast.get_extra(ea + si), sym)
        self.collect_capture_fields(tail, sym)
        return
    if kind == NK_CALL:
        self.collect_capture_fields(self.ast.get_data0(node), sym)
        let ea = self.ast.get_data1(node)
        let ac = self.ast.get_data2(node)
        for ai in 0..ac:
            self.collect_capture_fields(self.ast.get_extra(ea + ai), sym)
        return
    if kind == NK_IF_EXPR:
        self.collect_capture_fields(self.ast.get_data0(node), sym)
        self.collect_capture_fields(self.ast.get_data1(node), sym)
        self.collect_capture_fields(self.ast.get_data2(node), sym)
        return
    if kind == NK_LET_BINDING:
        self.collect_capture_fields(self.ast.get_data1(node), sym)
        return
    if kind == NK_RETURN:
        self.collect_capture_fields(self.ast.get_data0(node), sym)
        return
    if kind == NK_INDEX:
        self.collect_capture_fields(self.ast.get_data0(node), sym)
        self.collect_capture_fields(self.ast.get_data1(node), sym)
        return
    if kind == NK_GROUPED:
        self.collect_capture_fields(self.ast.get_data0(node), sym)

fn Sema.expire_dead_borrows_in_block(self: Sema, block_extra_start: i32, stmt_count: i32, next_stmt_index: i32, tail_node: i32):
    var bi = 0
    while bi < self.borrow_refs.len() as i32:
        let ref_sym = self.borrow_refs.get(bi as i64)
        if ref_sym == 0:
            // Unnamed temporary borrows (e.g. &mut x as *mut T passed to a call)
            // have no named reference holding them, so they expire at statement
            // boundaries — the borrow is consumed by the enclosing expression.
            self.remove_borrow_at(bi)
            continue

        var live = 0
        var si = next_stmt_index
        while si < stmt_count:
            if self.expr_uses_symbol(self.ast.get_extra(block_extra_start + si), ref_sym) != 0:
                live = 1
                break
            si = si + 1

        if live == 0 and tail_node != 0:
            if self.expr_uses_symbol(tail_node, ref_sym) != 0:
                live = 1

        if live == 0:
            self.remove_borrow_at(bi)
        else:
            bi = bi + 1

fn Sema.type_is_ephemeral_value(self: Sema, tid: i32) -> i32:
    if tid == 0:
        return 0
    let resolved = self.resolve_alias(tid)
    let tk = self.get_type_kind(resolved)
    if tk == TY_REF or tk == TY_SLICE:
        return 1
    if tk == TY_ARRAY:
        return self.type_is_ephemeral_value(self.get_type_d0(resolved))
    if tk == TY_TUPLE:
        let te_start = self.get_type_d0(resolved)
        let elem_count = self.get_type_d1(resolved)
        for ei in 0..elem_count:
            if self.type_is_ephemeral_value(self.type_extra.get((te_start + ei) as i64)) != 0:
                return 1
        return 0
    if tk == TY_STRUCT:
        let st_name = self.get_type_d0(resolved)
        if self.ephemeral_types.contains(st_name):
            return 1
        let te_start = self.get_type_d1(resolved)
        let field_count = self.get_type_d2(resolved)
        for fi in 0..field_count:
            let ft = self.type_extra.get((te_start + fi * 3 + 1) as i64)
            if self.type_is_ephemeral_value(ft) != 0:
                return 1
        return 0
    0

// ── Helper functions ─────────────────────────────────────────────

fn Sema.infer_for_element_type(self: Sema, iter_type: i32) -> i32:
    if iter_type == 0:
        return 0
    let resolved = self.resolve_alias(iter_type)
    let tk = self.get_type_kind(resolved)
    if tk == TY_RANGE:
        return self.get_type_d0(resolved)
    if tk == TY_ARRAY:
        return self.get_type_d0(resolved)
    if tk == TY_SLICE:
        return self.get_type_d0(resolved)
    if tk == TY_GENERIC_INST:
        let base_name = self.pool_resolve(self.get_type_d0(resolved))
        if base_name == "Vec" and self.get_generic_inst_arg_count(resolved) > 0:
            return self.get_generic_inst_arg(resolved, 0)
    self.ty_i32

fn Sema.mark_moved_if_consumed(self: Sema, node: i32):
    if node == 0:
        return
    let kind = self.ast.kind(node)
    if kind == NK_IDENT:
        let sym = self.ast.get_data0(node)
        if self.scope_has(sym) != 0:
            let tid = self.scope_lookup(sym)
            if not self.is_copy(tid):
                if sema_debug_move_enabled() != 0:
                    let resolved = self.resolve_alias(tid)
                    let name = self.pool_resolve(sym)
                    with_eprintln(
                        "[move] sym=" ++ name ++
                        " tid=" ++ int_to_string(tid) ++
                        " resolved=" ++ int_to_string(resolved) ++
                        " kind=" ++ int_to_string(self.get_type_kind(resolved))
                    )
                self.scope_set_state(sym, VS_MOVED)
    if kind == NK_GROUPED:
        self.mark_moved_if_consumed(self.ast.get_data0(node))

fn Sema.method_key(self: Sema, type_sym: i32, method_sym: i32) -> i32:
    if type_sym <= 0 or method_sym <= 0:
        return 0
    let cache_key = int_to_string(type_sym) ++ "|" ++ int_to_string(method_sym)
    let cached = self.method_key_cache.get(cache_key)
    if cached.is_some():
        return cached.unwrap()

    let out = self.pool_intern("$m$" ++ cache_key)
    self.method_key_cache.insert(cache_key, out)
    out

fn Sema.get_type_name(self: Sema, tid: i32) -> i32:
    let resolved = self.resolve_alias(tid)
    let tk = self.get_type_kind(resolved)
    if tk == TY_REF or tk == TY_PTR:
        return self.get_type_name(self.get_type_d0(resolved))
    if tk == TY_STRUCT:
        return self.get_type_d0(resolved)
    if tk == TY_ENUM:
        return self.get_type_d0(resolved)
    if tk == TY_GENERIC_INST:
        return self.get_type_d0(resolved)
    0

// ── Type compatibility ───────────────────────────────────────────

fn Sema.types_compatible_fast(self: Sema, expected: i32, actual: i32) -> i32:
    if expected == actual:
        return 1
    if expected == 0 or actual == 0:
        return 1

    let exp_r = self.resolve_alias(expected)
    let act_r = self.resolve_alias(actual)
    if exp_r == act_r:
        return 1

    let exp_k = self.get_type_kind(exp_r)
    let act_k = self.get_type_kind(act_r)

    if act_k == TY_NEVER:
        return 1
    if exp_k == TY_BOOL and act_k == TY_BOOL:
        return 1
    if exp_k == TY_VOID and act_k == TY_VOID:
        return 1
    if exp_k == TY_STR and act_k == TY_STR:
        return 1
    if exp_k == TY_INT and act_k == TY_INT:
        return 1
    if exp_k == TY_FLOAT and act_k == TY_FLOAT:
        return 1
    if exp_k == TY_FLOAT and act_k == TY_INT:
        return 1
    if exp_k == TY_INT and act_k == TY_FLOAT:
        return 1
    if (exp_k == TY_PTR or exp_k == TY_REF) and act_k == TY_STR:
        return 1
    if exp_k == TY_STR and (act_k == TY_PTR or act_k == TY_REF):
        return 1
    if exp_k == TY_FN and act_k == TY_FN:
        return 1
    if (exp_k == TY_PTR or exp_k == TY_REF) and act_k == TY_FN:
        return 1
    if exp_k == TY_FN and (act_k == TY_PTR or act_k == TY_REF):
        return 1
    if self.is_option_pointer_type(exp_r) != 0 and (act_k == TY_PTR or act_k == TY_REF or act_k == TY_FN):
        let opt_payload = self.option_pointer_payload_type(exp_r)
        if opt_payload != 0:
            return self.types_compatible_fast(opt_payload, actual)
    if exp_k == TY_STRUCT and act_k == TY_STRUCT:
        return if self.get_type_d0(exp_r) == self.get_type_d0(act_r): 1 else: 0
    if exp_k == TY_ENUM and act_k == TY_ENUM:
        return if self.get_type_d0(exp_r) == self.get_type_d0(act_r): 1 else: 0
    // TY_GENERIC_INST: compatible if same base and all args compatible
    if exp_k == TY_GENERIC_INST and act_k == TY_GENERIC_INST:
        if self.get_type_d0(exp_r) == self.get_type_d0(act_r):
            let gi_ac = self.get_type_d2(exp_r)
            if gi_ac == self.get_type_d2(act_r):
                var gi_all_match = 1
                for gi_i in 0..gi_ac:
                    let gi_exp_arg = self.get_generic_inst_arg(exp_r, gi_i)
                    let gi_act_arg = self.get_generic_inst_arg(act_r, gi_i)
                    if gi_exp_arg != self.ty_void and gi_act_arg != self.ty_void:
                        if self.types_compatible_fast(gi_exp_arg, gi_act_arg) == 0:
                            gi_all_match = 0
                return gi_all_match
        return 0
    // TY_GENERIC_INST is compatible with its base struct type (for codegen interop)
    if exp_k == TY_GENERIC_INST and act_k == TY_STRUCT:
        return if self.get_type_d0(exp_r) == self.get_type_d0(act_r): 1 else: 0
    if exp_k == TY_STRUCT and act_k == TY_GENERIC_INST:
        return if self.get_type_d0(exp_r) == self.get_type_d0(act_r): 1 else: 0
    if exp_k == TY_GENERIC_INST and act_k == TY_ENUM:
        return if self.get_type_d0(exp_r) == self.get_type_d0(act_r): 1 else: 0
    if exp_k == TY_ENUM and act_k == TY_GENERIC_INST:
        return if self.get_type_d0(exp_r) == self.get_type_d0(act_r): 1 else: 0
    0

fn Sema.types_compatible(self: Sema, expected: i32, actual: i32) -> i32:
    if self.types_compatible_fast(expected, actual) != 0:
        return 1

    let exp_r = self.resolve_alias(expected)
    let act_r = self.resolve_alias(actual)
    let exp_k = self.get_type_kind(exp_r)
    let act_k = self.get_type_kind(act_r)

    if self.is_option_pointer_type(exp_r) != 0 and (act_k == TY_PTR or act_k == TY_REF or act_k == TY_FN):
        let opt_payload = self.option_pointer_payload_type(exp_r)
        if opt_payload != 0:
            return self.types_compatible(opt_payload, actual)

    // Structural compatibility for non-interned compound types.
    if exp_k == TY_PTR and act_k == TY_PTR:
        if self.get_type_kind(self.resolve_alias(self.get_type_d0(exp_r))) == TY_VOID:
            return 1
        let exp_mut = self.get_type_d1(exp_r)
        let act_mut = self.get_type_d1(act_r)
        if exp_mut != 0 and act_mut == 0:
            return 0
        return self.types_compatible(self.get_type_d0(exp_r), self.get_type_d0(act_r))
    if exp_k == TY_PTR and act_k == TY_REF:
        if self.get_type_kind(self.resolve_alias(self.get_type_d0(exp_r))) == TY_VOID:
            return 1
        let exp_mut = self.get_type_d1(exp_r)
        let act_mut = self.get_type_d1(act_r)
        if exp_mut != 0 and act_mut == 0:
            return 0
        return self.types_compatible(self.get_type_d0(exp_r), self.get_type_d0(act_r))
    if exp_k == TY_REF and act_k == TY_REF:
        if self.get_type_kind(self.resolve_alias(self.get_type_d0(exp_r))) == TY_VOID:
            return 1
        let exp_mut = self.get_type_d1(exp_r)
        let act_mut = self.get_type_d1(act_r)
        if exp_mut != 0 and act_mut == 0:
            return 0
        return self.types_compatible(self.get_type_d0(exp_r), self.get_type_d0(act_r))
    if exp_k == TY_REF and act_k == TY_PTR:
        if self.get_type_kind(self.resolve_alias(self.get_type_d0(exp_r))) == TY_VOID:
            return 1
        let exp_mut = self.get_type_d1(exp_r)
        let act_mut = self.get_type_d1(act_r)
        if exp_mut != 0 and act_mut == 0:
            return 0
        return self.types_compatible(self.get_type_d0(exp_r), self.get_type_d0(act_r))
    if exp_k == TY_SLICE and act_k == TY_SLICE:
        return self.types_compatible(self.get_type_d0(exp_r), self.get_type_d0(act_r))
    if exp_k == TY_ARRAY and act_k == TY_ARRAY:
        if self.get_type_d1(exp_r) != self.get_type_d1(act_r):
            return 0
        return self.types_compatible(self.get_type_d0(exp_r), self.get_type_d0(act_r))
    if exp_k == TY_TUPLE and act_k == TY_TUPLE:
        let exp_count = self.get_type_d1(exp_r)
        let act_count = self.get_type_d1(act_r)
        if exp_count != act_count:
            return 0
        let exp_start = self.get_type_d0(exp_r)
        let act_start = self.get_type_d0(act_r)
        for ei in 0..exp_count:
            let exp_elem = self.type_extra.get((exp_start + ei) as i64)
            let act_elem = self.type_extra.get((act_start + ei) as i64)
            if self.types_compatible(exp_elem, act_elem) == 0:
                return 0
        return 1

    // TY_GENERIC_INST structural comparison (different TypeIds, same structure)
    if exp_k == TY_GENERIC_INST and act_k == TY_GENERIC_INST:
        if self.get_type_d0(exp_r) == self.get_type_d0(act_r):
            let gi_ec = self.get_type_d2(exp_r)
            let gi_ac2 = self.get_type_d2(act_r)
            if gi_ec == gi_ac2:
                var gi_all_ok = 1
                for gi_i in 0..gi_ec:
                    if self.types_compatible(self.get_generic_inst_arg(exp_r, gi_i), self.get_generic_inst_arg(act_r, gi_i)) == 0:
                        gi_all_ok = 0
                        break
                if gi_all_ok != 0:
                    return 1
    // TY_GENERIC_INST ↔ base struct/enum (interop with codegen's erased types)
    if exp_k == TY_GENERIC_INST and (act_k == TY_STRUCT or act_k == TY_ENUM):
        if self.get_type_d0(exp_r) == self.get_type_d0(act_r):
            return 1
    if (exp_k == TY_STRUCT or exp_k == TY_ENUM) and act_k == TY_GENERIC_INST:
        if self.get_type_d0(exp_r) == self.get_type_d0(act_r):
            return 1

    // Auto-referencing: T → &T
    if exp_k == TY_REF:
        if self.get_type_d1(exp_r) == 0:
            if self.types_compatible(self.get_type_d0(exp_r), act_r):
                return 1
    0

fn Sema.arithmetic_result_type(self: Sema, lhs: i32, rhs: i32) -> i32:
    if lhs == 0:
        return rhs
    if rhs == 0:
        return lhs
    let lk = self.get_type_kind(self.resolve_alias(lhs))
    let rk = self.get_type_kind(self.resolve_alias(rhs))
    if lk == TY_NEVER:
        return rhs
    if rk == TY_NEVER:
        return lhs
    // Float wins over int
    if lk == TY_FLOAT and rk == TY_FLOAT:
        let lb = self.get_type_d0(self.resolve_alias(lhs))
        let rb = self.get_type_d0(self.resolve_alias(rhs))
        if lb >= rb:
            return lhs
        return rhs
    if lk == TY_FLOAT:
        return lhs
    if rk == TY_FLOAT:
        return rhs
    // Wider int wins
    if lk == TY_INT and rk == TY_INT:
        let lb = self.get_type_d0(self.resolve_alias(lhs))
        let rb = self.get_type_d0(self.resolve_alias(rhs))
        if lb >= rb:
            return lhs
        return rhs
    0

fn Sema.is_copy(self: Sema, tid: i32) -> i32:
    if tid == 0:
        return 1
    let resolved = self.resolve_alias(tid)
    let tk = self.get_type_kind(resolved)
    if tk == TY_ERR or tk == TY_INT or tk == TY_FLOAT or tk == TY_BOOL or tk == TY_VOID or tk == TY_NEVER or tk == TY_STR:
        return 1
    if tk == TY_PTR or tk == TY_REF or tk == TY_FN or tk == TY_GENERIC_FN:
        return 1
    if tk == TY_STRUCT or tk == TY_ARRAY or tk == TY_TUPLE or tk == TY_RANGE:
        // Break copy-check recursion on cyclic type graphs.
        for vi in 0..self.copy_visit_stack.len() as i32:
            if self.copy_visit_stack.get(vi as i64) == resolved:
                return 0
        self.copy_visit_stack.push(resolved)

        var out = 1
        if tk == TY_STRUCT:
            let name = self.get_type_d0(resolved)
            if self.has_drop_method(name):
                if sema_debug_move_enabled() != 0:
                    with_eprintln("[noncopy] type=" ++ self.pool_resolve(name) ++ " reason=drop")
                out = 0
            else:
                let struct_te_start = self.get_type_d1(resolved)
                let struct_field_count = self.get_type_d2(resolved)
                for fi in 0..struct_field_count:
                    let ft = self.type_extra.get((struct_te_start + fi * 3 + 1) as i64)
                    if self.is_copy(ft) == 0:
                        if sema_debug_move_enabled() != 0:
                            let field_name = self.type_extra.get((struct_te_start + fi * 3) as i64)
                            with_eprintln(
                                "[noncopy] type=" ++ self.pool_resolve(name) ++
                                " field=" ++ self.pool_resolve(field_name) ++
                                " field_ty=" ++ self.type_name(ft)
                            )
                        out = 0
                        break
        else if tk == TY_ARRAY:
            out = self.is_copy(self.get_type_d0(resolved))
        else if tk == TY_TUPLE:
            let tuple_te_start = self.get_type_d0(resolved)
            let tuple_elem_count = self.get_type_d1(resolved)
            for ei in 0..tuple_elem_count:
                if self.is_copy(self.type_extra.get((tuple_te_start + ei) as i64)) == 0:
                    out = 0
                    break
        else: // TY_RANGE
            out = self.is_copy(self.get_type_d0(resolved))

        self.copy_visit_stack.pop()
        return out
    if tk == TY_ENUM:
        return 1
    if tk == TY_SLICE:
        return 1
    1

fn Sema.has_drop_method(self: Sema, type_name: i32) -> i32:
    if type_name <= 0:
        return 0
    if self.drop_method_cache.contains(type_name):
        return self.drop_method_cache.get(type_name).unwrap()

    let type_text = self.pool_resolve(type_name)
    if type_text.len() == 0:
        self.drop_method_cache.insert(type_name, 0)
        return 0
    if type_text.len() > 512:
        self.drop_method_cache.insert(type_name, 0)
        return 0

    let target = if type_text.len() >= 5 and
                    type_text[type_text.len() - 5] == 46 and // '.'
                    type_text[type_text.len() - 4] == 100 and // d
                    type_text[type_text.len() - 3] == 114 and // r
                    type_text[type_text.len() - 2] == 111 and // o
                    type_text[type_text.len() - 1] == 112: // p
        type_text
    else:
        type_text ++ ".drop"

    var has = 0
    for si in 0..self.sig_names.len() as i32:
        let sig_sym = self.sig_names.get(si as i64)
        if with_str_eq(self.pool_resolve(sig_sym), target) != 0:
            has = 1
            break

    self.drop_method_cache.insert(type_name, has)
    has

// ── Borrow checking ──────────────────────────────────────────────

fn Sema.expire_borrows_in_scope(self: Sema, scope_start: i32):
    var i = self.bind_names.len() as i32 - 1
    while i >= scope_start:
        let sym = self.bind_names.get(i as i64)
        // Remove borrows whose ref_binding is this sym
        var bi = 0
        while bi < self.borrow_refs.len() as i32:
            if self.borrow_refs.get(bi as i64) == sym:
                // Swap-remove
                let last = self.borrow_refs.len() as i32 - 1
                if bi < last:
                    self.borrow_kinds.set_i32(bi as i64, self.borrow_kinds.get(last as i64))
                    self.borrow_places.set_i32(bi as i64, self.borrow_places.get(last as i64))
                    self.borrow_fields.set_i32(bi as i64, self.borrow_fields.get(last as i64))
                    self.borrow_refs.set_i32(bi as i64, self.borrow_refs.get(last as i64))
                    self.borrow_path_starts.set_i32(bi as i64, self.borrow_path_starts.get(last as i64))
                    self.borrow_path_counts.set_i32(bi as i64, self.borrow_path_counts.get(last as i64))
                self.borrow_kinds.pop()
                self.borrow_places.pop()
                self.borrow_fields.pop()
                self.borrow_refs.pop()
                self.borrow_path_starts.pop()
                self.borrow_path_counts.pop()
                bi = bi  // keep same type as else branch for phi
            else:
                bi = bi + 1
        i = i - 1

// ── Diagnostics ──────────────────────────────────────────────────

fn Sema.call_param_name(self: Sema, fn_sym: i32, param_i: i32) -> str:
    if fn_sym <= 0 or param_i < 0:
        return ""
    if not self.fn_decl_nodes.contains(fn_sym):
        return ""
    let fn_node = self.fn_decl_nodes.get(fn_sym).unwrap()
    let meta = self.ast.find_fn_meta(fn_node)
    if meta < 0:
        return ""
    let param_start = self.ast.fn_meta_param_start(meta)
    let param_count = self.ast.fn_meta_param_count(meta)
    if param_i >= param_count:
        return ""
    let param_sym = self.ast.fn_param_name(param_start, param_i)
    self.safe_symbol_text(param_sym)

fn Sema.argument_literal_default_help(self: Sema, arg_node: i32, expr_text: str, expected_ty: i32, actual_ty: i32) -> str:
    if arg_node == 0 or expr_text.len() == 0:
        return ""
    let kind = self.ast.kind(arg_node)
    let expected_name = self.type_name(expected_ty)
    if kind == NK_INT_LIT and actual_ty == self.ty_i32 and expected_ty != 0 and expected_ty != actual_ty:
        return "integer literal '" ++ expr_text ++ "' defaults to i32; cast with '" ++ expr_text ++ " as " ++ expected_name ++ "'"
    if kind == NK_FLOAT_LIT and actual_ty == self.ty_f64 and expected_ty != 0 and expected_ty != actual_ty:
        return "float literal '" ++ expr_text ++ "' defaults to f64; cast with '" ++ expr_text ++ " as " ++ expected_name ++ "'"
    ""

fn Sema.try_ci_coercion(self: Sema, arg_ty: i32, param_ty: i32) -> i32:
    // c_import auto-coercion: allow bool → integer at ABI boundary
    let arg_k = self.get_type_kind(self.resolve_alias(arg_ty))
    let par_k = self.get_type_kind(self.resolve_alias(param_ty))
    if arg_k == TY_BOOL and par_k == TY_INT:
        return 1
    0

fn Sema.emit_argument_type_mismatch(self: Sema, call_name: str, fn_sym: i32, arg_index: i32, param_i: i32, expected_ty: i32, actual_ty: i32, arg_node: i32):
    if self.suppress_errors != 0:
        return
    let start = self.ast.get_start(arg_node)
    let end = self.ast.get_end(arg_node)
    let primary = Span { file: self.local_file_id, start: start, end: end }
    let expected_name = self.type_name(expected_ty)
    let actual_name = self.type_name(actual_ty)
    let expr_text = render_expr(self.ast, self.pool, arg_node, 0)
    var msg = "wrong argument type"
    if call_name.len() > 0:
        msg = msg ++ " in call to '" ++ call_name ++ "'"
    var diag = Diagnostic.err(msg, primary)
    if expr_text.len() > 0 and sema_str_contains_char(expr_text, 10) == 0:
        diag.add_label(primary, "argument expression '" ++ expr_text ++ "' has type " ++ actual_name)
    else:
        diag.add_label(primary, "argument has type " ++ actual_name)

    let param_name = self.call_param_name(fn_sym, param_i)
    if param_name.len() > 0:
        diag.add_note("parameter '" ++ param_name ++ "' expects " ++ expected_name)
    else if arg_index >= 0:
        diag.add_note("argument " ++ int_to_string(arg_index + 1) ++ " expects " ++ expected_name)
    else:
        diag.add_note("expected type: " ++ expected_name)
    diag.add_note("actual type: " ++ actual_name)

    let help = self.argument_literal_default_help(arg_node, expr_text, expected_ty, actual_ty)
    if help.len() > 0:
        diag.add_help(help)
    self.diags.emit(diag)

fn Sema.unknown_type_message(self: Sema, sym: i32) -> str:
    let name = self.pool_resolve(sym)
    if name.len() == 0:
        return "unknown type"
    if name == "string":
        return "unknown type 'string'; use 'str' or 'String'"
    "unknown type '" ++ name ++ "'"

fn Sema.emit_unknown_type_error(self: Sema, sym: i32, node: i32):
    self.emit_error(self.unknown_type_message(sym), node)

fn Sema.emit_error(self: Sema, msg: str, node: i32):
    if self.suppress_errors != 0:
        return
    let start = self.ast.get_start(node)
    let end = self.ast.get_end(node)
    self.diags.emit(Diagnostic.err(msg, Span { file: self.local_file_id, start: start, end: end }))

fn Sema.emit_warning(self: Sema, msg: str, node: i32):
    let start = self.ast.get_start(node)
    let end = self.ast.get_end(node)
    self.diags.emit(Diagnostic.warn(msg, Span { file: self.local_file_id, start: start, end: end }))

// ── Typed dump rendering ────────────────────────────────────────

fn typed_decl_kind_name(kind: i32) -> str:
    if kind == NK_FN_DECL: return "function"
    if kind == NK_TYPE_DECL: return "type_decl"
    if kind == NK_USE_DECL: return "use_decl"
    if kind == NK_LET_DECL: return "let_decl"
    if kind == NK_EXTERN_FN: return "extern_fn"
    if kind == NK_C_IMPORT: return "c_import"
    if kind == NK_TRAIT_DECL: return "trait_decl"
    if kind == NK_IMPL_DECL: return "impl_decl"
    if kind == NK_POISONED_DECL: return "poisoned"
    "unknown"

fn typed_expr_kind_name(kind: i32) -> str:
    if kind == NK_INT_LIT: return "int_literal"
    if kind == NK_FLOAT_LIT: return "float_literal"
    if kind == NK_STRING_LIT: return "string_literal"
    if kind == NK_C_STRING_LIT: return "c_string_literal"
    if kind == NK_BOOL_LIT: return "bool_literal"
    if kind == NK_IDENT: return "ident"
    if kind == NK_BINARY: return "binary"
    if kind == NK_UNARY: return "unary"
    if kind == NK_CALL: return "call"
    if kind == NK_FIELD_ACCESS: return "field_access"
    if kind == NK_INDEX: return "index"
    if kind == NK_SLICE: return "slice"
    if kind == NK_BLOCK: return "block"
    if kind == NK_IF_EXPR: return "if_expr"
    if kind == NK_RETURN: return "return_expr"
    if kind == NK_LET_BINDING: return "let_binding"
    if kind == NK_LET_ELSE: return "let_else"
    if kind == NK_TUPLE_DESTRUCTURE: return "tuple_destructure"
    if kind == NK_ASSIGN: return "assign"
    if kind == NK_TUPLE: return "tuple"
    if kind == NK_RANGE: return "range"
    if kind == NK_VARIANT_SHORTHAND: return "variant_shorthand"
    if kind == NK_AWAIT: return "await_expr"
    if kind == NK_ASYNC_BLOCK: return "async_block"
    if kind == NK_SPAWN: return "spawn_expr"
    if kind == NK_PIPELINE: return "pipeline"
    if kind == NK_GROUPED: return "grouped"
    if kind == NK_WHILE: return "while_expr"
    if kind == NK_LOOP: return "loop_expr"
    if kind == NK_FOR: return "for_expr"
    if kind == NK_BREAK: return "break_expr"
    if kind == NK_CONTINUE: return "continue_expr"
    if kind == NK_ARRAY_LIT: return "array_literal"
    if kind == NK_ARRAY_COMPREHENSION: return "array_comprehension"
    if kind == NK_STRUCT_LIT: return "struct_literal"
    if kind == NK_MATCH: return "match_expr"
    if kind == NK_ENUM_VARIANT: return "enum_variant"
    if kind == NK_CLOSURE: return "closure"
    if kind == NK_CAST: return "cast"
    if kind == NK_DEFER: return "defer_expr"
    if kind == NK_ERRDEFER: return "errdefer_expr"
    if kind == NK_WITH_EXPR: return "with_expr"
    if kind == NK_RECORD_UPDATE: return "record_update"
    if kind == NK_YIELD: return "yield_expr"
    if kind == NK_COMPTIME: return "comptime_expr"
    if kind == NK_ASYNC_SCOPE: return "async_scope"
    if kind == NK_SELECT_AWAIT: return "select_await"
    if kind == NK_OPTIONAL_CHAIN: return "optional_chain"
    if kind == NK_POISONED_EXPR: return "poisoned"
    "unknown"

fn typed_indent(indent: i32) -> str:
    var out = ""
    for i in 0..indent:
        out = out ++ "  "
    out

fn emit_typed_indent(indent: i32):
    for i in 0..indent:
        print("  ")

fn sema_str_contains_char(text: str, needle: i32) -> i32:
    for i in 0..text.len():
        if text[i] == needle:
            return 1
    0

fn Sema.safe_symbol_text(self: Sema, sym: i32) -> str:
    if sym <= 0:
        return ""
    if self.pretty_symbol_names.contains(sym):
        let pretty = self.pretty_symbol_names.get(sym).unwrap()
        if pretty.len() > 0:
            return pretty
    let pooled = self.pool_resolve(sym)
    if pooled.len() > 0:
        return pooled
    "sym" ++ int_to_string(sym)

fn Sema.impl_owner_type_name_for_decl(self: Sema, decl: i32) -> str:
    let start = self.ast.get_start(decl)
    let end = self.ast.get_end(decl)
    var best_span = 0
    var best_name = ""
    for di in 0..self.ast.decl_count():
        let cand = self.ast.get_decl(di)
        if self.ast.kind(cand) != NK_IMPL_DECL:
            continue
        let impl_start = self.ast.get_start(cand)
        let impl_end = self.ast.get_end(cand)
        if impl_start <= start and end <= impl_end:
            let span = impl_end - impl_start
            if best_name.len() == 0 or span < best_span:
                best_span = span
                best_name = self.safe_symbol_text(self.ast.get_data0(cand))
    best_name

fn Sema.reset_typed_dump_safety(self: Sema):
    self.typed_dump_seen_nodes = sema_new_map_i32_i32()
    self.typed_dump_visit_budget = 1000

fn Sema.mark_typed_dump_visit(self: Sema, node: i32) -> i32:
    if self.typed_dump_visit_budget <= 0:
        return 0
    if self.typed_dump_seen_nodes.contains(node):
        return 0
    self.typed_dump_visit_budget = self.typed_dump_visit_budget - 1
    self.typed_dump_seen_nodes.insert(node, 1)
    1

fn Sema.clamp_extra_span_count(self: Sema, extra_start: i32, raw_count: i32, stride: i32, hard_cap: i32) -> i32:
    if raw_count <= 0:
        return 0
    if extra_start < 0 or extra_start >= self.ast.extra_len():
        return 0
    if stride <= 0:
        return 0
    let available = self.ast.extra_len() - extra_start
    if available <= 0:
        return 0
    var max_count = available / stride
    if max_count < 0:
        max_count = 0
    var count = raw_count
    if count > max_count:
        count = max_count
    if hard_cap > 0 and count > hard_cap:
        count = hard_cap
    if count < 0:
        count = 0
    count

fn Sema.clamp_sig_param_count(self: Sema, sig_idx: i32, meta_param_count: i32) -> i32:
    var count = self.sig_get_param_count(sig_idx)
    if meta_param_count >= 0 and meta_param_count < count:
        count = meta_param_count
    if count < 0:
        return 0
    if count > 64:
        return 64
    count

fn Sema.dump_typed_module(self: Sema) -> str:
    self.reset_typed_dump_safety()
    var out = ""
    let total_decl_count = self.ast.decl_count()
    let dump_decl_count = total_decl_count
    out = out ++ "typed module decls=" ++ int_to_string(dump_decl_count) ++ "\n"

    for di in 0..dump_decl_count:
        let decl = self.ast.get_decl(di)
        let kind = self.ast.kind(decl)
        let start = self.ast.get_start(decl)
        let end = self.ast.get_end(decl)

        out = out ++ "decl[" ++ int_to_string(di) ++ "] kind=" ++ typed_decl_kind_name(kind) ++ " span=" ++ int_to_string(start) ++ ".." ++ int_to_string(end) ++ "\n"

        if kind == NK_FN_DECL:
            let fn_name_sym = self.ast.get_data0(decl)
            var fn_name = self.safe_symbol_text(fn_name_sym)
            let owner_type_name = self.impl_owner_type_name_for_decl(decl)
            let parsed_fn_name = self.extract_decl_name_after(decl, "fn")
            if owner_type_name.len() > 0:
                if parsed_fn_name.len() > 0:
                    fn_name = owner_type_name ++ "." ++ parsed_fn_name
                else if sema_str_contains_char(fn_name, 46) == 0:
                    fn_name = owner_type_name ++ "." ++ fn_name
            let sig_idx = self.get_sig(fn_name_sym)
            if fn_name_sym > 0 and self.sig_idx_valid(sig_idx) != 0:
                out = out ++ "  fn " ++ fn_name ++ "("
                let meta = self.ast.find_fn_meta(decl)
                var param_start = 0
                var meta_param_count = 0
                if meta >= 0:
                    param_start = self.ast.fn_meta_param_start(meta)
                    meta_param_count = self.ast.fn_meta_param_count(meta)
                let param_count = self.clamp_sig_param_count(sig_idx, meta_param_count)
                for pi in 0..param_count:
                    if pi > 0:
                        out = out ++ ", "
                    let p_name_sym = if meta >= 0: self.ast.fn_param_name(param_start, pi) else: 0
                    let p_name = if p_name_sym != 0: self.safe_symbol_text(p_name_sym) else: "_"
                    out = out ++ p_name ++ ": " ++ self.type_name(self.sig_param_type(sig_idx, pi))
                out = out ++ ") -> " ++ self.type_name(self.sig_return_type(sig_idx)) ++ "\n"
                let inferred_ret = if meta >= 0 and self.ast.fn_meta_ret(meta) == 0: self.sig_return_type(sig_idx) else: 0
                out = out ++ (if inferred_ret != 0 and inferred_ret != self.ty_void: "  inferred_return: " ++ self.type_name(inferred_ret) ++ "\n" else: "")
            else:
                out = out ++ "  fn " ++ fn_name ++ "(<unknown>)\n"
            out = out ++ self.dump_typed_expr_tree(self.ast.get_data1(decl), 2)
            continue

        if kind == NK_EXTERN_FN:
            let ext_name_sym = self.ast.get_data0(decl)
            let ext_name = self.safe_symbol_text(ext_name_sym)
            let sig_idx = self.get_sig(ext_name_sym)
            if ext_name_sym > 0 and self.sig_idx_valid(sig_idx) != 0:
                out = out ++ "  extern fn " ++ ext_name ++ "("
                let meta = self.ast.find_fn_meta(decl)
                var param_start = 0
                var meta_param_count = 0
                if meta >= 0:
                    param_start = self.ast.fn_meta_param_start(meta)
                    meta_param_count = self.ast.fn_meta_param_count(meta)
                let param_count = self.clamp_sig_param_count(sig_idx, meta_param_count)
                for pi in 0..param_count:
                    if pi > 0:
                        out = out ++ ", "
                    let p_name_sym = if meta >= 0: self.ast.fn_param_name(param_start, pi) else: 0
                    let p_name = if p_name_sym != 0: self.safe_symbol_text(p_name_sym) else: "_"
                    out = out ++ p_name ++ ": " ++ self.type_name(self.sig_param_type(sig_idx, pi))
                out = out ++ ") -> " ++ self.type_name(self.sig_return_type(sig_idx)) ++ "\n"
            else:
                out = out ++ "  extern fn (<unknown>)\n"
            continue

        if kind == NK_LET_DECL:
            let name = self.safe_symbol_text(self.ast.get_data0(decl))
            let has_resolved = self.typed_binding_types.contains(decl) and self.typed_binding_types.get(decl).unwrap() != 0
            if has_resolved:
                let ty = self.typed_binding_types.get(decl).unwrap()
                let is_mut = if self.typed_binding_muts.contains(decl): self.typed_binding_muts.get(decl).unwrap() else: 0
                out = out ++ "  let " ++ name
                if is_mut != 0:
                    out = out ++ " (mut)"
                out = out ++ ": " ++ self.type_name(ty) ++ "\n"
            else:
                // Stage0 parity: emit <annotated> when type expr present but unresolved,
                // <inferred> when no annotation at all.
                let flags = self.ast.get_data2(decl)
                let has_ann = self.top_level_let_type_ann_extra(flags) >= 0
                out = out ++ "  let " ++ name ++ ": " ++ (if has_ann: "<annotated>" else: "<inferred>") ++ "\n"
            continue

        if kind == NK_TYPE_DECL:
            out = out ++ "  type " ++ self.safe_symbol_text(self.ast.get_data0(decl)) ++ "\n"
            continue

        if kind == NK_TRAIT_DECL:
            out = out ++ "  trait " ++ self.safe_symbol_text(self.ast.get_data0(decl)) ++ "\n"
            continue

        if kind == NK_IMPL_DECL:
            let type_name = self.safe_symbol_text(self.ast.get_data0(decl))
            let trait_sym = self.ast.get_data2(decl)
            if trait_sym != 0:
                out = out ++ "  impl " ++ self.safe_symbol_text(trait_sym) ++ " for " ++ type_name ++ "\n"
            else:
                out = out ++ "  impl " ++ type_name ++ "\n"
            continue

        if kind == NK_USE_DECL:
            let extra_start = self.ast.get_data0(decl)
            let path_count = self.ast.get_data1(decl)
            out = out ++ "  use "
            for pi in 0..path_count:
                if pi > 0:
                    out = out ++ "."
                out = out ++ self.safe_symbol_text(self.ast.get_extra(extra_start + pi))
            out = out ++ "\n"
            continue

        if kind == NK_C_IMPORT:
            out = out ++ "  c_import \"" ++ self.safe_symbol_text(self.ast.get_data0(decl)) ++ "\"\n"
            continue

        if kind == NK_POISONED_DECL:
            out = out ++ "  <poisoned>\n"

    out

fn Sema.emit_typed_module(self: Sema, requested_limit: i32):
    self.reset_typed_dump_safety()
    let total_decl_count = self.ast.decl_count()
    var dump_decl_count = total_decl_count
    if requested_limit > 0 and requested_limit <= total_decl_count:
        dump_decl_count = requested_limit
    print("typed module decls=" ++ int_to_string(dump_decl_count) ++ "\n")

    for di in 0..dump_decl_count:
        let decl = self.ast.get_decl(di)
        let kind = self.ast.kind(decl)
        let start = self.ast.get_start(decl)
        let end = self.ast.get_end(decl)

        print("decl[" ++ int_to_string(di) ++ "] kind=" ++ typed_decl_kind_name(kind) ++ " span=" ++ int_to_string(start) ++ ".." ++ int_to_string(end) ++ "\n")

        if kind == NK_FN_DECL:
            let fn_name_sym = self.ast.get_data0(decl)
            var fn_name = self.safe_symbol_text(fn_name_sym)
            let owner_type_name = self.impl_owner_type_name_for_decl(decl)
            let parsed_fn_name = self.extract_decl_name_after(decl, "fn")
            if owner_type_name.len() > 0:
                if parsed_fn_name.len() > 0:
                    fn_name = owner_type_name ++ "." ++ parsed_fn_name
                else if sema_str_contains_char(fn_name, 46) == 0:
                    fn_name = owner_type_name ++ "." ++ fn_name
            let sig_idx = self.get_sig(fn_name_sym)
            if fn_name_sym > 0 and self.sig_idx_valid(sig_idx) != 0:
                print("  fn ")
                print(fn_name)
                print("(")
                let meta = self.ast.find_fn_meta(decl)
                var param_start = 0
                var meta_param_count = 0
                if meta >= 0:
                    param_start = self.ast.fn_meta_param_start(meta)
                    meta_param_count = self.ast.fn_meta_param_count(meta)
                let param_count = self.clamp_sig_param_count(sig_idx, meta_param_count)
                for pi in 0..param_count:
                    if pi > 0:
                        print(", ")
                    let p_name_sym = if meta >= 0: self.ast.fn_param_name(param_start, pi) else: 0
                    let p_name = if p_name_sym != 0: self.safe_symbol_text(p_name_sym) else: "_"
                    print(p_name)
                    print(": ")
                    print(self.type_name(self.sig_param_type(sig_idx, pi)))
                print(") -> ")
                print(self.type_name(self.sig_return_type(sig_idx)))
                print("\n")
                let inferred_ret = if meta >= 0 and self.ast.fn_meta_ret(meta) == 0: self.sig_return_type(sig_idx) else: 0
                print(if inferred_ret != 0 and inferred_ret != self.ty_void: "  inferred_return: " ++ self.type_name(inferred_ret) ++ "\n" else: "")
            else:
                print("  fn ")
                print(fn_name)
                print("(<unknown>)\n")
            self.emit_typed_expr_tree(self.ast.get_data1(decl), 2)
            continue

        if kind == NK_EXTERN_FN:
            let ext_name_sym = self.ast.get_data0(decl)
            let ext_name = self.safe_symbol_text(ext_name_sym)
            let sig_idx = self.get_sig(ext_name_sym)
            if ext_name_sym > 0 and self.sig_idx_valid(sig_idx) != 0:
                print("  extern fn ")
                print(ext_name)
                print("(")
                let meta = self.ast.find_fn_meta(decl)
                var param_start = 0
                var meta_param_count = 0
                if meta >= 0:
                    param_start = self.ast.fn_meta_param_start(meta)
                    meta_param_count = self.ast.fn_meta_param_count(meta)
                let param_count = self.clamp_sig_param_count(sig_idx, meta_param_count)
                for pi in 0..param_count:
                    if pi > 0:
                        print(", ")
                    let p_name_sym = if meta >= 0: self.ast.fn_param_name(param_start, pi) else: 0
                    let p_name = if p_name_sym != 0: self.safe_symbol_text(p_name_sym) else: "_"
                    print(p_name)
                    print(": ")
                    print(self.type_name(self.sig_param_type(sig_idx, pi)))
                print(") -> ")
                print(self.type_name(self.sig_return_type(sig_idx)))
                print("\n")
            else:
                print("  extern fn (<unknown>)\n")
            continue

        if kind == NK_LET_DECL:
            let name = self.safe_symbol_text(self.ast.get_data0(decl))
            let has_resolved = self.typed_binding_types.contains(decl) and self.typed_binding_types.get(decl).unwrap() != 0
            if has_resolved:
                let ty = self.typed_binding_types.get(decl).unwrap()
                let is_mut = if self.typed_binding_muts.contains(decl): self.typed_binding_muts.get(decl).unwrap() else: 0
                print("  let ")
                print(name)
                if is_mut != 0:
                    print(" (mut)")
                print(": ")
                print(self.type_name(ty))
                print("\n")
            else:
                let flags = self.ast.get_data2(decl)
                let has_ann = self.top_level_let_type_ann_extra(flags) >= 0
                print("  let ")
                print(name)
                print(": ")
                print(if has_ann: "<annotated>" else: "<inferred>")
                print("\n")
            continue

        if kind == NK_TYPE_DECL:
            print("  type ")
            print(self.safe_symbol_text(self.ast.get_data0(decl)))
            print("\n")
            continue

        if kind == NK_TRAIT_DECL:
            print("  trait ")
            print(self.safe_symbol_text(self.ast.get_data0(decl)))
            print("\n")
            continue

        if kind == NK_IMPL_DECL:
            let type_name = self.safe_symbol_text(self.ast.get_data0(decl))
            let trait_sym = self.ast.get_data2(decl)
            if trait_sym != 0:
                print("  impl ")
                print(self.safe_symbol_text(trait_sym))
                print(" for ")
                print(type_name)
                print("\n")
            else:
                print("  impl ")
                print(type_name)
                print("\n")
            continue

        if kind == NK_USE_DECL:
            let extra_start = self.ast.get_data0(decl)
            let path_count = self.ast.get_data1(decl)
            print("  use ")
            for pi in 0..path_count:
                if pi > 0:
                    print(".")
                print(self.safe_symbol_text(self.ast.get_extra(extra_start + pi)))
            print("\n")
            continue

        if kind == NK_C_IMPORT:
            print("  c_import \"")
            print(self.safe_symbol_text(self.ast.get_data0(decl)))
            print("\"\n")
            continue

        if kind == NK_POISONED_DECL:
            print("  <poisoned>\n")

fn Sema.dump_typed_expr_tree(self: Sema, node: i32, indent: i32) -> str:
    if node == 0:
        return ""
    if node < 0 or node >= self.ast.node_count():
        return ""
    if indent > 80:
        return ""

    var out = ""
    let kind = self.ast.kind(node)
    let start = self.ast.get_start(node)
    let end = self.ast.get_end(node)
    let has_typed_expr = self.typed_expr_types.contains(node)

    if has_typed_expr:
        let tid = self.typed_expr_types.get(node).unwrap()
        out = out ++ typed_indent(indent) ++ "expr " ++ typed_expr_kind_name(kind) ++ " span=" ++ int_to_string(start) ++ ".." ++ int_to_string(end) ++ " : " ++ self.type_name(tid) ++ "\n"

    if kind == NK_LET_BINDING:
        if self.typed_binding_types.contains(node):
            let name_sym = if self.typed_binding_names.contains(node): self.typed_binding_names.get(node).unwrap() else: self.ast.get_data0(node)
            let is_mut = if self.typed_binding_muts.contains(node): self.typed_binding_muts.get(node).unwrap() else: (self.ast.get_data2(node) % 2)
            out = out ++ typed_indent(indent + 1) ++ "bind " ++ self.safe_symbol_text(name_sym)
            if is_mut != 0:
                out = out ++ " (mut)"
            out = out ++ ": " ++ self.type_name(self.typed_binding_types.get(node).unwrap()) ++ "\n"

    if kind == NK_BINARY:
        out = out ++ self.dump_typed_expr_tree(self.ast.get_data1(node), indent + 1)
        out = out ++ self.dump_typed_expr_tree(self.ast.get_data2(node), indent + 1)
        return out

    if kind == NK_UNARY:
        out = out ++ self.dump_typed_expr_tree(self.ast.get_data1(node), indent + 1)
        return out

    if kind == NK_CALL:
        let extra_start = self.ast.get_data1(node)
        let arg_count = self.ast.get_data2(node)
        let safe_arg_count = self.clamp_extra_span_count(extra_start, arg_count, 1, 64)
        out = out ++ self.dump_typed_expr_tree(self.ast.get_data0(node), indent + 1)
        for ai in 0..safe_arg_count:
            out = out ++ self.dump_typed_expr_tree(self.ast.get_extra(extra_start + ai), indent + 1)
        return out

    if kind == NK_FIELD_ACCESS:
        out = out ++ self.dump_typed_expr_tree(self.ast.get_data0(node), indent + 1)
        return out

    if kind == NK_OPTIONAL_CHAIN:
        let extra_start = self.ast.get_data2(node)
        if extra_start < 0 or extra_start >= self.ast.extra_len():
            return out
        let arg_count = self.ast.get_extra(extra_start)
        let safe_arg_count = self.clamp_extra_span_count(extra_start + 1, arg_count, 1, 64)
        out = out ++ self.dump_typed_expr_tree(self.ast.get_data0(node), indent + 1)
        for ai in 0..safe_arg_count:
            out = out ++ self.dump_typed_expr_tree(self.ast.get_extra(extra_start + 1 + ai), indent + 1)
        return out

    if kind == NK_INDEX:
        out = out ++ self.dump_typed_expr_tree(self.ast.get_data0(node), indent + 1)
        out = out ++ self.dump_typed_expr_tree(self.ast.get_data1(node), indent + 1)
        return out

    if kind == NK_SLICE:
        out = out ++ self.dump_typed_expr_tree(self.ast.get_data0(node), indent + 1)
        out = out ++ self.dump_typed_expr_tree(self.ast.get_data1(node), indent + 1)
        out = out ++ self.dump_typed_expr_tree(self.ast.get_data2(node), indent + 1)
        return out

    if kind == NK_BLOCK:
        let extra_start = self.ast.get_data0(node)
        let stmt_count = self.ast.get_data1(node)
        let tail = self.ast.get_data2(node)
        let safe_stmt_count = self.clamp_extra_span_count(extra_start, stmt_count, 1, 256)
        for si in 0..safe_stmt_count:
            out = out ++ self.dump_typed_expr_tree(self.ast.get_extra(extra_start + si), indent + 1)
        out = out ++ self.dump_typed_expr_tree(tail, indent + 1)
        return out

    if kind == NK_IF_EXPR:
        out = out ++ self.dump_typed_expr_tree(self.ast.get_data0(node), indent + 1)
        out = out ++ self.dump_typed_expr_tree(self.ast.get_data1(node), indent + 1)
        out = out ++ self.dump_typed_expr_tree(self.ast.get_data2(node), indent + 1)
        return out

    if kind == NK_RETURN:
        out = out ++ self.dump_typed_expr_tree(self.ast.get_data0(node), indent + 1)
        return out

    if kind == NK_LET_BINDING:
        out = out ++ self.dump_typed_expr_tree(self.ast.get_data1(node), indent + 1)
        return out

    if kind == NK_LET_ELSE:
        out = out ++ self.dump_typed_expr_tree(self.ast.get_data1(node), indent + 1)
        out = out ++ self.dump_typed_expr_tree(self.ast.get_data2(node), indent + 1)
        return out

    if kind == NK_TUPLE_DESTRUCTURE:
        out = out ++ self.dump_typed_expr_tree(self.ast.get_data2(node), indent + 1)
        return out

    if kind == NK_ASSIGN:
        out = out ++ self.dump_typed_expr_tree(self.ast.get_data0(node), indent + 1)
        out = out ++ self.dump_typed_expr_tree(self.ast.get_data1(node), indent + 1)
        return out

    if kind == NK_TUPLE:
        let extra_start = self.ast.get_data0(node)
        let count = self.ast.get_data1(node)
        let safe_count = self.clamp_extra_span_count(extra_start, count, 1, 64)
        for i in 0..safe_count:
            out = out ++ self.dump_typed_expr_tree(self.ast.get_extra(extra_start + i), indent + 1)
        return out

    if kind == NK_RANGE:
        out = out ++ self.dump_typed_expr_tree(self.ast.get_data0(node), indent + 1)
        out = out ++ self.dump_typed_expr_tree(self.ast.get_data1(node), indent + 1)
        return out

    if kind == NK_VARIANT_SHORTHAND:
        let extra_start = self.ast.get_data1(node)
        let arg_count = self.ast.get_data2(node)
        let safe_arg_count = self.clamp_extra_span_count(extra_start, arg_count, 1, 64)
        for i in 0..safe_arg_count:
            out = out ++ self.dump_typed_expr_tree(self.ast.get_extra(extra_start + i), indent + 1)
        return out

    if kind == NK_AWAIT or kind == NK_ASYNC_BLOCK or kind == NK_SPAWN or kind == NK_GROUPED or kind == NK_DEFER or kind == NK_ERRDEFER or kind == NK_YIELD or kind == NK_COMPTIME:
        out = out ++ self.dump_typed_expr_tree(self.ast.get_data0(node), indent + 1)
        return out

    if kind == NK_PIPELINE:
        out = out ++ self.dump_typed_expr_tree(self.ast.get_data0(node), indent + 1)
        out = out ++ self.dump_typed_expr_tree(self.ast.get_data1(node), indent + 1)
        return out

    if kind == NK_WHILE:
        out = out ++ self.dump_typed_expr_tree(self.ast.get_data0(node), indent + 1)
        out = out ++ self.dump_typed_expr_tree(self.ast.get_data1(node), indent + 1)
        return out

    if kind == NK_LOOP:
        out = out ++ self.dump_typed_expr_tree(self.ast.get_data0(node), indent + 1)
        return out

    if kind == NK_FOR:
        out = out ++ self.dump_typed_expr_tree(self.ast.get_data1(node), indent + 1)
        out = out ++ self.dump_typed_expr_tree(self.ast.get_data2(node), indent + 1)
        return out

    if kind == NK_BREAK:
        out = out ++ self.dump_typed_expr_tree(self.ast.get_data0(node), indent + 1)
        return out

    if kind == NK_ARRAY_LIT:
        let extra_start = self.ast.get_data0(node)
        let count = self.ast.get_data1(node)
        let safe_count = self.clamp_extra_span_count(extra_start, count, 1, 128)
        for i in 0..safe_count:
            out = out ++ self.dump_typed_expr_tree(self.ast.get_extra(extra_start + i), indent + 1)
        return out

    if kind == NK_ARRAY_COMPREHENSION:
        out = out ++ self.dump_typed_expr_tree(self.ast.get_data0(node), indent + 1)
        out = out ++ self.dump_typed_expr_tree(self.ast.get_data2(node), indent + 1)
        return out

    if kind == NK_STRUCT_LIT:
        let extra_start = self.ast.get_data1(node)
        let field_count = self.ast.get_data2(node)
        let safe_field_count = self.clamp_extra_span_count(extra_start, field_count, 2, 128)
        for i in 0..safe_field_count:
            out = out ++ self.dump_typed_expr_tree(self.ast.get_extra(extra_start + i * 2 + 1), indent + 1)
        return out

    if kind == NK_MATCH:
        let extra_start = self.ast.get_data1(node)
        let arm_count = self.ast.get_data2(node)
        let safe_arm_count = self.clamp_extra_span_count(extra_start, arm_count, 1, 128)
        out = out ++ self.dump_typed_expr_tree(self.ast.get_data0(node), indent + 1)
        for i in 0..safe_arm_count:
            let arm = self.ast.get_extra(extra_start + i)
            let guard = self.ast.get_data2(arm)
            if guard != 0:
                out = out ++ self.dump_typed_expr_tree(guard, indent + 1)
            out = out ++ self.dump_typed_expr_tree(self.ast.get_data1(arm), indent + 1)
        return out

    if kind == NK_ENUM_VARIANT:
        let extra_start = self.ast.get_data2(node)
        if extra_start < 0 or extra_start >= self.ast.extra_len():
            return out
        let arg_count = self.ast.get_extra(extra_start)
        let safe_arg_count = self.clamp_extra_span_count(extra_start + 1, arg_count, 1, 64)
        for i in 0..safe_arg_count:
            out = out ++ self.dump_typed_expr_tree(self.ast.get_extra(extra_start + 1 + i), indent + 1)
        return out

    if kind == NK_CLOSURE:
        out = out ++ self.dump_typed_expr_tree(self.ast.get_data0(node), indent + 1)
        return out

    if kind == NK_CAST:
        out = out ++ self.dump_typed_expr_tree(self.ast.get_data0(node), indent + 1)
        return out

    if kind == NK_WITH_EXPR:
        out = out ++ self.dump_typed_expr_tree(self.ast.get_data0(node), indent + 1)
        out = out ++ self.dump_typed_expr_tree(self.ast.get_data1(node), indent + 1)
        return out

    if kind == NK_RECORD_UPDATE:
        let extra_start = self.ast.get_data1(node)
        let field_count = self.ast.get_data2(node)
        out = out ++ self.dump_typed_expr_tree(self.ast.get_data0(node), indent + 1)
        let safe_field_count = self.clamp_extra_span_count(extra_start, field_count, 2, 128)
        for i in 0..safe_field_count:
            out = out ++ self.dump_typed_expr_tree(self.ast.get_extra(extra_start + i * 2 + 1), indent + 1)
        return out

    if kind == NK_ASYNC_SCOPE:
        out = out ++ self.dump_typed_expr_tree(self.ast.get_data1(node), indent + 1)
        return out

    if kind == NK_SELECT_AWAIT:
        let extra_start = self.ast.get_data0(node)
        let arm_count = self.ast.get_data1(node)
        let safe_arm_count = self.clamp_extra_span_count(extra_start, arm_count, 3, 32)
        for i in 0..safe_arm_count:
            out = out ++ self.dump_typed_expr_tree(self.ast.get_extra(extra_start + i * 3 + 1), indent + 1)
            out = out ++ self.dump_typed_expr_tree(self.ast.get_extra(extra_start + i * 3 + 2), indent + 1)
        return out

    out

fn Sema.emit_typed_expr_tree(self: Sema, node: i32, indent: i32):
    if node == 0:
        return
    if node < 0 or node >= self.ast.node_count():
        return
    if indent > 80:
        return

    let kind = self.ast.kind(node)
    let start = self.ast.get_start(node)
    let end = self.ast.get_end(node)
    let has_typed_expr = self.typed_expr_types.contains(node)

    if has_typed_expr:
        let tid = self.typed_expr_types.get(node).unwrap()
        emit_typed_indent(indent)
        print("expr ")
        print(typed_expr_kind_name(kind))
        print(" span=")
        print(int_to_string(start))
        print("..")
        print(int_to_string(end))
        print(" : ")
        print(self.type_name(tid))
        print("\n")

    if kind == NK_LET_BINDING:
        if self.typed_binding_types.contains(node):
            let name_sym = if self.typed_binding_names.contains(node): self.typed_binding_names.get(node).unwrap() else: self.ast.get_data0(node)
            let is_mut = if self.typed_binding_muts.contains(node): self.typed_binding_muts.get(node).unwrap() else: (self.ast.get_data2(node) % 2)
            emit_typed_indent(indent + 1)
            print("bind ")
            print(self.safe_symbol_text(name_sym))
            if is_mut != 0:
                print(" (mut)")
            print(": ")
            print(self.type_name(self.typed_binding_types.get(node).unwrap()))
            print("\n")

    if kind == NK_BINARY:
        self.emit_typed_expr_tree(self.ast.get_data1(node), indent + 1)
        self.emit_typed_expr_tree(self.ast.get_data2(node), indent + 1)
        return

    if kind == NK_UNARY:
        self.emit_typed_expr_tree(self.ast.get_data1(node), indent + 1)
        return

    if kind == NK_CALL:
        let extra_start = self.ast.get_data1(node)
        let arg_count = self.ast.get_data2(node)
        let safe_arg_count = self.clamp_extra_span_count(extra_start, arg_count, 1, 64)
        self.emit_typed_expr_tree(self.ast.get_data0(node), indent + 1)
        for ai in 0..safe_arg_count:
            self.emit_typed_expr_tree(self.ast.get_extra(extra_start + ai), indent + 1)
        return

    if kind == NK_FIELD_ACCESS:
        self.emit_typed_expr_tree(self.ast.get_data0(node), indent + 1)
        return

    if kind == NK_OPTIONAL_CHAIN:
        let extra_start = self.ast.get_data2(node)
        if extra_start < 0 or extra_start >= self.ast.extra_len():
            return
        let arg_count = self.ast.get_extra(extra_start)
        let safe_arg_count = self.clamp_extra_span_count(extra_start + 1, arg_count, 1, 64)
        self.emit_typed_expr_tree(self.ast.get_data0(node), indent + 1)
        for ai in 0..safe_arg_count:
            self.emit_typed_expr_tree(self.ast.get_extra(extra_start + 1 + ai), indent + 1)
        return

    if kind == NK_INDEX:
        self.emit_typed_expr_tree(self.ast.get_data0(node), indent + 1)
        self.emit_typed_expr_tree(self.ast.get_data1(node), indent + 1)
        return

    if kind == NK_SLICE:
        self.emit_typed_expr_tree(self.ast.get_data0(node), indent + 1)
        self.emit_typed_expr_tree(self.ast.get_data1(node), indent + 1)
        self.emit_typed_expr_tree(self.ast.get_data2(node), indent + 1)
        return

    if kind == NK_BLOCK:
        let extra_start = self.ast.get_data0(node)
        let stmt_count = self.ast.get_data1(node)
        let tail = self.ast.get_data2(node)
        let safe_stmt_count = self.clamp_extra_span_count(extra_start, stmt_count, 1, 256)
        for si in 0..safe_stmt_count:
            self.emit_typed_expr_tree(self.ast.get_extra(extra_start + si), indent + 1)
        self.emit_typed_expr_tree(tail, indent + 1)
        return

    if kind == NK_IF_EXPR:
        self.emit_typed_expr_tree(self.ast.get_data0(node), indent + 1)
        self.emit_typed_expr_tree(self.ast.get_data1(node), indent + 1)
        self.emit_typed_expr_tree(self.ast.get_data2(node), indent + 1)
        return

    if kind == NK_RETURN:
        self.emit_typed_expr_tree(self.ast.get_data0(node), indent + 1)
        return

    if kind == NK_LET_BINDING:
        self.emit_typed_expr_tree(self.ast.get_data1(node), indent + 1)
        return

    if kind == NK_LET_ELSE:
        self.emit_typed_expr_tree(self.ast.get_data1(node), indent + 1)
        self.emit_typed_expr_tree(self.ast.get_data2(node), indent + 1)
        return

    if kind == NK_TUPLE_DESTRUCTURE:
        self.emit_typed_expr_tree(self.ast.get_data2(node), indent + 1)
        return

    if kind == NK_ASSIGN:
        self.emit_typed_expr_tree(self.ast.get_data0(node), indent + 1)
        self.emit_typed_expr_tree(self.ast.get_data1(node), indent + 1)
        return

    if kind == NK_TUPLE:
        let extra_start = self.ast.get_data0(node)
        let count = self.ast.get_data1(node)
        let safe_count = self.clamp_extra_span_count(extra_start, count, 1, 64)
        for i in 0..safe_count:
            self.emit_typed_expr_tree(self.ast.get_extra(extra_start + i), indent + 1)
        return

    if kind == NK_RANGE:
        self.emit_typed_expr_tree(self.ast.get_data0(node), indent + 1)
        self.emit_typed_expr_tree(self.ast.get_data1(node), indent + 1)
        return

    if kind == NK_VARIANT_SHORTHAND:
        let extra_start = self.ast.get_data1(node)
        let arg_count = self.ast.get_data2(node)
        let safe_arg_count = self.clamp_extra_span_count(extra_start, arg_count, 1, 64)
        for i in 0..safe_arg_count:
            self.emit_typed_expr_tree(self.ast.get_extra(extra_start + i), indent + 1)
        return

    if kind == NK_AWAIT or kind == NK_ASYNC_BLOCK or kind == NK_SPAWN or kind == NK_GROUPED or kind == NK_DEFER or kind == NK_ERRDEFER or kind == NK_YIELD or kind == NK_COMPTIME:
        self.emit_typed_expr_tree(self.ast.get_data0(node), indent + 1)
        return

    if kind == NK_PIPELINE:
        self.emit_typed_expr_tree(self.ast.get_data0(node), indent + 1)
        self.emit_typed_expr_tree(self.ast.get_data1(node), indent + 1)
        return

    if kind == NK_WHILE:
        self.emit_typed_expr_tree(self.ast.get_data0(node), indent + 1)
        self.emit_typed_expr_tree(self.ast.get_data1(node), indent + 1)
        return

    if kind == NK_LOOP:
        self.emit_typed_expr_tree(self.ast.get_data0(node), indent + 1)
        return

    if kind == NK_FOR:
        self.emit_typed_expr_tree(self.ast.get_data1(node), indent + 1)
        self.emit_typed_expr_tree(self.ast.get_data2(node), indent + 1)
        return

    if kind == NK_BREAK:
        self.emit_typed_expr_tree(self.ast.get_data0(node), indent + 1)
        return

    if kind == NK_ARRAY_LIT:
        let extra_start = self.ast.get_data0(node)
        let count = self.ast.get_data1(node)
        let safe_count = self.clamp_extra_span_count(extra_start, count, 1, 128)
        for i in 0..safe_count:
            self.emit_typed_expr_tree(self.ast.get_extra(extra_start + i), indent + 1)
        return

    if kind == NK_ARRAY_COMPREHENSION:
        self.emit_typed_expr_tree(self.ast.get_data0(node), indent + 1)
        self.emit_typed_expr_tree(self.ast.get_data2(node), indent + 1)
        return

    if kind == NK_STRUCT_LIT:
        let extra_start = self.ast.get_data1(node)
        let field_count = self.ast.get_data2(node)
        let safe_field_count = self.clamp_extra_span_count(extra_start, field_count, 2, 128)
        for i in 0..safe_field_count:
            self.emit_typed_expr_tree(self.ast.get_extra(extra_start + i * 2 + 1), indent + 1)
        return

    if kind == NK_MATCH:
        let extra_start = self.ast.get_data1(node)
        let arm_count = self.ast.get_data2(node)
        let safe_arm_count = self.clamp_extra_span_count(extra_start, arm_count, 1, 128)
        self.emit_typed_expr_tree(self.ast.get_data0(node), indent + 1)
        for i in 0..safe_arm_count:
            let arm = self.ast.get_extra(extra_start + i)
            let guard = self.ast.get_data2(arm)
            if guard != 0:
                self.emit_typed_expr_tree(guard, indent + 1)
            self.emit_typed_expr_tree(self.ast.get_data1(arm), indent + 1)
        return

    if kind == NK_ENUM_VARIANT:
        let extra_start = self.ast.get_data2(node)
        if extra_start < 0 or extra_start >= self.ast.extra_len():
            return
        let arg_count = self.ast.get_extra(extra_start)
        let safe_arg_count = self.clamp_extra_span_count(extra_start + 1, arg_count, 1, 64)
        for i in 0..safe_arg_count:
            self.emit_typed_expr_tree(self.ast.get_extra(extra_start + 1 + i), indent + 1)
        return

    if kind == NK_CLOSURE:
        self.emit_typed_expr_tree(self.ast.get_data0(node), indent + 1)
        return

    if kind == NK_CAST:
        self.emit_typed_expr_tree(self.ast.get_data0(node), indent + 1)
        return

    if kind == NK_WITH_EXPR:
        self.emit_typed_expr_tree(self.ast.get_data0(node), indent + 1)
        self.emit_typed_expr_tree(self.ast.get_data1(node), indent + 1)
        return

    if kind == NK_RECORD_UPDATE:
        let extra_start = self.ast.get_data1(node)
        let field_count = self.ast.get_data2(node)
        self.emit_typed_expr_tree(self.ast.get_data0(node), indent + 1)
        let safe_field_count = self.clamp_extra_span_count(extra_start, field_count, 2, 128)
        for i in 0..safe_field_count:
            self.emit_typed_expr_tree(self.ast.get_extra(extra_start + i * 2 + 1), indent + 1)
        return

    if kind == NK_ASYNC_SCOPE:
        self.emit_typed_expr_tree(self.ast.get_data1(node), indent + 1)
        return

    if kind == NK_SELECT_AWAIT:
        let extra_start = self.ast.get_data0(node)
        let arm_count = self.ast.get_data1(node)
        let safe_arm_count = self.clamp_extra_span_count(extra_start, arm_count, 3, 32)
        for i in 0..safe_arm_count:
            self.emit_typed_expr_tree(self.ast.get_extra(extra_start + i * 3 + 1), indent + 1)
            self.emit_typed_expr_tree(self.ast.get_extra(extra_start + i * 3 + 2), indent + 1)
        return

// ── Type name formatting ─────────────────────────────────────────

fn Sema.type_name(self: Sema, tid: i32) -> str:
    let resolved = self.resolve_alias(tid)
    let tk = self.get_type_kind(resolved)
    if tk == TY_ERR:
        return "<error>"
    if tk == TY_INT:
        let bits = self.get_type_d0(resolved)
        let signed = self.get_type_d1(resolved)
        let is_ptr_width = self.get_type_d2(resolved)
        if is_ptr_width != 0:
            return if signed != 0: "isize" else: "usize"
        if bits == 8:
            return if signed != 0: "i8" else: "u8"
        if bits == 16:
            return if signed != 0: "i16" else: "u16"
        if bits == 32:
            return if signed != 0: "i32" else: "u32"
        if bits == 64:
            return if signed != 0: "i64" else: "u64"
        if bits == 128:
            return if signed != 0: "i128" else: "u128"
        return "<int>"
    if tk == TY_FLOAT:
        if self.get_type_d0(resolved) == 32:
            return "f32"
        return "f64"
    if tk == TY_BOOL:
        return "bool"
    if tk == TY_VOID:
        return "void"
    if tk == TY_NEVER:
        return "Never"
    if tk == TY_STR:
        return "str"
    if tk == TY_STRUCT:
        return self.safe_symbol_text(self.get_type_d0(resolved))
    if tk == TY_ENUM:
        return self.safe_symbol_text(self.get_type_d0(resolved))
    if tk == TY_ARRAY:
        let size = self.get_type_d1(resolved)
        return "[" ++ int_to_string(size) ++ "]" ++ self.type_name(self.get_type_d0(resolved))
    if tk == TY_SLICE:
        return "[]" ++ self.type_name(self.get_type_d0(resolved))
    if tk == TY_TUPLE:
        let te_start = self.get_type_d0(resolved)
        let elem_count = self.get_type_d1(resolved)
        var out = "("
        for ei in 0..elem_count:
            if ei > 0:
                out = out ++ ", "
            out = out ++ self.type_name(self.type_extra.get((te_start + ei) as i64))
        if elem_count == 1:
            out = out ++ ","
        return out ++ ")"
    if tk == TY_RANGE:
        let elem_name = self.type_name(self.get_type_d0(resolved))
        if self.get_type_d1(resolved) != 0:
            return "RangeInclusive[" ++ elem_name ++ "]"
        return "Range[" ++ elem_name ++ "]"
    if tk == TY_FN:
        let te_start = self.get_type_d0(resolved)
        let param_count = self.get_type_d1(resolved)
        var out = "fn("
        for pi in 0..param_count:
            if pi > 0:
                out = out ++ ", "
            out = out ++ self.type_name(self.type_extra.get((te_start + pi) as i64))
        return out ++ ") -> " ++ self.type_name(self.get_type_d2(resolved))
    if tk == TY_PTR:
        let pointee = self.type_name(self.get_type_d0(resolved))
        if self.get_type_d1(resolved) != 0:
            return "*mut " ++ pointee
        return "*const " ++ pointee
    if tk == TY_REF:
        let pointee = self.type_name(self.get_type_d0(resolved))
        if self.get_type_d1(resolved) != 0:
            return "&mut " ++ pointee
        return "&" ++ pointee
    if tk == TY_ALIAS:
        return "<alias>"
    if tk == TY_GENERIC_FN:
        return "<generic>"
    if tk == TY_TRAIT_OBJ:
        return "dyn " ++ self.safe_symbol_text(self.get_type_d0(resolved))
    if tk == TY_GENERIC_INST:
        let base_name = self.safe_symbol_text(self.get_type_d0(resolved))
        let arg_count = self.get_type_d2(resolved)
        let extra_start = self.get_type_d1(resolved)
        var out = base_name ++ "["
        for ai in 0..arg_count:
            if ai > 0:
                out = out ++ ", "
            out = out ++ self.type_name(self.type_extra.get((extra_start + ai) as i64))
        return out ++ "]"
    "<unknown>"
