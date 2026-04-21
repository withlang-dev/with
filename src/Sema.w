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

extern fn with_write(s: str) -> void
extern fn with_eprint(s: str) -> void
extern fn with_str_eq(a: str, b: str) -> i32
extern fn with_getenv_str(name: str) -> str
extern fn with_str_clone(s: str) -> str
extern fn with_hashmap_new(key_size: i64, val_size: i64) -> *i8

// ── Type kind constants ──────────────────────────────────────────

enum TypeKind: i32:
    TY_ERR = 0
    TY_INT = 1
    TY_FLOAT = 2
    TY_BOOL = 3
    TY_VOID = 4
    TY_STR = 5
    TY_STRUCT = 6
    TY_ENUM = 7
    TY_ARRAY = 8
    TY_SLICE = 9
    TY_TUPLE = 10
    TY_RANGE = 11
    TY_FN = 12
    TY_PTR = 13
    TY_REF = 14
    TY_ALIAS = 15
    TY_GENERIC_FN = 16
    TY_TRAIT_OBJ = 17
    TY_NEVER = 18
    TY_GENERIC_INST = 19

type TypeId = distinct i32

enum VarState: i32:
    LIVE = 0
    MOVED = 1

enum BorrowKind: i32:
    SHARED = 0
    EXCLUSIVE = 1

enum DeriveReq: i32:
    COPY = 0
    CLONE = 1
    EQ = 2

type SemaBuiltinSymbols {
    task: i32,
    channel: i32,
    send: i32,
    recv: i32,
    close: i32,
    cancel: i32,
    is_done: i32,
    todo: i32,
    unreachable: i32,
    track: i32,
    src: i32,
    embed_file: i32,
    copy: i32,
    drop: i32,
    self_type: i32,
    vec: i32,
    veciter: i32,
    option: i32,
    result: i32,
    hashmap: i32,
    hashset: i32,
    box: i32,
    ok: i32,
    err: i32,
    some: i32,
    none: i32,
    new: i32,
    push: i32,
    insert: i32,
    get: i32,
    remove: i32,
    len: i32,
    contains: i32,
    join: i32,
    iter: i32,
    filter: i32,
    map: i32,
    fold: i32,
    clear: i32,
    pop: i32,
    set_i32: i32,
    keys: i32,
    next: i32,
    unwrap: i32,
    is_some: i32,
    is_none: i32,
    is_ok: i32,
    is_err: i32,
    starts_with: i32,
    ends_with: i32,
    trim: i32,
    to_lower: i32,
    to_upper: i32,
    replace: i32,
    slice: i32,
    fields: i32,
    variants: i32,
    name: i32,
    size: i32,
    align: i32,
    implements: i32,
    is_copy: i32,
}

type SemaMethodLookup {
    sig_lookup: HashMap[i64, i32],
    fn_lookup: HashMap[i64, i32],
}

const GLOBAL_VALUE_DECL_DEF: i32 = 1
const GLOBAL_VALUE_DECL_EXTERN: i32 = 2

// ── Sema state ───────────────────────────────────────────────────

type Sema {
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
    // Exact type binding for each declaration node.
    type_decl_tids: HashMap[i32, i32],
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
    bitpacked_types: HashMap[i32, i32],  // type_id → 1 if bitpacked

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
    // Key: pair(type_id, trait_sym) → 1
    impl_generic_inst: HashMap[i64, i32],
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
    selection_cache: HashMap[i64, i32],
    // Blanket impl recursion guard: keys currently being resolved
    blanket_guard: Vec[i64],

    // Local trait/type names
    local_trait_names: HashMap[i32, i32],
    lang_trait_syms: HashMap[i32, i32],
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
    fn_stack_sizes: HashMap[i32, i32],
    mutable_global_syms: HashMap[i32, i32],
    global_value_decl_kinds: HashMap[i32, i32],

    // Hot intrinsic symbols used in semantic dispatch paths.
    syms: SemaBuiltinSymbols,

    // Method origin tracking
    method_impl_nodes: HashMap[i32, i32],
    method_decl_origins: HashMap[i32, i32],
    method_has_inherent: HashMap[i32, i32],
    method_symbol_flags: HashMap[i32, i32],
    method_lookup: SemaMethodLookup,
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
    scope_name_map: HashMap[i32, i32],
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

    // Resolved call args for named-arg calls: call_node → (start << 16 | count) in call_resolved_args_data
    call_resolved_args_map: HashMap[i32, i32],
    call_resolved_args_data: Vec[i32],
    // Implicit parameter bindings stack: pairs of (type_id, binding_sym)
    implicit_binding_types: Vec[i32],
    implicit_binding_syms: Vec[i32],

    // For-comprehension resolved variants: node → resolved variant sym.
    // Maps _Payload/_Empty marker nodes to Some/None or Ok/Err.
    comp_resolved: HashMap[i32, i32],
    // Match value-pattern sidecar: pattern node → symbol compared by value.
    pattern_value_syms: HashMap[i32, i32],

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
    generic_inst_cache: HashMap[i64, i32],

    // Associated type bindings from current impl (for Self.Name resolution)
    assoc_type_bindings: HashMap[i32, i32],

    // Frozen flags: set to 1 after check_module + preregister completes.
    // When frozen, add_type and new semantic symbol interning will error.
    symbols_frozen: i32,
    types_frozen: i32,

    // Current state
    source_text: str,
    current_return_type: TypeId,
    current_gen_yield_type: TypeId,
    has_gen_yield_type: i32,
    in_pipeline_rhs: i32,
    match_in_stmt_pos: i32,
    in_comptime_fn: i32,
    in_async_fn: i32,
    no_std: i32,
    alloc: i32,
    in_defer: i32,
    in_unsafe: i32,
    break_value_type: TypeId,
    has_break_value_type: i32,
    loop_depth: i32,
    closure_direct_arg_depth: i32,
    expected_expr_type: TypeId,
    has_expected_type: i32,
    local_file_id: i32,
    collecting_types: i32,
    discard_sym: i32,
    suppress_errors: i32,

    // Canonical primitive TypeIds
    ty_i8: TypeId,
    ty_i16: TypeId,
    ty_i32: TypeId,
    ty_i64: TypeId,
    ty_i128: TypeId,
    ty_u8: TypeId,
    ty_u16: TypeId,
    ty_u32: TypeId,
    ty_u64: TypeId,
    ty_u128: TypeId,
    ty_f32: TypeId,
    ty_f64: TypeId,
    ty_bool: TypeId,
    ty_void: TypeId,
    ty_never: TypeId,
    ty_str: TypeId,
    ty_str_view: TypeId,
    ty_usize: TypeId,
    ty_isize: TypeId,
    ty_const_i8_ptr: TypeId,
    ty_field_info: TypeId,
    ty_variant_info: TypeId,

    // Per-module scoping: tracks which module each declaration belongs to
    // and which symbols are visible in each module context.
    decl_source_paths: Vec[str],     // one path per decl index (from Frontend)
    decl_source_file_ids: Vec[i32],  // one file id per decl index (from Frontend)
    decl_is_c_import: Vec[i32],      // 1 if decl came from c_import, 0 otherwise
    current_module_path: str,        // module path being checked right now
    module_paths: Vec[str],          // resolved module graph paths
    module_import_starts: Vec[i32],  // per-module start into module_import_targets
    module_import_counts: Vec[i32],  // per-module import edge count
    module_import_targets: Vec[i32], // flattened target module indices
    module_index_by_path: HashMap[str, i32],   // path -> module index
    global_visible_module_paths: HashMap[str, i32], // prelude-visible modules
    module_visibility_cache: HashMap[str, i32], // "from->to" -> visibility
    named_type_candidate_syms: Vec[i32],       // every registered named type symbol
    named_type_candidate_tids: Vec[i32],       // parallel type id for candidate
    named_type_candidate_paths: Vec[str],      // defining module path or "" for global
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
    with_eprint(f"[unknown-type] {context} sym={sym} name={name} prim={prim} named={named} collecting={self.collecting_types} node_kind={self.ast.kind(node)}")

fn Sema.pool_resolve_symbol(self: Sema, sym: i32) -> str:
    self.pool.resolve_symbol(sym)

fn Sema.pool_resolve(self: Sema, sym: i32) -> str:
    self.pool_resolve_symbol(sym)

fn Sema.pool_lookup_symbol(self: Sema, name: str) -> i32:
    if name.len() == 0:
        return 0
    let existing = self.pool.state.symbol_map.get(name)
    if existing.is_some():
        return existing.unwrap()

    var i = 1
    while i < self.pool.state.symbol_texts.len() as i32:
        let existing_text = self.pool.state.symbol_texts.get(i as i64)
        if sema_str_eq(existing_text, name) != 0:
            return i
        i = i + 1
    0

fn Sema.pool_intern(self: &mut Sema, name: str) -> i32:
    if self.symbols_frozen != 0:
        let existing = self.pool_lookup_symbol(name)
        if existing != 0:
            return existing
        with_eprint("BUG: Sema.pool_intern called after symbol freeze")
        return 0
    let existing = self.pool.state.symbol_map.get(name)
    if existing.is_some():
        return existing.unwrap()

    var i = 1
    while i < self.pool.state.symbol_texts.len() as i32:
        let existing_text = self.pool.state.symbol_texts.get(i as i64)
        if sema_str_eq(existing_text, name) != 0:
            self.pool.state.symbol_map.insert(existing_text, i)
            return i
        i = i + 1

    let id = self.pool.state.symbol_texts.len() as i32
    let owned = sema_owned_text(name)
    self.pool.state.symbol_texts.push(owned)
    self.pool.state.symbol_map.insert(owned, id)
    id

fn sema_new_map_i32_i32 -> HashMap[i32, i32]:
    HashMap.new()

fn sema_new_map_i32_str -> HashMap[i32, str]:
    HashMap.new()

fn sema_new_map_str_i32 -> HashMap[str, i32]:
    HashMap.new()

fn sema_new_map_i64_i32 -> HashMap[i64, i32]:
    HashMap.new()

fn sema_owned_text(text: str) -> str:
    if text.len() == 0:
        return ""
    with_str_clone(text)

fn sema_pair_key(a: i32, b: i32) -> i64:
    (a as i64) * 4294967296 + (b as i64)

fn sema_builtin_symbols_zero -> SemaBuiltinSymbols:
    SemaBuiltinSymbols {
        task: 0,
        channel: 0,
        send: 0,
        recv: 0,
        close: 0,
        cancel: 0,
        is_done: 0,
        todo: 0,
        unreachable: 0,
        track: 0,
        src: 0,
        embed_file: 0,
        copy: 0,
        drop: 0,
        self_type: 0,
        vec: 0,
        veciter: 0,
        option: 0,
        result: 0,
        hashmap: 0,
        hashset: 0,
        box: 0,
        ok: 0,
        err: 0,
        some: 0,
        none: 0,
        new: 0,
        push: 0,
        insert: 0,
        get: 0,
        remove: 0,
        len: 0,
        contains: 0,
        join: 0,
        iter: 0,
        filter: 0,
        map: 0,
        fold: 0,
        clear: 0,
        pop: 0,
        set_i32: 0,
        keys: 0,
        next: 0,
        unwrap: 0,
        is_some: 0,
        is_none: 0,
        is_ok: 0,
        is_err: 0,
        starts_with: 0,
        ends_with: 0,
        trim: 0,
        to_lower: 0,
        to_upper: 0,
        replace: 0,
        slice: 0,
        fields: 0,
        variants: 0,
        name: 0,
        size: 0,
        align: 0,
        implements: 0,
        is_copy: 0,
    }

fn sema_method_lookup_new -> SemaMethodLookup:
    SemaMethodLookup {
        sig_lookup: sema_new_map_i64_i32(),
        fn_lookup: sema_new_map_i64_i32(),
    }

fn sema_visibility_cache_key(from_path: str, to_path: str) -> str:
    from_path ++ "->" ++ to_path

fn sema_empty_state(pool: InternPool, diags: DiagnosticList, ast: AstPool) -> Sema:
    let named_types = sema_new_map_i32_i32()
    let type_decl_nodes = sema_new_map_i32_i32()
    let type_decl_tids = sema_new_map_i32_i32()
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
    let selection_cache = sema_new_map_i64_i32()
    let local_trait_names = sema_new_map_i32_i32()
    let lang_trait_syms = sema_new_map_i32_i32()
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
    let fn_stack_sizes = sema_new_map_i32_i32()
    let mutable_global_syms = sema_new_map_i32_i32()
    let global_value_decl_kinds = sema_new_map_i32_i32()
    let method_impl_nodes = sema_new_map_i32_i32()
    let method_decl_origins = sema_new_map_i32_i32()
    let method_has_inherent = sema_new_map_i32_i32()
    let method_symbol_flags = sema_new_map_i32_i32()
    let method_lookup = sema_method_lookup_new()
    let drop_method_cache = sema_new_map_i32_i32()
    let typed_expr_types = sema_new_map_i32_i32()
    let typed_binding_types = sema_new_map_i32_i32()
    let typed_binding_names = sema_new_map_i32_i32()
    let typed_binding_muts = sema_new_map_i32_i32()
    let typed_dump_seen_nodes = sema_new_map_i32_i32()
    let generic_specialization_cache = sema_new_map_str_i32()
    let generic_inst_cache = sema_new_map_i64_i32()
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
        type_decl_tids,
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
        bitpacked_types: sema_new_map_i32_i32(),
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
        lang_trait_syms,
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
        fn_stack_sizes,
        mutable_global_syms,
        global_value_decl_kinds,
        syms: sema_builtin_symbols_zero(),
        method_impl_nodes,
        method_decl_origins,
        method_has_inherent,
        method_symbol_flags,
        method_lookup,
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
        scope_name_map: HashMap.new(),
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
        call_resolved_args_map: sema_new_map_i32_i32(),
        call_resolved_args_data: Vec.new(),
        implicit_binding_types: Vec.new(),
        implicit_binding_syms: Vec.new(),
        comp_resolved: sema_new_map_i32_i32(),
        pattern_value_syms: sema_new_map_i32_i32(),
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
        symbols_frozen: 0,
        types_frozen: 0,
        source_text: "",
        current_return_type: 0,
        current_gen_yield_type: 0,
        has_gen_yield_type: 0,
        in_pipeline_rhs: 0,
        match_in_stmt_pos: 0,
        in_comptime_fn: 0,
        in_async_fn: 0,
        no_std: 0,
        alloc: 0,
        in_defer: 0,
        in_unsafe: 0,
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
        ty_field_info: 0, ty_variant_info: 0,
        decl_source_paths: Vec.new(),
        decl_source_file_ids: Vec.new(),
        decl_is_c_import: Vec.new(),
        current_module_path: "",
        module_paths: Vec.new(),
        module_import_starts: Vec.new(),
        module_import_counts: Vec.new(),
        module_import_targets: Vec.new(),
        module_index_by_path: sema_new_map_str_i32(),
        global_visible_module_paths: sema_new_map_str_i32(),
        module_visibility_cache: sema_new_map_str_i32(),
        named_type_candidate_syms: Vec.new(),
        named_type_candidate_tids: Vec.new(),
        named_type_candidate_paths: Vec.new(),
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
    s.add_type(TypeKind.TY_ERR, 0, 0, 0)

    // Register primitive types.
    s.ty_i8 = s.add_type(TypeKind.TY_INT, 8, 1, 0)
    s.ty_i16 = s.add_type(TypeKind.TY_INT, 16, 1, 0)
    s.ty_i32 = s.add_type(TypeKind.TY_INT, 32, 1, 0)
    s.ty_i64 = s.add_type(TypeKind.TY_INT, 64, 1, 0)
    s.ty_i128 = s.add_type(TypeKind.TY_INT, 128, 1, 0)
    s.ty_u8 = s.add_type(TypeKind.TY_INT, 8, 0, 0)
    s.ty_u16 = s.add_type(TypeKind.TY_INT, 16, 0, 0)
    s.ty_u32 = s.add_type(TypeKind.TY_INT, 32, 0, 0)
    s.ty_u64 = s.add_type(TypeKind.TY_INT, 64, 0, 0)
    s.ty_u128 = s.add_type(TypeKind.TY_INT, 128, 0, 0)
    s.ty_f32 = s.add_type(TypeKind.TY_FLOAT, 32, 0, 0)
    s.ty_f64 = s.add_type(TypeKind.TY_FLOAT, 64, 0, 0)
    s.ty_bool = s.add_type(TypeKind.TY_BOOL, 0, 0, 0)
    s.ty_void = s.add_type(TypeKind.TY_VOID, 0, 0, 0)
    s.ty_never = s.add_type(TypeKind.TY_NEVER, 0, 0, 0)
    s.ty_str = s.add_type(TypeKind.TY_STR, 0, 0, 0)
    s.ty_str_view = s.add_type(TypeKind.TY_REF, s.ty_str, 0, 0)
    // Pointer-width integers: d2=1 marks them as usize/isize (64-bit on arm64)
    s.ty_usize = s.add_type(TypeKind.TY_INT, 64, 0, 1)
    s.ty_isize = s.add_type(TypeKind.TY_INT, 64, 1, 1)
    s.ty_const_i8_ptr = s.add_type(TypeKind.TY_PTR, s.ty_i8, 0, 0)

    // Sub-byte and non-standard integer widths for bitpacked structs.
    for w in 1..8:
        s.add_type(TypeKind.TY_INT, w, 0, 0)  // u1-u7
        s.add_type(TypeKind.TY_INT, w, 1, 0)  // i1-i7
    s.add_type(TypeKind.TY_INT, 12, 0, 0)  // u12
    s.add_type(TypeKind.TY_INT, 21, 0, 0)  // u21
    s.add_type(TypeKind.TY_INT, 24, 0, 0)  // u24

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
    s.init_builtin_reflection_types()
    s.discard_sym = s.pool_intern("_")

    // Push root scope marker
    s.scope_starts.push(0)
    s.init_intrinsic_symbols()
    s

fn Sema.register_prim(self: &mut Sema, name: str, tid: i32):
    let sym = self.pool_intern(name)
    self.record_named_type(sym, tid)

fn Sema.record_named_type(self: &mut Sema, sym: i32, tid: i32):
    self.named_types.insert(sym, tid)
    self.named_type_candidate_syms.push(sym)
    self.named_type_candidate_tids.push(tid)
    let path = if self.current_module_path.len() > 0: self.current_module_path else: ""
    self.named_type_candidate_paths.push(sema_owned_text(path))

fn Sema.module_is_visible_from_current(self: Sema, target_path: str) -> i32:
    if target_path.len() == 0:
        return 1
    if self.global_visible_module_paths.contains(target_path):
        return 1
    if self.current_module_path.len() == 0:
        return 1
    if target_path == self.current_module_path:
        return 1
    if not self.module_index_by_path.contains(self.current_module_path):
        return 1
    if not self.module_index_by_path.contains(target_path):
        return 1
    let cache_key = sema_visibility_cache_key(self.current_module_path, target_path)
    if self.module_visibility_cache.contains(cache_key):
        return self.module_visibility_cache.get(cache_key).unwrap()
    let start_idx = self.module_index_by_path.get(self.current_module_path).unwrap()
    let target_idx = self.module_index_by_path.get(target_path).unwrap()
    if start_idx == target_idx:
        self.module_visibility_cache.insert(sema_owned_text(cache_key), 1)
        return 1
    let seen: HashMap[i32, i32] = sema_new_map_i32_i32()
    let stack: Vec[i32] = Vec.new()
    stack.push(start_idx)
    while stack.len() as i32 > 0:
        let last = stack.len() as i32 - 1
        let current = stack.get(last as i64)
        stack.pop()
        if seen.contains(current):
            continue
        seen.insert(current, 1)
        if current == target_idx:
            self.module_visibility_cache.insert(sema_owned_text(cache_key), 1)
            return 1
        if current >= 0 and current < self.module_import_starts.len() as i32:
            let edge_start = self.module_import_starts.get(current as i64)
            let edge_count = self.module_import_counts.get(current as i64)
            for ei in 0..edge_count:
                stack.push(self.module_import_targets.get((edge_start + ei) as i64))
    self.module_visibility_cache.insert(sema_owned_text(cache_key), 0)
    0

fn Sema.lookup_named_type_visible(self: Sema, sym: i32) -> i32:
    let named_tid = if self.named_types.contains(sym): self.named_types.get(sym).unwrap() else: 0
    var global_tid = 0
    var saw_recorded = 0
    var saw_named_tid = 0
    var i = self.named_type_candidate_syms.len() as i32 - 1
    while i >= 0:
        if self.named_type_candidate_syms.get(i as i64) == sym:
            saw_recorded = 1
            let candidate_tid = self.named_type_candidate_tids.get(i as i64)
            let candidate_path = self.named_type_candidate_paths.get(i as i64)
            if named_tid != 0 and candidate_tid == named_tid:
                saw_named_tid = 1
            if candidate_path.len() == 0:
                if global_tid == 0:
                    global_tid = candidate_tid
            else if self.module_is_visible_from_current(candidate_path) != 0:
                return candidate_tid
        i = i - 1
    if named_tid != 0 and (saw_recorded == 0 or saw_named_tid == 0):
        return named_tid
    if global_tid != 0:
        return global_tid
    0

fn Sema.has_named_type_visible(self: Sema, sym: i32) -> i32:
    if self.lookup_named_type_visible(sym) != 0:
        return 1
    0

fn Sema.register_builtin_struct_type(self: &mut Sema, name: str, field_names: Vec[str], field_types: Vec[i32], field_count: i32) -> i32:
    let name_sym = self.pool_intern(name)
    let te_start = self.type_extra.len() as i32
    for fi in 0..field_count:
        let field_sym = self.pool_intern(field_names.get(fi as i64))
        self.type_extra.push(field_sym)
        self.type_extra.push(field_types.get(fi as i64))
        self.type_extra.push(0)
    for _ in 0..field_count:
        self.type_extra.push(0)
    let tid = self.add_type(TypeKind.TY_STRUCT, name_sym, te_start, field_count)
    self.record_named_type(name_sym, tid as i32)
    self.pretty_symbol_names.insert(name_sym, sema_owned_text(name))
    tid as i32

fn Sema.init_builtin_reflection_types(self: &mut Sema):
    let field_info_names: Vec[str] = Vec.new()
    field_info_names.push("name")
    field_info_names.push("type_name")
    field_info_names.push("offset")
    field_info_names.push("size")
    field_info_names.push("is_ephemeral")
    let field_info_types: Vec[i32] = Vec.new()
    field_info_types.push(self.ty_str as i32)
    field_info_types.push(self.ty_str as i32)
    field_info_types.push(self.ty_usize as i32)
    field_info_types.push(self.ty_usize as i32)
    field_info_types.push(self.ty_bool as i32)
    self.ty_field_info = self.register_builtin_struct_type("FieldInfo", field_info_names, field_info_types, 5) as TypeId

    let variant_info_names: Vec[str] = Vec.new()
    variant_info_names.push("name")
    variant_info_names.push("discriminant")
    variant_info_names.push("has_payload")
    variant_info_names.push("payload_type_name")
    let variant_info_types: Vec[i32] = Vec.new()
    variant_info_types.push(self.ty_str as i32)
    variant_info_types.push(self.ty_i64 as i32)
    variant_info_types.push(self.ty_bool as i32)
    variant_info_types.push(self.ty_str as i32)
    self.ty_variant_info = self.register_builtin_struct_type("VariantInfo", variant_info_names, variant_info_types, 4) as TypeId

fn Sema.init_intrinsic_symbols(self: &mut Sema):
    self.syms.task = self.pool_intern("Task")
    self.syms.channel = self.pool_intern("Channel")
    self.syms.send = self.pool_intern("send")
    self.syms.recv = self.pool_intern("recv")
    self.syms.close = self.pool_intern("close")
    self.syms.cancel = self.pool_intern("cancel")
    self.syms.is_done = self.pool_intern("is_done")
    self.syms.todo = self.pool_intern("todo")
    self.syms.unreachable = self.pool_intern("unreachable")
    self.syms.track = self.pool_intern("track")
    self.syms.src = self.pool_intern("src")
    self.syms.embed_file = self.pool_intern("embed_file")
    self.syms.copy = self.pool_intern("Copy")
    self.syms.drop = self.pool_intern("Drop")
    self.syms.self_type = self.pool_intern("Self")
    self.syms.vec = self.pool_intern("Vec")
    self.syms.veciter = self.pool_intern("VecIter")
    self.syms.option = self.pool_intern("Option")
    self.syms.result = self.pool_intern("Result")
    self.syms.hashmap = self.pool_intern("HashMap")
    self.syms.hashset = self.pool_intern("HashSet")
    self.syms.box = self.pool_intern("Box")
    self.syms.ok = self.pool_intern("Ok")
    self.syms.err = self.pool_intern("Err")
    self.syms.some = self.pool_intern("Some")
    self.syms.none = self.pool_intern("None")
    self.syms.new = self.pool_intern("new")
    self.syms.push = self.pool_intern("push")
    self.syms.insert = self.pool_intern("insert")
    self.syms.get = self.pool_intern("get")
    self.syms.remove = self.pool_intern("remove")
    self.syms.len = self.pool_intern("len")
    self.syms.contains = self.pool_intern("contains")
    self.syms.join = self.pool_intern("join")
    self.syms.iter = self.pool_intern("iter")
    self.syms.filter = self.pool_intern("filter")
    self.syms.map = self.pool_intern("map")
    self.syms.fold = self.pool_intern("fold")
    self.syms.clear = self.pool_intern("clear")
    self.syms.pop = self.pool_intern("pop")
    self.syms.set_i32 = self.pool_intern("set_i32")
    self.syms.keys = self.pool_intern("keys")
    self.syms.next = self.pool_intern("next")
    self.syms.unwrap = self.pool_intern("unwrap")
    self.syms.is_some = self.pool_intern("is_some")
    self.syms.is_none = self.pool_intern("is_none")
    self.syms.is_ok = self.pool_intern("is_ok")
    self.syms.is_err = self.pool_intern("is_err")
    self.syms.starts_with = self.pool_intern("starts_with")
    self.syms.ends_with = self.pool_intern("ends_with")
    self.syms.trim = self.pool_intern("trim")
    self.syms.to_lower = self.pool_intern("to_lower")
    self.syms.to_upper = self.pool_intern("to_upper")
    self.syms.replace = self.pool_intern("replace")
    self.syms.slice = self.pool_intern("slice")
    self.syms.fields = self.pool_intern("fields")
    self.syms.variants = self.pool_intern("variants")
    self.syms.name = self.pool_intern("name")
    self.syms.size = self.pool_intern("size")
    self.syms.align = self.pool_intern("align")
    self.syms.implements = self.pool_intern("implements")
    self.syms.is_copy = self.pool_intern("is_copy")
    // Language-level traits: these affect codegen semantics (copy vs move,
    // destruction, thread safety). Always recognized regardless of prelude.
    self.lang_trait_syms.insert(self.syms.copy, 1)
    self.lang_trait_syms.insert(self.syms.drop, 1)
    self.lang_trait_syms.insert(self.pool_intern("Send"), 1)
    self.lang_trait_syms.insert(self.pool_intern("ScopedSend"), 1)

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
    self.pretty_symbol_names.insert(sym, sema_owned_text(name))

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

fn Sema.freeze_symbols(self: Sema):
    self.symbols_frozen = 1

fn Sema.add_type(self: Sema, kind: i32, d0: i32, d1: i32, d2: i32) -> TypeId:
    if self.types_frozen != 0:
        with_eprint("BUG: Sema.add_type called after freeze_types")
    let id = self.type_kinds.len() as i32
    self.type_kinds.push(kind)
    self.type_d0.push(d0)
    self.type_d1.push(d1)
    self.type_d2.push(d2)
    id as TypeId

// Mark type tables as immutable. Any subsequent add_type will error.
fn Sema.freeze_types(self: Sema):
    self.types_frozen = 1

fn Sema.type_extra_matches(self: Sema, extra_start: i32, values: Vec[i32], count: i32) -> i32:
    for i in 0..count:
        if self.type_extra.get((extra_start + i) as i64) != values.get(i as i64):
            return 0
    1

fn Sema.find_exact_type(self: Sema, kind: i32, d0: i32, d1: i32, d2: i32) -> TypeId:
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
        return ti as TypeId
    0 as TypeId

fn Sema.ensure_exact_type(self: Sema, kind: i32, d0: i32, d1: i32, d2: i32) -> TypeId:
    let existing = self.find_exact_type(kind, d0, d1, d2)
    if existing != 0:
        return existing
    if self.types_frozen != 0:
        return 0 as TypeId
    self.add_type(kind, d0, d1, d2)

fn Sema.find_tuple_type(self: Sema, elems: Vec[i32], elem_count: i32) -> TypeId:
    let type_count = self.type_kinds.len() as i32
    for ti in 0..type_count:
        if self.type_kinds.get(ti as i64) != TypeKind.TY_TUPLE:
            continue
        if self.type_d1.get(ti as i64) != elem_count:
            continue
        let te_start = self.type_d0.get(ti as i64)
        if self.type_extra_matches(te_start, elems, elem_count) != 0:
            return ti as TypeId
    0 as TypeId

fn Sema.ensure_tuple_type(self: Sema, elems: Vec[i32], elem_count: i32) -> TypeId:
    let existing = self.find_tuple_type(elems, elem_count)
    if existing != 0:
        return existing
    if self.types_frozen != 0:
        return 0 as TypeId
    let te_start = self.type_extra.len() as i32
    for ei in 0..elem_count:
        self.type_extra.push(elems.get(ei as i64))
    self.add_type(TypeKind.TY_TUPLE, te_start, elem_count, 0)

fn Sema.find_fn_type(self: Sema, params: Vec[i32], param_count: i32, ret: TypeId) -> TypeId:
    let type_count = self.type_kinds.len() as i32
    for ti in 0..type_count:
        if self.type_kinds.get(ti as i64) != TypeKind.TY_FN:
            continue
        if self.type_d1.get(ti as i64) != param_count:
            continue
        if self.type_d2.get(ti as i64) != ret as i32:
            continue
        let te_start = self.type_d0.get(ti as i64)
        if self.type_extra_matches(te_start, params, param_count) != 0:
            return ti as TypeId
    0 as TypeId

fn Sema.ensure_fn_type(self: Sema, params: Vec[i32], param_count: i32, ret: TypeId) -> TypeId:
    let existing = self.find_fn_type(params, param_count, ret)
    if existing != 0:
        return existing
    if self.types_frozen != 0:
        return 0 as TypeId
    let te_start = self.type_extra.len() as i32
    for pi in 0..param_count:
        self.type_extra.push(params.get(pi as i64))
    self.add_type(TypeKind.TY_FN, te_start, param_count, ret as i32)

fn Sema.callable_fn_type(self: Sema, tid: TypeId) -> i32:
    var current = tid as i32
    while current != 0:
        let resolved = self.resolve_alias(current as TypeId) as i32
        let tk = self.get_type_kind(resolved)
        if tk == TypeKind.TY_FN:
            return resolved
        if tk != TypeKind.TY_PTR and tk != TypeKind.TY_REF:
            return 0
        current = self.get_type_d0(resolved)
    0

fn Sema.callable_fn_param_type(self: Sema, tid: TypeId, param_i: i32) -> i32:
    let fn_tid = self.callable_fn_type(tid)
    if fn_tid == 0 or param_i < 0:
        return 0
    let param_count = self.get_type_d1(fn_tid)
    if param_i >= param_count:
        return 0
    let te_start = self.get_type_d0(fn_tid)
    self.type_extra.get((te_start + param_i) as i64)

fn sema_generic_inst_hash(base_sym: i32, args: Vec[i32], arg_count: i32) -> i64:
    var h: i64 = base_sym as i64
    for ai in 0..arg_count:
        h = h * 31 + (args.get(ai as i64) as i64)
    h

fn Sema.find_generic_inst_type(self: Sema, base_sym: i32, args: Vec[i32], arg_count: i32) -> TypeId:
    let key = sema_generic_inst_hash(base_sym, args, arg_count)
    if self.generic_inst_cache.contains(key):
        return self.generic_inst_cache.get(key).unwrap() as TypeId
    let type_count = self.type_kinds.len() as i32
    for ti in 0..type_count:
        if self.type_kinds.get(ti as i64) != TypeKind.TY_GENERIC_INST:
            continue
        if self.type_d0.get(ti as i64) != base_sym:
            continue
        if self.type_d2.get(ti as i64) != arg_count:
            continue
        let te_start = self.type_d1.get(ti as i64)
        if self.type_extra_matches(te_start, args, arg_count) != 0:
            self.generic_inst_cache.insert(key, ti)
            return ti as TypeId
    0 as TypeId

fn Sema.ensure_generic_inst_type(self: Sema, base_sym: i32, args: Vec[i32], arg_count: i32) -> TypeId:
    let existing = self.find_generic_inst_type(base_sym, args, arg_count)
    if existing != 0:
        return existing
    if self.types_frozen != 0:
        return 0 as TypeId
    let te_start = self.type_extra.len() as i32
    for ai in 0..arg_count:
        self.type_extra.push(args.get(ai as i64))
    let tid = self.add_type(TypeKind.TY_GENERIC_INST, base_sym, te_start, arg_count)
    let key = sema_generic_inst_hash(base_sym, args, arg_count)
    self.generic_inst_cache.insert(key, tid as i32)
    tid

// Look up an existing TypeKind.TY_GENERIC_INST(base_sym, [arg_tid]) in the cache.
// Returns the TypeId, or 0 if not found.
fn Sema.find_generic_inst(self: Sema, base_sym: i32, arg_tid: i32) -> i32:
    let args: Vec[i32] = Vec.new()
    args.push(arg_tid)
    self.find_generic_inst_type(base_sym, args, 1) as i32

// Look up an existing TypeKind.TY_RANGE(elem_tid, inclusive) in the type tables.
// Returns the TypeId, or 0 if not found.
fn Sema.find_range_type(self: Sema, elem_tid: TypeId, inclusive: i32) -> TypeId:
    let type_count = self.type_kinds.len() as i32
    for ti in 0..type_count:
        if self.type_kinds.get(ti as i64) == TypeKind.TY_RANGE:
            if self.type_d0.get(ti as i64) == elem_tid as i32:
                if self.type_d1.get(ti as i64) == inclusive:
                    return ti as TypeId
    0 as TypeId

// Pre-register generic instantiation types needed by MirLower so that
// downstream passes never need to mutate the type tables.
// Must be called after check_module() and before freeze_types().
fn Sema.preregister_mir_types(self: Sema):
    let vec_sym = self.syms.vec
    let vi_sym = self.syms.veciter

    // For every Vec[T] type registered, also register VecIter[T].
    let type_count = self.type_kinds.len() as i32
    for ti in 0..type_count:
        if self.type_kinds.get(ti as i64) == TypeKind.TY_GENERIC_INST:
            if self.type_d0.get(ti as i64) == vec_sym:
                let extra_start = self.type_d1.get(ti as i64)
                let arg_count = self.type_d2.get(ti as i64)
                if arg_count >= 1:
                    let elem_ty = self.type_extra.get(extra_start as i64)
                    let vi_args: Vec[i32] = Vec.new()
                    vi_args.push(elem_ty)
                    let vi_key = sema_generic_inst_hash(vi_sym, vi_args, 1)
                    if not self.generic_inst_cache.contains(vi_key):
                        let te_start = self.type_extra.len() as i32
                        self.type_extra.push(elem_ty)
                        let tid = self.add_type(TypeKind.TY_GENERIC_INST, vi_sym, te_start, 1)
                        self.generic_inst_cache.insert(vi_key, tid as i32)

    // Register Vec[str] for str.split() return type.
    let vec_str_args: Vec[i32] = Vec.new()
    vec_str_args.push(self.ty_str as i32)
    let vec_str_key = sema_generic_inst_hash(vec_sym, vec_str_args, 1)
    if not self.generic_inst_cache.contains(vec_str_key):
        let te_start = self.type_extra.len() as i32
        self.type_extra.push(self.ty_str as i32)
        let tid = self.add_type(TypeKind.TY_GENERIC_INST, vec_sym, te_start, 1)
        self.generic_inst_cache.insert(vec_str_key, tid as i32)

    // Also register VecIter[str] in case Vec[str].iter() is called.
    let vi_str_args: Vec[i32] = Vec.new()
    vi_str_args.push(self.ty_str as i32)
    let vi_str_key = sema_generic_inst_hash(vi_sym, vi_str_args, 1)
    if not self.generic_inst_cache.contains(vi_str_key):
        let te_start = self.type_extra.len() as i32
        self.type_extra.push(self.ty_str as i32)
        let tid = self.add_type(TypeKind.TY_GENERIC_INST, vi_sym, te_start, 1)
        self.generic_inst_cache.insert(vi_str_key, tid as i32)

// TypeKind.TY_GENERIC_INST: d0=base_sym, d1=extra_start, d2=arg_count
// Type args stored in type_extra[extra_start..extra_start+arg_count] as TypeIds.

fn Sema.resolve_generic_type(self: Sema, node: i32) -> i32:
    let gi_base_sym = self.ast.get_data0(node)
    let gi_base_tid = self.lookup_named_type_visible(gi_base_sym)
    if gi_base_tid == 0:
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
        gi_args.push(gi_arg_tid as i32)
    self.ensure_generic_inst_type(gi_base_sym, gi_args, gi_arg_count) as i32

fn Sema.get_generic_inst_base(self: Sema, tid: i32) -> i32:
    self.get_type_d0(tid)

fn Sema.get_generic_inst_arg_count(self: Sema, tid: i32) -> i32:
    self.get_type_d2(tid)

fn Sema.get_generic_inst_arg(self: Sema, tid: i32, index: i32) -> i32:
    let extra_start = self.get_type_d1(tid)
    self.type_extra.get((extra_start + index) as i64)

fn Sema.numeric_operand_type(self: Sema, tid: i32) -> i32:
    let resolved = self.resolve_alias(tid as TypeId)
    if self.get_type_kind(resolved) == TypeKind.TY_ENUM:
        let repr = self.enum_repr_type(resolved as i32)
        if repr != 0:
            return self.resolve_alias(repr as TypeId) as i32
    resolved as i32

fn Sema.is_unsigned_int_type(self: Sema, tid: i32) -> bool:
    let resolved = self.numeric_operand_type(tid)
    if self.get_type_kind(resolved) != TypeKind.TY_INT:
        return false
    self.get_type_d1(resolved) == 0

fn Sema.is_numeric_type(self: Sema, tid: i32) -> bool:
    let resolved = self.numeric_operand_type(tid)
    let kind = self.get_type_kind(resolved)
    kind == TypeKind.TY_INT or kind == TypeKind.TY_FLOAT

fn Sema.literal_suffix_type(self: Sema, suffix: i32) -> i32:
    if suffix == LiteralSuffix.I8: return self.ty_i8 as i32
    if suffix == LiteralSuffix.I16: return self.ty_i16 as i32
    if suffix == LiteralSuffix.I32: return self.ty_i32 as i32
    if suffix == LiteralSuffix.I64: return self.ty_i64 as i32
    if suffix == LiteralSuffix.I128: return self.ty_i128 as i32
    if suffix == LiteralSuffix.Isize: return self.ty_isize as i32
    if suffix == LiteralSuffix.U8: return self.ty_u8 as i32
    if suffix == LiteralSuffix.U16: return self.ty_u16 as i32
    if suffix == LiteralSuffix.U32: return self.ty_u32 as i32
    if suffix == LiteralSuffix.U64: return self.ty_u64 as i32
    if suffix == LiteralSuffix.U128: return self.ty_u128 as i32
    if suffix == LiteralSuffix.Usize: return self.ty_usize as i32
    if suffix == LiteralSuffix.F32: return self.ty_f32 as i32
    if suffix == LiteralSuffix.F64: return self.ty_f64 as i32
    0

fn Sema.int_literal_fits_type(self: Sema, node: i32, tid: i32) -> bool:
    let resolved = self.resolve_alias(tid)
    let kind = self.get_type_kind(resolved)
    if kind == TypeKind.TY_FLOAT:
        return true
    if kind != TypeKind.TY_INT:
        return false
    let bits = self.get_type_d0(resolved)
    let signed = self.get_type_d1(resolved)
    if self.ast.has_int_literal_exact(node as NodeId):
        let value = self.ast.int_literal_exact_value(node as NodeId)
        if signed != 0:
            return exact_int_fits_signed_magnitude_bits(value, bits)
        return exact_int_fits_unsigned_bits(value, bits)
    let value = self.ast.int_lit_value(node)
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

fn Sema.numeric_literal_expected_type(self: Sema, node: i32) -> i32:
    if self.has_expected_type == 0 or self.expected_expr_type == 0:
        return 0
    let expected = self.numeric_operand_type(self.expected_expr_type as i32)
    if not self.is_numeric_type(expected):
        return 0
    if not self.int_literal_fits_type(node, expected):
        self.emit_error("integer literal does not fit expected type", node)
    expected

fn Sema.float_literal_expected_type(self: Sema) -> i32:
    if self.has_expected_type == 0 or self.expected_expr_type == 0:
        return 0
    let expected = self.resolve_alias(self.expected_expr_type)
    if self.get_type_kind(expected) == TypeKind.TY_FLOAT:
        return expected as i32
    0

fn sema_node_is_numeric_literal(ast: AstPool, node: i32) -> bool:
    if node == 0:
        return false
    let kind = ast.kind(node)
    kind == NodeKind.NK_INT_LIT or kind == NodeKind.NK_FLOAT_LIT

fn Sema.is_option_pointer_type(self: Sema, tid: i32) -> i32:
    if tid <= 0:
        return 0
    let resolved = self.resolve_alias(tid)
    if self.get_type_kind(resolved) != TypeKind.TY_GENERIC_INST:
        return 0
    if self.get_type_d0(resolved) != self.syms.option:
        return 0
    if self.get_type_d2(resolved) <= 0:
        return 0
    let payload = self.get_generic_inst_arg(resolved, 0)
    let payload_resolved = self.resolve_alias(payload)
    if self.get_type_kind(payload_resolved) == TypeKind.TY_PTR:
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
    let ok_payloads = self.enum_variant_payload_types(tid, self.syms.ok)
    if ok_payloads.len() as i32 == 1:
        return ok_payloads.get(0)
    let some_payloads = self.enum_variant_payload_types(tid, self.syms.some)
    if some_payloads.len() as i32 == 1:
        return some_payloads.get(0)
    0

// substitute_type: walk a TypeId, replacing type parameters with concrete types.
// subst_syms/subst_tids/count define the mapping: subst_syms[i] → subst_tids[i].
// Returns the substituted TypeId, or the original if no substitution applies.
fn Sema.substitute_type(self: Sema, tid: i32, subst_syms: Vec[i32], subst_tids: Vec[i32], count: i32) -> i32:
    if tid <= 0 or count == 0:
        return tid
    let kind = self.get_type_kind(tid as TypeId)
    let d0 = self.get_type_d0(tid as TypeId)
    // Direct match: struct/enum/alias whose name matches a type param symbol
    if kind == TypeKind.TY_STRUCT or kind == TypeKind.TY_ENUM or kind == TypeKind.TY_ALIAS:
        for si in 0..count:
            if subst_syms.get(si as i64) == d0:
                return subst_tids.get(si as i64)
        return tid
    // TypeKind.TY_GENERIC_INST: substitute each type arg
    if kind == TypeKind.TY_GENERIC_INST:
        let gi_ac = self.get_type_d2(tid as TypeId)
        var changed = 0
        let sub_args: Vec[i32] = Vec.new()
        for ai in 0..gi_ac:
            let orig = self.get_generic_inst_arg(tid, ai)
            let subbed = self.substitute_type(orig, subst_syms, subst_tids, count)
            if subbed != orig: changed = 1
            sub_args.push(subbed)
        if changed == 0: return tid
        return self.ensure_generic_inst_type(d0, sub_args, gi_ac) as i32
    // TypeKind.TY_PTR / TypeKind.TY_REF: substitute pointee
    if kind == TypeKind.TY_PTR or kind == TypeKind.TY_REF:
        let pointee = d0
        let subbed = self.substitute_type(pointee, subst_syms, subst_tids, count)
        if subbed == pointee: return tid
        let d1 = self.get_type_d1(tid as TypeId)
        return self.ensure_exact_type(kind, subbed, d1, 0) as i32
    // TypeKind.TY_ARRAY: substitute element
    if kind == TypeKind.TY_ARRAY:
        let elem = d0
        let subbed = self.substitute_type(elem, subst_syms, subst_tids, count)
        if subbed == elem: return tid
        let size = self.get_type_d1(tid as TypeId)
        return self.ensure_exact_type(TypeKind.TY_ARRAY, subbed, size, 0) as i32
    // TypeKind.TY_SLICE: substitute element
    if kind == TypeKind.TY_SLICE:
        let elem = d0
        let subbed = self.substitute_type(elem, subst_syms, subst_tids, count)
        if subbed == elem: return tid
        return self.ensure_exact_type(TypeKind.TY_SLICE, subbed, 0, 0) as i32
    // TypeKind.TY_TUPLE: substitute each element
    if kind == TypeKind.TY_TUPLE:
        let te_start_orig = d0
        let elem_count = self.get_type_d1(tid as TypeId)
        var t_changed = 0
        let tuple_elems: Vec[i32] = Vec.new()
        for ei in 0..elem_count:
            let orig = self.type_extra.get((te_start_orig + ei) as i64)
            let subbed = self.substitute_type(orig, subst_syms, subst_tids, count)
            if subbed != orig: t_changed = 1
            tuple_elems.push(subbed)
        if t_changed == 0: return tid
        return self.ensure_tuple_type(tuple_elems, elem_count) as i32
    // All other kinds: return unchanged
    tid

fn Sema.get_type_kind(self: Sema, tid: TypeId) -> i32:
    if tid < 0 or tid >= self.type_kinds.len() as i32:
        return TypeKind.TY_ERR
    self.type_kinds.get(tid as i64)

fn Sema.get_type_name_for_lsp(self: Sema, tid: i32) -> str:
    if tid <= 0 or tid >= self.type_kinds.len() as i32:
        return ""
    let kind = self.type_kinds.get(tid as i64)
    if kind == TypeKind.TY_STR:
        return "str"
    if kind == TypeKind.TY_INT:
        return "i32"
    if kind == TypeKind.TY_FLOAT:
        return "f64"
    if kind == TypeKind.TY_BOOL:
        return "bool"
    if kind == TypeKind.TY_STRUCT or kind == TypeKind.TY_ENUM or kind == TypeKind.TY_ALIAS or kind == TypeKind.TY_GENERIC_INST:
        return self.pool_resolve(self.type_d0.get(tid as i64))
    ""

fn Sema.get_type_d0(self: Sema, tid: TypeId) -> i32:
    if tid < 0 or tid >= self.type_d0.len() as i32:
        return 0
    self.type_d0.get(tid as i64)

fn Sema.get_type_d1(self: Sema, tid: TypeId) -> i32:
    if tid < 0 or tid >= self.type_d1.len() as i32:
        return 0
    self.type_d1.get(tid as i64)

fn Sema.get_type_d2(self: Sema, tid: TypeId) -> i32:
    if tid < 0 or tid >= self.type_d2.len() as i32:
        return 0
    self.type_d2.get(tid as i64)

fn Sema.resolve_alias(self: Sema, tid: TypeId) -> TypeId:
    var current = tid
    for depth in 0..32:
        if self.get_type_kind(current) == TypeKind.TY_ALIAS:
            current = self.get_type_d0(current) as TypeId
        else:
            return current
    current

fn Sema.is_opaque_value_type(self: Sema, tid: i32) -> i32:
    if tid == 0:
        return 0
    let resolved = self.resolve_alias(tid)
    if self.get_type_kind(resolved) != TypeKind.TY_STRUCT:
        return 0
    let name_sym = self.get_type_d0(resolved)
    if name_sym == 0 or not self.type_decl_nodes.contains(name_sym):
        return 0
    let decl = self.type_decl_nodes.get(name_sym).unwrap()
    if self.ast.kind(decl) != NodeKind.NK_TYPE_DECL:
        return 0
    if type_decl_sub_kind(self.ast.get_data2(decl)) == TypeDeclKind.Opaque:
        return 1
    0

fn Sema.is_c_void_like_type(self: Sema, tid: i32) -> i32:
    if tid == 0:
        return 0
    let resolved = self.resolve_alias(tid as TypeId)
    if self.get_type_kind(resolved) == TypeKind.TY_VOID:
        return 1
    if self.get_type_kind(resolved) != TypeKind.TY_STRUCT:
        return 0
    let name_sym = self.get_type_d0(resolved)
    if name_sym != 0 and self.pool_resolve(name_sym) == "c_void":
        return 1
    0

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
    // Remove bindings from map and parallel arrays
    while self.bind_names.len() as i32 > start:
        let removed_sym = self.bind_names.get(self.bind_names.len() - 1)
        self.scope_name_map.remove(removed_sym)
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

fn Sema.scope_insert_at(self: Sema, sym: i32, tid: i32, is_mut: i32):
    let idx = self.bind_names.len() as i32
    self.bind_names.push(sym)
    self.bind_types.push(tid)
    self.bind_muts.push(is_mut)
    self.bind_states.push(VarState.LIVE)
    self.bind_is_task.push(0)
    self.bind_is_scoped_task.push(0)
    self.bind_is_ephemeral_task.push(0)
    self.scope_name_map.insert(sym, idx)

fn Sema.scope_put_at(self: Sema, sym: i32, tid: i32, is_mut: i32, node: i32):
    if self.is_discard_binding_symbol(sym) != 0:
        return
    if self.scope_lookup(sym) >= 0:
        let name = self.pool_resolve(sym)
        self.emit_error("shadowing is not allowed for '" ++ name ++ "'", node)
        return
    self.scope_insert_at(sym, tid, is_mut)

fn Sema.global_value_decl_kind(self: Sema, sym: i32) -> i32:
    let opt = self.global_value_decl_kinds.get(sym)
    if opt.is_some():
        return opt.unwrap()
    0

fn Sema.global_value_decl_types_compatible(self: Sema, existing_tid: i32, new_tid: i32) -> i32:
    if existing_tid == 0 or new_tid == 0:
        return 1
    let existing_resolved = self.resolve_alias(existing_tid as TypeId) as i32
    let new_resolved = self.resolve_alias(new_tid as TypeId) as i32
    if existing_resolved != 0 and existing_resolved == new_resolved:
        return 1
    0

fn Sema.register_top_level_global_decl(self: Sema, sym: i32, tid: i32, is_mut: i32, node: i32, decl_kind: i32):
    if self.is_discard_binding_symbol(sym) != 0:
        return
    let existing_opt = self.scope_name_map.get(sym)
    if not existing_opt.is_some():
        self.scope_insert_at(sym, tid, is_mut)
        self.global_value_decl_kinds.insert(sym, decl_kind)
        return

    let existing_idx = existing_opt.unwrap()
    let existing_kind = self.global_value_decl_kind(sym)
    if existing_kind == 0:
        let name = self.pool_resolve(sym)
        self.emit_error("shadowing is not allowed for '" ++ name ++ "'", node)
        return

    if existing_kind == GLOBAL_VALUE_DECL_DEF and decl_kind == GLOBAL_VALUE_DECL_DEF:
        let name = self.pool_resolve(sym)
        self.emit_error("shadowing is not allowed for '" ++ name ++ "'", node)
        return

    let existing_mut = self.bind_muts.get(existing_idx as i64)
    if existing_mut != is_mut:
        let name = self.pool_resolve(sym)
        self.emit_error("conflicting global declaration for '" ++ name ++ "'", node)
        return

    let existing_tid = self.bind_types.get(existing_idx as i64)
    if self.global_value_decl_types_compatible(existing_tid, tid) == 0:
        let name = self.pool_resolve(sym)
        self.emit_error("conflicting global declaration for '" ++ name ++ "'", node)
        return

    if existing_tid == 0 and tid != 0:
        self.bind_types.set_i32(existing_idx as i64, tid)

    if existing_kind == GLOBAL_VALUE_DECL_EXTERN and decl_kind == GLOBAL_VALUE_DECL_DEF:
        self.global_value_decl_kinds.insert(sym, GLOBAL_VALUE_DECL_DEF)

fn Sema.scope_lookup(self: Sema, sym: i32) -> i32:
    let opt = self.scope_name_map.get(sym)
    if opt.is_some():
        return self.bind_types.get(opt.unwrap() as i64)
    0 - 1

fn Sema.scope_lookup_mut(self: Sema, sym: i32) -> i32:
    let opt = self.scope_name_map.get(sym)
    if opt.is_some():
        return self.bind_muts.get(opt.unwrap() as i64)
    0

fn Sema.scope_lookup_state(self: Sema, sym: i32) -> i32:
    let opt = self.scope_name_map.get(sym)
    if opt.is_some():
        return self.bind_states.get(opt.unwrap() as i64)
    VarState.LIVE

fn Sema.scope_lookup_is_task(self: Sema, sym: i32) -> i32:
    let opt = self.scope_name_map.get(sym)
    if opt.is_some():
        return self.bind_is_task.get(opt.unwrap() as i64)
    0

fn Sema.scope_set_is_task(self: Sema, sym: i32, is_task: i32):
    let opt = self.scope_name_map.get(sym)
    if opt.is_some():
        self.bind_is_task.set_i32(opt.unwrap() as i64, is_task)

fn Sema.scope_lookup_is_scoped_task(self: Sema, sym: i32) -> i32:
    let opt = self.scope_name_map.get(sym)
    if opt.is_some():
        return self.bind_is_scoped_task.get(opt.unwrap() as i64)
    0

fn Sema.scope_set_is_scoped_task(self: Sema, sym: i32, is_scoped_task: i32):
    let opt = self.scope_name_map.get(sym)
    if opt.is_some():
        self.bind_is_scoped_task.set_i32(opt.unwrap() as i64, is_scoped_task)

fn Sema.scope_lookup_is_ephemeral_task(self: Sema, sym: i32) -> i32:
    let opt = self.scope_name_map.get(sym)
    if opt.is_some():
        return self.bind_is_ephemeral_task.get(opt.unwrap() as i64)
    0

fn Sema.scope_set_is_ephemeral_task(self: Sema, sym: i32, is_ephemeral_task: i32):
    let opt = self.scope_name_map.get(sym)
    if opt.is_some():
        self.bind_is_ephemeral_task.set_i32(opt.unwrap() as i64, is_ephemeral_task)

fn Sema.scope_set_state(self: Sema, sym: i32, state: i32):
    let opt = self.scope_name_map.get(sym)
    if opt.is_some():
        self.bind_states.set_i32(opt.unwrap() as i64, state)

fn Sema.scope_has(self: Sema, sym: i32) -> i32:
    if self.scope_name_map.contains(sym): return 1
    0

fn Sema.is_mutable_global(self: Sema, sym: i32) -> i32:
    if self.mutable_global_syms.contains(sym): return 1
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
    self.prepare_for_comptime_transform()
    self.check_top_level_comptime_let_values()
    self.check_bodies()

fn Sema.prepare_for_comptime_transform(self: Sema):
    self.compute_method_origins()
    self.collect_declarations()
    self.build_ci_scoping()
    self.build_ci_destructor_map()
    self.validate_copy_derives()
    self.validate_generic_type_decls()

// ── Utility functions ────────────────────────────────────────────

fn sema_str_has_data(text: str) -> i32:
    if text.len() <= 0:
        return 0
    let ptr_ptr = &text as *const *const u8
    if ptr_ptr as i64 == 0:
        return 0
    let data_ptr = *ptr_ptr
    if data_ptr as i64 == 0:
        return 0
    1

fn sema_str_contains_char(text: str, needle: i32) -> i32:
    if sema_str_has_data(text) == 0:
        return 0
    var i = 0
    while i < text.len() as i32:
        if text.byte_at(i as i64) == needle:
            return 1
        i = i + 1
    0

// ── "Did you mean?" suggestions ─────────────────────────────────

fn sema_levenshtein(a: str, b: str, max: i32) -> i32:
    let al = a.len() as i32
    let bl = b.len() as i32
    if al == 0: return bl
    if bl == 0: return al
    let diff = if al > bl: al - bl else: bl - al
    if diff > max: return max + 1
    // Single-row DP with early exit
    var prev: Vec[i32] = Vec.new()
    for j in 0..bl + 1:
        prev.push(j)
    for i in 1..al + 1:
        var row_min = max + 1
        var cur: Vec[i32] = Vec.new()
        cur.push(i)
        for j in 1..bl + 1:
            let cost = if a[(i - 1) as i64] == b[(j - 1) as i64]: 0 else: 1
            let del = prev.get(j as i64) + 1
            let ins = cur.get((j - 1) as i64) + 1
            let sub = prev.get((j - 1) as i64) + cost
            var best = del
            if ins < best: best = ins
            if sub < best: best = sub
            cur.push(best)
            if best < row_min: row_min = best
        prev = cur
        if row_min > max: return max + 1
    prev.get(bl as i64)

fn Sema.suggest_name(self: Sema, target: str, node: i32) -> str:
    if target.len() == 0: return ""
    let max_dist = if target.len() as i32 <= 3: 1 else: 2
    var best_name = ""
    var best_dist = max_dist + 1
    // Search scope bindings
    for idx in 0..self.bind_names.len():
        let sym = self.bind_names.get(idx)
        let name = self.pool_resolve(sym)
        if name.len() > 0:
            let d = sema_levenshtein(target, name, max_dist)
            if d < best_dist:
                best_dist = d
                best_name = name
    // Search function signatures
    for si in 0..self.sig_names.len():
        let sym = self.sig_names.get(si)
        if self.is_ci_visible(sym) != 0:
            let name = self.pool_resolve(sym)
            if name.len() > 0:
                let d = sema_levenshtein(target, name, max_dist)
                if d < best_dist:
                    best_dist = d
                    best_name = name
    best_name

fn Sema.suggest_type_name(self: Sema, target: str, node: i32) -> str:
    if target.len() == 0 or sema_str_has_data(target) == 0:
        return ""
    let max_dist = if target.len() as i32 <= 3: 1 else: 2
    var best_name = ""
    var best_dist = max_dist + 1
    // Search named types by scanning type table
    for ti in 1..self.type_kinds.len():
        let tk = self.type_kinds.get(ti)
        if tk == TypeKind.TY_STRUCT as i32 or tk == TypeKind.TY_ENUM as i32:
            let sym = self.type_d0.get(ti)
            if sym > 0 and sym < self.pool.state.symbol_texts.len() as i32:
                let name = self.pool_resolve(sym)
                if sema_str_has_data(name) != 0 and not sema_str_contains_char(name, 46) != 0:
                    let d = sema_levenshtein(target, name, max_dist)
                    if d < best_dist:
                        best_dist = d
                        best_name = name
    best_name

fn Sema.emit_error_with_suggestion(self: Sema, msg: str, node: i32, suggestion: str):
    if self.suppress_errors != 0:
        return
    let start = self.ast.get_start(node)
    let end = self.ast.get_end(node)
    let diag = Diagnostic.err(msg, Span { file: self.local_file_id, start: start, end: end })
    if suggestion.len() > 0:
        diag.add_help("did you mean '" ++ suggestion ++ "'?")
    self.diags.emit(diag)

// ── Type compatibility ───────────────────────────────────────────

fn Sema.types_compatible_fast(self: Sema, expected: TypeId, actual: TypeId) -> i32:
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

    if act_k == TypeKind.TY_NEVER:
        return 1
    if exp_k == TypeKind.TY_BOOL and act_k == TypeKind.TY_BOOL:
        return 1
    if exp_k == TypeKind.TY_VOID and act_k == TypeKind.TY_VOID:
        return 1
    if exp_k == TypeKind.TY_STR and act_k == TypeKind.TY_STR:
        return 1
    if exp_k == TypeKind.TY_INT and act_k == TypeKind.TY_INT:
        return 1
    if exp_k == TypeKind.TY_INT and act_k == TypeKind.TY_ENUM:
        let act_repr = self.enum_repr_type(act_r)
        if act_repr != 0:
            return self.types_compatible_fast(expected, act_repr)
    if exp_k == TypeKind.TY_FLOAT and act_k == TypeKind.TY_FLOAT:
        return 1
    if exp_k == TypeKind.TY_FLOAT and act_k == TypeKind.TY_INT:
        return 1
    if exp_k == TypeKind.TY_INT and act_k == TypeKind.TY_FLOAT:
        return 1
    if (exp_k == TypeKind.TY_PTR or exp_k == TypeKind.TY_REF) and act_k == TypeKind.TY_STR:
        return 1
    if exp_k == TypeKind.TY_STR and (act_k == TypeKind.TY_PTR or act_k == TypeKind.TY_REF):
        return 1
    if exp_k == TypeKind.TY_FN and act_k == TypeKind.TY_FN:
        return 1
    if (exp_k == TypeKind.TY_PTR or exp_k == TypeKind.TY_REF) and act_k == TypeKind.TY_FN:
        return 1
    if exp_k == TypeKind.TY_FN and (act_k == TypeKind.TY_PTR or act_k == TypeKind.TY_REF):
        return 1
    if self.is_option_pointer_type(exp_r) != 0 and (act_k == TypeKind.TY_PTR or act_k == TypeKind.TY_REF or act_k == TypeKind.TY_FN):
        let opt_payload = self.option_pointer_payload_type(exp_r)
        if opt_payload != 0:
            return self.types_compatible_fast(opt_payload, actual)
    if exp_k == TypeKind.TY_STRUCT and act_k == TypeKind.TY_STRUCT:
        return if self.get_type_d0(exp_r) == self.get_type_d0(act_r): 1 else: 0
    if exp_k == TypeKind.TY_ENUM and act_k == TypeKind.TY_ENUM:
        return if self.get_type_d0(exp_r) == self.get_type_d0(act_r): 1 else: 0
    // TypeKind.TY_GENERIC_INST: compatible if same base and all args compatible
    if exp_k == TypeKind.TY_GENERIC_INST and act_k == TypeKind.TY_GENERIC_INST:
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
    // TypeKind.TY_GENERIC_INST is compatible with its base struct type (for codegen interop)
    if exp_k == TypeKind.TY_GENERIC_INST and act_k == TypeKind.TY_STRUCT:
        return if self.get_type_d0(exp_r) == self.get_type_d0(act_r): 1 else: 0
    if exp_k == TypeKind.TY_STRUCT and act_k == TypeKind.TY_GENERIC_INST:
        return if self.get_type_d0(exp_r) == self.get_type_d0(act_r): 1 else: 0
    if exp_k == TypeKind.TY_GENERIC_INST and act_k == TypeKind.TY_ENUM:
        return if self.get_type_d0(exp_r) == self.get_type_d0(act_r): 1 else: 0
    if exp_k == TypeKind.TY_ENUM and act_k == TypeKind.TY_GENERIC_INST:
        return if self.get_type_d0(exp_r) == self.get_type_d0(act_r): 1 else: 0
    0

fn Sema.types_compatible(self: Sema, expected: TypeId, actual: TypeId) -> i32:
    if self.types_compatible_fast(expected, actual) != 0:
        return 1

    let exp_r = self.resolve_alias(expected)
    let act_r = self.resolve_alias(actual)
    let exp_k = self.get_type_kind(exp_r)
    let act_k = self.get_type_kind(act_r)

    if self.is_option_pointer_type(exp_r) != 0 and (act_k == TypeKind.TY_PTR or act_k == TypeKind.TY_REF or act_k == TypeKind.TY_FN):
        let opt_payload = self.option_pointer_payload_type(exp_r)
        if opt_payload != 0:
            return self.types_compatible(opt_payload, actual)

    // Structural compatibility for non-interned compound types.
    if exp_k == TypeKind.TY_PTR and act_k == TypeKind.TY_PTR:
        let exp_mut = self.get_type_d1(exp_r)
        let act_mut = self.get_type_d1(act_r)
        if exp_mut != 0 and act_mut == 0:
            return 0
        if self.is_c_void_like_type(self.get_type_d0(exp_r)) != 0 or self.is_c_void_like_type(self.get_type_d0(act_r)) != 0:
            return 1
        return self.types_compatible(self.get_type_d0(exp_r), self.get_type_d0(act_r))
    if exp_k == TypeKind.TY_PTR and act_k == TypeKind.TY_REF:
        let exp_mut = self.get_type_d1(exp_r)
        let act_mut = self.get_type_d1(act_r)
        if exp_mut != 0 and act_mut == 0:
            return 0
        if self.is_c_void_like_type(self.get_type_d0(exp_r)) != 0 or self.is_c_void_like_type(self.get_type_d0(act_r)) != 0:
            return 1
        return self.types_compatible(self.get_type_d0(exp_r), self.get_type_d0(act_r))
    if exp_k == TypeKind.TY_REF and act_k == TypeKind.TY_REF:
        let exp_mut = self.get_type_d1(exp_r)
        let act_mut = self.get_type_d1(act_r)
        if exp_mut != 0 and act_mut == 0:
            return 0
        if self.is_c_void_like_type(self.get_type_d0(exp_r)) != 0 or self.is_c_void_like_type(self.get_type_d0(act_r)) != 0:
            return 1
        return self.types_compatible(self.get_type_d0(exp_r), self.get_type_d0(act_r))
    if exp_k == TypeKind.TY_REF and act_k == TypeKind.TY_PTR:
        let exp_mut = self.get_type_d1(exp_r)
        let act_mut = self.get_type_d1(act_r)
        if exp_mut != 0 and act_mut == 0:
            return 0
        if self.is_c_void_like_type(self.get_type_d0(exp_r)) != 0 or self.is_c_void_like_type(self.get_type_d0(act_r)) != 0:
            return 1
        return self.types_compatible(self.get_type_d0(exp_r), self.get_type_d0(act_r))
    if exp_k == TypeKind.TY_SLICE and act_k == TypeKind.TY_SLICE:
        return self.types_compatible(self.get_type_d0(exp_r), self.get_type_d0(act_r))
    if exp_k == TypeKind.TY_ARRAY and act_k == TypeKind.TY_ARRAY:
        if self.get_type_d1(exp_r) != self.get_type_d1(act_r):
            return 0
        return self.types_compatible(self.get_type_d0(exp_r), self.get_type_d0(act_r))
    if exp_k == TypeKind.TY_TUPLE and act_k == TypeKind.TY_TUPLE:
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

    // TypeKind.TY_GENERIC_INST structural comparison (different TypeIds, same structure)
    if exp_k == TypeKind.TY_GENERIC_INST and act_k == TypeKind.TY_GENERIC_INST:
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
    // TypeKind.TY_GENERIC_INST ↔ base struct/enum (interop with codegen's erased types)
    if exp_k == TypeKind.TY_GENERIC_INST and (act_k == TypeKind.TY_STRUCT or act_k == TypeKind.TY_ENUM):
        if self.get_type_d0(exp_r) == self.get_type_d0(act_r):
            return 1
    if (exp_k == TypeKind.TY_STRUCT or exp_k == TypeKind.TY_ENUM) and act_k == TypeKind.TY_GENERIC_INST:
        if self.get_type_d0(exp_r) == self.get_type_d0(act_r):
            return 1

    // Auto-referencing: T → &T
    if exp_k == TypeKind.TY_REF:
        if self.get_type_d1(exp_r) == 0:
            if self.types_compatible(self.get_type_d0(exp_r), act_r):
                return 1
    0

fn Sema.arithmetic_result_type(self: Sema, lhs: TypeId, rhs: TypeId) -> TypeId:
    if lhs == 0:
        return rhs
    if rhs == 0:
        return lhs
    let lhs_numeric = self.numeric_operand_type(lhs as i32)
    let rhs_numeric = self.numeric_operand_type(rhs as i32)
    let lk = self.get_type_kind(self.resolve_alias(lhs_numeric as TypeId))
    let rk = self.get_type_kind(self.resolve_alias(rhs_numeric as TypeId))
    if lk == TypeKind.TY_NEVER:
        if rhs_numeric != 0:
            return rhs_numeric as TypeId
        return rhs
    if rk == TypeKind.TY_NEVER:
        if lhs_numeric != 0:
            return lhs_numeric as TypeId
        return lhs
    // Float wins over int
    if lk == TypeKind.TY_FLOAT and rk == TypeKind.TY_FLOAT:
        let lb = self.get_type_d0(self.resolve_alias(lhs_numeric as TypeId))
        let rb = self.get_type_d0(self.resolve_alias(rhs_numeric as TypeId))
        if lb >= rb:
            return lhs_numeric as TypeId
        return rhs_numeric as TypeId
    if lk == TypeKind.TY_FLOAT:
        return lhs_numeric as TypeId
    if rk == TypeKind.TY_FLOAT:
        return rhs_numeric as TypeId
    // Wider int wins
    if lk == TypeKind.TY_INT and rk == TypeKind.TY_INT:
        let lb = self.get_type_d0(self.resolve_alias(lhs_numeric as TypeId))
        let rb = self.get_type_d0(self.resolve_alias(rhs_numeric as TypeId))
        if lb >= rb:
            return lhs_numeric as TypeId
        return rhs_numeric as TypeId
    0 as TypeId

fn Sema.is_copy(self: Sema, tid: TypeId) -> i32:
    if tid == 0:
        return 1
    let resolved = self.resolve_alias(tid)
    let tk = self.get_type_kind(resolved)
    if tk == TypeKind.TY_ERR or tk == TypeKind.TY_INT or tk == TypeKind.TY_FLOAT or tk == TypeKind.TY_BOOL or tk == TypeKind.TY_VOID or tk == TypeKind.TY_NEVER or tk == TypeKind.TY_STR:
        return 1
    if tk == TypeKind.TY_PTR or tk == TypeKind.TY_REF or tk == TypeKind.TY_FN or tk == TypeKind.TY_GENERIC_FN:
        return 1
    if tk == TypeKind.TY_STRUCT or tk == TypeKind.TY_ARRAY or tk == TypeKind.TY_TUPLE or tk == TypeKind.TY_RANGE:
        // Break copy-check recursion on cyclic type graphs.
        for vi in 0..self.copy_visit_stack.len() as i32:
            if self.copy_visit_stack.get(vi as i64) == resolved as i32:
                return 0
        self.copy_visit_stack.push(resolved as i32)

        var out = 1
        if tk == TypeKind.TY_STRUCT:
            let name = self.get_type_d0(resolved)
            if self.has_drop_method(name):
                if sema_debug_move_enabled() != 0:
                    with_eprint("[noncopy] type=" ++ self.pool_resolve(name) ++ " reason=drop")
                out = 0
            else:
                let struct_te_start = self.get_type_d1(resolved)
                let struct_field_count = self.get_type_d2(resolved)
                for fi in 0..struct_field_count:
                    let ft = self.type_extra.get((struct_te_start + fi * 3 + 1) as i64)
                    if self.is_copy(ft) == 0:
                        if sema_debug_move_enabled() != 0:
                            let field_name = self.type_extra.get((struct_te_start + fi * 3) as i64)
                            with_eprint(
                                "[noncopy] type=" ++ self.pool_resolve(name) ++
                                " field=" ++ self.pool_resolve(field_name) ++
                                " field_ty=" ++ self.type_name(ft)
                            )
                        out = 0
                        break
        else if tk == TypeKind.TY_ARRAY:
            out = self.is_copy(self.get_type_d0(resolved))
        else if tk == TypeKind.TY_TUPLE:
            let tuple_te_start = self.get_type_d0(resolved)
            let tuple_elem_count = self.get_type_d1(resolved)
            for ei in 0..tuple_elem_count:
                if self.is_copy(self.type_extra.get((tuple_te_start + ei) as i64)) == 0:
                    out = 0
                    break
        else: // TypeKind.TY_RANGE
            out = self.is_copy(self.get_type_d0(resolved))

        self.copy_visit_stack.pop()
        return out
    if tk == TypeKind.TY_ENUM:
        return 1
    if tk == TypeKind.TY_SLICE:
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
