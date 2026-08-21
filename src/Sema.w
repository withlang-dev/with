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
use Overflow
use compiler.TrackedInputs
use std.collections.HashMap
use std.collections.HashSet

extern fn with_write(s: &str) -> Unit
extern fn with_eprint(s: &str) -> Unit
extern fn with_getenv_str(name: &str) -> str
extern fn with_str_clone_ref(s: &str) -> str
extern fn i64_to_string(n: i64) -> str
extern fn abort() -> Unit

fn sema_phase_bug(message: &str, origin_file: &str = __FILE__, origin_line: u32 = __LINE__, origin_fn: &str = __FN__):
    with_eprint(f"{message} [{origin_file}:{origin_line} {origin_fn}]")
    abort()

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
    TY_EXTERN_FN = 20

type TypeId = i32

type SemaSourceLocation {
    line: i32,
    col: i32,
}
impl Copy for SemaSourceLocation

enum VarState: i32:
    LIVE = 0
    MOVED = 1

type BindingProvenance {
    view_origin_mask: i32,
    view_dep_start: i32,
    view_dep_count: i32,
    effect_dep_sym: i32,
    is_ephemeral_value: i32,
    is_ephemeral_task: i32,
    is_non_send_task: i32,
    poisoned_origin_sym: i32,
    poisoned_origin_node: i32,
    poisoned_binding_node: i32,
}
impl Copy for BindingProvenance

fn binding_provenance_empty -> BindingProvenance:
    BindingProvenance { view_origin_mask: 0, view_dep_start: 0, view_dep_count: 0, effect_dep_sym: 0, is_ephemeral_value: 0, is_ephemeral_task: 0, is_non_send_task: 0, poisoned_origin_sym: 0, poisoned_origin_node: 0, poisoned_binding_node: 0 }

fn sema_param_origin_bit(pi: i32) -> i32:
    if pi < 0:
        return 0
    if pi >= 31:
        return -1
    ((1 as i64) << (pi as u32)) as i32

fn sema_param_origin_mask_contains(mask: i32, pi: i32) -> i32:
    if mask == 0 or pi < 0:
        return 0
    if mask < 0:
        return 1
    if pi >= 31:
        return 0
    if (mask & sema_param_origin_bit(pi)) != 0: 1 else: 0

enum BorrowKind: i32:
    SHARED = 0
    EXCLUSIVE = 1

enum LabelFrameKind: i32:
    LFK_BOUNDARY = 0
    LFK_WHILE = 1
    LFK_FOR = 2
    LFK_BLOCK = 3
    LFK_LOOP = 4

type LabelRegistryState {
    label_syms: Vec[i32],
    label_nodes: Vec[i32],
    label_paths: Vec[str],
    label_orders: Vec[i32],
    label_used: Vec[i32],
    goto_syms: Vec[i32],
    goto_nodes: Vec[i32],
    goto_paths: Vec[str],
    goto_orders: Vec[i32],
    init_nodes: Vec[i32],
    init_paths: Vec[str],
    init_orders: Vec[i32],
    scope_stack: Vec[i32],
    next_scope_id: i32,
    order_counter: i32,
}

enum DeriveReq: i32:
    COPY = 0
    CLONE = 1
    DEFAULT = 2
    EQ = 3
    HASH = 4
    ORD = 5
    DEBUG = 6
    DISPLAY = 7
    BUILDER = 8

enum SemaMagicIdentKind: i32:
    NONE = 0
    FILE = 1
    LINE = 2
    FN = 3

// #695: a clone of the moved_field_* parallel arrays, for branch-merge of the
// partial-move set (see save/restore/union in the checker).
type MovedFieldSnap {
    base: Vec[i32],
    starts: Vec[i32],
    counts: Vec[i32],
    syms: Vec[i32],
}

type SemaBuiltinSymbols {
    task: i32,
    scoped_task: i32,
    scoped_join_handle: i32,
    channel: i32,
    send: i32,
    recv: i32,
    close: i32,
    cancel: i32,
    join_cleanup: i32,
    is_done: i32,
    was_cancelled: i32,
    todo: i32,
    unreachable: i32,
    track: i32,
    spawn_method: i32,
    src: i32,
    file_magic: i32,
    line_magic: i32,
    fn_magic: i32,
    embed_file: i32,
    copy_trait: i32,
    clone_trait: i32,
    send_trait: i32,
    sync_trait: i32,
    scoped_send_trait: i32,
    deref_trait: i32,
    deref_method: i32,
    drop: i32,
    self_type: i32,
    vec: i32,
    fixed_string: i32,
    veciter: i32,
    mapiter: i32,
    filteriter: i32,
    filtermapiter: i32,
    takeiter: i32,
    dropiter: i32,
    takewhileiter: i32,
    dropwhileiter: i32,
    zipiter: i32,
    enumerateiter: i32,
    chainiter: i32,
    zipwithiter: i32,
    stepbyiter: i32,
    flatmapiter: i32,
    vecslot: i32,
    veciterplace: i32,
    vecrange: i32,
    veciterref: i32,
    range_type: i32,
    range_inclusive_type: i32,
    iter_place: i32,
    iter_ref: i32,
    range_method: i32,
    split_at: i32,
    split_at_mut: i32,
    hashmapentry: i32,
    entry: i32,
    or_insert: i32,
    option: i32,
    result: i32,
    context_error: i32,
    hashmap: i32,
    hashset: i32,
    btreemap: i32,
    btreeset: i32,
    handle: i32,
    slotmap: i32,
    slotmapslot: i32,
    box: i32,
    regex: i32,
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
    slot: i32,
    get_disjoint: i32,
    filter: i32,
    filter_map: i32,
    map: i32,
    fold: i32,
    collect: i32,
    reduce: i32,
    take: i32,
    take_while: i32,
    drop_items: i32,
    drop_while: i32,
    zip: i32,
    zip_with: i32,
    enumerate: i32,
    chain: i32,
    step_by: i32,
    flat_map: i32,
    sum: i32,
    product: i32,
    min: i32,
    max: i32,
    min_by: i32,
    max_by: i32,
    find: i32,
    position: i32,
    any: i32,
    all: i32,
    none_pred: i32,
    for_each: i32,
    unzip: i32,
    count: i32,
    partition: i32,
    sequence: i32,
    traverse: i32,
    transpose: i32,
    clear: i32,
    pop: i32,
    set_i32: i32,
    keys: i32,
    values: i32,
    items: i32,
    next: i32,
    unwrap: i32,
    expect: i32,
    is_some: i32,
    is_none: i32,
    is_ok: i32,
    is_err: i32,
    starts_with: i32,
    ends_with: i32,
    trim: i32,
    to_lower: i32,
    to_upper: i32,
    lower: i32,
    upper: i32,
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

// docs/mutability.md §5 — per-parameter effect bits.
const EFF_READ: i32         = 1   // parameter is read
const EFF_WRITE: i32        = 2   // parameter place is mutated (implies read)
const EFF_CONSUME: i32      = 4   // parameter is moved/consumed in the body
const EFF_ESCAPE_VALUE: i32 = 8   // owned value escapes the call (return / global store)
const EFF_ESCAPE_VIEW: i32  = 16  // view into parameter escapes (return &param.field)
const EFF_RAW_PTR_VALIDITY: i32 = 32  // raw pointer parameter validity is caller-guaranteed
const EFF_DECLARED_MASK: i32 = EFF_READ | EFF_WRITE | EFF_CONSUME | EFF_ESCAPE_VALUE | EFF_ESCAPE_VIEW

enum ReceiverMode: i32:
    None = 0
    Read = 1
    Mut = 2
    Move = 3
    Missing = 4

impl Copy for ReceiverMode

enum WithFormKind: i32:
    Binding = 0
    Guarded = 1
    GuardedMut = 2

enum AllocConstructKind: i32:
    EXPLICIT_API = 1
    VEC_NEW = 2
    TO_OWNED = 3
    OWNED_LITERAL = 4
    FSTRING = 5
    COMPREHENSION = 6
    ASYNC_FIBER = 7
    FFI_TEMPORARY = 8
    CALLEE = 9

impl Copy for AllocConstructKind

fn sema_effect_bits_text(bits: i32) -> str:
    let public_bits = bits & EFF_DECLARED_MASK
    var out = ""
    if (public_bits & EFF_READ) != 0:
        out = "read"
    if (public_bits & EFF_WRITE) != 0:
        if out.len() > 0: out = out ++ ", "
        out = out ++ "write"
    if (public_bits & EFF_CONSUME) != 0:
        if out.len() > 0: out = out ++ ", "
        out = out ++ "consume"
    if (public_bits & EFF_ESCAPE_VALUE) != 0:
        if out.len() > 0: out = out ++ ", "
        out = out ++ "escape_value"
    if (public_bits & EFF_ESCAPE_VIEW) != 0:
        if out.len() > 0: out = out ++ ", "
        out = out ++ "escape_view"
    if out.len() == 0:
        return "none"
    out

// ── Sema state ───────────────────────────────────────────────────

// D22 Stage 2: one semantic record for a shared-reference expression that an
// independently resolved owned context will materialize. `exact_source_type`
// remains &T. `owned_value_type` is T, and `target_type` is the destination
// after any ordinary value coercion. A differing `post_copy_type` records that
// final coercion explicitly for later MIR/backend consumption.
type ContextualCopyAdjustment {
    context_sig: i32,
    source_node: i32,
    exact_source_type: i32,
    owned_value_type: i32,
    target_type: i32,
    post_copy_type: i32,
}

impl Copy for ContextualCopyAdjustment

// D22 Stage 3: one order-independent semantic decision for a multi-expression
// join. Arm details live in the parallel contextual_join_arm_* vectors so MIR
// and diagnostics consume the same classification instead of re-running type
// inference. `origin_mask`/origin deps record the origins visible at this
// stage; Stage 4 makes transparent-carrier propagation complete.
type ContextualJoinDecision {
    context_sig: i32,
    join_node: i32,
    expected_type: i32,
    final_type: i32,
    arm_start: i32,
    arm_count: i32,
    expected_is_anchor: i32,
    owned_anchor_count: i32,
    materialized_count: i32,
    view_count: i32,
    diverging_count: i32,
    origin_mask: i32,
    origin_start: i32,
    origin_count: i32,
}

impl Copy for ContextualJoinDecision

type Sema {
    pool: InternPool,
    diags: DiagnosticList,
    ast: AstPool,
    // Reverse index for the AST declaration table. The first declaration for
    // a node wins, matching find_decl_index's original forward scan.
    decl_index_by_node: HashMap[i32, i32],

    // Type table (SoA parallel arrays)
    type_kinds: Vec[i32],
    type_d0: Vec[i32],
    type_d1: Vec[i32],
    type_d2: Vec[i32],
    type_extra: Vec[i32],
    // Exact structural type lookup. Hash buckets point into a collision chain
    // indexed by TypeId; component checks keep hash collisions harmless.
    exact_type_cache_heads: HashMap[i64, i32],
    exact_type_cache_next: Vec[i32],

    // Named type lookup: sym → TypeId
    named_types: HashMap[i32, i32],
    // Type declaration AST nodes: sym → node (for cycle diagnostics)
    type_decl_nodes: HashMap[i32, i32],
    // #650: memoized trait_sym -> decl node (find_trait_decl_node was a
    // linear scan over every decl per call; hot in whole-compiler sema).
    trait_decl_node_cache: HashMap[i32, i32],
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
    // docs/mutability.md Phase 4 — per-parameter effect bitsets.
    // sig_param_effects[sig_param_eff_starts[si] + pi] = effect bits for param pi of sig si.
    // Effects: EFF_READ=1, EFF_WRITE=2, EFF_CONSUME=4,
    // EFF_ESCAPE_VALUE=8, EFF_ESCAPE_VIEW=16, EFF_RAW_PTR_VALIDITY=32.
    sig_param_effects: Vec[i32],
    // Snapshot of sig_param_effects before call-edge fixed-point propagation.
    // Used only by receiver-effect provenance/debugging.
    sig_param_direct_effects: Vec[i32],
    // Parallel to sig_param_effects: bitmask of signature parameter indices that a returned
    // view may originate from when this parameter participates in escape_view.
    sig_param_view_origins: Vec[i32],
    sig_param_eff_starts: Vec[i32],
    // Parallel signature metadata for value parameters lowered through pointer ABI.
    // This is distinct from semantic reference types: `self: &Self` is already a
    // pointer value, while `mut self: Self` / value owner params are With values
    // whose native ABI passes an address.
    sig_value_ref_abi_params: Vec[i32],
    // Tool Gap #2 — production method-resolution trace, one row per checked
    // method call: which owner/method was looked up, whether the inherent
    // registry hit, how many extension candidates existed and were visible,
    // and the selected signature/function. `with analyze` renders these as
    // kind=method-resolution facts; nothing downstream re-derives lookup.
    mres_nodes: Vec[i32],
    mres_recv_types: Vec[i32],
    mres_owner_syms: Vec[i32],
    mres_method_syms: Vec[i32],
    mres_sigs: Vec[i32],
    mres_fn_syms: Vec[i32],
    mres_flags: Vec[i32],
    mres_cands_total: Vec[i32],
    mres_cands_visible: Vec[i32],
    // D7 receiver contracts are stored separately from ABI effects. The mode is
    // declaration syntax; required effects are derived from the checked body and
    // completed call graph. This keeps migration analysis from changing ABI policy.
    sig_receiver_modes: Vec[i32],
    sig_receiver_required_effects: Vec[i32],

    // #D5 share-place foundation (P0): effect-flow edges discovered during body
    // checking, flattened as 4-tuples [caller_sig, caller_pi, callee_sig,
    // callee_pi] — "caller param `caller_pi` is passed as the argument to callee
    // param `callee_pi`." `effect_flow_projections` records whether that argument
    // is a field/index projection rather than the root place itself. After all
    // bodies are checked, `fixpoint_effect_flow`
    // propagates write/consume/escape effects backward along these edges to a fixpoint,
    // so every sig_param_effects entry is COMPLETE (transitively, across forward
    // references and mutual recursion) before any call-site share-place decision
    // reads it. Single-pass inference alone under-detects forward-ref escapes;
    // under share-place that would double-free (caller keeps ownership of a
    // param the callee actually escapes/consumes). See decisions.md D5.
    effect_flow_edges: Vec[i32],
    effect_flow_projections: Vec[i32],

    // #D5/P1 share-place: recorded plain (non-move/copy) non-Copy value arguments,
    // flattened as 3-tuples [arg_node, callee_sig, callee_pi]. A plain argument is
    // share-place (the caller keeps ownership); after effects finalize,
    // `finalize_call_site_ownership` errors on any whose param is OWNED
    // (consume/escape_value → not value_ref_abi), requiring an explicit
    // `move`/`copy`. Recorded in pass 1, resolved post-fixpoint so the ownership
    // verdict uses COMPLETE effects (a forward-ref owned param must not slip
    // through as share-place — that would be a double-free).
    // Stride-8 records: [arg_node, callee_sig, callee_pi, file_id, root_sym,
    // use_seq, loop_depth, liveness] — liveness stamped at body end (0=unknown,
    // 1=last-use, 2=live-after); backs the `move-sites` analysis request
    // (docs/deep-debugging-tools.md).
    consume_call_sites: Vec[i32],
    // move-sites: use sequencing. ONE persistent map per key kind, one owner —
    // bodies are separated by an epoch packed into every value (epoch*2^32 +
    // seq), never by swapping map headers (bit-copy map swaps are the #697
    // aliasing class and corrupted Sema state via stale-header inserts).
    binding_use_seq: i32,
    binding_use_epoch: i32,
    binding_epoch_counter: i32,
    binding_last_use: HashMap[i32, i64],
    // move-sites: last use per (root, first-field) path — the liveness key for
    // FIELD-shaped transfer args, so `eat(move self.r)` followed by `self.tag`
    // reads verdicts on the `.r` path, not the whole receiver. Key packs
    // root_sym * 2^32 + field_sym; value packs epoch * 2^32 + seq.
    field_last_use: HashMap[i64, i64],
    // explain:effect provenance — first setter of each ownership-forcing bit.
    // Key packs (sig, param, bit-index); value packs (kind, a, b): kind 1 =
    // direct (a = AST node), kind 2 = effect-flow edge (a = callee sig,
    // b = callee param).
    effect_prov: HashMap[i64, i64],
    // Origin node for the next note_param_effect call (set/cleared by the
    // node-bearing noters; 0 = unknown source construct).
    effect_note_origin_node: i32,

    // Extern fn names
    extern_fn_names: HashMap[i32, i32],
    // #602: c_import/extern params that RETAIN a passed C-string pointer past
    // the call (§16.3c). Keyed by fn name sym → bitmask of retained param
    // indices. Such a param is modeled as a C-string input (cstr_in) but
    // rejects a call-scoped `str` temporary — the caller must own the storage.
    retained_extern_params: HashMap[i32, i32],
    // Function AST node indices by name
    fn_decl_nodes: HashMap[i32, i32],
    // Function declaration node -> semantic symbol. Most declarations use
    // their parsed symbol; cross-module extension methods get a unique symbol
    // so packages can define the same Type.method without colliding.
    fn_decl_effective_syms: HashMap[i32, i32],
    // Function declaration source path by name
    fn_decl_source_paths: HashMap[i32, str],
    // Multiple function clauses (§9.7): public dispatch symbol -> clause group index.
    fn_clause_group_lookup: HashMap[i32, i32],
    fn_clause_group_names: Vec[i32],
    fn_clause_group_starts: Vec[i32],
    fn_clause_group_counts: Vec[i32],
    fn_clause_group_decls: Vec[i32],
    // Hidden clause body symbol -> public dispatch symbol.
    fn_clause_body_dispatch: HashMap[i32, i32],
    // Memoized §14.22 by-value Task parameter disposition:
    // key(fn_sym,param_i) -> 1 when the parameter is proven consumed in scope.
    task_param_consumed_memo: HashMap[i64, i32],
    task_param_consumed_visiting: HashMap[i64, i32],
    detached_task_stmt_nodes: HashMap[i32, i32],
    // Generic function node indices by name. The map preserves the first
    // declaration for single-template metadata lookups; the candidate tables
    // retain every same-name generic declaration for structural overload
    // selection at call sites.
    generic_fn_nodes: HashMap[i32, i32],
    generic_fn_candidate_counts: HashMap[i32, i32],
    generic_fn_candidate_syms: Vec[i32],
    generic_fn_candidate_nodes: Vec[i32],
    // Call expression/pipeline node -> selected generic declaration node.
    resolved_generic_call_nodes: HashMap[i32, i32],

    // Methods: hash(type_sym, method_sym) → sig index
    extension_method_owner_syms: Vec[i32],
    extension_method_syms: Vec[i32],
    extension_method_fn_syms: Vec[i32],
    extension_method_sig_idxs: Vec[i32],
    extension_method_paths: Vec[str],
    qualified_extension_call_nodes: HashMap[i32, i32],
    // Variant lookup: variant_sym → variant_index
    variant_lookup: HashMap[i32, i32],
    // Variant type IDs: variant_sym → enum_tid
    variant_type_ids: HashMap[i32, i32],
    // Explicit constructor imports: variant_sym -> enum_tid.
    imported_variant_owners: HashMap[i32, i32],
    // Discriminant enum data
    disc_repr_types: HashMap[i32, i32],
    disc_values: HashMap[i32, i32],
    disc_has_payload: HashMap[i32, i32],
    bitpacked_types: HashMap[i32, i32],  // type_id → 1 if bitpacked
    packed_types: HashMap[i32, i32],     // type_id → 1 if repr(packed)/@[packed]
    repr_c_types: HashMap[i32, i32],     // type_id → 1 if @[repr(C)] (or repr(packed))
    // §16.11: TY_FN/TY_EXTERN_FN type_id → 1 when the callable is unsafe to
    // call (carries a raw-pointer-validity precondition). Part of type identity.
    unsafe_fn_type_set: HashMap[i32, i32],
    // §16.4 union last-written tracking. Maps a local union variable's name
    // sym → the last-written field sym (0 = tracked-but-unknown after control
    // flow). Absent = untracked (never literal-initialized/assigned) and never
    // flagged, which keeps raw/uninitialized union access build-safe.
    union_last_written: HashMap[i32, i32],
    union_tracked_syms: Vec[i32],   // insertion-ordered tracked union var syms
    union_in_assign_target: i32,

    // Dyn-erased generic-inst trait impls: methods specialized for the
    // concrete inst when a ref-to-dyn coercion is accepted, keyed by
    // pair(resolved inst tid, trait sym) into flat (method, sig, mono) rows.
    // Codegen's vtable builder consumes these (blanket impls have no
    // pre-monomorphized Type__Arg.method functions).
    dyn_impl_starts: HashMap[i64, i32],
    dyn_impl_counts: HashMap[i64, i32],
    dyn_impl_flat_method_names: Vec[i32],
    dyn_impl_flat_sigs: Vec[i32],
    dyn_impl_flat_mono_syms: Vec[i32],

    // Trait declarations
    trait_method_names: Vec[i32],
    trait_method_starts: Vec[i32],
    trait_method_counts: Vec[i32],
    trait_method_flags: Vec[i32],
    trait_method_param_starts: Vec[i32],
    trait_method_param_counts: Vec[i32],
    trait_method_ret_nodes: Vec[i32],
    trait_method_default_bodies: Vec[i32],
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
    // D29 scaffolding (#750): tier provenance for the shadow case (a user type
    // decl reusing a prelude-closure type name). impl_extra_is_std runs in
    // lockstep with impl_extra; type_tid_is_std / type_decl_nodes_by_tid are
    // recorded at type-decl registration; type_sym_tier_mask bits: 1=std, 2=user.
    // All queries stay on the flat path unless the mask reads 3 (shadowed).
    impl_extra_is_std: Vec[i32],
    type_decl_nodes_by_tid: HashMap[i32, i32],
    type_tid_is_std: HashMap[i32, i32],
    type_sym_tier_mask: HashMap[i32, i32],
    // Generic inst impls: impl Trait for Type[Args]
    // Key: pair(type_id, trait_sym) → 1
    impl_generic_inst: HashMap[i64, i32],
    // Blanket impls: impl[T: Bound] Trait for T
    blanket_trait_syms: Vec[i32],
    blanket_bound_syms: Vec[i32],
    blanket_bound_starts: Vec[i32],
    blanket_bound_counts: Vec[i32],
    // Blanket impl target type: 0 = bare type param, else: = base_sym of generic target
    blanket_target_base_syms: Vec[i32],
    blanket_impl_nodes: Vec[i32],
    // Trait obligations + deterministic selection cache
    obligation_trait_syms: Vec[i32],
    obligation_type_syms: Vec[i32],
    obligation_nodes: Vec[i32],
    selection_cache: HashMap[i64, i32],
    // Blanket impl recursion guard: keys currently being resolved
    // Cycle-detection guard for select_trait_impl. A HashSet (heap handle), not a
    // Vec, so it can be mutated through a copied handle from a `&Self` query method
    // (D7: query methods are read; the guard is interior bookkeeping). See
    // project_enforce_receiver_modes.
    blanket_guard: HashSet[i64],

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
    no_await_guard_types: HashMap[i32, i32],
    must_use_fns: HashMap[i32, i32],
    result_option_fns: HashMap[i32, i32],
    task_fns: HashMap[i32, i32],
    no_alloc_fns: HashMap[i32, i32],
    fn_may_alloc: HashMap[i32, i32],
    fn_stack_sizes: HashMap[i32, i32],
    // Generator metadata. A `gen fn f(...) -> T` semantically returns an
    // internal state struct and exposes an internal `next(mut self)` method
    // returning Option[T].
    generator_fn_yield_types: HashMap[i32, i32],
    generator_fn_state_types: HashMap[i32, i32],
    generator_fn_state_syms: HashMap[i32, i32],
    generator_fn_next_syms: HashMap[i32, i32],
    generator_next_fn_syms: HashMap[i32, i32],
    generator_state_yield_types: HashMap[i32, i32],
    generator_state_field_counts: HashMap[i32, i32],
    generator_state_field_names: HashMap[i64, i32],
    generator_state_field_types: HashMap[i64, i32],
    mutable_global_syms: HashMap[i32, i32],
    // docs/mut.md Rev 8 §12 / §15.12 — symbols declared via `global X = ...`
    // (stable) recorded here. Used by check_assign to emit a specific
    // diagnostic on rebind attempts. `global var X = ...` does NOT register
    // here — it's rebindable.
    stable_global_syms: HashMap[i32, i32],
    global_value_decl_kinds: HashMap[i32, i32],
    global_race_access_syms: Vec[i32],
    global_race_access_nodes: Vec[i32],
    global_race_access_files: Vec[i32],
    global_race_access_paths: Vec[str],
    global_race_access_kinds: Vec[i32],
    global_race_access_unsafe: Vec[i32],
    global_race_mutated_syms: HashMap[i32, i32],
    global_race_mutation_nodes: HashMap[i32, i32],
    global_race_concurrency_node: i32,
    global_race_concurrency_file: i32,
    global_race_concurrency_reason: str,

    // Hot intrinsic symbols used in semantic dispatch paths.
    syms: SemaBuiltinSymbols,

    // Method origin tracking
    method_impl_nodes: HashMap[i32, i32],
    method_decl_impl_nodes: HashMap[i32, i32],
    method_decl_origins: HashMap[i32, i32],
    method_has_inherent: HashMap[i32, i32],
    method_symbol_flags: HashMap[i32, i32],
    method_lookup: SemaMethodLookup,
    drop_method_cache: HashMap[i32, i32],
    // is_copy cycle guard — HashSet (heap handle) so is_copy can be `&Self` and
    // mutate it through a copied handle (D7 interior-mutability recipe).
    copy_visit_stack: HashSet[i32],
    // type_needs_drop cycle guard — HashSet (heap handle) for `&Self` interior mut.
    needs_drop_visit: HashSet[i32],
    current_drop_type_sym: i32,
    drop_control_flow_depth: i32,
    move_control_flow_depth: i32,
    move_control_flow_binding_starts: Vec[i32],
    move_control_flow_supports_drop_flags: Vec[i32],
    drop_consumed_field_owner_syms: Vec[i32],
    drop_consumed_field_syms: Vec[i32],

    // Scope binding storage (stack-based with watermarks)
    bind_names: Vec[i32],
    bind_types: Vec[i32],
    bind_muts: Vec[i32],
    bind_states: Vec[i32],
    moved_field_base_syms: Vec[i32],
    // #782: bindings whose partial state came from an EXPLICIT `move x.f`.
    // §2.5.1 sanctions whole-value transfer after a spelled-out field move
    // (the hole arrives blanked by design); only IMPLICIT moves (bare
    // assignment-RHS reads) make later whole-value uses an error. A
    // suppression set, so branch-merge imprecision only ever suppresses.
    explicitly_partial_syms: HashMap[i32, i32],
    marking_explicit_move: i32,
    moved_field_path_starts: Vec[i32],
    moved_field_path_counts: Vec[i32],
    moved_field_path_syms: Vec[i32],
    bind_is_task: Vec[i32],
    bind_task_used: Vec[i32],
    bind_is_scoped_task: Vec[i32],
    bind_is_view_bound: Vec[i32],
    bind_provenance: Vec[BindingProvenance],
    binding_decl_nodes: HashMap[i32, i32],
    binding_value_nodes: HashMap[i32, i32],
    scope_starts: Vec[i32],
    scope_name_map: HashMap[i32, i32],
    pending_generic_binding_base: HashMap[i32, i32],
    pending_generic_binding_call: HashMap[i32, i32],
    pending_generic_binding_decl: HashMap[i32, i32],
    async_scope_names: Vec[i32],
    sync_scope_names: Vec[i32],
    label_syms: Vec[i32],
    label_kinds: Vec[i32],
    label_nodes: Vec[i32],
    label_break_value_types: Vec[i32],
    // Loop move-state tracking (docs/branch-merge-soundness.md §6.7 / #613):
    // per label frame: entry bind-count (outer/inner boundary), the offset of this
    // loop's break-flag region in loop_break_flat (-1 = none), and whether any
    // break to this frame was captured. loop_break_flat is a flat stack of
    // per-binding break-moved flags (VarState), one region per active loop — kept
    // as Vec[i32] (not Vec[Vec[i32]]) for seed compatibility.
    label_loop_entry_binds: Vec[i32],
    label_break_off: Vec[i32],
    label_break_seen: Vec[i32],
    loop_break_flat: Vec[i32],
    // Parallel to loop_break_flat and sharing its per-frame offset (label_break_off):
    // the loop-entry move-state snapshot, one region per active loop. It lets the
    // `continue` back-edge check apply the SAME entry==LIVE guard that
    // finalize_loop_move_state uses for the fall-through back-edge — without it, a
    // value moved *before* the loop is wrongly flagged as moved *inside* it (#696).
    loop_entry_flat: Vec[i32],
    fn_label_syms: Vec[i32],
    fn_label_nodes: Vec[i32],
    fn_label_paths: Vec[str],
    fn_label_orders: Vec[i32],
    fn_label_used: Vec[i32],
    fn_goto_syms: Vec[i32],
    fn_goto_nodes: Vec[i32],
    fn_goto_paths: Vec[str],
    fn_goto_orders: Vec[i32],
    fn_init_nodes: Vec[i32],
    fn_init_paths: Vec[str],
    fn_init_orders: Vec[i32],
    fn_label_scope_stack: Vec[i32],
    fn_label_next_scope_id: i32,
    fn_label_order_counter: i32,

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
    borrow_scope_depths: Vec[i32],
    borrow_creation_nodes: Vec[i32],
    // Block context for §15.6 three-location diagnostics
    current_block_extra_start: i32,
    current_block_stmt_count: i32,
    current_block_stmt_index: i32,
    current_block_tail: i32,
    // Transient storage for closure field-level capture analysis.
    capture_field_syms: Vec[i32],
    capture_field_kinds: Vec[i32],

    // Resolved call args for named/default-arg calls. Keep starts and counts
    // explicit: AST node IDs and the flattened data index both exceed 16 bits.
    call_resolved_arg_starts: HashMap[i32, i32],
    call_resolved_arg_counts: HashMap[i32, i32],
    call_resolved_args_data: Vec[i32],
    call_resolved_default_arg_keys: HashMap[i64, i32],
    // Concrete call contract chosen by Sema. Generic calls cannot recover this
    // from their template symbol: the concrete signature owns the final
    // share-place ABI and the monomorphized MIR identity.
    resolved_call_sigs: HashMap[i32, i32],
    resolved_call_mono_syms: HashMap[i32, i32],
    magic_ident_kinds: HashMap[i32, i32],
    // Implicit parameter bindings stack: pairs of (type_id, binding_sym)
    implicit_binding_types: Vec[i32],
    implicit_binding_syms: Vec[i32],
    with_form_kinds: HashMap[i32, i32],
    with_payload_types: HashMap[i32, i32],
    with_enter_methods: HashMap[i32, i32],
    with_exit_methods: HashMap[i32, i32],
    with_enter_sigs: HashMap[i32, i32],
    with_enter_mono_syms: HashMap[i32, i32],
    with_exit_sigs: HashMap[i32, i32],
    with_exit_mono_syms: HashMap[i32, i32],
    no_await_guard_origin_roots: Vec[i32],
    no_await_guard_scope_depth: i32,
    no_suspend_scope_depth: i32,

    // For-comprehension resolved variants: node → resolved variant sym.
    // Maps _Payload/_Empty marker nodes to Some/None or Ok/Err.
    comp_resolved: HashMap[i32, i32],
    // Surviving generic comptime-if wrapper node → selected branch node.
    comptime_selected_branches: HashMap[i32, i32],
    // Pipeline method calls: NK_PIPELINE node → method-name symbol. D21 keeps
    // the ordinary call result separate from the value carried to the next
    // stage: carrier kind 1 threads the receiver place, 0 threads the result.
    pipeline_method_calls: HashMap[i32, i32],
    pipeline_call_return_types: HashMap[i32, i32],
    pipeline_carrier_kinds: HashMap[i32, i32],
    // Operator method calls: NK_BINARY node -> resolved function symbol, plus
    // node -> 1 when the right operand is the receiver.
    operator_method_calls: HashMap[i32, i32],
    operator_method_reversed: HashMap[i32, i32],
    // User Try resolution sidecars for NK_UNARY(UOP_TRY): node -> type/fn data.
    try_continue_tys: HashMap[i32, i32],
    try_break_tys: HashMap[i32, i32],
    try_branch_result_tys: HashMap[i32, i32],
    try_branch_fns: HashMap[i32, i32],
    try_from_break_fns: HashMap[i32, i32],
    try_branch_sigs: HashMap[i32, i32],
    try_branch_mono_syms: HashMap[i32, i32],
    try_from_break_sigs: HashMap[i32, i32],
    try_from_break_mono_syms: HashMap[i32, i32],
    // Synthetic BTree literal/comprehension insertion contracts. These cannot
    // use resolved_call_*: the anchor expression may itself be a generic call.
    btree_insert_sigs: HashMap[i32, i32],
    btree_insert_mono_syms: HashMap[i32, i32],
    // Compiler-synthesized Clone calls (currently Option[&T].cloned()).
    // The source node names the builtin eliminator, not the payload's clone
    // method, so resolved_call_* cannot carry both contracts. Sema resolves
    // and specializes the payload method once; MIR consumes this sidecar.
    clone_contract_fns: HashMap[i32, i32],
    clone_contract_sigs: HashMap[i32, i32],
    clone_contract_mono_syms: HashMap[i32, i32],
    // Auto-deref adjustment sidecar: expression node -> contiguous step range.
    // Step fn 0 means builtin &/* deref; non-zero is a user Deref.deref fn.
    autoderef_step_starts: HashMap[i32, i32],
    autoderef_step_counts: HashMap[i32, i32],
    // #604 stage 1: call-arg nodes coerced collection→slice (1=imm, 3=mut);
    // consumed by MirLower.lower_call_arg to borrow the place instead of
    // moving the collection.
    slice_coerce_args: HashMap[i32, i32],
    // D22 Stage 2 contextual-Copy decisions. The node map indexes the single
    // structured record consumed by later stages; expression type inference
    // never reads this sidecar and therefore remains exact.
    contextual_copy_adjustment_indices: HashMap[i64, i32],
    contextual_copy_adjustments: Vec[ContextualCopyAdjustment],
    // D22 Stage 3 contextual-join decisions. Roles distinguish ordinary AST
    // expressions from synthetic carrier payloads and lazy fallback results.
    contextual_join_decision_indices: HashMap[i64, i32],
    contextual_join_decisions: Vec[ContextualJoinDecision],
    contextual_join_arm_nodes: Vec[i32],
    contextual_join_arm_origin_nodes: Vec[i32],
    contextual_join_arm_types: Vec[i32],
    contextual_join_arm_kinds: Vec[i32],
    contextual_join_arm_roles: Vec[i32],
    contextual_join_origin_deps: Vec[i32],
    // #604 stage 1: >0 while resolving a function-signature parameter type —
    // the only position where `[]mut T` is legal in this release.
    in_param_type_position: i32,
    autoderef_step_fns: Vec[i32],
    autoderef_step_tys: Vec[i32],
    // Match value-pattern sidecar: pattern node → symbol compared by value.
    pattern_value_syms: HashMap[i32, i32],
    // Regex literal metadata sidecars, keyed by NK_REGEX_LIT/NK_PAT_REGEX node.
    regex_capture_counts: HashMap[i32, i32],
    regex_capture_name_starts: HashMap[i32, i32],
    regex_capture_name_counts: HashMap[i32, i32],
    regex_capture_name_syms: Vec[i32],

    // Typed dump sidecar maps (keyed by span start byte offset)
    typed_expr_types: HashMap[i32, i32],
    typed_binding_types: HashMap[i32, i32],
    // D22 §13.6: field-access exprs whose base is a shared view and whose
    // field type is non-Copy — an owned demand on one is an error.
    view_projection_exprs: HashMap[i32, i32],
    // §2.4: value nodes of drop-body self-field lets — MirLower binds these
    // by MOVE (never the alias path); the field glue skips them via
    // drop_consumed_field.
    drop_consumed_binding_values: HashMap[i32, i32],
    typed_binding_names: HashMap[i32, i32],
    typed_binding_muts: HashMap[i32, i32],
    ephemeral_task_binding_nodes: HashMap[i32, i32],
    // Whole-var assignment target being re-checked: a moved binding is a
    // legal assignment target (the store revives it, spec §2.4), so the
    // ident check must not flag it. Set around check_assign's LHS check.
    assign_target_revive_sym: i32,
    // Cycle-detection state for the may_suspend / ephemeral-task walkers
    // (reset at each outer query; same pattern as reachable_visiting).
    suspend_visiting: HashMap[i32, i32],
    eph_task_visiting: HashMap[i32, i32],
    typed_dump_seen_nodes: HashMap[i32, i32],
    typed_dump_visit_budget: i32,
    // Generic substitution map + specialization cache
    generic_subst_param_syms: Vec[i32],
    generic_subst_type_ids: Vec[i32],
    generic_specialization_cache: HashMap[str, i32],
    // Concrete generic bodies are checked during Sema, then rechecked/lowered
    // into MIR before freeze. Codegen consumes those bodies; it must never
    // reopen Sema. Parallel descriptor arrays are indexed by
    // concrete_specialization_by_sym[mono_sym].
    concrete_specialization_by_sym: HashMap[i32, i32],
    concrete_specialization_nodes: Vec[i32],
    concrete_specialization_syms: Vec[i32],
    concrete_specialization_sigs: Vec[i32],
    concrete_specialization_subst_starts: Vec[i32],
    concrete_specialization_subst_counts: Vec[i32],
    concrete_specialization_subst_syms: Vec[i32],
    concrete_specialization_subst_types: Vec[i32],
    concrete_specialization_param_starts: Vec[i32],
    concrete_specialization_param_counts: Vec[i32],
    concrete_specialization_param_types: Vec[i32],
    // Synthetic drop glue has no AST call node. Map each concrete generic
    // instance to the Drop.drop contract registered before MIR freeze.
    concrete_drop_sigs: HashMap[i32, i32],
    concrete_drop_mono_syms: HashMap[i32, i32],
    generic_inst_cache: HashMap[i64, i32],
    // D7: eager tables filled in preregister_mir_types (before freeze) so the frozen
    // consumers read answers via &Self twins instead of re-deriving them through the
    // mutating checker. is_copy_cache[tid] = 0/1 copy-ness.
    layout_size_cache: HashMap[i32, i64],
    layout_align_cache: HashMap[i32, i64],
    layout_field_offset_cache: HashMap[i64, i64],
    is_copy_cache: HashMap[i32, i32],
    needs_drop_result_cache: HashMap[i32, i32],
    unwrapped_type_cache: HashMap[i32, i32],
    for_element_type_cache: HashMap[i32, i32],
    generic_struct_field_type_cache: HashMap[i64, i32],
    generic_struct_field_index_type_cache: HashMap[i64, i32],
    generic_enum_payload_cache_starts: HashMap[i64, i32],
    generic_enum_payload_cache_counts: HashMap[i64, i32],
    generic_enum_payload_cache_values: Vec[i32],

    // Associated type bindings from current impl (for Self.Name resolution)
    assoc_type_bindings: HashMap[i32, i32],

    // Frozen flags: set to 1 after check_module + preregister completes.
    // When frozen, add_type and new semantic symbol interning will error.
    symbols_frozen: i32,
    types_frozen: i32,

    // docs/mutability.md Phase 4 — per-function effect tracking during body analysis.
    // Cleared and set by check_fn_body_with_sig; used to accumulate effects as the body is checked.
    current_fn_param_syms: Vec[i32],   // param name symbols for the function being checked
    current_fn_param_effs: Vec[i32],   // accumulated effect bits per param
    current_fn_param_direct_effs: Vec[i32], // body-local effects, excluding propagated calls
    current_fn_param_origins: Vec[i32],// accumulated escape_view origin masks per param
    current_fn_param_view_nodes: Vec[i32], // representative return/view node for escape_view diagnostics
    current_fn_sig_idx: i32,           // sig index of current function (-1 if not in a fn body)
    recording_propagated_effect: i32,

    // Closure capture summaries: closure node -> flat [capture_sym, effect_bits]* slice.
    closure_capture_summary_starts: HashMap[i32, i32],
    closure_capture_summary_counts: HashMap[i32, i32],
    closure_capture_summary_data: Vec[i32],
    // Binding -> originating closure node when initialized directly from a closure literal.
    binding_closure_nodes: HashMap[i32, i32],
    binding_view_dep_data: Vec[i32],
    // Expression-level view metadata for call expressions and view-producing nodes.
    expr_view_param_origins: HashMap[i32, i32],
    expr_view_dep_starts: HashMap[i32, i32],
    expr_view_dep_counts: HashMap[i32, i32],
    expr_view_dep_data: Vec[i32],
    alloc_site_nodes: Vec[i32],
    alloc_site_kinds: Vec[i32],
    alloc_site_fn_syms: Vec[i32],
    alloc_site_elided: Vec[i32],
    current_no_alloc_depth: i32,
    current_fn_may_alloc: i32,
    current_fn_symbol: i32,

    // Current state
    source_text: str,
    tracked_input_root: str,
    tracked_input_paths: Vec[str],
    current_return_type: TypeId,
    current_gen_yield_type: TypeId,
    has_gen_yield_type: i32,
    in_pipeline_rhs: i32,
    match_in_stmt_pos: i32,
    current_for_comprehension_carrier: i32,
    in_comptime_fn: i32,
    in_concrete_generic_body: i32,
    in_async_fn: i32,
    no_std: i32,
    alloc: i32,
    runtime_available: i32,
    runtime_fiber_stack_size: i64,
    runtime_fiber_pool_size: i32,
    runtime_fiber_worker_count: i32,
    copy_warn_threshold: i64,
    emit_config_warnings: i32,
    lint_partial_statement_match: i32,
    overflow_mode: i32,
    in_defer: i32,
    in_unsafe: i32,
    in_bitwise_literal_context: i32,
    unsafe_scope_used: Vec[i32],
    break_value_type: TypeId,
    has_break_value_type: i32,
    loop_depth: i32,
    stmt_pos_depth: i32,
    current_statement_expr_root: i32,
    current_value_expr_root: i32,
    closure_direct_arg_depth: i32,
    closure_direct_arg_escape_flags: Vec[i32],
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
    ty_cstr: TypeId,
    ty_cstr_view: TypeId,
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
    source_text_file_ids: Vec[i32],  // imported/extra source text file ids
    source_text_names: Vec[str],     // source display names aligned with source_text_file_ids
    source_texts: Vec[str],          // source buffers aligned with source_text_file_ids
    source_line_offsets: Vec[Vec[i32]], // root first, then one index per source_texts entry
    current_module_path: str,        // module path being checked right now
    tool_mode_entry_path: str,        // compiler-generated tool runner allowed to mint capabilities
    module_paths: Vec[str],          // resolved module graph paths
    module_import_starts: Vec[i32],  // per-module start into module_import_targets
    module_import_counts: Vec[i32],  // per-module import edge count
    module_import_targets: Vec[i32], // flattened target module indices
    module_import_paths: Vec[str],   // flattened import path text aligned with module_import_targets
    module_index_by_path: HashMap[str, i32],   // path -> module index
    global_visible_module_paths: HashMap[str, i32], // prelude-visible modules
    module_visibility_cache: HashMap[str, i32], // "from->to" -> visibility
    named_type_candidate_syms: Vec[i32],       // every registered named type symbol
    named_type_candidate_tids: Vec[i32],       // parallel type id for candidate
    named_type_candidate_paths: Vec[str],      // defining module path or "" for global
    named_type_candidate_pub: Vec[i32],        // parallel public flag
    named_type_candidate_heads: HashMap[i32, i32], // symbol -> newest candidate index
    named_type_candidate_next: Vec[i32],       // previous candidate for the same symbol
    decl_visibility_syms: Vec[i32],            // top-level symbol visibility candidates
    decl_visibility_paths: Vec[str],           // parallel declaring module path
    decl_visibility_pub: Vec[i32],             // parallel public flag
    decl_visibility_nodes: Vec[i32],           // parallel declaration node
    // c_import scoping: tracks which symbols are c_import-origin
    ci_syms: HashMap[i32, i32],      // sym → 1 for c_import-origin symbols
    ci_raw_syms: HashMap[i32, i32],  // sym → 1 for c_import raw ABI calls
    ci_omitted_symbols: HashMap[str, str], // C name → omission reason
    ci_modules: HashMap[i32, i32],   // module-path-sym → 1 for modules that have c_import
    scoping_active: i32,             // 1 when multi-module c_import scoping is active
    current_module_has_ci: i32,      // 1 if current module has c_import declarations
    // Reachable-comptime-error traversal accumulators (formerly free-fn
    // &mut HashMap params). Reset on each entry to check_reachable_comptime_errors.
    reachable_seen: HashMap[i32, i32],
    reachable_visiting: HashMap[i32, i32],
    reachable_decl_indices: HashMap[i32, i32],
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

impl Sema:
    fn debug_unknown_type(sym: i32, node: i32, context: &str):
        if sema_debug_stage1_enabled() == 0:
            return
        let name = self.pool_resolve_symbol(sym)
        let prim = self.primitive_type_by_sym(sym)
        let named = if self.named_types.contains(sym): 1 else: 0
        with_eprint(f"[unknown-type] {context} sym={sym} name={name} prim={prim} named={named} collecting={self.collecting_types} node_kind={self.ast.kind(node)}")

    fn pool_resolve_symbol(sym: i32) -> &str:
        self.pool.resolve_symbol(sym)

    fn pool_resolve(sym: i32) -> &str:
        self.pool_resolve_symbol(sym)

    fn pool_lookup_symbol(name: &str) -> i32:
        if name.len() == 0:
            return 0
        // symbol_map is authoritative: every symbol_texts entry is inserted
        // into symbol_map at the same site it is pushed (see pool_intern /
        // InternPool.intern_str), so a map miss means the symbol is absent.
        let existing = self.pool.state.symbol_map.get(name)
        if existing.is_some():
            return existing.unwrap()
        0

    mut fn pool_intern(name: &str) -> i32:
        if self.symbols_frozen != 0:
            let existing = self.pool_lookup_symbol(name)
            if existing != 0:
                return existing
            sema_phase_bug("BUG: Sema.pool_intern called after symbol freeze: '" ++ name ++ "'")
            return 0
        let existing = self.pool.state.symbol_map.get(name)
        if existing.is_some():
            return existing.unwrap()

        let id = self.pool.state.symbol_texts.len() as i32
        let owned = sema_owned_text(name)
        self.pool.state.symbol_map.insert(with_str_clone_ref(owned), id)
        self.pool.state.symbol_texts.push(owned)
        id

fn sema_tier_path_is_std_implementation(path: &str) -> i32:
    if path.starts_with("lib/std/") or path.starts_with("<embedded-std>/"):
        return 1
    if path.contains("/lib/std/"):
        return 1
    0

fn sema_vec_str_contains(v: &Vec[str], s: &str) -> i32:
    for i in 0..v.len() as i32:
        if v.get(i as i64) == s:
            return 1
    0

// "<embedded-std>/std/collections.w" or ".../lib/std/collections.w" → "std.collections"
fn sema_std_module_dotted(path: &str) -> str:
    var rel = ""
    if path.starts_with("<embedded-std>/"):
        rel = path.slice("<embedded-std>/".len(), path.len())
    else if path.starts_with("lib/std/"):
        rel = path.slice("lib/".len(), path.len())
    else:
        var i = 0 as i64
        let marker = "/lib/std/"
        while i + marker.len() <= path.len():
            if path.slice(i, i + marker.len()) == marker:
                rel = path.slice(i + "/lib/".len(), path.len())
                break
            i = i + 1
    if rel.len() == 0:
        return ""
    if rel.ends_with(".w"):
        rel = rel.slice(0, rel.len() - 2)
    rel.replace("/", ".")

// D29 scaffolding (#750): the §18.2 prelude, exactly as enumerated. These
// names stay ambient; every other prelude-closure name is import-gated until
// the D fallback tier activates. Primitives and Bool literals never reach the
// gate (they register pathless). c_void and assert_matches_failed are
// compiler-lowering support: c_import emissions and the assert_matches
// desugaring reference them in user-tier positions the user never spelled.
fn sema_prelude_gate_allows_name(name: &str) -> i32:
    if name == "print" or name == "eprint":
        return 1
    if name == "assert" or name == "assert_eq" or name == "assert_ne":
        return 1
    if name == "require" or name == "check":
        return 1
    if name == "panic" or name == "unreachable" or name == "todo":
        return 1
    if name == "drop":
        return 1
    if name == "Option" or name == "Some" or name == "None":
        return 1
    if name == "Result" or name == "Ok" or name == "Err":
        return 1
    if name == "Vec" or name == "String" or name == "str" or name == "Unit":
        return 1
    if name == "Eq" or name == "Ord" or name == "Hash" or name == "Debug":
        return 1
    if name == "Display" or name == "Default" or name == "Drop":
        return 1
    if name == "c_void" or name == "assert_matches_failed":
        return 1
    0

fn sema_path_is_std_box_module(path: &str) -> i32:
    if path == "lib/std/box.w" or path == "<embedded-std>/std/box.w":
        return 1
    if path.ends_with("/lib/std/box.w") or path.ends_with("\\lib\\std\\box.w"):
        return 1
    0

fn sema_path_is_std_rc_module(path: &str) -> i32:
    if path == "lib/std/rc.w" or path == "<embedded-std>/std/rc.w":
        return 1
    if path.ends_with("/lib/std/rc.w") or path.ends_with("\\lib\\std\\rc.w"):
        return 1
    0

impl Sema:
    fn current_module_is_std_implementation() -> i32:
        sema_tier_path_is_std_implementation(self.current_module_path)

    fn type_symbol_is_std_box(sym: i32) -> i32:
        if with_getenv_str("WITH_DEBUG_BOXSYM").len() > 0:
            let bs_path = self.type_decl_source_path(sym)
            let bs_eq = if sym == self.syms.box: 1 else: 0
            with_eprint(f"[boxsym] sym={sym} syms.box={self.syms.box} eq={bs_eq} path='{bs_path}' pathlen={bs_path.len() as i32} verdict={sema_path_is_std_box_module(bs_path)}")
        if sym != self.syms.box:
            return 0
        sema_path_is_std_box_module(self.type_decl_source_path(sym))

    fn type_is_std_box_inst(tid: i32) -> i32:
        let resolved = self.resolve_alias(tid as TypeId)
        if self.get_type_kind(resolved) != TypeKind.TY_GENERIC_INST:
            return 0
        if self.get_generic_inst_arg_count(resolved as i32) != 1:
            return 0
        self.type_symbol_is_std_box(self.get_type_d0(resolved))

    fn fn_symbol_is_std_box_member(fn_sym: i32) -> i32:
        sema_path_is_std_box_module(self.fn_symbol_source_path(fn_sym))

    fn type_symbol_is_std_rc_owner(sym: i32) -> i32:
        let name = self.pool_resolve_symbol(sym)
        if name != "Rc" and name != "Arc":
            return 0
        sema_path_is_std_rc_module(self.type_decl_source_path(sym))

fn sema_tier_std_only_module(path: &str) -> i32:
    if path == "std.io" or path.starts_with("std.io."):
        return 1
    if path == "std.fs" or path.starts_with("std.fs."):
        return 1
    if path == "std.net" or path.starts_with("std.net."):
        return 1
    if path == "std.sync" or path.starts_with("std.sync."):
        return 1
    if path == "std.channel" or path.starts_with("std.channel."):
        return 1
    if path == "std.task" or path.starts_with("std.task."):
        return 1
    if path == "std.thread" or path.starts_with("std.thread."):
        return 1
    if path == "std.process" or path.starts_with("std.process."):
        return 1
    if path == "std.os" or path.starts_with("std.os."):
        return 1
    if path == "std.signal" or path.starts_with("std.signal."):
        return 1
    if path == "std.sysinfo" or path.starts_with("std.sysinfo."):
        return 1
    if path == "std.time" or path.starts_with("std.time."):
        return 1
    0

fn sema_path_is_compiler_owned_implementation(path: &str) -> i32:
    if path.starts_with("src/") or path.contains("/src/"):
        return 1
    if path.starts_with("build/") or path.contains("/build/"):
        return 1
    if path.starts_with("rt/") or path.contains("/rt/"):
        return 1
    if path.starts_with("out/gen/") or path.contains("/out/gen/"):
        return 1
    if sema_tier_path_is_std_implementation(path) != 0:
        return 1
    0

fn sema_paths_share_internal_implementation_boundary(a: &str, b: &str) -> i32:
    if sema_path_is_compiler_owned_implementation(a) == 0:
        return 0
    if sema_path_is_compiler_owned_implementation(b) == 0:
        return 0
    1

fn sema_path_is_compiler_hook_runner(path: &str) -> i32:
    if path.contains("__with_compiler_hook_runner."):
        return 1
    0

impl Sema:
    fn core_without_alloc() -> i32:
        if self.no_std == 0:
            return 0
        if self.alloc != 0:
            return 0
        1

    fn symbol_requires_alloc_tier(sym: i32) -> i32:
        if sym == self.syms.vec or sym == self.syms.hashmap or sym == self.syms.hashset or sym == self.syms.slotmap:
            return 1
        if self.type_symbol_is_std_box(sym) != 0:
            return 1
        if self.type_symbol_is_std_rc_owner(sym) != 0:
            return 1
        let name = self.pool_resolve_symbol(sym)
        if name == "String" or name == "StringBuilder":
            return 1
        0

    fn symbol_requires_std_tier(sym: i32) -> i32:
        if sym == self.syms.regex:
            return 1
        let name = self.pool_resolve_symbol(sym)
        if name == "print" or name == "eprint" or name == "write" or name == "ewrite":
            return 1
        if name == "print_i32" or name == "print_i64" or name == "print_bool":
            return 1
        if name == "Task" or name == "ScopedTask" or name == "ScopedJoinHandle":
            return 1
        if name == "Sender" or name == "Receiver" or name == "chan":
            return 1
        if name == "Mutex" or name == "RwLock" or name == "Atomic" or name == "AtomicI64" or name == "Order":
            return 1
        if name == "MutexGuard" or name == "MutexGuardMut" or name == "RwReadGuard" or name == "RwWriteGuard":
            return 1
        0

    mut fn require_alloc_tier_for_symbol(sym: i32, node: i32) -> i32:
        if self.core_without_alloc() == 0:
            return 1
        if self.current_module_is_std_implementation() != 0:
            return 1
        if self.symbol_requires_alloc_tier(sym) == 0:
            return 1
        let name: str = with_str_clone_ref(self.pool_resolve_symbol(sym))
        self.emit_error(name ++ " requires alloc; use --alloc or set alloc = true with std = false", node)
        0

    mut fn require_std_tier_for_symbol(sym: i32, node: i32) -> i32:
        if self.no_std == 0:
            return 1
        if self.current_module_is_std_implementation() != 0:
            return 1
        if self.symbol_requires_std_tier(sym) == 0:
            return 1
        let name: str = with_str_clone_ref(self.pool_resolve_symbol(sym))
        self.emit_error(name ++ " requires std", node)
        0

fn sema_new_map_i32_i32 -> HashMap[i32, i32]:
    HashMap.new()

fn sema_new_map_i32_str -> HashMap[i32, str]:
    HashMap.new()

fn sema_new_map_str_i32 -> HashMap[str, i32]:
    HashMap.new()

fn sema_new_map_i64_i32 -> HashMap[i64, i32]:
    HashMap.new()

fn sema_new_vec_str -> Vec[str]:
    let out: Vec[str] = Vec{ ptr: 0, len: 0, cap: 0, elem_size: 16 }
    out

fn sema_new_vec_i32 -> Vec[i32]:
    let out: Vec[i32] = Vec.new()
    out

fn sema_owned_text(text: &str) -> str:
    if text.len() == 0:
        return ""
    with_str_clone_ref(text)

fn sema_clone_str_vec(values: &Vec[str]) -> Vec[str]:
    let out = sema_new_vec_str()
    for i in 0..values.len() as i32:
        out.push(sema_owned_text(values.get(i as i64)))
    out

fn sema_clone_i32_vec(values: &Vec[i32]) -> Vec[i32]:
    let out: Vec[i32] = Vec.new()
    for i in 0..values.len() as i32:
        out.push(values.get(i as i64))
    out

// Deep-clone a HashMap[str, str] so the destination owns independent backing
// arrays and string payloads. A plain `dst = src.field` only shallow-copies the
// map header, leaving both maps pointing at one buffer — two owners that
// double-free at teardown (Zcu.c_import_omitted_symbols aliased into the round's
// Sema was exactly this bug). Mirrors sema_clone_str_vec's owned-text policy.
fn sema_clone_str_str_hashmap(src: &HashMap[str, str]) -> HashMap[str, str]:
    var out: HashMap[str, str] = HashMap.new()
    let ks = src.keys()
    for i in 0..ks.len() as i32:
        let k = ks.get(i as i64)
        let v = src.get(k)
        if v.is_some():
            out.insert(sema_owned_text(k), sema_owned_text(v.unwrap()))
    out

impl Sema:
    pub move fn prepare_comptime_eval_copy() -> Sema:
        // Comptime callers replace `ast` before copying Sema. Rebuild this
        // owning map for that AST instead of sharing the source map header.
        self.rebuild_decl_index()
        self.type_kinds = sema_clone_i32_vec(&self.type_kinds)
        self.type_d0 = sema_clone_i32_vec(&self.type_d0)
        self.type_d1 = sema_clone_i32_vec(&self.type_d1)
        self.type_d2 = sema_clone_i32_vec(&self.type_d2)
        self.type_extra = sema_clone_i32_vec(&self.type_extra)
        self.rebuild_exact_type_cache()
        self.rebuild_named_type_candidate_index()
        self.generic_inst_cache = sema_new_map_i64_i32()
        self.layout_size_cache = HashMap.new()
        self.layout_align_cache = HashMap.new()
        self.layout_field_offset_cache = HashMap.new()
        self.is_copy_cache = sema_new_map_i32_i32()
        self.needs_drop_result_cache = sema_new_map_i32_i32()
        self.unwrapped_type_cache = sema_new_map_i32_i32()
        self.for_element_type_cache = sema_new_map_i32_i32()
        self.generic_struct_field_type_cache = sema_new_map_i64_i32()
        self.generic_struct_field_index_type_cache = sema_new_map_i64_i32()
        self.generic_enum_payload_cache_starts = sema_new_map_i64_i32()
        self.generic_enum_payload_cache_counts = sema_new_map_i64_i32()
        self.generic_enum_payload_cache_values = Vec.new()
        self.generic_subst_param_syms = sema_clone_i32_vec(&self.generic_subst_param_syms)
        self.generic_subst_type_ids = sema_clone_i32_vec(&self.generic_subst_type_ids)
        self.source_text_file_ids = sema_clone_i32_vec(&self.source_text_file_ids)
        // source_texts / source_text_names / tracked_input_paths are read-only during
        // comptime eval and are restored by the write-back in comptime_eval_finish, so
        // share them (shallow) instead of deep-cloning. Deep-cloning the full source
        // text on every comptime eval leaked ~8.5 MB × N evals = GBs of dead copies.
        self

fn sema_pair_key(a: i32, b: i32) -> i64:
    (a as i64) * 4294967296 + (b as i64)

fn sema_exact_type_hash(kind: i32, d0: i32, d1: i32, d2: i32) -> i64:
    var h: u64 = 14695981039346656037
    h = (h ^ kind as u64) *% 1099511628211
    h = (h ^ d0 as u64) *% 1099511628211
    h = (h ^ d1 as u64) *% 1099511628211
    ((h ^ d2 as u64) *% 1099511628211) as i64

fn sema_pair_hi(key: i64): (key / 4294967296) as i32
fn sema_pair_lo(key: i64): (key % 4294967296) as i32

// Effect-provenance packing (docs/deep-debugging-tools.md, explain:effect).
// Key = (sig, pi, bit_idx) with pi < 2^16, bit_idx < 2^8; value = (kind, a, b)
// with a, b < 2^28. These fns are the only place the field widths appear;
// encode and decode both live here so they cannot drift apart.
fn effect_prov_key(sig: i32, pi: i32, bit_idx: i32) -> i64:
    (sig as i64) * 16777216 + (pi as i64) * 256 + bit_idx as i64

fn effect_prov_val(kind: i64, a: i32, b: i32) -> i64:
    kind * 72057594037927936 + (a as i64) * 268435456 + b as i64

fn effect_prov_val_kind(v: i64): v / 72057594037927936
fn effect_prov_val_a(v: i64): ((v / 268435456) % 268435456) as i32
fn effect_prov_val_b(v: i64): (v % 268435456) as i32

impl Sema:
    mut fn copy_module_graph_from(source: &Sema):
        let global_paths = sema_new_vec_str()
        for mi in 0..source.module_paths.len() as i32:
            let source_path = source.module_paths.get(mi as i64)
            if source.global_visible_module_paths.contains(source_path):
                global_paths.push(sema_owned_text(source_path))
        self.copy_module_graph_parts(&source.module_paths, &source.module_import_starts, &source.module_import_counts, &source.module_import_targets, &source.module_import_paths, &global_paths)

    mut fn copy_module_graph_parts(module_paths: &Vec[str], module_import_starts: &Vec[i32], module_import_counts: &Vec[i32], module_import_targets: &Vec[i32], module_import_paths: &Vec[str], global_paths: &Vec[str]):
        self.module_paths = sema_new_vec_str()
        self.module_import_starts = sema_new_vec_i32()
        self.module_import_counts = sema_new_vec_i32()
        self.module_import_targets = sema_new_vec_i32()
        self.module_import_paths = sema_new_vec_str()
        self.module_index_by_path = sema_new_map_str_i32()
        self.global_visible_module_paths = sema_new_map_str_i32()
        self.module_visibility_cache = sema_new_map_str_i32()

        for mi in 0..module_paths.len() as i32:
            let source_path = module_paths.get(mi as i64)
            self.module_paths.push(sema_owned_text(source_path))
            self.module_index_by_path.insert(sema_owned_text(source_path), mi)

        for gi in 0..global_paths.len() as i32:
            self.global_visible_module_paths.insert(sema_owned_text(global_paths.get(gi as i64)), 1)

        for i in 0..module_import_starts.len() as i32:
            self.module_import_starts.push(module_import_starts.get(i as i64))
        for i in 0..module_import_counts.len() as i32:
            self.module_import_counts.push(module_import_counts.get(i as i64))
        for i in 0..module_import_targets.len() as i32:
            self.module_import_targets.push(module_import_targets.get(i as i64))
        for i in 0..module_import_paths.len() as i32:
            self.module_import_paths.push(sema_owned_text(module_import_paths.get(i as i64)))

fn sema_builtin_symbols_zero -> SemaBuiltinSymbols:
    SemaBuiltinSymbols {
        task: 0,
        scoped_task: 0,
        scoped_join_handle: 0,
        channel: 0,
        send: 0,
        recv: 0,
        close: 0,
        cancel: 0,
        join_cleanup: 0,
        is_done: 0,
        was_cancelled: 0,
        todo: 0,
        unreachable: 0,
        track: 0,
        spawn_method: 0,
        src: 0,
        file_magic: 0,
        line_magic: 0,
        fn_magic: 0,
        embed_file: 0,
        copy_trait: 0,
        clone_trait: 0,
        send_trait: 0,
        sync_trait: 0,
        scoped_send_trait: 0,
        deref_trait: 0,
        deref_method: 0,
        drop: 0,
        self_type: 0,
        vec: 0,
        fixed_string: 0,
        veciter: 0,
        mapiter: 0,
        filteriter: 0,
        filtermapiter: 0,
        takeiter: 0,
        dropiter: 0,
        takewhileiter: 0,
        dropwhileiter: 0,
        zipiter: 0,
        enumerateiter: 0,
        chainiter: 0,
        zipwithiter: 0,
        stepbyiter: 0,
        flatmapiter: 0,
        vecslot: 0,
        veciterplace: 0,
        vecrange: 0,
        veciterref: 0,
        range_type: 0,
        range_inclusive_type: 0,
        iter_place: 0,
        iter_ref: 0,
        range_method: 0,
        split_at: 0,
        split_at_mut: 0,
        hashmapentry: 0,
        entry: 0,
        or_insert: 0,
        option: 0,
        result: 0,
        context_error: 0,
        hashmap: 0,
        hashset: 0,
        btreemap: 0,
        btreeset: 0,
        handle: 0,
        slotmap: 0,
        slotmapslot: 0,
        box: 0,
        regex: 0,
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
        slot: 0,
        get_disjoint: 0,
        filter: 0,
        filter_map: 0,
        map: 0,
        fold: 0,
        collect: 0,
        reduce: 0,
        take: 0,
        take_while: 0,
        drop_items: 0,
        drop_while: 0,
        zip: 0,
        zip_with: 0,
        enumerate: 0,
        chain: 0,
        step_by: 0,
        flat_map: 0,
        sum: 0,
        product: 0,
        min: 0,
        max: 0,
        min_by: 0,
        max_by: 0,
        find: 0,
        position: 0,
        any: 0,
        all: 0,
        none_pred: 0,
        for_each: 0,
        unzip: 0,
        count: 0,
        partition: 0,
        sequence: 0,
        traverse: 0,
        transpose: 0,
        clear: 0,
        pop: 0,
        set_i32: 0,
        keys: 0,
        values: 0,
        items: 0,
        next: 0,
        unwrap: 0,
        expect: 0,
        is_some: 0,
        is_none: 0,
        is_ok: 0,
        is_err: 0,
        starts_with: 0,
        ends_with: 0,
        trim: 0,
        to_lower: 0,
        to_upper: 0,
        lower: 0,
        upper: 0,
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

fn sema_visibility_cache_key(from_path: &str, to_path: &str) -> str:
    from_path ++ "->" ++ to_path

fn sema_empty_state(pool: InternPool, diags: DiagnosticList, ast: AstPool) -> Sema:
    let named_types = sema_new_map_i32_i32()
    let exact_type_cache_heads = sema_new_map_i64_i32()
    let type_decl_nodes = sema_new_map_i32_i32()
    let trait_decl_node_cache = sema_new_map_i32_i32()
    let type_decl_tids = sema_new_map_i32_i32()
    let pretty_symbol_names = sema_new_map_i32_str()
    let sig_lookup = sema_new_map_i32_i32()
    let extern_fn_names = sema_new_map_i32_i32()
    let retained_extern_params = sema_new_map_i32_i32()
    let fn_decl_nodes = sema_new_map_i32_i32()
    let fn_decl_effective_syms = sema_new_map_i32_i32()
    let fn_decl_source_paths = HashMap[i32, str].new()
    let fn_clause_group_lookup = sema_new_map_i32_i32()
    let fn_clause_body_dispatch = sema_new_map_i32_i32()
    let generic_fn_nodes = sema_new_map_i32_i32()
    let generic_fn_candidate_counts = sema_new_map_i32_i32()
    let variant_lookup = sema_new_map_i32_i32()
    let variant_type_ids = sema_new_map_i32_i32()
    let imported_variant_owners = sema_new_map_i32_i32()
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
    let no_await_guard_types = sema_new_map_i32_i32()
    let must_use_fns = sema_new_map_i32_i32()
    let result_option_fns = sema_new_map_i32_i32()
    let task_fns = sema_new_map_i32_i32()
    let no_alloc_fns = sema_new_map_i32_i32()
    let fn_may_alloc = sema_new_map_i32_i32()
    let fn_stack_sizes = sema_new_map_i32_i32()
    let generator_fn_yield_types = sema_new_map_i32_i32()
    let generator_fn_state_types = sema_new_map_i32_i32()
    let generator_fn_state_syms = sema_new_map_i32_i32()
    let generator_fn_next_syms = sema_new_map_i32_i32()
    let generator_next_fn_syms = sema_new_map_i32_i32()
    let generator_state_yield_types = sema_new_map_i32_i32()
    let generator_state_field_counts = sema_new_map_i32_i32()
    let generator_state_field_names = sema_new_map_i64_i32()
    let generator_state_field_types = sema_new_map_i64_i32()
    let mutable_global_syms = sema_new_map_i32_i32()
    let stable_global_syms = sema_new_map_i32_i32()
    let global_value_decl_kinds = sema_new_map_i32_i32()
    let global_race_mutated_syms = sema_new_map_i32_i32()
    let global_race_mutation_nodes = sema_new_map_i32_i32()
    let method_impl_nodes = sema_new_map_i32_i32()
    let method_decl_impl_nodes = sema_new_map_i32_i32()
    let method_decl_origins = sema_new_map_i32_i32()
    let method_has_inherent = sema_new_map_i32_i32()
    let method_symbol_flags = sema_new_map_i32_i32()
    let method_lookup = sema_method_lookup_new()
    let extension_method_owner_syms = sema_new_vec_i32()
    let extension_method_syms = sema_new_vec_i32()
    let extension_method_fn_syms = sema_new_vec_i32()
    let extension_method_sig_idxs = sema_new_vec_i32()
    let extension_method_paths = sema_new_vec_str()
    let qualified_extension_call_nodes = sema_new_map_i32_i32()
    let drop_method_cache = sema_new_map_i32_i32()
    let typed_expr_types = sema_new_map_i32_i32()
    let typed_binding_types = sema_new_map_i32_i32()
    let view_projection_exprs = sema_new_map_i32_i32()
    let drop_consumed_binding_values = sema_new_map_i32_i32()
    let typed_binding_names = sema_new_map_i32_i32()
    let typed_binding_muts = sema_new_map_i32_i32()
    let ephemeral_task_binding_nodes = sema_new_map_i32_i32()
    let typed_dump_seen_nodes = sema_new_map_i32_i32()
    let generic_specialization_cache = sema_new_map_str_i32()
    let generic_inst_cache = sema_new_map_i64_i32()
    let layout_size_cache: HashMap[i32, i64] = HashMap.new()
    let layout_align_cache: HashMap[i32, i64] = HashMap.new()
    let layout_field_offset_cache: HashMap[i64, i64] = HashMap.new()
    let is_copy_cache = sema_new_map_i32_i32()
    let needs_drop_result_cache = sema_new_map_i32_i32()
    let unwrapped_type_cache = sema_new_map_i32_i32()
    let for_element_type_cache = sema_new_map_i32_i32()
    let generic_struct_field_type_cache = sema_new_map_i64_i32()
    let generic_struct_field_index_type_cache = sema_new_map_i64_i32()
    let generic_enum_payload_cache_starts = sema_new_map_i64_i32()
    let generic_enum_payload_cache_counts = sema_new_map_i64_i32()
    let generic_enum_payload_cache_values: Vec[i32] = Vec.new()
    var s = Sema {
        pool: pool,
        diags: diags,
        ast: ast,
        decl_index_by_node: sema_new_map_i32_i32(),
        type_kinds: Vec.new(),
        type_d0: Vec.new(),
        type_d1: Vec.new(),
        type_d2: Vec.new(),
        type_extra: Vec.new(),
        exact_type_cache_heads,
        exact_type_cache_next: Vec.new(),
        named_types,
        type_decl_nodes,
        trait_decl_node_cache,
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
        sig_param_effects: Vec.new(),
        sig_param_direct_effects: Vec.new(),
        sig_param_view_origins: Vec.new(),
        sig_param_eff_starts: Vec.new(),
        sig_value_ref_abi_params: Vec.new(),
        mres_nodes: Vec.new(),
        mres_recv_types: Vec.new(),
        mres_owner_syms: Vec.new(),
        mres_method_syms: Vec.new(),
        mres_sigs: Vec.new(),
        mres_fn_syms: Vec.new(),
        mres_flags: Vec.new(),
        mres_cands_total: Vec.new(),
        mres_cands_visible: Vec.new(),
        sig_receiver_modes: Vec.new(),
        sig_receiver_required_effects: Vec.new(),
        effect_flow_edges: Vec.new(),
        effect_flow_projections: Vec.new(),
        consume_call_sites: Vec.new(),
        binding_use_seq: 0,
        binding_use_epoch: 0,
        binding_epoch_counter: 0,
        binding_last_use: HashMap.new(),
        field_last_use: HashMap.new(),
        effect_prov: HashMap.new(),
        effect_note_origin_node: 0,
        extern_fn_names,
        retained_extern_params,
        fn_decl_nodes,
        fn_decl_effective_syms,
        fn_decl_source_paths,
        fn_clause_group_lookup,
        fn_clause_group_names: Vec.new(),
        fn_clause_group_starts: Vec.new(),
        fn_clause_group_counts: Vec.new(),
        fn_clause_group_decls: Vec.new(),
        fn_clause_body_dispatch,
        task_param_consumed_memo: sema_new_map_i64_i32(),
        task_param_consumed_visiting: sema_new_map_i64_i32(),
        detached_task_stmt_nodes: sema_new_map_i32_i32(),
        generic_fn_nodes,
        generic_fn_candidate_counts,
        generic_fn_candidate_syms: Vec.new(),
        generic_fn_candidate_nodes: Vec.new(),
        resolved_generic_call_nodes: sema_new_map_i32_i32(),
        extension_method_owner_syms,
        extension_method_syms,
        extension_method_fn_syms,
        extension_method_sig_idxs,
        extension_method_paths,
        qualified_extension_call_nodes,
        variant_lookup,
        variant_type_ids,
        imported_variant_owners,
        disc_repr_types,
        disc_values,
        disc_has_payload,
        bitpacked_types: sema_new_map_i32_i32(),
        packed_types: sema_new_map_i32_i32(),
        repr_c_types: sema_new_map_i32_i32(),
        unsafe_fn_type_set: sema_new_map_i32_i32(),
        union_last_written: sema_new_map_i32_i32(),
        union_tracked_syms: Vec.new(),
        union_in_assign_target: 0,
        dyn_impl_starts: HashMap.new(),
        dyn_impl_counts: HashMap.new(),
        dyn_impl_flat_method_names: Vec.new(),
        dyn_impl_flat_sigs: Vec.new(),
        dyn_impl_flat_mono_syms: Vec.new(),
        trait_method_names: Vec.new(),
        trait_method_starts: Vec.new(),
        trait_method_counts: Vec.new(),
        trait_method_flags: Vec.new(),
        trait_method_param_starts: Vec.new(),
        trait_method_param_counts: Vec.new(),
        trait_method_ret_nodes: Vec.new(),
        trait_method_default_bodies: Vec.new(),
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
        impl_extra_is_std: Vec.new(),
        type_decl_nodes_by_tid: HashMap.new(),
        type_tid_is_std: HashMap.new(),
        type_sym_tier_mask: HashMap.new(),
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
        blanket_impl_nodes: Vec.new(),
        obligation_trait_syms: Vec.new(),
        obligation_type_syms: Vec.new(),
        obligation_nodes: Vec.new(),
        selection_cache,
        blanket_guard: HashSet.new(),
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
        no_await_guard_types,
        must_use_fns,
        result_option_fns,
        task_fns,
        no_alloc_fns,
        fn_may_alloc,
        fn_stack_sizes,
        generator_fn_yield_types,
        generator_fn_state_types,
        generator_fn_state_syms,
        generator_fn_next_syms,
        generator_next_fn_syms,
        generator_state_yield_types,
        generator_state_field_counts,
        generator_state_field_names,
        generator_state_field_types,
        mutable_global_syms,
        stable_global_syms,
        global_value_decl_kinds,
        global_race_access_syms: Vec.new(),
        global_race_access_nodes: Vec.new(),
        global_race_access_files: Vec.new(),
        global_race_access_paths: sema_new_vec_str(),
        global_race_access_kinds: Vec.new(),
        global_race_access_unsafe: Vec.new(),
        global_race_mutated_syms,
        global_race_mutation_nodes,
        global_race_concurrency_node: 0,
        global_race_concurrency_file: 0,
        global_race_concurrency_reason: "",
        syms: sema_builtin_symbols_zero(),
        method_impl_nodes,
        method_decl_impl_nodes,
        method_decl_origins,
        method_has_inherent,
        method_symbol_flags,
        method_lookup,
        drop_method_cache,
        copy_visit_stack: HashSet.new(),
        needs_drop_visit: HashSet.new(),
        current_drop_type_sym: 0,
        drop_control_flow_depth: 0,
        move_control_flow_depth: 0,
        move_control_flow_binding_starts: Vec.new(),
        move_control_flow_supports_drop_flags: Vec.new(),
        drop_consumed_field_owner_syms: Vec.new(),
        drop_consumed_field_syms: Vec.new(),
        bind_names: Vec.new(),
        bind_types: Vec.new(),
        bind_muts: Vec.new(),
        bind_states: Vec.new(),
        moved_field_base_syms: Vec.new(),
        explicitly_partial_syms: sema_new_map_i32_i32(),
        marking_explicit_move: 0,
        moved_field_path_starts: Vec.new(),
        moved_field_path_counts: Vec.new(),
        moved_field_path_syms: Vec.new(),
        bind_is_task: Vec.new(),
        bind_task_used: Vec.new(),
        bind_is_scoped_task: Vec.new(),
        bind_is_view_bound: Vec.new(),
        bind_provenance: Vec.new(),
        binding_decl_nodes: sema_new_map_i32_i32(),
        binding_value_nodes: sema_new_map_i32_i32(),
        scope_starts: Vec.new(),
        scope_name_map: HashMap.new(),
        pending_generic_binding_base: sema_new_map_i32_i32(),
        pending_generic_binding_call: sema_new_map_i32_i32(),
        pending_generic_binding_decl: sema_new_map_i32_i32(),
        async_scope_names: Vec.new(),
        sync_scope_names: Vec.new(),
        label_syms: Vec.new(),
        label_kinds: Vec.new(),
        label_nodes: Vec.new(),
        label_break_value_types: Vec.new(),
        label_loop_entry_binds: Vec.new(),
        label_break_off: Vec.new(),
        label_break_seen: Vec.new(),
        loop_break_flat: Vec.new(),
        loop_entry_flat: Vec.new(),
        fn_label_syms: Vec.new(),
        fn_label_nodes: Vec.new(),
        fn_label_paths: sema_new_vec_str(),
        fn_label_orders: Vec.new(),
        fn_label_used: Vec.new(),
        fn_goto_syms: Vec.new(),
        fn_goto_nodes: Vec.new(),
        fn_goto_paths: sema_new_vec_str(),
        fn_goto_orders: Vec.new(),
        fn_init_nodes: Vec.new(),
        fn_init_paths: sema_new_vec_str(),
        fn_init_orders: Vec.new(),
        fn_label_scope_stack: Vec.new(),
        fn_label_next_scope_id: 0,
        fn_label_order_counter: 0,
        borrow_kinds: Vec.new(),
        borrow_places: Vec.new(),
        borrow_fields: Vec.new(),
        borrow_refs: Vec.new(),
        borrow_path_starts: Vec.new(),
        borrow_path_counts: Vec.new(),
        borrow_path_data: Vec.new(),
        borrow_scope_depths: Vec.new(),
        borrow_creation_nodes: Vec.new(),
        current_block_extra_start: 0,
        current_block_stmt_count: 0,
        current_block_stmt_index: 0,
        current_block_tail: 0,
        capture_field_syms: Vec.new(),
        capture_field_kinds: Vec.new(),
        call_resolved_arg_starts: sema_new_map_i32_i32(),
        call_resolved_arg_counts: sema_new_map_i32_i32(),
        call_resolved_args_data: Vec.new(),
        call_resolved_default_arg_keys: sema_new_map_i64_i32(),
        resolved_call_sigs: sema_new_map_i32_i32(),
        resolved_call_mono_syms: sema_new_map_i32_i32(),
        magic_ident_kinds: sema_new_map_i32_i32(),
        implicit_binding_types: Vec.new(),
        implicit_binding_syms: Vec.new(),
        with_form_kinds: sema_new_map_i32_i32(),
        with_payload_types: sema_new_map_i32_i32(),
        with_enter_methods: sema_new_map_i32_i32(),
        with_exit_methods: sema_new_map_i32_i32(),
        with_enter_sigs: sema_new_map_i32_i32(),
        with_enter_mono_syms: sema_new_map_i32_i32(),
        with_exit_sigs: sema_new_map_i32_i32(),
        with_exit_mono_syms: sema_new_map_i32_i32(),
        no_await_guard_origin_roots: Vec.new(),
        no_await_guard_scope_depth: 0,
        no_suspend_scope_depth: 0,
        comp_resolved: sema_new_map_i32_i32(),
        comptime_selected_branches: sema_new_map_i32_i32(),
        pipeline_method_calls: sema_new_map_i32_i32(),
        pipeline_call_return_types: sema_new_map_i32_i32(),
        pipeline_carrier_kinds: sema_new_map_i32_i32(),
        operator_method_calls: sema_new_map_i32_i32(),
        operator_method_reversed: sema_new_map_i32_i32(),
        try_continue_tys: sema_new_map_i32_i32(),
        try_break_tys: sema_new_map_i32_i32(),
        try_branch_result_tys: sema_new_map_i32_i32(),
        try_branch_fns: sema_new_map_i32_i32(),
        try_from_break_fns: sema_new_map_i32_i32(),
        try_branch_sigs: sema_new_map_i32_i32(),
        try_branch_mono_syms: sema_new_map_i32_i32(),
        try_from_break_sigs: sema_new_map_i32_i32(),
        try_from_break_mono_syms: sema_new_map_i32_i32(),
        btree_insert_sigs: sema_new_map_i32_i32(),
        btree_insert_mono_syms: sema_new_map_i32_i32(),
        clone_contract_fns: sema_new_map_i32_i32(),
        clone_contract_sigs: sema_new_map_i32_i32(),
        clone_contract_mono_syms: sema_new_map_i32_i32(),
        autoderef_step_starts: sema_new_map_i32_i32(),
        autoderef_step_counts: sema_new_map_i32_i32(),
        slice_coerce_args: sema_new_map_i32_i32(),
        contextual_copy_adjustment_indices: sema_new_map_i64_i32(),
        contextual_copy_adjustments: Vec.new(),
        contextual_join_decision_indices: sema_new_map_i64_i32(),
        contextual_join_decisions: Vec.new(),
        contextual_join_arm_nodes: Vec.new(),
        contextual_join_arm_origin_nodes: Vec.new(),
        contextual_join_arm_types: Vec.new(),
        contextual_join_arm_kinds: Vec.new(),
        contextual_join_arm_roles: Vec.new(),
        contextual_join_origin_deps: Vec.new(),
        in_param_type_position: 0,
        autoderef_step_fns: Vec.new(),
        autoderef_step_tys: Vec.new(),
        pattern_value_syms: sema_new_map_i32_i32(),
        regex_capture_counts: sema_new_map_i32_i32(),
        regex_capture_name_starts: sema_new_map_i32_i32(),
        regex_capture_name_counts: sema_new_map_i32_i32(),
        regex_capture_name_syms: Vec.new(),
        typed_expr_types,
        typed_binding_types,
        view_projection_exprs,
        drop_consumed_binding_values,
        typed_binding_names,
        typed_binding_muts,
        ephemeral_task_binding_nodes,
        assign_target_revive_sym: 0,
        suspend_visiting: sema_new_map_i32_i32(),
        eph_task_visiting: sema_new_map_i32_i32(),
        typed_dump_seen_nodes,
        typed_dump_visit_budget: 0,
        generic_subst_param_syms: Vec.new(),
        generic_subst_type_ids: Vec.new(),
        generic_specialization_cache,
        concrete_specialization_by_sym: sema_new_map_i32_i32(),
        concrete_specialization_nodes: Vec.new(),
        concrete_specialization_syms: Vec.new(),
        concrete_specialization_sigs: Vec.new(),
        concrete_specialization_subst_starts: Vec.new(),
        concrete_specialization_subst_counts: Vec.new(),
        concrete_specialization_subst_syms: Vec.new(),
        concrete_specialization_subst_types: Vec.new(),
        concrete_specialization_param_starts: Vec.new(),
        concrete_specialization_param_counts: Vec.new(),
        concrete_specialization_param_types: Vec.new(),
        concrete_drop_sigs: sema_new_map_i32_i32(),
        concrete_drop_mono_syms: sema_new_map_i32_i32(),
        generic_inst_cache,
        layout_size_cache,
        layout_align_cache,
        layout_field_offset_cache,
        is_copy_cache,
        needs_drop_result_cache,
        unwrapped_type_cache,
        for_element_type_cache,
        generic_struct_field_type_cache,
        generic_struct_field_index_type_cache,
        generic_enum_payload_cache_starts,
        generic_enum_payload_cache_counts,
        generic_enum_payload_cache_values,
        assoc_type_bindings: sema_new_map_i32_i32(),
        symbols_frozen: 0,
        types_frozen: 0,
        current_fn_param_syms: Vec.new(),
        current_fn_param_effs: Vec.new(),
        current_fn_param_direct_effs: Vec.new(),
        current_fn_param_origins: Vec.new(),
        current_fn_param_view_nodes: Vec.new(),
        current_fn_sig_idx: -1,
        recording_propagated_effect: 0,
        closure_capture_summary_starts: sema_new_map_i32_i32(),
        closure_capture_summary_counts: sema_new_map_i32_i32(),
        closure_capture_summary_data: Vec.new(),
        binding_closure_nodes: sema_new_map_i32_i32(),
        binding_view_dep_data: Vec.new(),
        expr_view_param_origins: sema_new_map_i32_i32(),
        expr_view_dep_starts: sema_new_map_i32_i32(),
        expr_view_dep_counts: sema_new_map_i32_i32(),
        expr_view_dep_data: Vec.new(),
        alloc_site_nodes: Vec.new(),
        alloc_site_kinds: Vec.new(),
        alloc_site_fn_syms: Vec.new(),
        alloc_site_elided: Vec.new(),
        current_no_alloc_depth: 0,
        current_fn_may_alloc: 0,
        current_fn_symbol: 0,
        source_text: "",
        tracked_input_root: "",
        tracked_input_paths: sema_new_vec_str(),
        current_return_type: 0,
        current_gen_yield_type: 0,
        has_gen_yield_type: 0,
        in_pipeline_rhs: 0,
        match_in_stmt_pos: 0,
        current_for_comprehension_carrier: 0,
        in_comptime_fn: 0,
        in_concrete_generic_body: 0,
        in_async_fn: 0,
        no_std: 0,
        alloc: 0,
        runtime_available: 1,
        runtime_fiber_stack_size: 0,
        runtime_fiber_pool_size: 0,
        runtime_fiber_worker_count: 0,
        copy_warn_threshold: 128,
        emit_config_warnings: 0,
        lint_partial_statement_match: 0,
        overflow_mode: overflow_mode_default(),
        in_defer: 0,
        in_unsafe: 0,
        in_bitwise_literal_context: 0,
        unsafe_scope_used: Vec.new(),
        break_value_type: 0,
        has_break_value_type: 0,
        loop_depth: 0,
        stmt_pos_depth: 0,
        current_statement_expr_root: 0,
        current_value_expr_root: 0,
        closure_direct_arg_depth: 0,
        closure_direct_arg_escape_flags: Vec.new(),
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
        ty_cstr: 0, ty_cstr_view: 0,
        ty_usize: 0, ty_isize: 0, ty_const_i8_ptr: 0,
        ty_field_info: 0, ty_variant_info: 0,
        decl_source_paths: sema_new_vec_str(),
        decl_source_file_ids: Vec.new(),
        decl_is_c_import: Vec.new(),
        source_text_file_ids: Vec.new(),
        source_text_names: sema_new_vec_str(),
        source_texts: sema_new_vec_str(),
        source_line_offsets: Vec.new(),
        current_module_path: "",
        tool_mode_entry_path: "",
        module_paths: sema_new_vec_str(),
        module_import_starts: Vec.new(),
        module_import_counts: Vec.new(),
        module_import_targets: Vec.new(),
        module_import_paths: sema_new_vec_str(),
        module_index_by_path: sema_new_map_str_i32(),
        global_visible_module_paths: sema_new_map_str_i32(),
        module_visibility_cache: sema_new_map_str_i32(),
        named_type_candidate_syms: Vec.new(),
        named_type_candidate_tids: Vec.new(),
        named_type_candidate_paths: sema_new_vec_str(),
        named_type_candidate_pub: Vec.new(),
        named_type_candidate_heads: sema_new_map_i32_i32(),
        named_type_candidate_next: Vec.new(),
        decl_visibility_syms: Vec.new(),
        decl_visibility_paths: sema_new_vec_str(),
        decl_visibility_pub: Vec.new(),
        decl_visibility_nodes: Vec.new(),
        ci_syms: sema_new_map_i32_i32(),
        ci_raw_syms: sema_new_map_i32_i32(),
        ci_omitted_symbols: HashMap.new(),
        ci_modules: sema_new_map_i32_i32(),
        scoping_active: 0,
        current_module_has_ci: 0,
        reachable_seen: sema_new_map_i32_i32(),
        reachable_visiting: sema_new_map_i32_i32(),
        reachable_decl_indices: sema_new_map_i32_i32(),
    }
    s.rebuild_decl_index()
    return s

fn Sema.placeholder(pool: InternPool, diags: DiagnosticList, ast: AstPool) -> Sema:
    return sema_empty_state(pool, move diags, ast)

// #602: mark param `idx` of extern/c_import fn `name_sym` as retaining its ptr.
impl Sema:
    mut fn mark_param_retained(name_sym: i32, idx: i32):
        if name_sym == 0 or idx < 0 or idx >= 31:
            return
        let existing = if self.retained_extern_params.contains(name_sym): self.retained_extern_params.get(name_sym).unwrap() else: 0
        self.retained_extern_params.insert(name_sym, existing | (1 << (idx as u32)))

    fn param_is_retained(name_sym: i32, idx: i32) -> i32:
        if name_sym == 0 or idx < 0 or idx >= 31:
            return 0
        if not self.retained_extern_params.contains(name_sym):
            return 0
        let mask = self.retained_extern_params.get(name_sym).unwrap()
        if (mask & (1 << (idx as u32))) != 0: 1 else: 0

    // #602: parse a `retains:` entry of the form "fnname(idx)" and register it.
    mut fn register_retains_entry(entry_sym: i32):
        let text = self.pool_resolve_symbol(entry_sym)
        let n = text.len() as i32
        var paren = -1
        for i in 0..n:
            if text.byte_at(i as i64) == 40:
                paren = i
                break
        if paren <= 0:
            return
        let fn_name = text.slice(0, paren as i64)
        var idx = 0
        var got = 0
        var j = paren + 1
        while j < n:
            let c = text.byte_at(j as i64)
            if c >= 48 and c <= 57:
                idx = idx * 10 + (c - 48)
                got = 1
                j = j + 1
            else:
                break
        if got == 0:
            return
        let fn_sym = self.pool_intern(fn_name)
        self.mark_param_retained(fn_sym, idx)

    // #602: read a c_import node's `retains:` record (appended after the #357
    // ownership record) and register each entry. Layout after extra_start:
    // links, allow, no_methods (packed counts), then strict(1), only_count(1),
    // only..., owns_count(1), owns..., borrows_count(1), borrows...,
    // retains_count(1), retains...
    mut fn read_c_import_retentions(c_import_node: i32):
        let extra_start = self.ast.get_data1(c_import_node)
        let packed = self.ast.get_data2(c_import_node)
        let extra_len = self.ast.extra_len()
        var ep = extra_start + c_import_link_count(packed) + c_import_allow_count(packed) + c_import_no_methods_count(packed)
        ep = ep + 1
        if ep < 0 or ep >= extra_len:
            return
        let only_count = self.ast.get_extra(ep)
        if only_count < 0 or only_count > 65536:
            return
        ep = ep + 1 + only_count
        if ep < 0 or ep >= extra_len:
            return
        let owns_count = self.ast.get_extra(ep)
        if owns_count < 0 or owns_count > 65536:
            return
        ep = ep + 1 + owns_count
        if ep < 0 or ep >= extra_len:
            return
        let borrows_count = self.ast.get_extra(ep)
        if borrows_count < 0 or borrows_count > 65536:
            return
        ep = ep + 1 + borrows_count
        if ep < 0 or ep >= extra_len:
            return
        let retains_count = self.ast.get_extra(ep)
        if retains_count <= 0 or retains_count > 65536:
            return
        ep = ep + 1
        if ep + retains_count > extra_len:
            return
        for i in 0..retains_count:
            self.register_retains_entry(self.ast.get_extra(ep + i))

fn Sema.init(pool: InternPool, diags: DiagnosticList, ast: AstPool) -> Sema:
    var s = sema_empty_state(pool, move diags, ast)

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
    let cstr_field_names: Vec[str] = Vec.new()
    cstr_field_names.push("ptr")
    cstr_field_names.push("len")
    let cstr_field_types: Vec[i32] = Vec.new()
    cstr_field_types.push(s.ty_const_i8_ptr as i32)
    cstr_field_types.push(s.ty_i64 as i32)
    s.ty_cstr = s.register_builtin_struct_type("CStr", cstr_field_names, cstr_field_types, 2) as TypeId
    s.ty_cstr_view = s.add_type(TypeKind.TY_REF, s.ty_cstr, 0, 0)

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
    s.register_prim("Int", s.ty_i64)
    s.register_prim("i128", s.ty_i128)
    s.register_prim("u8", s.ty_u8)
    s.register_prim("u16", s.ty_u16)
    s.register_prim("u32", s.ty_u32)
    s.register_prim("u64", s.ty_u64)
    s.register_prim("UInt", s.ty_u64)
    s.register_prim("u128", s.ty_u128)
    s.register_prim("f32", s.ty_f32)
    s.register_prim("f64", s.ty_f64)
    s.register_prim("bool", s.ty_bool)
    s.register_prim("Unit", s.ty_void)
    s.register_prim("Never", s.ty_never)
    s.register_prim("str", s.ty_str)
    s.register_prim("String", s.ty_str)
    s.register_prim("StrView", s.ty_str_view)
    s.register_prim("CStr", s.ty_cstr)
    s.register_prim("usize", s.ty_usize)
    s.register_prim("isize", s.ty_isize)
    s.init_builtin_reflection_types()
    s.discard_sym = s.pool_intern("_")

    // Push root scope marker
    s.scope_starts.push(0)
    s.init_intrinsic_symbols()
    s

impl Sema:
    mut fn set_tracked_input_context(root: &str, paths: &Vec[str]):
        self.tracked_input_root = sema_owned_text(root)
        self.tracked_input_paths = sema_clone_str_vec(paths)

    mut fn record_tracked_input(path: &str):
        var paths = move self.tracked_input_paths
        self.tracked_input_paths = tracked_input_insert_unique(move paths, path)

    mut fn merge_tracked_inputs(paths: &Vec[str]):
        var tracked_paths = move self.tracked_input_paths
        self.tracked_input_paths = tracked_input_merge_unique(move tracked_paths, paths)

    mut fn read_tracked_embed_file(source_path: &str, raw_path: &str) -> TrackedReadResult:
        let result = tracked_embed_read(source_path, raw_path, self.tracked_input_root)
        if result.ok:
            self.record_tracked_input(result.resolved_path)
        result

    mut fn register_prim(name: &str, tid: i32):
        let sym = self.pool_intern(name)
        self.record_named_type(sym, tid)

    mut fn record_named_type(sym: i32, tid: i32) -> Unit:
        self.record_named_type_with_pub(sym, tid, 1)

    fn named_type_candidate_head(sym: i32) -> i32:
        if self.named_type_candidate_heads.contains(sym):
            return self.named_type_candidate_heads.get(sym).unwrap()
        -1

    fn index_named_type_candidate(sym: i32, candidate_index: i32):
        self.named_type_candidate_next.push(self.named_type_candidate_head(sym))
        self.named_type_candidate_heads.insert(sym, candidate_index)

    mut fn rebuild_named_type_candidate_index():
        self.named_type_candidate_heads = sema_new_map_i32_i32()
        self.named_type_candidate_next = Vec.new()
        for candidate_index in 0..self.named_type_candidate_syms.len() as i32:
            self.index_named_type_candidate(
                self.named_type_candidate_syms.get(candidate_index as i64),
                candidate_index,
            )

    mut fn record_named_type_with_pub(sym: i32, tid: i32, is_pub: i32) -> Unit:
        self.named_types.insert(sym, tid)
        self.index_named_type_candidate(sym, self.named_type_candidate_syms.len() as i32)
        self.named_type_candidate_syms.push(sym)
        self.named_type_candidate_tids.push(tid)
        let path = if self.current_module_path.len() > 0: self.current_module_path else: ""
        self.named_type_candidate_paths.push(sema_owned_text(path))
        self.named_type_candidate_pub.push(is_pub)

    fn record_decl_visibility(sym: i32, node: i32, is_pub: i32) -> Unit:
        if sym == 0:
            return
        self.decl_visibility_syms.push(sym)
        let path = if self.current_module_path.len() > 0: self.current_module_path else: ""
        self.decl_visibility_paths.push(sema_owned_text(path))
        self.decl_visibility_pub.push(is_pub)
        self.decl_visibility_nodes.push(node)

    fn decl_visible_from_current(target_path: &str, is_pub: i32) -> i32:
        if target_path.len() == 0:
            return 1
        if self.current_module_path.len() == 0:
            return 1
        if target_path == self.current_module_path:
            return 1
        if sema_path_is_compiler_hook_runner(self.current_module_path) != 0:
            return 1
        if sema_paths_share_internal_implementation_boundary(self.current_module_path, target_path) != 0:
            return 1
        if is_pub == 0:
            return 0
        self.module_is_visible_from_current(target_path)

    // D29 scaffolding (#750): name-aware visibility. Two rules on top of
    // decl_visible_from_current, applied before its internal-boundary and
    // reachability shortcuts:
    //   1. std blindness — a std implementation module never resolves a
    //      user-tier declaration. The flat merge let newer user decls hijack
    //      std-internal references (user `type Regex` rebound regex.w).
    //   2. prelude gate — a prelude-closure declaration is ambient only for
    //      the §18.2 enumerated names; any other std name resolves from user
    //      code only through an explicit import path (never the synthetic
    //      prelude edge). Replaced by the D fallback tier when #751 lands.
    fn decl_visible_from_current_gated(target_path: &str, is_pub: i32, sym: i32) -> i32:
        if target_path.len() == 0:
            return 1
        if self.current_module_path.len() == 0:
            return 1
        if target_path == self.current_module_path:
            return 1
        if sema_path_is_compiler_hook_runner(self.current_module_path) != 0:
            return 1
        let current_is_std = sema_tier_path_is_std_implementation(self.current_module_path)
        let target_is_std = sema_tier_path_is_std_implementation(target_path)
        if current_is_std != 0 and target_is_std == 0:
            return 0
        if current_is_std == 0 and target_is_std != 0 and self.module_in_prelude_closure(target_path) != 0:
            if sema_prelude_gate_allows_name(self.pool_resolve(sym)) == 0:
                if self.module_visible_no_prelude(target_path) == 0:
                    return 0
        self.decl_visible_from_current(target_path, is_pub)

    fn module_in_prelude_closure(path: &str) -> i32:
        if self.global_visible_module_paths.contains(path): 1 else: 0

    // Reachability over explicit import edges only: the synthetic prelude
    // edge and the global prelude-closure shortcut are excluded, so this
    // answers "did the user actually import a path to this module?".
    fn module_visible_no_prelude(target_path: &str) -> i32:
        if self.current_module_path.len() == 0:
            return 1
        if target_path == self.current_module_path:
            return 1
        if not self.module_index_by_path.contains(with_str_clone_ref(self.current_module_path)):
            return 0
        if not self.module_index_by_path.contains(target_path):
            return 0
        let cache_key = "noprelude|" ++ sema_visibility_cache_key(self.current_module_path, target_path)
        if self.module_visibility_cache.contains(cache_key):
            return self.module_visibility_cache.get(cache_key).unwrap()
        let start_idx: i32 = self.module_index_by_path.get(with_str_clone_ref(self.current_module_path)).unwrap()
        let target_idx: i32 = self.module_index_by_path.get(target_path).unwrap()
        let seen: HashMap[i32, i32] = sema_new_map_i32_i32()
        let stack: Vec[i32] = Vec.new()
        stack.push(start_idx)
        while stack.len() as i32 > 0:
            let last = stack.len() as i32 - 1
            let current: i32 = stack.get(last as i64)
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
                    let idx = edge_start + ei
                    if idx >= 0 and idx < self.module_import_paths.len() as i32:
                        let ip: str = with_str_clone_ref(self.module_import_paths.get(idx as i64))
                        if ip == "std.prelude" or ip == "std.prelude_core" or ip == "std.prelude_alloc":
                            continue
                        stack.push(self.module_import_targets.get(idx as i64))
        self.module_visibility_cache.insert(sema_owned_text(cache_key), 0)
        0

    fn symbol_visible_from_current(sym: i32) -> i32:
        let symbol_name = self.pool_resolve(sym)
        if symbol_name.starts_with("with_") or symbol_name.starts_with("rt_") or symbol_name.starts_with("wl_"):
            return 1
        // D29 (#750): an extern declaration names a global C symbol — one
        // contract in every tier, and the frontend dedups the decls across
        // tiers — so tier gating and blindness do not apply.
        if self.extern_fn_names.contains(sym):
            return 1
        if self.ci_syms.contains(sym) and self.is_ci_visible(sym) != 0:
            return 1
        var saw_candidate = 0
        var i = self.decl_visibility_syms.len() as i32 - 1
        while i >= 0:
            if self.decl_visibility_syms.get(i as i64) == sym:
                saw_candidate = 1
                let path = self.decl_visibility_paths.get(i as i64)
                let is_pub = self.decl_visibility_pub.get(i as i64)
                if self.decl_visible_from_current_gated(path, is_pub, sym) != 0:
                    return 1
            i = i - 1
        if saw_candidate == 0:
            return 1
        0

    fn decl_node_visible_from_current(node: i32) -> i32:
        if node == 0:
            return 1
        var i = self.decl_visibility_nodes.len() as i32 - 1
        while i >= 0:
            if self.decl_visibility_nodes.get(i as i64) == node:
                return self.decl_visible_from_current(self.decl_visibility_paths.get(i as i64), self.decl_visibility_pub.get(i as i64))
            i = i - 1
        1

    fn has_extern_var_decl(sym: i32) -> i32:
        let target_name = self.pool_resolve(sym)
        for di in 0..self.ast.decl_count():
            let decl = self.ast.get_decl(di)
            if self.ast.kind(decl) != NodeKind.NK_EXTERN_VAR:
                continue
            let extern_sym = self.ast.get_data0(decl)
            if extern_sym != sym and self.pool_resolve(extern_sym) != target_name:
                continue
            return 1
        0

    fn private_symbol_path_from_current(sym: i32) -> str:
        var i = self.decl_visibility_syms.len() as i32 - 1
        while i >= 0:
            if self.decl_visibility_syms.get(i as i64) == sym:
                let path = self.decl_visibility_paths.get(i as i64)
                let is_pub = self.decl_visibility_pub.get(i as i64)
                if path.len() > 0 and path != self.current_module_path and is_pub == 0 and self.module_is_visible_from_current(path) != 0:
                    return with_str_clone_ref(path)
            i = i - 1
        ""

    // D29 scaffolding (#750): when a name failed resolution only because the
    // prelude gate requires an import, name the exact use line. The message
    // suffix "; add: use <module>.<name>" is a stable contract consumed by
    // tools/insert_std_uses.w and the migrator's self-fix pass.
    fn std_gated_import_note(sym: i32) -> str:
        if sym == 0:
            return ""
        let name = self.pool_resolve(sym)
        if name.len() == 0 or sema_prelude_gate_allows_name(name) != 0:
            return ""
        var modules = sema_new_vec_str()
        var i = 0
        while i < self.named_type_candidate_syms.len() as i32:
            if self.named_type_candidate_syms.get(i as i64) == sym and self.named_type_candidate_pub.get(i as i64) != 0:
                let path = self.named_type_candidate_paths.get(i as i64)
                if sema_tier_path_is_std_implementation(path) != 0 and self.module_in_prelude_closure(path) != 0:
                    let dotted = sema_std_module_dotted(path)
                    if dotted.len() > 0 and sema_vec_str_contains(&modules, dotted) == 0:
                        modules.push(sema_owned_text(dotted))
            i = i + 1
        i = 0
        while i < self.decl_visibility_syms.len() as i32:
            if self.decl_visibility_syms.get(i as i64) == sym and self.decl_visibility_pub.get(i as i64) != 0:
                let path = self.decl_visibility_paths.get(i as i64)
                if sema_tier_path_is_std_implementation(path) != 0 and self.module_in_prelude_closure(path) != 0:
                    let dotted = sema_std_module_dotted(path)
                    if dotted.len() > 0 and sema_vec_str_contains(&modules, dotted) == 0:
                        modules.push(sema_owned_text(dotted))
            i = i + 1
        if modules.len() as i32 == 0:
            return ""
        if modules.len() as i32 == 1:
            return "; add: use " ++ modules.get(0) ++ "." ++ name
        var listed = ""
        for mi in 0..modules.len() as i32:
            if mi > 0:
                listed = listed ++ " | "
            listed = listed ++ "use " ++ modules.get(mi as i64) ++ "." ++ name
        "; candidates: " ++ listed

    mut fn emit_private_symbol_error(sym: i32, node: i32) -> Unit:
        let name: str = with_str_clone_ref(self.pool_resolve(sym))
        let gate_note = self.std_gated_import_note(sym)
        if gate_note.len() > 0:
            self.emit_error("'" ++ name ++ "' requires an explicit import (§18.1)" ++ gate_note, node)
            return
        let path = self.private_symbol_path_from_current(sym)
        if path.len() > 0:
            self.emit_error("symbol '" ++ name ++ "' is private to module '" ++ path ++ "'", node)
        else:
            self.emit_error("symbol '" ++ name ++ "' is not visible from this module", node)

    fn module_is_visible_from_current(target_path: &str) -> i32:
        if target_path.len() == 0:
            return 1
        if self.global_visible_module_paths.contains(target_path):
            return 1
        if self.current_module_path.len() == 0:
            return 1
        if target_path == self.current_module_path:
            return 1
        if not self.module_index_by_path.contains(with_str_clone_ref(self.current_module_path)):
            return 1
        if not self.module_index_by_path.contains(target_path):
            return 1
        let cache_key = sema_visibility_cache_key(self.current_module_path, target_path)
        if self.module_visibility_cache.contains(cache_key):
            return self.module_visibility_cache.get(cache_key).unwrap()
        let start_idx: i32 = self.module_index_by_path.get(with_str_clone_ref(self.current_module_path)).unwrap()
        let target_idx: i32 = self.module_index_by_path.get(target_path).unwrap()
        if start_idx == target_idx:
            self.module_visibility_cache.insert(sema_owned_text(cache_key), 1)
            return 1
        let seen: HashMap[i32, i32] = sema_new_map_i32_i32()
        let stack: Vec[i32] = Vec.new()
        stack.push(start_idx)
        while stack.len() as i32 > 0:
            let last = stack.len() as i32 - 1
            let current: i32 = stack.get(last as i64)
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

    fn lookup_named_type_visible(sym: i32) -> i32:
        self.lookup_named_type_filtered(sym, 1)

    // Ambient lookup for compiler-demand resolutions (regex literals, async
    // Task synthesis, dyn boxing): lowerings the user never spelled bypass
    // the D29 prelude gate, but still honor module privacy.
    fn lookup_named_type_ambient(sym: i32) -> i32:
        self.lookup_named_type_filtered(sym, 0)

    // D29 scaffolding (#750): registration-truth lookup for codegen. Picks the
    // candidate declared in the requested tier, ignoring module visibility —
    // codegen runs after checking and needs the layout of a specific tier's
    // decl, not a context-relative resolution.
    fn lookup_named_type_for_tier(sym: i32, want_std: i32) -> i32:
        var i = self.named_type_candidate_head(sym)
        while i >= 0:
            let path = self.named_type_candidate_paths.get(i as i64)
            if path.len() > 0:
                let cand_std = if sema_tier_path_is_std_implementation(path) != 0: 1 else: 0
                if cand_std == want_std:
                    return self.named_type_candidate_tids.get(i as i64)
            i = self.named_type_candidate_next.get(i as i64)
        if self.named_types.contains(sym): self.named_types.get(sym).unwrap() else: 0

    fn lookup_named_type_filtered(sym: i32, gated: i32) -> i32:
        let named_tid = if self.named_types.contains(sym): self.named_types.get(sym).unwrap() else: 0
        var global_tid = 0
        var saw_recorded = 0
        var saw_named_tid = 0
        var i = self.named_type_candidate_head(sym)
        while i >= 0:
            saw_recorded = 1
            let candidate_tid = self.named_type_candidate_tids.get(i as i64)
            let candidate_path = self.named_type_candidate_paths.get(i as i64)
            let candidate_pub = self.named_type_candidate_pub.get(i as i64)
            if named_tid != 0 and candidate_tid == named_tid:
                saw_named_tid = 1
            let candidate_visible = if gated != 0: self.decl_visible_from_current_gated(candidate_path, candidate_pub, sym) else: self.decl_visible_from_current(candidate_path, candidate_pub)
            if candidate_path.len() == 0:
                if global_tid == 0:
                    global_tid = candidate_tid
            else if candidate_visible != 0:
                return candidate_tid
            i = self.named_type_candidate_next.get(i as i64)
        if named_tid != 0 and (saw_recorded == 0 or saw_named_tid == 0):
            return named_tid
        if global_tid != 0:
            return global_tid
        0

    fn has_named_type_visible(sym: i32) -> i32:
        if self.lookup_named_type_visible(sym) != 0:
            return 1
        0

    fn typeinfo_builtin_shadowed(sym: i32) -> i32:
        if self.scope_lookup(sym) >= 0:
            return 1
        if self.has_named_type_visible(sym) != 0:
            return 1
        0

    fn typeinfo_module_field(callee: i32) -> i32:
        var access = callee
        let kind = self.ast.kind(callee)
        if kind == NodeKind.NK_INDEX:
            access = self.ast.get_data0(callee)
        else if kind != NodeKind.NK_FIELD_ACCESS:
            return 0
        if self.ast.kind(access) != NodeKind.NK_FIELD_ACCESS:
            return 0
        let recv = self.ast.get_data0(access)
        if self.ast.kind(recv) != NodeKind.NK_IDENT:
            return 0
        let recv_sym = self.ast.get_data0(recv)
        if self.pool_resolve(recv_sym) != "TypeInfo":
            return 0
        if self.typeinfo_builtin_shadowed(recv_sym) != 0:
            return 0
        self.ast.get_data1(access)

    fn typeinfo_module_type_arg_count(callee: i32) -> i32:
        if self.ast.kind(callee) != NodeKind.NK_INDEX:
            return 0
        if self.ast.get_data2(callee) != 0:
            return 2
        1

    fn typeinfo_module_type_arg_node(callee: i32, index: i32) -> i32:
        if self.ast.kind(callee) != NodeKind.NK_INDEX:
            return 0
        if index == 0:
            return self.ast.get_data1(callee)
        if index == 1:
            return self.ast.get_data2(callee)
        0

    mut fn register_builtin_struct_type(name: &str, field_names: &Vec[str], field_types: &Vec[i32], field_count: i32) -> i32:
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

    mut fn init_builtin_reflection_types():
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

    mut fn init_intrinsic_symbols():
        self.syms.task = self.pool_intern("Task")
        self.syms.scoped_task = self.pool_intern("ScopedTask")
        self.syms.scoped_join_handle = self.pool_intern("ScopedJoinHandle")
        self.syms.channel = self.pool_intern("Channel")
        self.syms.send = self.pool_intern("send")
        self.syms.recv = self.pool_intern("recv")
        self.syms.close = self.pool_intern("close")
        self.syms.cancel = self.pool_intern("cancel")
        self.syms.join_cleanup = self.pool_intern("join_cleanup")
        self.syms.is_done = self.pool_intern("is_done")
        self.syms.was_cancelled = self.pool_intern("was_cancelled")
        self.syms.todo = self.pool_intern("todo")
        self.syms.unreachable = self.pool_intern("unreachable")
        self.syms.track = self.pool_intern("track")
        self.syms.spawn_method = self.pool_intern("spawn")
        self.syms.src = self.pool_intern("src")
        self.syms.file_magic = self.pool_intern("__FILE__")
        self.syms.line_magic = self.pool_intern("__LINE__")
        self.syms.fn_magic = self.pool_intern("__FN__")
        self.syms.embed_file = self.pool_intern("embed_file")
        self.syms.copy_trait = self.pool_intern("Copy")
        self.syms.clone_trait = self.pool_intern("Clone")
        self.syms.send_trait = self.pool_intern("Send")
        self.syms.sync_trait = self.pool_intern("Sync")
        self.syms.scoped_send_trait = self.pool_intern("ScopedSend")
        self.syms.deref_trait = self.pool_intern("Deref")
        self.syms.deref_method = self.pool_intern("deref")
        self.syms.regex = self.pool_intern("Regex")
        self.syms.drop = self.pool_intern("Drop")
        self.syms.self_type = self.pool_intern("Self")
        self.syms.vec = self.pool_intern("Vec")
        self.syms.fixed_string = self.pool_intern("FixedString")
        self.syms.veciter = self.pool_intern("VecIter")
        self.syms.mapiter = self.pool_intern("MapIter")
        self.syms.filteriter = self.pool_intern("FilterIter")
        self.syms.filtermapiter = self.pool_intern("FilterMapIter")
        self.syms.takeiter = self.pool_intern("TakeIter")
        self.syms.dropiter = self.pool_intern("DropIter")
        self.syms.takewhileiter = self.pool_intern("TakeWhileIter")
        self.syms.dropwhileiter = self.pool_intern("DropWhileIter")
        self.syms.zipiter = self.pool_intern("ZipIter")
        self.syms.enumerateiter = self.pool_intern("EnumerateIter")
        self.syms.chainiter = self.pool_intern("ChainIter")
        self.syms.zipwithiter = self.pool_intern("ZipWithIter")
        self.syms.stepbyiter = self.pool_intern("StepByIter")
        self.syms.flatmapiter = self.pool_intern("FlatMapIter")
        self.syms.vecslot = self.pool_intern("VecSlot")
        self.syms.veciterplace = self.pool_intern("VecIterPlace")
        self.syms.vecrange = self.pool_intern("VecRange")
        self.syms.veciterref = self.pool_intern("VecIterRef")
        self.syms.range_type = self.pool_intern("Range")
        self.syms.range_inclusive_type = self.pool_intern("RangeInclusive")
        self.syms.iter_place = self.pool_intern("iter_place")
        self.syms.iter_ref = self.pool_intern("iter_ref")
        self.syms.range_method = self.pool_intern("range")
        self.syms.split_at = self.pool_intern("split_at")
        self.syms.split_at_mut = self.pool_intern("split_at_mut")
        self.syms.hashmapentry = self.pool_intern("HashMapEntry")
        self.syms.entry = self.pool_intern("entry")
        self.syms.or_insert = self.pool_intern("or_insert")
        self.syms.option = self.pool_intern("Option")
        self.syms.result = self.pool_intern("Result")
        self.syms.context_error = self.pool_intern("ContextError")
        self.syms.hashmap = self.pool_intern("HashMap")
        self.syms.hashset = self.pool_intern("HashSet")
        self.syms.btreemap = self.pool_intern("BTreeMap")
        self.syms.btreeset = self.pool_intern("BTreeSet")
        self.syms.handle = self.pool_intern("Handle")
        self.syms.slotmap = self.pool_intern("SlotMap")
        self.syms.slotmapslot = self.pool_intern("SlotMapSlot")
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
        self.syms.slot = self.pool_intern("slot")
        self.syms.get_disjoint = self.pool_intern("get_disjoint")
        self.syms.filter = self.pool_intern("filter")
        self.syms.filter_map = self.pool_intern("filter_map")
        self.syms.map = self.pool_intern("map")
        self.syms.fold = self.pool_intern("fold")
        self.syms.collect = self.pool_intern("collect")
        self.syms.reduce = self.pool_intern("reduce")
        self.syms.take = self.pool_intern("take")
        self.syms.take_while = self.pool_intern("take_while")
        self.syms.drop_items = self.pool_intern("drop")
        self.syms.drop_while = self.pool_intern("drop_while")
        self.syms.zip = self.pool_intern("zip")
        self.syms.zip_with = self.pool_intern("zip_with")
        self.syms.enumerate = self.pool_intern("enumerate")
        self.syms.chain = self.pool_intern("chain")
        self.syms.step_by = self.pool_intern("step_by")
        self.syms.flat_map = self.pool_intern("flat_map")
        self.syms.sum = self.pool_intern("sum")
        self.syms.product = self.pool_intern("product")
        self.syms.min = self.pool_intern("min")
        self.syms.max = self.pool_intern("max")
        self.syms.min_by = self.pool_intern("min_by")
        self.syms.max_by = self.pool_intern("max_by")
        self.syms.find = self.pool_intern("find")
        self.syms.position = self.pool_intern("position")
        self.syms.any = self.pool_intern("any")
        self.syms.all = self.pool_intern("all")
        self.syms.none_pred = self.pool_intern("none")
        self.syms.for_each = self.pool_intern("for_each")
        self.syms.unzip = self.pool_intern("unzip")
        self.syms.count = self.pool_intern("count")
        self.syms.partition = self.pool_intern("partition")
        self.syms.sequence = self.pool_intern("sequence")
        self.syms.traverse = self.pool_intern("traverse")
        self.syms.transpose = self.pool_intern("transpose")
        self.syms.clear = self.pool_intern("clear")
        self.syms.pop = self.pool_intern("pop")
        self.syms.set_i32 = self.pool_intern("set_i32")
        self.syms.keys = self.pool_intern("keys")
        self.syms.values = self.pool_intern("values")
        self.syms.items = self.pool_intern("items")
        self.syms.next = self.pool_intern("next")
        self.syms.unwrap = self.pool_intern("unwrap")
        self.syms.expect = self.pool_intern("expect")
        self.syms.is_some = self.pool_intern("is_some")
        self.syms.is_none = self.pool_intern("is_none")
        self.syms.is_ok = self.pool_intern("is_ok")
        self.syms.is_err = self.pool_intern("is_err")
        self.syms.starts_with = self.pool_intern("starts_with")
        self.syms.ends_with = self.pool_intern("ends_with")
        self.syms.trim = self.pool_intern("trim")
        self.syms.to_lower = self.pool_intern("to_lower")
        self.syms.to_upper = self.pool_intern("to_upper")
        self.syms.lower = self.pool_intern("lower")
        self.syms.upper = self.pool_intern("upper")
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
        self.lang_trait_syms.insert(self.syms.copy_trait, 1)
        self.lang_trait_syms.insert(self.syms.drop, 1)
        self.lang_trait_syms.insert(self.syms.send_trait, 1)
        self.lang_trait_syms.insert(self.syms.sync_trait, 1)
        self.lang_trait_syms.insert(self.syms.scoped_send_trait, 1)
        self.lang_trait_syms.insert(self.pool_intern("Scoped"), 1)
        self.lang_trait_syms.insert(self.pool_intern("ScopedMut"), 1)
        self.lang_trait_syms.insert(self.pool_intern("Error"), 1)

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

fn extract_name_after_keyword_in_text(text: &str, keyword: &str) -> str:
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

fn extract_param_name_from_segment(segment: &str) -> str:
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

fn extract_fn_param_name_in_text(text: &str, param_index: i32) -> str:
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

fn sema_source_line_offsets(text: &str):
    let offsets: Vec[i32] = Vec.new()
    offsets.push(0)
    for i in 0..text.len():
        if text.byte_at(i) == 10:
            offsets.push(i as i32 + 1)
    offsets

impl Sema:
    mut fn prepare_source_line_offsets():
        self.source_line_offsets = Vec.new()
        self.source_line_offsets.push(sema_source_line_offsets(self.source_text))
        for si in 0..self.source_texts.len() as i32:
            self.source_line_offsets.push(sema_source_line_offsets(self.source_texts.get(si as i64)))

    fn source_location_for_file_id(file_id: i32, offset: i32) -> SemaSourceLocation:
        var source_index = 0
        if file_id != 0:
            for si in 0..self.source_text_file_ids.len() as i32:
                if self.source_text_file_ids.get(si as i64) == file_id:
                    source_index = si + 1
                    break
        if source_index >= self.source_line_offsets.len() as i32:
            sema_phase_bug("source line offsets were not prepared before MIR lowering")
        let offsets = self.source_line_offsets.get(source_index as i64)
        var clamped = offset
        if clamped < 0:
            clamped = 0
        let source_len = if source_index == 0: self.source_text.len() as i32 else: self.source_texts.get((source_index - 1) as i64).len() as i32
        if clamped > source_len:
            clamped = source_len
        var lo = 0
        var hi = offsets.len() as i32
        while lo < hi:
            let mid = lo + (hi - lo) / 2
            if offsets.get(mid as i64) <= clamped:
                lo = mid + 1
            else:
                hi = mid
        let line = if lo > 0: lo - 1 else: 0
        SemaSourceLocation { line, col: clamped - offsets.get(line as i64) }

    fn source_text_view_for_file_id(file_id: i32) -> &str:
        if file_id == 0:
            return &self.source_text
        for si in 0..self.source_text_file_ids.len() as i32:
            if self.source_text_file_ids.get(si as i64) == file_id:
                return self.source_texts.get(si as i64)
        ""

    fn source_text_for_file_id(file_id: i32) -> str:
        with_str_clone_ref(self.source_text_view_for_file_id(file_id))

    fn source_text_for_decl_node(node: i32) -> &str:
        let di = self.find_decl_index(node)
        if di >= 0 and di < self.decl_source_file_ids.len() as i32:
            let file_id = self.decl_source_file_ids.get(di as i64)
            let text = self.source_text_view_for_file_id(file_id)
            if text.len() > 0:
                return text
        // Body nodes never match a top-level decl, so the lookup above fails
        // for every local binding. Falling straight through to the primary
        // source silently slices ANOTHER file at this node's span — whenever
        // the bytes there happen to read `let <ident>`, set_pretty_symbol
        // poisons that symbol's name compiler-wide (a std module's locals
        // renamed to whatever the user file has at the same offsets). Use the
        // checker's per-decl context, which update_decl_source_context /
        // update_fn_source_context keep current for diagnostics.
        if self.local_file_id != 0:
            let text = self.source_text_view_for_file_id(self.local_file_id)
            if text.len() > 0:
                return text
        &self.source_text

    fn extract_decl_name_after(node: i32, keyword: &str) -> str:
        let source_text = self.source_text_for_decl_node(node)
        if source_text.len() == 0:
            return ""
        let source_len = source_text.len() as i32
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
        let snippet = source_text.slice(start as i64, end as i64)
        extract_name_after_keyword_in_text(snippet, keyword)

    fn set_pretty_symbol(sym: i32, name: &str):
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

    fn extract_fn_param_name(node: i32, param_index: i32) -> str:
        let source_text = self.source_text_for_decl_node(node)
        if source_text.len() == 0:
            return ""
        let source_len = source_text.len() as i32
        var start = self.ast.get_start(node)
        var end = self.ast.get_end(node)
        if start < 0:
            start = 0
        if end > source_len:
            end = source_len
        if end <= start:
            return ""
        extract_fn_param_name_in_text(source_text.slice(start as i64, end as i64), param_index)

    // ── Type management ──────────────────────────────────────────────

    fn exact_type_components_match(tid: i32, kind: i32, d0: i32, d1: i32, d2: i32) -> bool:
        self.type_kinds.get(tid as i64) == kind and
            self.type_d0.get(tid as i64) == d0 and
            self.type_d1.get(tid as i64) == d1 and
            self.type_d2.get(tid as i64) == d2

    fn index_exact_type(tid: i32, kind: i32, d0: i32, d1: i32, d2: i32):
        let key = sema_exact_type_hash(kind, d0, d1, d2)
        var head = -1
        if self.exact_type_cache_heads.contains(key):
            head = self.exact_type_cache_heads.get(key).unwrap()
        var existing = head
        while existing >= 0:
            if self.exact_type_components_match(existing, kind, d0, d1, d2):
                // Preserve find_exact_type's original first-TypeId result when
                // identical rows exist in the type table.
                self.exact_type_cache_next.push(-1)
                return
            existing = self.exact_type_cache_next.get(existing as i64)
        self.exact_type_cache_next.push(head)
        self.exact_type_cache_heads.insert(key, tid)

    mut fn rebuild_exact_type_cache():
        self.exact_type_cache_heads = sema_new_map_i64_i32()
        self.exact_type_cache_next = Vec.new()
        for tid in 0..self.type_kinds.len() as i32:
            self.index_exact_type(
                tid,
                self.type_kinds.get(tid as i64),
                self.type_d0.get(tid as i64),
                self.type_d1.get(tid as i64),
                self.type_d2.get(tid as i64),
            )

    mut fn freeze_symbols():
        self.symbols_frozen = 1

    fn add_type(kind: i32, d0: i32, d1: i32, d2: i32) -> TypeId:
        if self.types_frozen != 0:
            sema_phase_bug("BUG: Sema.add_type called after freeze_types")
        let id = self.type_kinds.len() as i32
        if kind == TypeKind.TY_GENERIC_INST and with_getenv_str("WITH_TRACE_INST").len() > 0:
            with_eprint(f"[inst] add tid={id} base={self.pool_resolve_symbol(d0)} frozen={self.types_frozen}")
        self.type_kinds.push(kind)
        self.type_d0.push(d0)
        self.type_d1.push(d1)
        self.type_d2.push(d2)
        self.index_exact_type(id, kind, d0, d1, d2)
        id as TypeId

    // Mark type tables as immutable. Any subsequent add_type will error.
    mut fn freeze_types():
        self.types_frozen = 1

    fn type_extra_matches(extra_start: i32, values: &Vec[i32], count: i32) -> i32:
        for i in 0..count:
            if self.type_extra.get((extra_start + i) as i64) != values.get(i as i64):
                return 0
        1

    fn find_exact_type(kind: i32, d0: i32, d1: i32, d2: i32) -> TypeId:
        let key = sema_exact_type_hash(kind, d0, d1, d2)
        if not self.exact_type_cache_heads.contains(key):
            return 0 as TypeId
        var ti = self.exact_type_cache_heads.get(key).unwrap()
        while ti >= 0:
            if self.exact_type_components_match(ti, kind, d0, d1, d2):
                return ti as TypeId
            ti = self.exact_type_cache_next.get(ti as i64)
        0 as TypeId

    fn ensure_exact_type(kind: i32, d0: i32, d1: i32, d2: i32) -> TypeId:
        let existing = self.find_exact_type(kind, d0, d1, d2)
        if existing != 0:
            return existing
        if self.types_frozen != 0:
            return 0 as TypeId
        self.add_type(kind, d0, d1, d2)

    fn find_tuple_type(elems: &Vec[i32], elem_count: i32) -> TypeId:
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

    fn ensure_tuple_type(elems: &Vec[i32], elem_count: i32) -> TypeId:
        let existing = self.find_tuple_type(elems, elem_count)
        if existing != 0:
            return existing
        if self.types_frozen != 0:
            return 0 as TypeId
        let te_start = self.type_extra.len() as i32
        for ei in 0..elem_count:
            self.type_extra.push(elems.get(ei as i64))
        self.add_type(TypeKind.TY_TUPLE, te_start, elem_count, 0)

    fn find_fn_type_of_kind(kind: i32, params: &Vec[i32], param_count: i32, ret: TypeId) -> TypeId:
        self.find_fn_type_of_kind_u(kind, params, param_count, ret, 0)

    // §16.11: unsafe-ness is part of callable type identity, so two signatures
    // that differ only in unsafe-ness are distinct types.
    fn find_fn_type_of_kind_u(kind: i32, params: &Vec[i32], param_count: i32, ret: TypeId, is_unsafe: i32) -> TypeId:
        let type_count = self.type_kinds.len() as i32
        for ti in 0..type_count:
            if self.type_kinds.get(ti as i64) != kind:
                continue
            if self.type_d1.get(ti as i64) != param_count:
                continue
            if self.type_d2.get(ti as i64) != ret as i32:
                continue
            let ti_unsafe = if self.unsafe_fn_type_set.contains(ti): 1 else: 0
            if ti_unsafe != is_unsafe:
                continue
            let te_start = self.type_d0.get(ti as i64)
            if self.type_extra_matches(te_start, params, param_count) != 0:
                return ti as TypeId
        0 as TypeId

    fn find_fn_type(params: &Vec[i32], param_count: i32, ret: TypeId) -> TypeId:
        self.find_fn_type_of_kind_u(TypeKind.TY_FN, params, param_count, ret, 0)

    fn find_extern_fn_type(params: &Vec[i32], param_count: i32, ret: TypeId) -> TypeId:
        self.find_fn_type_of_kind_u(TypeKind.TY_EXTERN_FN, params, param_count, ret, 0)

    fn ensure_fn_type(params: &Vec[i32], param_count: i32, ret: TypeId) -> TypeId:
        self.ensure_callable_type(TypeKind.TY_FN, params, param_count, ret, 0)

    fn ensure_extern_fn_type(params: &Vec[i32], param_count: i32, ret: TypeId) -> TypeId:
        self.ensure_callable_type(TypeKind.TY_EXTERN_FN, params, param_count, ret, 0)

    fn ensure_callable_type(kind: i32, params: &Vec[i32], param_count: i32, ret: TypeId, is_unsafe: i32) -> TypeId:
        let existing = self.find_fn_type_of_kind_u(kind, params, param_count, ret, is_unsafe)
        if existing != 0:
            return existing
        if self.types_frozen != 0:
            return 0 as TypeId
        let te_start = self.type_extra.len() as i32
        for pi in 0..param_count:
            self.type_extra.push(params.get(pi as i64))
        let tid = self.add_type(kind, te_start, param_count, ret as i32)
        if is_unsafe != 0:
            self.unsafe_fn_type_set.insert(tid as i32, 1)
        tid

    // True when a callable type is an unsafe fn/extern fn type.
    fn fn_type_is_unsafe(tid: i32) -> i32:
        if tid == 0:
            return 0
        if self.unsafe_fn_type_set.contains(self.resolve_alias(tid as TypeId) as i32): 1 else: 0

    fn callable_fn_type(tid: TypeId) -> i32:
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

    fn callable_any_fn_type(tid: TypeId) -> i32:
        var current = tid as i32
        while current != 0:
            let resolved = self.resolve_alias(current as TypeId) as i32
            let tk = self.get_type_kind(resolved)
            if tk == TypeKind.TY_FN or tk == TypeKind.TY_EXTERN_FN:
                return resolved
            if tk != TypeKind.TY_PTR and tk != TypeKind.TY_REF:
                return 0
            current = self.get_type_d0(resolved)
        0

    fn fn_type_param_type(fn_tid: i32, param_i: i32) -> i32:
        if fn_tid == 0 or param_i < 0:
            return 0
        let param_count = self.get_type_d1(fn_tid)
        if param_i >= param_count:
            return 0
        let te_start = self.get_type_d0(fn_tid)
        self.type_extra.get((te_start + param_i) as i64)

    fn callable_fn_param_type(tid: TypeId, param_i: i32) -> i32:
        self.fn_type_param_type(self.callable_fn_type(tid), param_i)

    fn callable_any_fn_param_type(tid: TypeId, param_i: i32) -> i32:
        self.fn_type_param_type(self.callable_any_fn_type(tid), param_i)

    // §16.11: a safe callable type cannot accept an unsafe callable value; safe→
    // unsafe widening and same-unsafe-ness are allowed.
    fn callable_unsafe_coercion_ok(expected: i32, actual: i32) -> i32:
        if self.fn_type_is_unsafe(expected) == 0 and self.fn_type_is_unsafe(actual) != 0:
            return 0
        1

    mut fn fn_types_compatible(expected: i32, actual: i32) -> i32:
        if self.get_type_d1(expected) != self.get_type_d1(actual):
            return 0
        let param_count = self.get_type_d1(expected)
        let exp_start = self.get_type_d0(expected)
        let act_start = self.get_type_d0(actual)
        for pi in 0..param_count:
            let exp_param: i32 = self.type_extra.get((exp_start + pi) as i64)
            let act_param: i32 = self.type_extra.get((act_start + pi) as i64)
            if self.types_compatible(exp_param, act_param) == 0:
                return 0
        self.types_compatible(self.get_type_d2(expected), self.get_type_d2(actual))

fn sema_generic_inst_hash(base_sym: i32, args: &Vec[i32], arg_count: i32) -> i64:
    var h: i64 = base_sym as i64
    for ai in 0..arg_count:
        h = (h *% 31) +% (args.get(ai as i64) as i64)
    h

impl Sema:
    fn find_generic_inst_type(base_sym: i32, args: &Vec[i32], arg_count: i32) -> TypeId:
        let key = sema_generic_inst_hash(base_sym, args, arg_count)
        if self.generic_inst_cache.contains(key):
            let cached = self.generic_inst_cache.get(key).unwrap()
            if cached >= 0 and cached < self.type_kinds.len() as i32:
                if self.type_kinds.get(cached as i64) == TypeKind.TY_GENERIC_INST:
                    let cached_base = self.type_d0.get(cached as i64)
                    let canonical_base = self.canonical_symbol_by_text(base_sym)
                    if (cached_base == base_sym or self.canonical_symbol_by_text(cached_base) == canonical_base) and self.type_d2.get(cached as i64) == arg_count:
                        let cached_start = self.type_d1.get(cached as i64)
                        if self.type_extra_matches(cached_start, args, arg_count) != 0:
                            return cached as TypeId
        let canonical_base2 = self.canonical_symbol_by_text(base_sym)
        let type_count = self.type_kinds.len() as i32
        for ti in 0..type_count:
            if self.type_kinds.get(ti as i64) != TypeKind.TY_GENERIC_INST:
                continue
            let seen_base = self.type_d0.get(ti as i64)
            if seen_base != base_sym and self.canonical_symbol_by_text(seen_base) != canonical_base2:
                continue
            if self.type_d2.get(ti as i64) != arg_count:
                continue
            let te_start = self.type_d1.get(ti as i64)
            if self.type_extra_matches(te_start, args, arg_count) != 0:
                // Interior-mut cache memoization. HashMap is an owning D22
                // handle, so copying the field would move it out of self (the
                // old D7 handle-copy trick blanks the field under #691).
                // Reborrow as an explicit raw place like drop_method_cache.
                let gic = &raw const self.generic_inst_cache as *const HashMap[i64, i32] as *mut HashMap[i64, i32]
                unsafe { (*gic).insert(key, ti) }
                return ti as TypeId
        0 as TypeId

    fn ensure_generic_inst_type(base_sym: i32, args: &Vec[i32], arg_count: i32) -> TypeId:
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
    fn find_generic_inst(base_sym: i32, arg_tid: i32) -> i32:
        let args: Vec[i32] = Vec.new()
        args.push(arg_tid)
        self.find_generic_inst_type(base_sym, args, 1) as i32

    // Look up an existing TypeKind.TY_RANGE(elem_tid, inclusive) in the type tables.
    // Returns the TypeId, or 0 if not found.
    fn find_range_type(elem_tid: TypeId, inclusive: i32) -> TypeId:
        let type_count = self.type_kinds.len() as i32
        for ti in 0..type_count:
            if self.type_kinds.get(ti as i64) == TypeKind.TY_RANGE:
                if self.type_d0.get(ti as i64) == elem_tid as i32:
                    if self.type_d1.get(ti as i64) == inclusive:
                        return ti as TypeId
        0 as TypeId

    fn range_type_constructor_inclusive(sym: i32) -> i32:
        if sym == self.syms.range_type:
            return 0
        if sym == self.syms.range_inclusive_type:
            return 1
        -1

    fn canonical_symbol_by_text(sym: i32) -> i32:
        let text = self.pool_resolve_symbol(sym)
        let canonical = if text.len() > 0: self.pool_lookup_symbol(text) else: 0
        if canonical != 0:
            return canonical
        sym

    fn canonical_range_type_constructor_inclusive(sym: i32) -> i32:
        let direct = self.range_type_constructor_inclusive(sym)
        if direct >= 0:
            return direct
        let canonical = self.canonical_symbol_by_text(sym)
        if canonical != sym:
            return self.range_type_constructor_inclusive(canonical)
        -1

    fn is_fixed_string_symbol(sym: i32) -> i32:
        if sym == self.syms.fixed_string:
            return 1
        let canonical = self.canonical_symbol_by_text(sym)
        if canonical == self.syms.fixed_string:
            return 1
        if self.pool_resolve_symbol(sym) == "FixedString":
            return 1
        0

    mut fn fixed_string_type_from_length_node(length_node: i32) -> i32:
        let length = self.int_literal_i64_value(length_node)
        if length.ok == 0:
            self.emit_error("FixedString length must be a compile-time integer constant", length_node)
            return 0
        if length.value <= 0:
            self.emit_error("FixedString length must be positive", length_node)
            return 0
        if length.value > 2147483647:
            self.emit_error("FixedString length is too large", length_node)
            return 0
        let storage_tid = self.ensure_exact_type(TypeKind.TY_ARRAY, self.ty_u8 as i32, length.value as i32, 0) as i32
        let args: Vec[i32] = Vec.new()
        args.push(storage_tid)
        self.ensure_generic_inst_type(self.syms.fixed_string, args, 1) as i32

    // Pre-register generic instantiation types needed by MirLower so that
    // downstream passes never need to mutate the type tables.
    // Must be called after check_module() and before freeze_types().
    mut fn preregister_generic_struct_fields(tid: i32):
        let field_count = self.type_reflection_field_count(tid)
        if with_getenv_str("WITH_TRACE_INST").len() > 0:
            with_eprint(f"[prereg-enter] tid={tid} base={self.pool_resolve_symbol(self.get_type_d0(tid as TypeId))} count={field_count}")
        for fi in 0..field_count:
            let field_sym = self.type_reflection_field_name(tid, fi)
            let field_ty = self.type_reflection_field_type(tid, fi)
            self.generic_struct_field_index_type_cache.insert(sema_pair_key(tid, fi), field_ty)
            if field_sym != 0:
                if with_getenv_str("WITH_TRACE_INST").len() > 0:
                    with_eprint(f"[prereg] tid={tid} fsym={field_sym} text={self.pool_resolve_symbol(field_sym)} fty={field_ty}")
                self.generic_struct_field_type_cache.insert(sema_pair_key(tid, field_sym), field_ty)
                let canonical = self.canonical_symbol_by_text(field_sym)
                if canonical != 0:
                    self.generic_struct_field_type_cache.insert(sema_pair_key(tid, canonical), field_ty)

    mut fn cache_generic_enum_payload(tid: i32, variant_sym: i32, payloads: &Vec[i32]):
        if variant_sym == 0:
            return
        let key = sema_pair_key(tid, variant_sym)
        if self.generic_enum_payload_cache_starts.contains(key):
            return
        let start = self.generic_enum_payload_cache_values.len() as i32
        let count = payloads.len() as i32
        for pi in 0..count:
            self.generic_enum_payload_cache_values.push(payloads.get(pi as i64))
        self.generic_enum_payload_cache_starts.insert(key, start)
        self.generic_enum_payload_cache_counts.insert(key, count)

    mut fn preregister_generic_enum_payloads(tid: i32):
        let variant_count = self.type_reflection_variant_count(tid)
        for vi in 0..variant_count:
            let variant_sym = self.type_reflection_variant_name(tid, vi)
            let payloads = self.enum_variant_payload_types(tid, variant_sym)
            self.cache_generic_enum_payload(tid, variant_sym, &payloads)
            let bare = self.unqualified_enum_variant_sym(variant_sym)
            if bare != variant_sym:
                self.cache_generic_enum_payload(tid, bare, &payloads)

    mut fn preregister_mir_types():
        let vec_sym = self.syms.vec
        let vi_sym = self.syms.veciter
        let hashmap_sym = self.syms.hashmap
        let option_sym = self.syms.option

        // For every Vec[T] type registered, also register VecIter[T].
        // For every HashMap[K, V], register Option[V] so MIR/codegen can
        // materialize aggregate map-get results after type freezing.
        let type_count = self.type_kinds.len() as i32
        for ti in 0..type_count:
            if self.type_kinds.get(ti as i64) == TypeKind.TY_GENERIC_INST:
                if self.type_d0.get(ti as i64) == vec_sym:
                    let extra_start: i32 = self.type_d1.get(ti as i64)
                    let arg_count = self.type_d2.get(ti as i64)
                    if arg_count >= 1:
                        let elem_ty: i32 = self.type_extra.get(extra_start as i64)
                        let vi_args: Vec[i32] = Vec.new()
                        vi_args.push(elem_ty)
                        let vi_key = sema_generic_inst_hash(vi_sym, vi_args, 1)
                        if not self.generic_inst_cache.contains(vi_key):
                            let te_start = self.type_extra.len() as i32
                            self.type_extra.push(elem_ty)
                            let tid = self.add_type(TypeKind.TY_GENERIC_INST, vi_sym, te_start, 1)
                            self.generic_inst_cache.insert(vi_key, tid as i32)
                if self.type_d0.get(ti as i64) == hashmap_sym:
                    let extra_start = self.type_d1.get(ti as i64)
                    let arg_count = self.type_d2.get(ti as i64)
                    if arg_count >= 2:
                        let value_ty: i32 = self.type_extra.get((extra_start + 1) as i64)
                        let opt_args: Vec[i32] = Vec.new()
                        opt_args.push(value_ty)
                        let opt_key = sema_generic_inst_hash(option_sym, opt_args, 1)
                        if not self.generic_inst_cache.contains(opt_key):
                            let opt_start = self.type_extra.len() as i32
                            self.type_extra.push(value_ty)
                            let tid = self.add_type(TypeKind.TY_GENERIC_INST, option_sym, opt_start, 1)
                            self.generic_inst_cache.insert(opt_key, tid as i32)

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

        // D7 eager layout tables: compute size/align for every type now (types_frozen is
        // still 0, so a layout that needs a dependent type may create it), then the frozen
        // consumers read them via &Self twins.
        self.eager_type_caches_pass()

    // Populate layout + generic field/payload caches for every type that does
    // not have them yet. Loops until stable in case layout adds a type. Runs
    // in the D7 eager pass and again from freeze_types as a catch-up: generic
    // insts created between the two (e.g. by specialization re-checks) must be
    // cached too, or frozen consumers phase-bug on the first drop/reflection
    // query (VecIter[i32] through iter_sum was the repro).
    mut fn eager_type_caches_pass():
        if with_getenv_str("WITH_TRACE_INST").len() > 0:
            with_eprint(f"[eager] pass types={self.type_kinds.len() as i32}")
        var layout_pass_done = false
        while not layout_pass_done:
            let lt_n = self.type_kinds.len() as i32
            for lti in 0..lt_n:
                if not self.layout_size_cache.contains(lti):
                    let lt_sz = self.type_layout_size_of(lti)
                    let lt_al = self.type_layout_align_of(lti)
                    let lt_cp = self.is_copy(lti as TypeId)
                    let lt_nd = self.type_needs_drop(lti)
                    let lt_uw = self.try_unwrapped_type(lti)
                    let lt_fe = self.infer_for_element_type(lti)
                    if self.type_kinds.get(lti as i64) == TypeKind.TY_GENERIC_INST:
                        self.preregister_generic_struct_fields(lti)
                        self.preregister_generic_enum_payloads(lti)
                    self.layout_size_cache.insert(lti, lt_sz)
                    self.layout_align_cache.insert(lti, lt_al)
                    self.is_copy_cache.insert(lti, lt_cp)
                    self.needs_drop_result_cache.insert(lti, lt_nd)
                    self.unwrapped_type_cache.insert(lti, lt_uw)
                    self.for_element_type_cache.insert(lti, lt_fe)
                    let field_count = self.type_reflection_field_count(lti)
                    for fi in 0..field_count:
                        self.layout_field_offset_cache.insert(sema_pair_key(lti, fi), self.type_layout_struct_field_offset(lti, fi))
            if self.type_kinds.len() as i32 == lt_n:
                layout_pass_done = true


    // TypeKind.TY_GENERIC_INST: d0=base_sym, d1=extra_start, d2=arg_count
    // Type args stored in type_extra[extra_start..extra_start+arg_count] as TypeIds.

    fn atomic_payload_type_is_valid(tid: i32) -> i32:
        if tid == 0:
            return 0
        let resolved = self.resolve_alias(tid as TypeId)
        let kind = self.get_type_kind(resolved)
        if kind == TypeKind.TY_INT or kind == TypeKind.TY_PTR:
            return 1
        0

    mut fn validate_atomic_payload_type(base_sym: i32, args: &Vec[i32], arg_count: i32, node: i32) -> i32:
        if self.pool_resolve_symbol(base_sym) != "Atomic":
            return 1
        if arg_count != 1:
            self.emit_error("Atomic[T] expects exactly one type argument", node)
            return 0
        if self.atomic_payload_type_is_valid(args.get(0)) == 0:
            self.emit_error("Atomic[T] requires integer or pointer T", node)
            return 0
        1

    mut fn resolve_generic_type(node: i32) -> i32:
        var gi_base_sym = self.ast.get_data0(node)
        if self.is_fixed_string_symbol(gi_base_sym) != 0:
            let gi_arg_count = self.ast.get_data2(node)
            if gi_arg_count != 1:
                self.emit_error("FixedString expects exactly one length argument", node)
                return 0
            let gi_extra_start = self.ast.get_data1(node)
            return self.fixed_string_type_from_length_node(self.ast.get_extra(gi_extra_start))
        let range_inclusive = self.canonical_range_type_constructor_inclusive(gi_base_sym)
        if range_inclusive >= 0:
            let gi_arg_count = self.ast.get_data2(node)
            if gi_arg_count != 1:
                self.emit_error("Range expects exactly one type argument", node)
                return 0
            let gi_extra_start = self.ast.get_data1(node)
            let elem_tid = self.resolve_type_expr(self.ast.get_extra(gi_extra_start))
            if elem_tid == 0:
                return 0
            return self.ensure_exact_type(TypeKind.TY_RANGE, elem_tid as i32, range_inclusive, 0) as i32
        var gi_base_tid = self.lookup_named_type_visible(gi_base_sym)
        if gi_base_tid == 0:
            let canonical_base = self.canonical_symbol_by_text(gi_base_sym)
            if canonical_base != 0 and canonical_base != gi_base_sym:
                gi_base_sym = canonical_base
                gi_base_tid = self.lookup_named_type_visible(gi_base_sym)
        if gi_base_tid == 0:
            // D29 scaffolding (#750): a registered-but-gated generic base is an
            // import error, not a silent flat-map fallback.
            let gi_gate_note = self.std_gated_import_note(gi_base_sym)
            if gi_gate_note.len() > 0:
                self.emit_error("'" ++ self.pool_resolve_symbol(gi_base_sym) ++ "' requires an explicit import (§18.1)" ++ gi_gate_note, node)
                return 0
            if not self.type_decl_nodes.contains(gi_base_sym):
                if self.require_alloc_tier_for_symbol(gi_base_sym, node) == 0:
                    return 0
                if self.require_std_tier_for_symbol(gi_base_sym, node) == 0:
                    return 0
                let gi_name: str = with_str_clone_ref(self.pool_resolve_symbol(gi_base_sym))
                self.emit_error("unknown type: " ++ gi_name, node)
                return 0
        if self.require_alloc_tier_for_symbol(gi_base_sym, node) == 0:
            return 0
        if self.require_std_tier_for_symbol(gi_base_sym, node) == 0:
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
        if self.validate_atomic_payload_type(gi_base_sym, &gi_args, gi_arg_count, node) == 0:
            return 0
        self.ensure_generic_inst_type(gi_base_sym, gi_args, gi_arg_count) as i32

    // The inst accessors are kind-guarded: reading base/count/args from a
    // NON-inst type returned whatever number lived in its d-slots — garbage
    // that happened to be harmless under one type-table layout and a live
    // type id under another (#682-inc1 bring-up: a pending unannotated
    // `Vec.new()` receiver typed push literals as u7 through exactly this).
    fn get_generic_inst_base(tid: i32) -> i32:
        if self.get_type_kind(tid as TypeId) != TypeKind.TY_GENERIC_INST:
            return 0
        self.get_type_d0(tid)

    fn get_generic_inst_arg_count(tid: i32) -> i32:
        if self.get_type_kind(tid as TypeId) != TypeKind.TY_GENERIC_INST:
            return 0
        self.get_type_d2(tid)

    fn get_generic_inst_arg(tid: i32, index: i32) -> i32:
        if self.get_type_kind(tid as TypeId) != TypeKind.TY_GENERIC_INST:
            return 0
        let extra_start = self.get_type_d1(tid)
        self.type_extra.get((extra_start + index) as i64)

    fn numeric_operand_type(tid: i32) -> i32:
        let resolved = self.resolve_alias(tid as TypeId)
        if self.get_type_kind(resolved) == TypeKind.TY_ENUM:
            let repr = self.enum_repr_type(resolved as i32)
            if repr != 0:
                return self.resolve_alias(repr as TypeId) as i32
        resolved as i32

    fn is_unsigned_int_type(tid: i32) -> bool:
        let resolved = self.numeric_operand_type(tid)
        if self.get_type_kind(resolved) != TypeKind.TY_INT:
            return false
        self.get_type_d1(resolved) == 0

    fn is_numeric_type(tid: i32) -> bool:
        let resolved = self.numeric_operand_type(tid)
        let kind = self.get_type_kind(resolved)
        kind == TypeKind.TY_INT or kind == TypeKind.TY_FLOAT

    fn literal_suffix_type(suffix: i32) -> i32:
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

    fn int_literal_fits_type(node: i32, tid: i32) -> bool:
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

    fn int_literal_bit_pattern_fits_type(node: i32, tid: i32) -> bool:
        let resolved = self.numeric_operand_type(tid)
        if self.get_type_kind(resolved) != TypeKind.TY_INT:
            return false
        let bits = self.get_type_d0(resolved)
        let expr = self.ast.int_literal_exact_expr(node)
        if expr.ok == 0 or expr.overflow != 0:
            return false
        let mag = ExactIntValue { ok: expr.ok, overflow: expr.overflow, lo: expr.lo, hi: expr.hi }
        if expr.negative != 0:
            return exact_int_fits_signed_negative_bits(mag, bits)
        exact_int_fits_unsigned_bits(mag, bits)

    mut fn numeric_literal_expected_type(node: i32) -> i32:
        if self.has_expected_type == 0 or self.expected_expr_type == 0:
            return 0
        let expected = self.numeric_operand_type(self.expected_expr_type as i32)
        if not self.is_numeric_type(expected):
            return 0
        if self.in_bitwise_literal_context != 0:
            if not self.int_literal_bit_pattern_fits_type(node, expected):
                self.emit_error("integer literal bit pattern does not fit expected type", node)
        else if not self.int_literal_fits_type(node, expected):
            // Enriched like the default-type arm (#767 payoff pattern): name
            // the literal and the resolved expectation — id-confusion and
            // stale-sidecar failures self-identify.
            let nf_digits = self.ast.int_literal_digits(node as NodeId)
            let nf_res = self.resolve_alias(expected as TypeId)
            self.emit_error(f"integer literal does not fit expected type (digits='{nf_digits}' raw={self.ast.int_lit_value(node as NodeId)} expected={expected} resolved_kind={self.get_type_kind(nf_res) as i32} d0={self.get_type_d0(nf_res)} d1={self.get_type_d1(nf_res)})", node)
        expected

    fn shift_count_literal_type(node: i32) -> i32:
        if self.ast.kind(node) != NodeKind.NK_INT_LIT:
            return self.ty_u32 as i32
        if self.literal_suffix_type(self.ast.literal_suffix(node)) != 0:
            return 0
        if self.int_literal_fits_type(node, self.ty_u32 as i32):
            return self.ty_u32 as i32
        if self.int_literal_fits_type(node, self.ty_u64 as i32):
            return self.ty_u64 as i32
        if self.int_literal_fits_type(node, self.ty_u128 as i32):
            return self.ty_u128 as i32
        self.ty_u128 as i32

    fn float_literal_expected_type() -> i32:
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

// A bitwise operand written as an int literal under grouping and `~` wrappers
// (`(~1)`, `~0x3c`) adapts to the other operand's integer type exactly like a
// bare literal; the mixed-signedness rule is for concretely typed operands.
fn sema_node_is_bitwise_adaptable_literal(ast: AstPool, node: i32) -> bool:
    var cur = node
    while cur != 0:
        let kind = ast.kind(cur)
        if kind == NodeKind.NK_INT_LIT:
            return true
        if kind == NodeKind.NK_GROUPED:
            cur = ast.get_data0(cur)
            continue
        if kind == NodeKind.NK_UNARY and ast.get_data0(cur) == UnaryOp.UOP_BIT_NOT:
            cur = ast.get_data1(cur)
            continue
        return false
    false

impl Sema:
    fn is_option_pointer_type(tid: i32) -> i32:
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
        let payload_kind = self.get_type_kind(payload_resolved)
        if payload_kind == TypeKind.TY_PTR or payload_kind == TypeKind.TY_EXTERN_FN:
            return 1
        0

    fn option_pointer_payload_type(tid: i32) -> i32:
        if self.is_option_pointer_type(tid) == 0:
            return 0
        let resolved = self.resolve_alias(tid)
        self.get_generic_inst_arg(resolved, 0)

    fn null_literal_target_type(tid: TypeId) -> TypeId:
        if tid == 0:
            return 0 as TypeId
        let resolved = self.resolve_alias(tid)
        let kind = self.get_type_kind(resolved)
        if kind == TypeKind.TY_PTR or kind == TypeKind.TY_EXTERN_FN or self.is_option_pointer_type(resolved) != 0:
            return resolved
        0 as TypeId

    fn type_allows_null_literal(tid: TypeId) -> i32:
        if self.null_literal_target_type(tid) != 0:
            return 1
        0

    mut fn try_unwrapped_type(tid: i32) -> i32:
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
    fn substitute_type(tid: i32, subst_syms: &Vec[i32], subst_tids: &Vec[i32], count: i32) -> i32:
        if tid <= 0 or count == 0:
            return tid
        let kind = self.get_type_kind(tid as TypeId)
        let d0 = self.get_type_d0(tid as TypeId)
        // Direct match: struct/enum/alias whose name matches a type param symbol
        if kind == TypeKind.TY_STRUCT or kind == TypeKind.TY_ENUM or kind == TypeKind.TY_ALIAS:
            for si in 0..count:
                let subst_sym = subst_syms.get(si as i64)
                if subst_sym == d0:
                    return subst_tids.get(si as i64)
            let d0_text = self.pool_resolve_symbol(d0)
            if d0_text.len() == 0:
                return tid
            var found = 0
            var found_count = 0
            for si2 in 0..count:
                let subst_sym2 = subst_syms.get(si2 as i64)
                if self.pool_resolve_symbol(subst_sym2) == d0_text:
                    found = subst_tids.get(si2 as i64)
                    found_count = found_count + 1
            if found_count == 1:
                return found
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
            return self.ensure_exact_type(TypeKind.TY_SLICE, subbed, self.get_type_d1(tid as TypeId), 0) as i32
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

    fn get_type_kind(tid: TypeId) -> i32:
        if tid < 0 or tid >= self.type_kinds.len() as i32:
            return TypeKind.TY_ERR
        self.type_kinds.get(tid as i64)

    fn get_type_name_for_lsp(tid: i32) -> str:
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
            return with_str_clone_ref(self.pool_resolve(self.type_d0.get(tid as i64)))
        ""

    fn get_type_d0(tid: TypeId) -> i32:
        if tid < 0 or tid >= self.type_d0.len() as i32:
            return 0
        self.type_d0.get(tid as i64)

    fn get_type_d1(tid: TypeId) -> i32:
        if tid < 0 or tid >= self.type_d1.len() as i32:
            return 0
        self.type_d1.get(tid as i64)

    fn get_type_d2(tid: TypeId) -> i32:
        if tid < 0 or tid >= self.type_d2.len() as i32:
            return 0
        self.type_d2.get(tid as i64)

    fn resolve_alias(tid: TypeId) -> TypeId:
        var current = tid
        for depth in 0..32:
            if self.get_type_kind(current) == TypeKind.TY_ALIAS:
                current = self.get_type_d0(current) as TypeId
            else:
                return current
        current

    fn is_opaque_value_type(tid: i32) -> i32:
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

    fn is_c_void_like_type(tid: i32) -> i32:
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

    mut fn pointer_pointees_compatible(exp_r: i32, act_r: i32) -> i32:
        let exp_mut = self.get_type_d1(exp_r)
        let act_mut = self.get_type_d1(act_r)
        if exp_mut != 0 and act_mut == 0:
            return 0
        let exp_pointee = self.get_type_d0(exp_r)
        if self.is_c_void_like_type(exp_pointee) != 0:
            return 1
        self.types_compatible(exp_pointee, self.get_type_d0(act_r))

    // ── Scope management ─────────────────────────────────────────────

    fn push_scope() -> Unit:
        self.scope_starts.push(self.bind_names.len() as i32)

    mut fn emit_pending_generic_binding_error(sym: i32):
        let binding_name: str = with_str_clone_ref(self.pool_resolve(sym))
        var node = 0
        if self.pending_generic_binding_decl.contains(sym):
            node = self.pending_generic_binding_decl.get(sym).unwrap()
        else if self.pending_generic_binding_call.contains(sym):
            node = self.pending_generic_binding_call.get(sym).unwrap()
        self.emit_error("cannot infer generic type for '" ++ binding_name ++ "'; add a type annotation", node)

    mut fn pop_scope():
        let len = self.scope_starts.len() as i32
        if len == 0:
            return
        let start = self.scope_starts.get((len - 1) as i64)
        // Expire borrows for bindings leaving scope
        self.expire_borrows_in_scope(start)
        // Remove bindings from map and parallel arrays
        let reported_pending_calls: Vec[i32] = Vec.new()
        while self.bind_names.len() as i32 > start:
            let removed_sym: i32 = self.bind_names.get(self.bind_names.len() - 1)
            let removed_node = self.binding_decl_node(removed_sym)
            self.check_live_views_for_origin(removed_sym, removed_node)
            self.poison_live_views_for_origin(removed_sym, removed_node)
            if self.pending_generic_binding_base.contains(removed_sym):
                let pending_call = if self.pending_generic_binding_call.contains(removed_sym): self.pending_generic_binding_call.get(removed_sym).unwrap() else: 0
                let report_key = if pending_call != 0: pending_call else: removed_sym
                var already_reported = 0
                for rpi in 0..reported_pending_calls.len() as i32:
                    if reported_pending_calls.get(rpi as i64) == report_key:
                        already_reported = 1
                if already_reported == 0:
                    reported_pending_calls.push(report_key)
                    self.emit_pending_generic_binding_error(removed_sym)
                self.pending_generic_binding_base.remove(removed_sym)
                self.pending_generic_binding_call.remove(removed_sym)
                self.pending_generic_binding_decl.remove(removed_sym)
            self.clear_moved_fields_for_binding(removed_sym)
            self.scope_name_map.remove(removed_sym)
            self.bind_names.pop()
            self.bind_types.pop()
            self.bind_muts.pop()
            self.bind_states.pop()
            self.bind_is_task.pop()
            self.bind_task_used.pop()
            self.bind_is_scoped_task.pop()
            self.bind_is_view_bound.pop()
            self.bind_provenance.pop()
            self.binding_decl_nodes.remove(removed_sym)
            self.binding_value_nodes.remove(removed_sym)
            self.binding_closure_nodes.remove(removed_sym)
            self.clear_binding_view_deps(removed_sym)
        self.scope_starts.pop()

    fn is_discard_binding_symbol(sym: i32) -> i32:
        if sym == 0:
            return 1
        if self.discard_sym != 0 and sym == self.discard_sym:
            return 1
        0

    mut fn scope_put(sym: i32, tid: i32, is_mut: i32):
        self.scope_put_at(sym, tid, is_mut, 0)

    fn scope_insert_at(sym: i32, tid: i32, is_mut: i32):
        let idx = self.bind_names.len() as i32
        self.bind_names.push(sym)
        self.bind_types.push(tid)
        self.bind_muts.push(is_mut)
        self.bind_states.push(VarState.LIVE)
        self.bind_is_task.push(0)
        self.bind_task_used.push(0)
        self.bind_is_scoped_task.push(0)
        self.bind_is_view_bound.push(0)
        self.bind_provenance.push(binding_provenance_empty())
        self.scope_name_map.insert(sym, idx)

    mut fn scope_put_at(sym: i32, tid: i32, is_mut: i32, node: i32):
        if self.is_discard_binding_symbol(sym) != 0:
            return
        if self.scope_lookup(sym) >= 0:
            let name: str = with_str_clone_ref(self.pool_resolve(sym))
            self.emit_error("shadowing is not allowed for '" ++ name ++ "'", node)
            return
        self.scope_insert_at(sym, tid, is_mut)

    mut fn scope_put_consuming_rebind_at(sym: i32, tid: i32, is_mut: i32, node: i32) -> i32:
        if self.is_discard_binding_symbol(sym) != 0:
            return 1
        let existing = self.scope_name_map.get(sym)
        if not existing.is_some():
            self.scope_insert_at(sym, tid, is_mut)
            return 1
        let idx: i32 = existing.unwrap()
        let current_start = if self.scope_starts.len() > 0: self.scope_starts.get((self.scope_starts.len() - 1) as i64) else: 0
        if idx < current_start or self.bind_states.get(idx as i64) != VarState.MOVED:
            let name: str = with_str_clone_ref(self.pool_resolve(sym))
            self.emit_error("shadowing is not allowed for '" ++ name ++ "'", node)
            return 0
        self.bind_types.set_i32(idx as i64, tid)
        self.bind_muts.set_i32(idx as i64, is_mut)
        self.bind_states.set_i32(idx as i64, VarState.LIVE)
        self.bind_is_task.set_i32(idx as i64, 0)
        self.bind_task_used.set_i32(idx as i64, 0)
        self.bind_is_scoped_task.set_i32(idx as i64, 0)
        self.bind_is_view_bound.set_i32(idx as i64, 0)
        let slot_idx = idx as i64
        with self.bind_provenance.slot(slot_idx) as mut slot:
            slot.set(binding_provenance_empty())
        self.clear_binding_view_deps(sym)
        self.binding_closure_nodes.remove(sym)
        1

    fn global_value_decl_kind(sym: i32) -> i32:
        let opt = self.global_value_decl_kinds.get(sym)
        if opt.is_some():
            return opt.unwrap()
        0

    fn global_value_decl_types_compatible(existing_tid: i32, new_tid: i32) -> i32:
        if existing_tid == 0 or new_tid == 0:
            return 1
        let existing_resolved = self.resolve_alias(existing_tid as TypeId) as i32
        let new_resolved = self.resolve_alias(new_tid as TypeId) as i32
        if existing_resolved != 0 and existing_resolved == new_resolved:
            return 1
        0

    mut fn register_top_level_global_decl(sym: i32, tid: i32, is_mut: i32, node: i32, decl_kind: i32):
        if self.is_discard_binding_symbol(sym) != 0:
            return
        let existing_opt = self.scope_name_map.get(sym)
        if not existing_opt.is_some():
            self.scope_insert_at(sym, tid, is_mut)
            self.global_value_decl_kinds.insert(sym, decl_kind)
            return

        let existing_idx: i32 = existing_opt.unwrap()
        let existing_kind = self.global_value_decl_kind(sym)
        if existing_kind == 0:
            let name: str = with_str_clone_ref(self.pool_resolve(sym))
            self.emit_error("shadowing is not allowed for '" ++ name ++ "'", node)
            return

        if existing_kind == GLOBAL_VALUE_DECL_DEF and decl_kind == GLOBAL_VALUE_DECL_DEF:
            let name: str = with_str_clone_ref(self.pool_resolve(sym))
            self.emit_error("shadowing is not allowed for '" ++ name ++ "'", node)
            return

        let existing_mut = self.bind_muts.get(existing_idx as i64)
        if existing_mut != is_mut:
            let name: str = with_str_clone_ref(self.pool_resolve(sym))
            self.emit_error("conflicting global declaration for '" ++ name ++ "'", node)
            return

        let existing_tid = self.bind_types.get(existing_idx as i64)
        if self.global_value_decl_types_compatible(existing_tid, tid) == 0:
            let name: str = with_str_clone_ref(self.pool_resolve(sym))
            self.emit_error("conflicting global declaration for '" ++ name ++ "'", node)
            return

        if existing_tid == 0 and tid != 0:
            self.bind_types.set_i32(existing_idx as i64, tid)

        if existing_kind == GLOBAL_VALUE_DECL_EXTERN and decl_kind == GLOBAL_VALUE_DECL_DEF:
            self.global_value_decl_kinds.insert(sym, GLOBAL_VALUE_DECL_DEF)

    fn scope_lookup(sym: i32) -> i32:
        let opt = self.scope_name_map.get(sym)
        if opt.is_some():
            return self.bind_types.get(opt.unwrap() as i64)
        -1

    fn scope_update_type(sym: i32, tid: i32):
        let opt = self.scope_name_map.get(sym)
        if opt.is_some():
            let idx: i32 = opt.unwrap()
            self.bind_types.set_i32(idx as i64, tid)
        for ii in 0..self.implicit_binding_syms.len() as i32:
            if self.implicit_binding_syms.get(ii as i64) == sym:
                self.implicit_binding_types.set_i32(ii as i64, tid)

    fn scope_lookup_mut(sym: i32) -> i32:
        let opt = self.scope_name_map.get(sym)
        if opt.is_some():
            return self.bind_muts.get(opt.unwrap() as i64)
        0

    fn scope_lookup_state(sym: i32) -> i32:
        let opt = self.scope_name_map.get(sym)
        if opt.is_some():
            return self.bind_states.get(opt.unwrap() as i64)
        VarState.LIVE

    fn moved_field_path_matches(idx: i32, base_sym: i32, path_start: i32, path_count: i32) -> i32:
        if idx < 0 or idx >= self.moved_field_base_syms.len() as i32:
            return 0
        if self.moved_field_base_syms.get(idx as i64) != base_sym:
            return 0
        if self.moved_field_path_counts.get(idx as i64) != path_count:
            return 0
        let stored_start = self.moved_field_path_starts.get(idx as i64)
        for pi in 0..path_count:
            if self.moved_field_path_syms.get((stored_start + pi) as i64) != self.borrow_path_data.get((path_start + pi) as i64):
                return 0
        1

    fn moved_field_path_has_prefix(idx: i32, base_sym: i32, path_start: i32, path_count: i32) -> i32:
        if idx < 0 or idx >= self.moved_field_base_syms.len() as i32:
            return 0
        if self.moved_field_base_syms.get(idx as i64) != base_sym:
            return 0
        let stored_count = self.moved_field_path_counts.get(idx as i64)
        if stored_count < path_count:
            return 0
        let stored_start = self.moved_field_path_starts.get(idx as i64)
        for pi in 0..path_count:
            if self.moved_field_path_syms.get((stored_start + pi) as i64) != self.borrow_path_data.get((path_start + pi) as i64):
                return 0
        1

    fn field_move_path_for_expr(node: i32) -> i64:
        let base_sym = self.place_root_sym(node)
        if base_sym == 0:
            return 0
        if self.scope_has(base_sym) == 0:
            return 0
        let path_start = self.borrow_path_data.len() as i32
        let path_count = self.borrow_collect_path(node)
        if path_count <= 0:
            return 0
        (base_sym as i64) | ((path_start as i64) << 32) | ((path_count as i64) << 48)

    fn mark_field_moved(node: i32):
        let packed = self.field_move_path_for_expr(node)
        if packed == 0:
            return
        let base_sym = (packed & 4294967295) as i32
        let path_start = ((packed >> 32) & 65535) as i32
        let path_count = ((packed >> 48) & 65535) as i32
        for i in 0..self.moved_field_base_syms.len() as i32:
            if self.moved_field_path_matches(i, base_sym, path_start, path_count) != 0:
                return
        let stored_start = self.moved_field_path_syms.len() as i32
        for pi in 0..path_count:
            self.moved_field_path_syms.push(self.borrow_path_data.get((path_start + pi) as i64))
        self.moved_field_base_syms.push(base_sym)
        self.moved_field_path_starts.push(stored_start)
        self.moved_field_path_counts.push(path_count)
        if self.marking_explicit_move != 0:
            self.explicitly_partial_syms.insert(base_sym, 1)

    fn field_is_moved(node: i32) -> i32:
        let packed = self.field_move_path_for_expr(node)
        if packed == 0:
            return 0
        let base_sym = (packed & 4294967295) as i32
        let path_start = ((packed >> 32) & 65535) as i32
        let path_count = ((packed >> 48) & 65535) as i32
        for i in 0..self.moved_field_base_syms.len() as i32:
            if self.moved_field_path_matches(i, base_sym, path_start, path_count) != 0:
                return 1
        0

    fn remove_moved_field_entry(idx: i32):
        let last = self.moved_field_base_syms.len() as i32 - 1
        if idx < 0 or idx > last:
            return
        if idx != last:
            self.moved_field_base_syms.set_i32(idx as i64, self.moved_field_base_syms.get(last as i64))
            self.moved_field_path_starts.set_i32(idx as i64, self.moved_field_path_starts.get(last as i64))
            self.moved_field_path_counts.set_i32(idx as i64, self.moved_field_path_counts.get(last as i64))
        self.moved_field_base_syms.pop()
        self.moved_field_path_starts.pop()
        self.moved_field_path_counts.pop()

    // #782: whether any field path rooted at this binding is currently
    // moved-out (the whole value is no longer intact).
    fn binding_has_moved_field(sym: i32) -> i32:
        for i in 0..self.moved_field_base_syms.len() as i32:
            if self.moved_field_base_syms.get(i as i64) == sym:
                return 1
        0

    // First moved field's leaf sym for diagnostics (0 when unknown).
    fn first_moved_field_sym(sym: i32) -> i32:
        for i in 0..self.moved_field_base_syms.len() as i32:
            if self.moved_field_base_syms.get(i as i64) == sym:
                let count: i32 = self.moved_field_path_counts.get(i as i64)
                if count > 0:
                    let start: i32 = self.moved_field_path_starts.get(i as i64)
                    return self.moved_field_path_syms.get((start + count - 1) as i64)
        0

    fn clear_moved_fields_for_binding(sym: i32):
        var i = self.moved_field_base_syms.len() as i32 - 1
        while i >= 0:
            if self.moved_field_base_syms.get(i as i64) == sym:
                self.remove_moved_field_entry(i)
            i = i - 1
        let _ = self.explicitly_partial_syms.remove(sym)

    fn clear_moved_fields_for_place_expr(node: i32):
        let packed = self.field_move_path_for_expr(node)
        if packed == 0:
            return
        let base_sym = (packed & 4294967295) as i32
        let path_start = ((packed >> 32) & 65535) as i32
        let path_count = ((packed >> 48) & 65535) as i32
        var i = self.moved_field_base_syms.len() as i32 - 1
        while i >= 0:
            if self.moved_field_path_has_prefix(i, base_sym, path_start, path_count) != 0:
                self.remove_moved_field_entry(i)
            i = i - 1

    fn scope_lookup_is_task(sym: i32) -> i32:
        let opt = self.scope_name_map.get(sym)
        if opt.is_some():
            return self.bind_is_task.get(opt.unwrap() as i64)
        0

    fn scope_mark_task_used(sym: i32):
        let opt = self.scope_name_map.get(sym)
        if opt.is_some():
            let idx: i32 = opt.unwrap()
            self.bind_task_used.set_i32(idx as i64, 1)

    fn scope_lookup_task_used(sym: i32) -> i32:
        let opt = self.scope_name_map.get(sym)
        if opt.is_some():
            return self.bind_task_used.get(opt.unwrap() as i64)
        0

    fn scope_set_is_task(sym: i32, is_task: i32):
        let opt = self.scope_name_map.get(sym)
        if opt.is_some():
            let idx: i32 = opt.unwrap()
            self.bind_is_task.set_i32(idx as i64, is_task)

    fn scope_lookup_is_scoped_task(sym: i32) -> i32:
        let opt = self.scope_name_map.get(sym)
        if opt.is_some():
            return self.bind_is_scoped_task.get(opt.unwrap() as i64)
        0

    fn scope_set_is_scoped_task(sym: i32, is_scoped_task: i32):
        let opt = self.scope_name_map.get(sym)
        if opt.is_some():
            let idx: i32 = opt.unwrap()
            self.bind_is_scoped_task.set_i32(idx as i64, is_scoped_task)

    fn scope_lookup_is_ephemeral_task(sym: i32) -> i32:
        let opt = self.scope_name_map.get(sym)
        if opt.is_some():
            return self.bind_provenance.get(opt.unwrap() as i64).is_ephemeral_task
        0

    fn scope_set_is_ephemeral_task(sym: i32, is_ephemeral_task: i32):
        let opt = self.scope_name_map.get(sym)
        if opt.is_some():
            let idx = opt.unwrap()
            let slot_idx = idx as i64
            with self.bind_provenance.slot(slot_idx) as mut slot:
                var provenance = slot.get()
                provenance.is_ephemeral_task = is_ephemeral_task
                slot.set(provenance)

    fn scope_lookup_is_non_send_task(sym: i32) -> i32:
        let opt = self.scope_name_map.get(sym)
        if opt.is_some():
            return self.bind_provenance.get(opt.unwrap() as i64).is_non_send_task
        0

    fn scope_set_is_non_send_task(sym: i32, is_non_send_task: i32):
        let opt = self.scope_name_map.get(sym)
        if opt.is_some():
            let idx = opt.unwrap()
            let slot_idx = idx as i64
            with self.bind_provenance.slot(slot_idx) as mut slot:
                var provenance = slot.get()
                provenance.is_non_send_task = is_non_send_task
                slot.set(provenance)

    fn scope_lookup_is_ephemeral_value(sym: i32) -> i32:
        let opt = self.scope_name_map.get(sym)
        if opt.is_some():
            return self.bind_provenance.get(opt.unwrap() as i64).is_ephemeral_value
        0

    fn scope_set_is_ephemeral_value(sym: i32, is_ephemeral_value: i32):
        let opt = self.scope_name_map.get(sym)
        if opt.is_some():
            let idx = opt.unwrap()
            let slot_idx = idx as i64
            with self.bind_provenance.slot(slot_idx) as mut slot:
                var provenance = slot.get()
                provenance.is_ephemeral_value = is_ephemeral_value
                slot.set(provenance)

    fn scope_set_effect_dep_sym(sym: i32, dep_sym: i32):
        let opt = self.scope_name_map.get(sym)
        if opt.is_some():
            let idx = opt.unwrap()
            let slot_idx = idx as i64
            with self.bind_provenance.slot(slot_idx) as mut slot:
                var provenance = slot.get()
                provenance.effect_dep_sym = dep_sym
                slot.set(provenance)

    fn binding_effect_dep_sym(sym: i32) -> i32:
        let opt = self.scope_name_map.get(sym)
        if opt.is_some():
            return self.bind_provenance.get(opt.unwrap() as i64).effect_dep_sym
        0

    fn scope_is_view_bound(sym: i32) -> i32:
        let opt = self.scope_name_map.get(sym)
        if opt.is_some():
            return self.bind_is_view_bound.get(opt.unwrap() as i64)
        0

    fn scope_set_is_view_bound(sym: i32):
        let opt = self.scope_name_map.get(sym)
        if opt.is_some():
            let idx: i32 = opt.unwrap()
            self.bind_is_view_bound.set_i32(idx as i64, 1)

    mut fn scope_set_state(sym: i32, state: i32):
        if sema_debug_move_enabled() != 0:
            let dbg_name = with_str_clone_ref(self.pool_resolve(sym))
            with_eprint(f"[state] sym=" ++ dbg_name ++ f" -> {state}")
        let opt = self.scope_name_map.get(sym)
        if opt.is_some():
            if state == VarState.MOVED:
                self.check_live_views_for_origin(sym, sym)
                self.clear_moved_fields_for_binding(sym)
            else if state == VarState.LIVE:
                self.clear_moved_fields_for_binding(sym)
            self.bind_states.set_i32(opt.unwrap() as i64, state)

    fn scope_has(sym: i32) -> i32:
        if self.scope_name_map.contains(sym): return 1
        0

    fn scope_binding_index(sym: i32) -> i32:
        let opt = self.scope_name_map.get(sym)
        if opt.is_some():
            return opt.unwrap()
        -1

    mut fn push_move_control_flow_context(supports_drop_flags: i32):
        self.move_control_flow_depth = self.move_control_flow_depth + 1
        self.move_control_flow_binding_starts.push(self.bind_names.len() as i32)
        self.move_control_flow_supports_drop_flags.push(supports_drop_flags)

    mut fn pop_move_control_flow_context():
        if self.move_control_flow_depth > 0:
            self.move_control_flow_depth = self.move_control_flow_depth - 1
        if self.move_control_flow_binding_starts.len() as i32 > 0:
            self.move_control_flow_binding_starts.pop()
        if self.move_control_flow_supports_drop_flags.len() as i32 > 0:
            self.move_control_flow_supports_drop_flags.pop()

    fn outer_binding_has_unsupported_move_context(sym: i32) -> i32:
        let bind_idx = self.scope_binding_index(sym)
        if bind_idx < 0:
            return 0
        let ctx_count = self.move_control_flow_binding_starts.len() as i32
        var ci = 0
        while ci < ctx_count:
            let start = self.move_control_flow_binding_starts.get(ci as i64)
            if bind_idx < start and self.move_control_flow_supports_drop_flags.get(ci as i64) == 0:
                return 1
            ci = ci + 1
        0

    // Snapshot current bind_states so early-returning if/else branches don't
    // permanently mark outer variables as MOVED.
    fn save_scope_states() -> Vec[i32]:
        let count = self.bind_states.len() as i32
        var snapshot: Vec[i32] = Vec.new()
        for i in 0..count:
            snapshot.push(self.bind_states.get(i as i64))
        snapshot

    fn restore_scope_states(snapshot: &Vec[i32]):
        let count = snapshot.len() as i32
        for i in 0..count:
            self.bind_states.set_i32(i as i64, snapshot.get(i as i64))

    // #695: partial (field/index) move state lives in the moved_field_* parallel
    // arrays, SEPARATE from bind_states. check_if_expr / match / loop merge
    // bind_states across branches with divergence handling, but not these — so a
    // field moved on a divergent (returning) branch wrongly poisoned the
    // fall-through. These mirror save/restore/merge for the field-move set.
    fn save_moved_field_state() -> MovedFieldSnap:
        MovedFieldSnap {
            base: sema_clone_i32_vec(&self.moved_field_base_syms),
            starts: sema_clone_i32_vec(&self.moved_field_path_starts),
            counts: sema_clone_i32_vec(&self.moved_field_path_counts),
            syms: sema_clone_i32_vec(&self.moved_field_path_syms),
        }

    mut fn restore_moved_field_state(snap: &MovedFieldSnap):
        self.moved_field_base_syms = sema_clone_i32_vec(&snap.base)
        self.moved_field_path_starts = sema_clone_i32_vec(&snap.starts)
        self.moved_field_path_counts = sema_clone_i32_vec(&snap.counts)
        self.moved_field_path_syms = sema_clone_i32_vec(&snap.syms)

    // Set the live field-move set to the union of two branch-exit snapshots
    // (a field is moved-after iff moved at some non-divergent exit). Concatenation
    // realizes the union — duplicate (base,path) entries are harmless to the
    // membership tests. path_starts from `b` are offset past `a`'s syms.
    // True iff snapshot entry (base_sym, path) is already present in the
    // result arrays being built — so the union DEDUPS. Without this the union
    // concatenated, and across N nested branches the moved-field set grew ~2^N
    // (a field moved on both paths re-added every merge), detonating memory
    // once the flip made Vec fields drop-tracked (#695 follow-up; the set must
    // stay bounded by the distinct field-paths in the function).
    fn moved_field_entry_present(base: &Vec[i32], starts: &Vec[i32], counts: &Vec[i32], syms: &Vec[i32], base_sym: i32, src_start: i32, src_count: i32, src_syms: &Vec[i32]) -> bool:
        for i in 0..base.len() as i32:
            if base.get(i as i64) != base_sym:
                continue
            if counts.get(i as i64) != src_count:
                continue
            let dst_start = starts.get(i as i64)
            var same = true
            for k in 0..src_count:
                if syms.get((dst_start + k) as i64) != src_syms.get((src_start + k) as i64):
                    same = false
                    break
            if same:
                return true
        false

    mut fn set_moved_field_union(a: &MovedFieldSnap, b: &MovedFieldSnap):
        var base: Vec[i32] = Vec.new()
        var starts: Vec[i32] = Vec.new()
        var counts: Vec[i32] = Vec.new()
        var syms: Vec[i32] = Vec.new()
        for i in 0..a.base.len() as i32:
            starts.push(syms.len() as i32)
            counts.push(a.counts.get(i as i64))
            base.push(a.base.get(i as i64))
            let s = a.starts.get(i as i64)
            let c = a.counts.get(i as i64)
            for k in 0..c:
                syms.push(a.syms.get((s + k) as i64))
        for i in 0..b.base.len() as i32:
            let bs = b.starts.get(i as i64)
            let bc = b.counts.get(i as i64)
            if self.moved_field_entry_present(&base, &starts, &counts, &syms, b.base.get(i as i64), bs, bc, &b.syms):
                continue
            starts.push(syms.len() as i32)
            counts.push(bc)
            base.push(b.base.get(i as i64))
            for k in 0..bc:
                syms.push(b.syms.get((bs + k) as i64))
        self.moved_field_base_syms = move base
        self.moved_field_path_starts = move starts
        self.moved_field_path_counts = move counts
        self.moved_field_path_syms = move syms

    // Conservative union of move-state across two control-flow branches, for the
    // MaybeUninitialized use-checking half (see docs/branch-merge-soundness.md). A
    // binding is MOVED after the construct iff it is MOVED on ANY non-diverging
    // branch (so a value moved on one path cannot be used after — use-after-move
    // soundness); divergent branches (TY_NEVER) contribute nothing. If both branches
    // diverge the continuation is unreachable, so fall back to the entry state.
    fn merge_branch_move_states(entry: &Vec[i32], a: &Vec[i32], a_diverges: i32, b: &Vec[i32], b_diverges: i32) -> Vec[i32]:
        var out: Vec[i32] = Vec.new()
        let n = entry.len() as i32
        if a_diverges != 0 and b_diverges != 0:
            for i in 0..n:
                out.push(entry.get(i as i64))
            return out
        for i in 0..n:
            var moved = 0
            if a_diverges == 0 and i < a.len() as i32 and a.get(i as i64) == VarState.MOVED:
                moved = 1
            if b_diverges == 0 and i < b.len() as i32 and b.get(i as i64) == VarState.MOVED:
                moved = 1
            out.push(if moved != 0: VarState.MOVED else: VarState.LIVE)
        out

    // Pointwise union for accumulating a join over N branches/arms (e.g. match): a
    // binding is MOVED in the result iff MOVED in either input. Seed the accumulator
    // with the entry state (the implicit no-match/fallthrough path) and fold each
    // non-diverging arm exit into it; see docs/branch-merge-soundness.md.
    fn union_move_states(base: &Vec[i32], other: &Vec[i32]) -> Vec[i32]:
        var out: Vec[i32] = Vec.new()
        let n = base.len() as i32
        for i in 0..n:
            let bv = base.get(i as i64)
            let ov = if i < other.len() as i32: other.get(i as i64) else: VarState.LIVE
            out.push(if bv == VarState.MOVED or ov == VarState.MOVED: VarState.MOVED else: VarState.LIVE)
        out

    // ── Loop move-state (#613, docs/branch-merge-soundness.md §6.7) ──────────────

    mut fn emit_loop_carried_move_error(bind_idx: i32, loop_node: i32):
        let sym = self.bind_names.get(bind_idx as i64)
        let name: str = with_str_clone_ref(self.pool_resolve(sym))
        self.emit_error_with_help("use of moved value: `" ++ name ++ "` is moved inside a loop and not reinitialized before the loop repeats", loop_node, "reinitialize `" ++ name ++ "` on every path before the loop repeats, or move it only on a path that exits the loop")

    // Allocate this loop's break-flag region in loop_break_flat (called by each loop
    // construct after push_label_frame). One VarState slot per outer binding, init
    // LIVE; freed in finalize_loop_move_state.
    fn alloc_loop_break_region(frame_idx: i32):
        if frame_idx < 0 or frame_idx >= self.label_break_off.len() as i32:
            return
        let count: i32 = self.label_loop_entry_binds.get(frame_idx as i64)
        self.label_break_off.set_i32(frame_idx as i64, self.loop_break_flat.len() as i32)
        var i = 0
        while i < count:
            self.loop_break_flat.push(VarState.LIVE)
            // Capture the loop-entry move-state (fresh push keeps loop_entry_flat in
            // lockstep with loop_break_flat, so label_break_off indexes both). A
            // binding already MOVED here was moved *before* the loop, not across a
            // back-edge — the continue check must not flag it (#696).
            let es = if i < self.bind_states.len() as i32: self.bind_states.get(i as i64) else: VarState.LIVE
            self.loop_entry_flat.push(es)
            i = i + 1

    // At a `break`, union the current move-state of the target loop's outer bindings
    // into that loop's break-flag region (the union of move-states over all breaks to
    // that loop), used to compute the post-loop state.
    mut fn capture_loop_break_move_state(frame_idx: i32):
        if frame_idx < 0 or frame_idx >= self.label_break_off.len() as i32:
            return
        let off = self.label_break_off.get(frame_idx as i64)
        if off < 0:
            return
        let boundary = self.label_loop_entry_binds.get(frame_idx as i64)
        var i = 0
        while i < boundary:
            if i < self.bind_states.len() as i32 and self.bind_states.get(i as i64) == VarState.MOVED and self.type_needs_drop(self.bind_types.get(i as i64)) != 0:
                self.loop_break_flat.set_i32((off + i) as i64, VarState.MOVED)
            i = i + 1
        self.label_break_seen.set_i32(frame_idx as i64, 1)

    // The ONE loop back-edge carried-move predicate. A binding is used moved on the
    // next iteration iff it was LIVE at loop entry but MOVED at the back-edge, and
    // its type needs drop (a moved-out POD value is a non-destructive copy today,
    // #607, so only Drop/transitive-Drop moves are errors). Both back-edges — the
    // fall-through (finalize_loop_move_state) and `continue`
    // (check_loop_continue_carried_move) — MUST call this; re-inlining the condition
    // per edge is exactly how #696 happened (the continue edge dropped the
    // entry==LIVE guard). `needs_drop` is passed in (callers already compute it) so
    // this stays a pure predicate. See docs/decisions.md.
    fn is_loop_carried_move(entry_state: i32, cur_state: i32, needs_drop: i32) -> i32:
        if entry_state == VarState.LIVE and cur_state == VarState.MOVED and needs_drop != 0: 1 else: 0

    // A `continue` jumps to the loop's back-edge: any outer binding moved (and not
    // reinitialized) at the continue would be used moved on the next iteration.
    mut fn check_loop_continue_carried_move(frame_idx: i32, node: i32):
        if frame_idx < 0 or frame_idx >= self.label_loop_entry_binds.len() as i32:
            return
        let boundary = self.label_loop_entry_binds.get(frame_idx as i64)
        let off = if frame_idx < self.label_break_off.len() as i32: self.label_break_off.get(frame_idx as i64) else: -1
        let trace_move = runtime_getenv("WITH_TRACE_MOVE").len() > 0
        if trace_move:
            with_eprint(f"[trace-move] continue back-edge: frame={frame_idx} bindings={boundary}")
        var i = 0
        while i < boundary:
            let entry_state = if off >= 0 and (off + i) < self.loop_entry_flat.len() as i32: self.loop_entry_flat.get((off + i) as i64) else: VarState.LIVE
            let cur_state = if i < self.bind_states.len() as i32: self.bind_states.get(i as i64) else: VarState.LIVE
            let nd = self.type_needs_drop(self.bind_types.get(i as i64))
            if trace_move and (entry_state == VarState.MOVED or cur_state == VarState.MOVED):
                let nm = self.pool_resolve(self.bind_names.get(i as i64))
                // old_verdict = the pre-#696 check (current-MOVED alone, ignores entry);
                // new_verdict = the corrected check (LIVE at entry, MOVED at back-edge).
                with_eprint(f"[trace-move]   #{i} `{nm}` entry={entry_state} at_continue={cur_state} needs_drop={nd} old_verdict={if cur_state == VarState.MOVED and nd != 0: 1 else: 0} new_verdict={self.is_loop_carried_move(entry_state, cur_state, nd)}")
            if self.is_loop_carried_move(entry_state, cur_state, nd) != 0:
                self.emit_loop_carried_move_error(i, node)
            i = i + 1

    // After a loop body: (1) the back-edge use-after-move check — an outer binding
    // LIVE at entry but MOVED at body-end is moved across the back-edge without
    // reinit (skipped when the body diverges, so there is no fall-through back-edge);
    // (2) compute the post-loop move-state. `has_condition_exit` is 1 for while/for
    // (the loop may exit via its condition with the entry or body-end state) and 0
    // for `loop` (exits only via break). The break accumulator carries moves that a
    // break propagated out of the loop.
    mut fn finalize_loop_move_state(entry: &Vec[i32], frame_idx: i32, body_diverges: i32, has_condition_exit: i32, loop_node: i32):
        let entry_count = entry.len() as i32
        // WITH_TRACE_MOVE: dump the loop back-edge move-check inputs per binding
        // (the sema-phase analog of --trace-ownership). Prints name, entry-state,
        // body-end-state, needs-drop, and the carried-move verdict — the direct
        // answer to "why is X flagged moved-in-a-loop?".
        let trace_move = runtime_getenv("WITH_TRACE_MOVE").len() > 0
        if trace_move:
            with_eprint(f"[trace-move] loop finalize: body_diverges={body_diverges} bindings={entry_count}")
        if body_diverges == 0:
            var i = 0
            while i < entry_count:
                // Scoped to needs-drop values (like the conditional-move feature): a
                // moved-out POD Vec is a non-destructive copy today (#607), and the
                // codebase relies on that, so only Drop/transitive-Drop loop-carried
                // moves are use-after-move errors here.
                let e_state = entry.get(i as i64)
                let cur_state = if i < self.bind_states.len() as i32: self.bind_states.get(i as i64) else: VarState.LIVE
                let nd = self.type_needs_drop(self.bind_types.get(i as i64))
                if trace_move and (e_state == VarState.MOVED or cur_state == VarState.MOVED):
                    let nm = self.pool_resolve(self.bind_names.get(i as i64))
                    with_eprint(f"[trace-move]   #{i} `{nm}` entry={e_state} body_end={cur_state} needs_drop={nd} carried_move={self.is_loop_carried_move(e_state, cur_state, nd)}")
                if self.is_loop_carried_move(e_state, cur_state, nd) != 0:
                    self.emit_loop_carried_move_error(i, loop_node)
                i = i + 1
        var post: Vec[i32] = if has_condition_exit != 0:
            let body_end = self.save_scope_states()
            self.union_move_states(entry, &body_end)
        else:
            self.union_move_states(entry, entry)
        if frame_idx >= 0 and frame_idx < self.label_break_seen.len() as i32 and self.label_break_seen.get(frame_idx as i64) != 0:
            let off = self.label_break_off.get(frame_idx as i64)
            if off >= 0:
                var brk: Vec[i32] = Vec.new()
                var i = 0
                while i < entry_count:
                    let v = if (off + i) < self.loop_break_flat.len() as i32: self.loop_break_flat.get((off + i) as i64) else: VarState.LIVE
                    brk.push(v)
                    i = i + 1
                post = self.union_move_states(&post, &brk)
        // Free this loop's break-flag and entry-state regions (both are the top of
        // their flat stacks and share the same offset).
        if frame_idx >= 0 and frame_idx < self.label_break_off.len() as i32:
            let off: i32 = self.label_break_off.get(frame_idx as i64)
            if off >= 0:
                while self.loop_break_flat.len() as i32 > off:
                    self.loop_break_flat.pop()
                while self.loop_entry_flat.len() as i32 > off:
                    self.loop_entry_flat.pop()
        self.restore_scope_states(&post)

    fn clear_binding_view_deps(sym: i32):
        let opt = self.scope_name_map.get(sym)
        if opt.is_some():
            let idx = opt.unwrap()
            let slot_idx = idx as i64
            with self.bind_provenance.slot(slot_idx) as mut slot:
                var provenance = slot.get()
                provenance.view_origin_mask = 0
                provenance.view_dep_start = 0
                provenance.view_dep_count = 0
                provenance.poisoned_origin_sym = 0
                provenance.poisoned_origin_node = 0
                provenance.poisoned_binding_node = 0
                slot.set(provenance)

    fn set_binding_view_deps(sym: i32, param_mask: i32, deps: &Vec[i32]):
        if sym == 0:
            return
        if param_mask == 0 and deps.len() == 0:
            self.clear_binding_view_deps(sym)
            return
        let start = self.binding_view_dep_data.len() as i32
        for i in 0..deps.len() as i32:
            self.binding_view_dep_data.push(deps.get(i as i64))
        let opt = self.scope_name_map.get(sym)
        if opt.is_some():
            let idx = opt.unwrap()
            let slot_idx = idx as i64
            with self.bind_provenance.slot(slot_idx) as mut slot:
                var provenance = slot.get()
                provenance.view_origin_mask = param_mask
                provenance.view_dep_start = start
                provenance.view_dep_count = deps.len() as i32
                provenance.poisoned_origin_sym = 0
                provenance.poisoned_origin_node = 0
                provenance.poisoned_binding_node = 0
                slot.set(provenance)

    // #625 (viral-escape): union additional view origins into a binding that
    // already exists — used when a store (Vec.push / HashMap.insert) adds the
    // pushed element's borrow origins to the container binding, so a later escape
    // of the container is caught by the ephemeral-escape checks.
    fn add_binding_view_deps(sym: i32, param_mask: i32, deps: &Vec[i32]):
        if sym == 0:
            return
        if param_mask == 0 and deps.len() == 0:
            return
        var merged: Vec[i32] = Vec.new()
        let existing = self.binding_view_dep_count(sym)
        for i in 0..existing:
            merged = self.push_unique_i32(move merged, self.binding_view_dep_at(sym, i))
        for i in 0..deps.len() as i32:
            merged = self.push_unique_i32(move merged, deps.get(i as i64))
        let merged_mask = self.binding_view_origin_mask(sym) | param_mask
        self.set_binding_view_deps(sym, merged_mask, merged)

    fn binding_view_origin_mask(sym: i32) -> i32:
        let opt = self.scope_name_map.get(sym)
        if opt.is_some():
            return self.bind_provenance.get(opt.unwrap() as i64).view_origin_mask
        0

    fn binding_view_dep_count(sym: i32) -> i32:
        let opt = self.scope_name_map.get(sym)
        if opt.is_some():
            return self.bind_provenance.get(opt.unwrap() as i64).view_dep_count
        0

    fn binding_view_dep_at(sym: i32, idx: i32) -> i32:
        let opt = self.scope_name_map.get(sym)
        if not opt.is_some():
            return 0
        let provenance = self.bind_provenance.get(opt.unwrap() as i64)
        let count = provenance.view_dep_count
        if idx < 0 or idx >= count:
            return 0
        let start = provenance.view_dep_start
        self.binding_view_dep_data.get((start + idx) as i64)

    fn binding_depends_on_origin(sym: i32, origin_sym: i32) -> i32:
        let count = self.binding_view_dep_count(sym)
        for i in 0..count:
            if self.binding_view_dep_at(sym, i) == origin_sym:
                return 1
        0

    fn mark_binding_poisoned_by_origin(view_sym: i32, origin_sym: i32, origin_node: i32):
        let opt = self.scope_name_map.get(view_sym)
        if not opt.is_some():
            return
        let idx = opt.unwrap()
        let slot_idx = idx as i64
        with self.bind_provenance.slot(slot_idx) as mut slot:
            var provenance = slot.get()
            if provenance.poisoned_origin_sym == 0:
                provenance.poisoned_origin_sym = origin_sym
                provenance.poisoned_origin_node = origin_node
                provenance.poisoned_binding_node = if self.binding_value_nodes.contains(view_sym): self.binding_value_nodes.get(view_sym).unwrap() else: self.binding_decl_node(view_sym)
                slot.set(provenance)

    fn binding_poisoned_origin_sym(sym: i32) -> i32:
        let opt = self.scope_name_map.get(sym)
        if opt.is_some():
            return self.bind_provenance.get(opt.unwrap() as i64).poisoned_origin_sym
        0

    fn binding_poisoned_origin_node(sym: i32) -> i32:
        let opt = self.scope_name_map.get(sym)
        if opt.is_some():
            return self.bind_provenance.get(opt.unwrap() as i64).poisoned_origin_node
        0

    fn binding_poisoned_binding_node(sym: i32) -> i32:
        let opt = self.scope_name_map.get(sym)
        if opt.is_some():
            return self.bind_provenance.get(opt.unwrap() as i64).poisoned_binding_node
        0

    fn poison_live_views_for_origin(origin_sym: i32, origin_node: i32):
        if origin_sym == 0:
            return
        for bi in 0..self.bind_names.len() as i32:
            let view_sym = self.bind_names.get(bi as i64)
            if view_sym == origin_sym:
                continue
            if self.bind_states.get(bi as i64) != VarState.LIVE:
                continue
            if self.binding_depends_on_origin(view_sym, origin_sym) != 0 or self.binding_value_depends_on_origin(view_sym, origin_sym) != 0:
                self.mark_binding_poisoned_by_origin(view_sym, origin_sym, origin_node)

    fn expr_view_depends_on_origin(node: i32, origin_sym: i32) -> i32:
        if node == 0 or origin_sym == 0:
            return 0
        let kind = self.ast.kind(node)
        if kind == NodeKind.NK_IDENT:
            return self.binding_depends_on_origin(self.ast.get_data0(node), origin_sym)
        if kind == NodeKind.NK_UNARY:
            let op = self.ast.get_data0(node)
            if op == UnaryOp.UOP_REF or op == UnaryOp.UOP_RAW_REF_CONST or op == UnaryOp.UOP_RAW_REF_MUT:
                if self.place_root_sym(self.ast.get_data1(node)) == origin_sym:
                    return 1
            return self.expr_view_depends_on_origin(self.ast.get_data1(node), origin_sym)
        if kind == NodeKind.NK_GROUPED or kind == NodeKind.NK_CAST or kind == NodeKind.NK_COMPTIME or kind == NodeKind.NK_NO_SUSPEND:
            return self.expr_view_depends_on_origin(self.ast.get_data0(node), origin_sym)
        if kind == NodeKind.NK_FIELD_ACCESS or kind == NodeKind.NK_COMPUTED_FIELD_ACCESS or kind == NodeKind.NK_INDEX:
            return self.expr_view_depends_on_origin(self.ast.get_data0(node), origin_sym)
        if kind == NodeKind.NK_BLOCK:
            return self.expr_view_depends_on_origin(self.ast.get_data2(node), origin_sym)
        if kind == NodeKind.NK_IF_EXPR:
            if self.expr_view_depends_on_origin(self.ast.get_data1(node), origin_sym) != 0:
                return 1
            return self.expr_view_depends_on_origin(self.ast.get_data2(node), origin_sym)
        if kind == NodeKind.NK_CALL:
            let dep_count = self.expr_view_dep_count(node)
            for i in 0..dep_count:
                if self.expr_view_dep_at(node, i) == origin_sym:
                    return 1
            let callee = self.ast.get_data0(node)
            if self.ast.kind(callee) == NodeKind.NK_IDENT:
                let fn_sym_raw = self.ast.get_data0(callee)
                let fn_sym = if self.comp_resolved.contains(node): self.comp_resolved.get(node).unwrap() else: fn_sym_raw
                var sig_idx = self.get_sig(fn_sym)
                if sig_idx < 0:
                    let sema_fn_sym = self.pool_lookup_symbol(self.pool_resolve(fn_sym))
                    sig_idx = self.get_sig(sema_fn_sym)
                if sig_idx >= 0:
                    let has_resolved = self.has_resolved_call_args(node)
                    let extra_start = self.ast.get_data1(node)
                    let arg_count = if has_resolved != 0: self.get_resolved_call_arg_count(node) else: self.ast.get_data2(node)
                    let param_count = self.sig_get_param_count(sig_idx)
                    for pi in 0..param_count:
                        if (self.sig_param_effect(sig_idx, pi) & EFF_ESCAPE_VIEW) == 0:
                            continue
                        let origin_mask = self.sig_param_view_origin(sig_idx, pi)
                        for origin_pi in 0..param_count:
                            if sema_param_origin_mask_contains(origin_mask, origin_pi) == 0:
                                continue
                            if origin_pi >= arg_count:
                                continue
                            let origin_arg = if has_resolved != 0: self.get_resolved_call_arg(node, origin_pi) else: self.ast.get_extra(extra_start + origin_pi)
                            if self.place_root_sym(origin_arg) == origin_sym or self.expr_view_depends_on_origin(origin_arg, origin_sym) != 0:
                                return 1
            return 0
        if kind == NodeKind.NK_STRUCT_LIT:
            let extra_start = self.ast.get_data1(node)
            let field_count = self.ast.get_data2(node)
            for fi in 0..field_count:
                if self.expr_view_depends_on_origin(self.ast.get_extra(extra_start + fi * 2 + 1), origin_sym) != 0:
                    return 1
            return 0
        let dep_count = self.expr_view_dep_count(node)
        for i in 0..dep_count:
            if self.expr_view_dep_at(node, i) == origin_sym:
                return 1
        0

    fn binding_value_depends_on_origin(sym: i32, origin_sym: i32) -> i32:
        if not self.binding_value_nodes.contains(sym):
            return 0
        self.expr_view_depends_on_origin(self.binding_value_nodes.get(sym).unwrap(), origin_sym)

    // D29 scaffolding (#750): shadow-case tier plumbing. A sym is shadowed when
    // both a prelude-closure module and user code declare a type under it; only
    // then do impl/drop queries discriminate by tier (registration-time truth,
    // valid in frozen phases too). Unshadowed syms take the flat path unchanged.
    fn type_sym_is_shadowed(sym: i32) -> i32:
        if sym == 0 or not self.type_sym_tier_mask.contains(sym):
            return 0
        if self.type_sym_tier_mask.get(sym).unwrap() == 3: 1 else: 0

    fn type_tid_std_tier(tid: i32) -> i32:
        if not self.type_tid_is_std.contains(tid):
            return 0
        self.type_tid_is_std.get(tid).unwrap()

    fn impl_record_matches_tier(record_idx: i32, want_std: i32) -> i32:
        if record_idx < 0 or record_idx >= self.impl_extra_is_std.len() as i32:
            return 1
        if self.impl_extra_is_std.get(record_idx as i64) == want_std: 1 else: 0

    fn type_has_drop_impl(tid: i32) -> i32:
        if tid == 0:
            return 0
        let resolved = self.resolve_alias(tid as TypeId)
        var owner_sym = self.get_type_name(resolved)
        if owner_sym == 0 and self.get_type_kind(resolved) == TypeKind.TY_GENERIC_INST:
            owner_sym = self.get_generic_inst_base(resolved as i32)
        if owner_sym != 0 and self.type_sym_is_shadowed(owner_sym) != 0:
            let want_std = self.type_tid_std_tier(resolved as i32)
            if self.select_trait_impl_tiered(owner_sym, self.syms.drop, want_std) != 0:
                return 1
            return 0
        if owner_sym != 0 and self.has_drop_method(owner_sym) != 0:
            return 1
        if owner_sym != 0 and self.impl_lookup.contains(owner_sym):
            let idx = self.impl_lookup.get(owner_sym).unwrap()
            let start = self.impl_starts.get(idx as i64)
            let count = self.impl_counts.get(idx as i64)
            for i in 0..count:
                if self.impl_extra.get((start + i) as i64) == self.syms.drop:
                    return 1
        0

    // Transitive needs-drop: does a value of this type run any destructor effect on
    // drop? True if the type has its own `impl Drop`, is a channel endpoint, or any
    // field / tuple-or-array element / enum-variant payload transitively needs drop.
    // `type_has_drop_impl` is shallow (own impl only); this recurses so that an
    // aggregate holding a Drop value is treated as owning it (gates move-consume at
    // construction and drop emission for the contents). Pointers/refs and primitives
    // stop the recursion, so by-value type graphs (which are acyclic) terminate; the
    // visit guard is defensive insurance against an unexpected cycle.
    mut fn type_needs_drop(tid: i32) -> i32:
        if tid == 0:
            return 0
        let resolved = self.resolve_alias(tid as TypeId)
        if self.type_has_drop_impl(resolved as i32) != 0:
            return 1
        let tk = self.get_type_kind(resolved)
        // #747 / D28 ruling 1: an owned str frees its buffer at scope end.
        if tk == TypeKind.TY_STR:
            return 1
        if tk == TypeKind.TY_GENERIC_INST:
            let base_sym = self.get_generic_inst_base(resolved as i32)
            // #691/D18 and D22 Stage 6: compiler-modeled collection handles own
            // runtime allocations independently of whether their elements need
            // drop. Codegen has exact drop glue for these opaque handles, so the
            // ownership classifier must agree; otherwise an aggregate move copies
            // the handle without resetting its source and both places free it.
            // BTreeMap/BTreeSet are ordinary Vec-backed structs and are discovered
            // transitively below rather than duplicated in this special case.
            if base_sym == self.syms.vec or base_sym == self.syms.hashmap or base_sym == self.syms.hashset or base_sym == self.syms.slotmap:
                return 1
            let base_name = self.pool_resolve(base_sym)
            if base_name == "Sender" or base_name == "Receiver":
                return 1
        if self.needs_drop_visit.contains(resolved as i32):
            return 0
        self.needs_drop_visit.insert(resolved as i32)
        var result = 0
        if tk == TypeKind.TY_TUPLE:
            let te_start = self.get_type_d0(resolved)
            let elem_count = self.get_type_d1(resolved)
            for ei in 0..elem_count:
                if self.type_needs_drop(self.type_extra.get((te_start + ei) as i64)) != 0:
                    result = 1
                    break
        else if tk == TypeKind.TY_ARRAY or tk == TypeKind.TY_RANGE:
            result = self.type_needs_drop(self.get_type_d0(resolved))
        else:
            let field_count = self.type_reflection_field_count(resolved as i32)
            for fi in 0..field_count:
                let field_ty = self.type_reflection_field_type(resolved as i32, fi)
                if self.type_needs_drop(field_ty) != 0:
                    result = 1
                    break
            if result == 0:
                let variant_count = self.type_reflection_variant_count(resolved as i32)
                var vidx = 0
                while vidx < variant_count and result == 0:
                    let payload_count = self.type_reflection_variant_payload_count(resolved as i32, vidx)
                    for pi in 0..payload_count:
                        let payload_ty = self.type_reflection_variant_payload_type(resolved as i32, vidx, pi)
                        if self.type_needs_drop(payload_ty) != 0:
                            result = 1
                            break
                    vidx = vidx + 1
        let _ = self.needs_drop_visit.remove(resolved as i32)
        result

    // Whether a value of this type transitively carries a USER Drop impl
    // (W, Vec[W], Holder{item: W}). Narrower than `type_needs_drop`: pure
    // memory-managed types (str, Vec[str], HashMap[str, str]) answer 0 —
    // their cleanup is invisible, so a field let may observe them (D22),
    // while a user-Drop-bearing field stays an explicit ownership transfer
    // (err_use_after_move_*_field pins).
    mut fn type_carries_user_drop(tid: i32) -> i32:
        if tid == 0:
            return 0
        let resolved = self.resolve_alias(tid as TypeId)
        if self.type_has_drop_impl(resolved as i32) != 0:
            return 1
        if self.needs_drop_visit.contains(resolved as i32):
            return 0
        self.needs_drop_visit.insert(resolved as i32)
        var result = 0
        let tk = self.get_type_kind(resolved)
        if tk == TypeKind.TY_GENERIC_INST:
            let arg_count = self.get_generic_inst_arg_count(resolved as i32)
            for ai in 0..arg_count:
                if self.type_carries_user_drop(self.get_generic_inst_arg(resolved as i32, ai)) != 0:
                    result = 1
                    break
        else if tk == TypeKind.TY_TUPLE:
            let te_start = self.get_type_d0(resolved)
            let elem_count = self.get_type_d1(resolved)
            for ei in 0..elem_count:
                if self.type_carries_user_drop(self.type_extra.get((te_start + ei) as i64)) != 0:
                    result = 1
                    break
        else if tk == TypeKind.TY_ARRAY or tk == TypeKind.TY_RANGE:
            result = self.type_carries_user_drop(self.get_type_d0(resolved))
        else:
            let field_count = self.type_reflection_field_count(resolved as i32)
            for fi in 0..field_count:
                let cf_ty = self.type_reflection_field_type(resolved as i32, fi)
                if self.type_carries_user_drop(cf_ty) != 0:
                    result = 1
                    break
            if result == 0:
                let variant_count = self.type_reflection_variant_count(resolved as i32)
                var vidx = 0
                while vidx < variant_count and result == 0:
                    let payload_count = self.type_reflection_variant_payload_count(resolved as i32, vidx)
                    for pi in 0..payload_count:
                        let cp_ty = self.type_reflection_variant_payload_type(resolved as i32, vidx, pi)
                        if self.type_carries_user_drop(cp_ty) != 0:
                            result = 1
                            break
                    vidx = vidx + 1
        let _ = self.needs_drop_visit.remove(resolved as i32)
        result

    mut fn emit_implicit_drop_view_use_error(view_sym: i32, origin_sym: i32, origin_node: i32):
        let view_name = self.pool_resolve(view_sym)
        let origin_name = self.pool_resolve(origin_sym)
        let view_node = self.binding_decl_node(view_sym)
        let primary_node = if view_node != 0: view_node else: origin_node
        let primary_start = if primary_node != 0: self.ast.get_start(primary_node) else: 0
        let primary_end = if primary_node != 0: self.ast.get_end(primary_node) else: 0
        var diag = Diagnostic.err("implicit drop of `" ++ view_name ++ "` uses `&" ++ origin_name ++ "` after `" ++ origin_name ++ "` is destroyed (§21.1 Rule 7)", Span { file: self.local_file_id, start: primary_start, end: primary_end })
        if view_node != 0:
            diag.add_label(Span { file: self.local_file_id, start: self.ast.get_start(view_node), end: self.ast.get_end(view_node) }, "Drop value retaining the borrow is declared here")
        if origin_node != 0:
            diag.add_label(Span { file: self.local_file_id, start: self.ast.get_start(origin_node), end: self.ast.get_end(origin_node) }, "`" ++ origin_name ++ "` is destroyed before `" ++ view_name ++ "` drops")
        diag.add_help("declare `" ++ view_name ++ "` after `" ++ origin_name ++ "`, or clear/drop `" ++ view_name ++ "` before `" ++ origin_name ++ "` goes out of scope")
        self.diags.emit(move diag)

    mut fn emit_returned_view_origin_use_error(view_sym: i32, use_node: i32):
        let origin_sym = self.binding_poisoned_origin_sym(view_sym)
        if origin_sym == 0:
            return
        let view_name = self.pool_resolve(view_sym)
        let origin_name = self.pool_resolve(origin_sym)
        let origin_node = self.binding_poisoned_origin_node(view_sym)
        let binding_node = self.binding_poisoned_binding_node(view_sym)
        let primary_start = if use_node != 0: self.ast.get_start(use_node) else: 0
        let primary_end = if use_node != 0: self.ast.get_end(use_node) else: 0
        var diag = Diagnostic.err("view `" ++ view_name ++ "` may originate from `" ++ origin_name ++ "`, which no longer lives here (§21.1 Rule 6)", Span { file: self.local_file_id, start: primary_start, end: primary_end })
        if binding_node != 0:
            diag.add_label(Span { file: self.local_file_id, start: self.ast.get_start(binding_node), end: self.ast.get_end(binding_node) }, "view origin was recorded here")
        if origin_node != 0:
            diag.add_label(Span { file: self.local_file_id, start: self.ast.get_start(origin_node), end: self.ast.get_end(origin_node) }, "`" ++ origin_name ++ "` is dropped at the end of its scope before this use")
        if use_node != 0:
            diag.add_label(Span { file: self.local_file_id, start: self.ast.get_start(use_node), end: self.ast.get_end(use_node) }, "view is used here after a possible origin died")
        diag.add_help("copy the data out before the origin's scope ends, or declare `" ++ origin_name ++ "` in the outer scope")
        self.diags.emit(move diag)

    fn binding_decl_node(sym: i32) -> i32:
        if self.binding_decl_nodes.contains(sym):
            return self.binding_decl_nodes.get(sym).unwrap()
        0

    fn binding_has_active_borrow_from(view_sym: i32, origin_sym: i32) -> i32:
        for bi in 0..self.borrow_refs.len() as i32:
            let ref_sym: i32 = self.borrow_refs.get(bi as i64)
            let place_sym: i32 = self.borrow_places.get(bi as i64)
            if ref_sym == view_sym and place_sym == origin_sym:
                return 1
        0

    mut fn check_live_views_for_origin(origin_sym: i32, node: i32):
        if origin_sym == 0:
            return
        // The migrated PCRE2 regex implementation predates view-origin
        // tracking and is goto-lowered C; it carries the same explicit
        // path exemption as the raw-pointer field rule.
        if sema_path_is_migrated_regex_implementation(self.current_module_path) != 0:
            return
        for bi in 0..self.bind_names.len() as i32:
            let view_sym: i32 = self.bind_names.get(bi as i64)
            if view_sym == origin_sym:
                continue
            if self.bind_states.get(bi as i64) != VarState.LIVE:
                continue
            let view_ty = self.bind_types.get(bi as i64)
            let view_has_drop = self.type_has_drop_impl(view_ty)
            let active_view = self.binding_depends_on_origin(view_sym, origin_sym) != 0 and self.binding_has_active_borrow_from(view_sym, origin_sym) != 0
            if active_view or (view_has_drop != 0 and self.binding_value_depends_on_origin(view_sym, origin_sym) != 0):
                let err_node = if node != 0: node else: self.binding_decl_node(view_sym)
                if view_has_drop != 0:
                    self.emit_implicit_drop_view_use_error(view_sym, origin_sym, err_node)
                    return
                let view_name: str = with_str_clone_ref(self.pool_resolve(view_sym))
                let origin_name: str = with_str_clone_ref(self.pool_resolve(origin_sym))
                self.emit_error("view '" ++ view_name ++ "' may outlive its origin '" ++ origin_name ++ "'", err_node)
                return

    fn set_expr_view_deps(expr_node: i32, param_mask: i32, deps: &Vec[i32]):
        if expr_node == 0:
            return
        if param_mask == 0 and deps.len() == 0:
            self.expr_view_param_origins.remove(expr_node)
            self.expr_view_dep_starts.remove(expr_node)
            self.expr_view_dep_counts.remove(expr_node)
            return
        self.expr_view_param_origins.insert(expr_node, param_mask)
        let start = self.expr_view_dep_data.len() as i32
        for i in 0..deps.len() as i32:
            self.expr_view_dep_data.push(deps.get(i as i64))
        self.expr_view_dep_starts.insert(expr_node, start)
        self.expr_view_dep_counts.insert(expr_node, deps.len() as i32)

    fn expr_view_origin_mask(expr_node: i32) -> i32:
        if self.expr_view_param_origins.contains(expr_node):
            return self.expr_view_param_origins.get(expr_node).unwrap()
        0

    fn expr_view_dep_count(expr_node: i32) -> i32:
        if self.expr_view_dep_counts.contains(expr_node):
            return self.expr_view_dep_counts.get(expr_node).unwrap()
        0

    fn expr_view_dep_at(expr_node: i32, idx: i32) -> i32:
        if not self.expr_view_dep_starts.contains(expr_node):
            return 0
        if not self.expr_view_dep_counts.contains(expr_node):
            return 0
        let count = self.expr_view_dep_counts.get(expr_node).unwrap()
        if idx < 0 or idx >= count:
            return 0
        let start = self.expr_view_dep_starts.get(expr_node).unwrap()
        self.expr_view_dep_data.get((start + idx) as i64)

    fn set_closure_capture_summary(closure_node: i32, capture_syms: &Vec[i32], capture_effs: &Vec[i32]):
        if closure_node == 0:
            return
        let start = self.closure_capture_summary_data.len() as i32
        let count = if capture_syms.len() < capture_effs.len(): capture_syms.len() as i32 else: capture_effs.len() as i32
        for i in 0..count:
            self.closure_capture_summary_data.push(capture_syms.get(i as i64))
            self.closure_capture_summary_data.push(capture_effs.get(i as i64))
        self.closure_capture_summary_starts.insert(closure_node, start)
        self.closure_capture_summary_counts.insert(closure_node, count)

    fn closure_capture_summary_count(closure_node: i32) -> i32:
        if self.closure_capture_summary_counts.contains(closure_node):
            return self.closure_capture_summary_counts.get(closure_node).unwrap()
        0

    fn closure_capture_summary_sym(closure_node: i32, idx: i32) -> i32:
        if not self.closure_capture_summary_starts.contains(closure_node):
            return 0
        let count = self.closure_capture_summary_count(closure_node)
        if idx < 0 or idx >= count:
            return 0
        let start = self.closure_capture_summary_starts.get(closure_node).unwrap()
        self.closure_capture_summary_data.get((start + idx * 2) as i64)

    fn closure_capture_summary_eff(closure_node: i32, idx: i32) -> i32:
        if not self.closure_capture_summary_starts.contains(closure_node):
            return 0
        let count = self.closure_capture_summary_count(closure_node)
        if idx < 0 or idx >= count:
            return 0
        let start = self.closure_capture_summary_starts.get(closure_node).unwrap()
        self.closure_capture_summary_data.get((start + idx * 2 + 1) as i64)

    fn is_mutable_global(sym: i32) -> i32:
        if self.mutable_global_syms.contains(sym): return 1
        0

    // docs/mut.md Rev 8 §15.12 — declared via `global X = ...`, no `var`.
    // Rebinding such a symbol is the §15.12 diagnostic.
    fn is_stable_global(sym: i32) -> i32:
        if self.stable_global_syms.contains(sym): return 1
        0

    fn is_active_async_scope_symbol(sym: i32) -> i32:
        var i = self.async_scope_names.len() as i32 - 1
        while i >= 0:
            if self.async_scope_names.get(i as i64) == sym:
                return 1
            i = i - 1
        0

    fn is_active_sync_scope_symbol(sym: i32) -> i32:
        var i = self.sync_scope_names.len() as i32 - 1
        while i >= 0:
            if self.sync_scope_names.get(i as i64) == sym:
                return 1
            i = i - 1
        0

    // ── Function signature management ────────────────────────────────

    fn add_sig(name: i32, fn_tid: i32, ret: i32, param_start: i32, param_count: i32, variadic: i32):
        let idx = self.sig_names.len() as i32
        self.sig_names.push(name)
        self.sig_type_ids.push(fn_tid)
        self.sig_ret_types.push(ret)
        self.sig_param_starts.push(param_start)
        self.sig_param_counts.push(param_count)
        self.sig_variadic.push(variadic)
        // docs/mutability.md Phase 4 — per-parameter effect storage.
        self.sig_param_eff_starts.push(self.sig_param_effects.len() as i32)
        for pi in 0..param_count:
            self.sig_param_effects.push(0)
            self.sig_param_direct_effects.push(0)
            self.sig_param_view_origins.push(0)
            self.sig_value_ref_abi_params.push(0)
        self.sig_receiver_modes.push(ReceiverMode.None as i32)
        self.sig_receiver_required_effects.push(0)
        self.sig_lookup.insert(name, idx)

    fn set_sig_receiver_mode(si: i32, mode: ReceiverMode):
        if si < 0 or si >= self.sig_receiver_modes.len() as i32:
            return
        self.sig_receiver_modes.set_i32(si as i64, mode as i32)

    fn sig_receiver_mode(si: i32) -> ReceiverMode:
        if si < 0 or si >= self.sig_receiver_modes.len() as i32:
            return ReceiverMode.None
        self.sig_receiver_modes.get(si as i64) as ReceiverMode

    fn receiver_mode_from_param(param_start: i32, param_count: i32) -> ReceiverMode:
        if param_count <= 0:
            return ReceiverMode.None
        if self.pool_resolve(self.ast.fn_param_name(param_start, 0)) != "self":
            return ReceiverMode.None
        let flags = self.ast.fn_param_flags(param_start, 0)
        if fn_param_is_move_self(flags) != 0:
            return ReceiverMode.Move
        if fn_param_is_mut_self(flags) != 0:
            return ReceiverMode.Mut
        if fn_param_is_ref_self(flags) != 0:
            return ReceiverMode.Read
        ReceiverMode.Missing

    fn sig_param_uses_value_ref_abi(si: i32, pi: i32) -> i32:
        if si < 0 or si >= self.sig_param_eff_starts.len() as i32:
            return 0
        let start = self.sig_param_eff_starts.get(si as i64)
        let count = self.sig_param_counts.get(si as i64)
        if pi < 0 or pi >= count:
            return 0
        self.sig_value_ref_abi_params.get((start + pi) as i64)

    fn set_sig_param_value_ref_abi(si: i32, pi: i32, value: i32):
        if si < 0 or si >= self.sig_param_eff_starts.len() as i32:
            return
        let start: i32 = self.sig_param_eff_starts.get(si as i64)
        let count = self.sig_param_counts.get(si as i64)
        if pi < 0 or pi >= count:
            return
        self.sig_value_ref_abi_params.set_i32((start + pi) as i64, value)

    fn sig_param_effect(si: i32, pi: i32) -> i32:
        if si < 0 or si >= self.sig_param_eff_starts.len() as i32:
            return 0
        let start = self.sig_param_eff_starts.get(si as i64)
        let count = self.sig_param_counts.get(si as i64)
        if pi < 0 or pi >= count:
            return 0
        self.sig_param_effects.get((start + pi) as i64)

    fn set_sig_param_effect(si: i32, pi: i32, eff: i32):
        if si < 0 or si >= self.sig_param_eff_starts.len() as i32:
            return
        let start: i32 = self.sig_param_eff_starts.get(si as i64)
        let count = self.sig_param_counts.get(si as i64)
        if pi < 0 or pi >= count:
            return
        self.sig_param_effects.set_i32((start + pi) as i64, eff)

    fn set_sig_param_direct_effect(si: i32, pi: i32, eff: i32):
        if si < 0 or si >= self.sig_param_eff_starts.len() as i32:
            return
        let start: i32 = self.sig_param_eff_starts.get(si as i64)
        let count = self.sig_param_counts.get(si as i64)
        if pi < 0 or pi >= count or start + pi >= self.sig_param_direct_effects.len() as i32:
            return
        self.sig_param_direct_effects.set_i32((start + pi) as i64, eff)

    fn find_effect_pin_param_index(param_start: i32, param_count: i32, param_sym: i32) -> i32:
        let param_name = self.pool_resolve(param_sym)
        for pi in 0..param_count:
            let candidate_sym = self.ast.fn_param_name(param_start, pi)
            if candidate_sym == param_sym:
                return pi
            if self.pool_resolve(candidate_sym) == param_name:
                return pi
        -1

    mut fn apply_declared_effects_to_extern_sig(node: i32, sig_idx: i32, param_start: i32, param_count: i32):
        let pin_count = self.ast.fn_effect_pin_count(node as NodeId)
        for pin_i in 0..pin_count:
            let pin_param_sym = self.ast.fn_effect_pin_param(node as NodeId, pin_i)
            let pin_bits = self.ast.fn_effect_pin_bits(node as NodeId, pin_i) & EFF_DECLARED_MASK
            let pin_pi = self.find_effect_pin_param_index(param_start, param_count, pin_param_sym)
            if pin_pi < 0:
                self.emit_error("@[effect] names unknown parameter '" ++ self.pool_resolve(pin_param_sym) ++ "'", node)
            else:
                self.set_sig_param_effect(sig_idx, pin_pi, pin_bits)
                self.set_sig_param_direct_effect(sig_idx, pin_pi, pin_bits)

    fn sig_param_view_origin(si: i32, pi: i32) -> i32:
        if si < 0 or si >= self.sig_param_eff_starts.len() as i32:
            return 0
        let start = self.sig_param_eff_starts.get(si as i64)
        let count = self.sig_param_counts.get(si as i64)
        if pi < 0 or pi >= count:
            return 0
        self.sig_param_view_origins.get((start + pi) as i64)

    fn set_sig_param_view_origin(si: i32, pi: i32, mask: i32):
        if si < 0 or si >= self.sig_param_eff_starts.len() as i32:
            return
        let start: i32 = self.sig_param_eff_starts.get(si as i64)
        let count = self.sig_param_counts.get(si as i64)
        if pi < 0 or pi >= count:
            return
        self.sig_param_view_origins.set_i32((start + pi) as i64, mask)

    fn param_index_for_sym(sym: i32) -> i32:
        let name = self.pool_resolve(sym)
        for pi in 0..self.current_fn_param_syms.len() as i32:
            let param_sym = self.current_fn_param_syms.get(pi as i64)
            if param_sym == sym or self.pool_resolve(param_sym) == name:
                return pi
        -1

    fn note_param_effect(sym: i32, eff: i32):
        if self.current_fn_sig_idx < 0 or sym == 0:
            return
        let pi = self.param_index_for_sym(sym)
        if pi >= 0:
            let cur: i32 = self.current_fn_param_effs.get(pi as i64)
            self.current_fn_param_effs.set_i32(pi as i64, cur | eff)
            // explain:effect provenance — record the FIRST setter of each
            // ownership-forcing bit. The origin node is carried in
            // effect_note_origin_node (set by note_place_effect and the other
            // node-bearing noters; 0 when unknown).
            let new_bits = eff & (EFF_CONSUME | EFF_ESCAPE_VALUE | EFF_WRITE) & (2147483647 - cur)
            if new_bits != 0:
                self.record_effect_provenance_direct(self.current_fn_sig_idx, pi, new_bits, self.effect_note_origin_node)
            if self.recording_propagated_effect == 0:
                let direct: i32 = self.current_fn_param_direct_effs.get(pi as i64)
                self.current_fn_param_direct_effs.set_i32(pi as i64, direct | eff)
            return

    // explain:effect provenance recording. Value packs kind*2^56 + a*2^28 + b:
    // kind 1 = direct (a = AST node, b = file id); kind 2 = effect-flow edge
    // (a = callee sig, b = callee param). First set wins.
    fn record_effect_provenance_direct(sig: i32, pi: i32, bits: i32, node: i32):
        if (bits & EFF_CONSUME) != 0:
            self.record_effect_provenance_bit(sig, pi, 0, 1, node, self.local_file_id)
        if (bits & EFF_ESCAPE_VALUE) != 0:
            self.record_effect_provenance_bit(sig, pi, 1, 1, node, self.local_file_id)
        if (bits & EFF_WRITE) != 0:
            self.record_effect_provenance_bit(sig, pi, 2, 1, node, self.local_file_id)

    fn record_effect_provenance_edge(sig: i32, pi: i32, bits: i32, callee_sig: i32, callee_pi: i32):
        if (bits & EFF_CONSUME) != 0:
            self.record_effect_provenance_bit(sig, pi, 0, 2, callee_sig, callee_pi)
        if (bits & EFF_ESCAPE_VALUE) != 0:
            self.record_effect_provenance_bit(sig, pi, 1, 2, callee_sig, callee_pi)
        if (bits & EFF_WRITE) != 0:
            self.record_effect_provenance_bit(sig, pi, 2, 2, callee_sig, callee_pi)

    fn record_effect_provenance_bit(sig: i32, pi: i32, bit_idx: i32, kind: i64, a: i32, b: i32):
        let key = effect_prov_key(sig, pi, bit_idx)
        if self.effect_prov.contains(key):
            return
        self.effect_prov.insert(key, effect_prov_val(kind, a, b))

    fn note_param_view_origin(sym: i32, mask: i32, origin_node: i32):
        if self.current_fn_sig_idx < 0 or sym == 0 or mask == 0:
            return
        let pi = self.param_index_for_sym(sym)
        if pi >= 0:
            let cur: i32 = self.current_fn_param_origins.get(pi as i64)
            self.current_fn_param_origins.set_i32(pi as i64, cur | mask)
            if origin_node != 0 and self.current_fn_param_view_nodes.get(pi as i64) == 0:
                self.current_fn_param_view_nodes.set_i32(pi as i64, origin_node)
            return

    mut fn note_place_effect(expr_node: i32, eff: i32):
        if self.current_fn_sig_idx < 0:
            return
        let root = self.place_root_sym(expr_node)
        if root != 0:
            self.effect_note_origin_node = expr_node
            self.note_param_effect(root, eff)
            let dep_sym = self.binding_effect_dep_sym(root)
            if dep_sym != 0:
                self.note_param_effect(dep_sym, eff)
            self.effect_note_origin_node = 0

    // D17: ownership-forcing effects do not cross a projection of a NON-COPY
    // field. A callee that consumes such a field blanks it (reset-on-move,
    // §2.5.1) and leaves the root's place valid-but-changed — a WRITE on the
    // root, never a consume of it (the promotion audit_receiver_projection_
    // origins already branded incorrect). A COPY field (raw pointer, handle)
    // keeps the promotion: escaping it captures the root's content by aliasing
    // (std/thread.w's transmuted worker), and nothing is blanked. escape_view
    // is untouched: a view into a field IS a view into the root.
    mut fn weaken_projection_owning_effects(arg_node: i32, eff: i32) -> i32:
        let owning = eff & (EFF_CONSUME | EFF_ESCAPE_VALUE)
        if owning == 0:
            return eff
        if self.effect_arg_is_projection(arg_node) == 0:
            return eff
        let fty_opt = self.typed_expr_types.get(arg_node)
        if not fty_opt.is_some():
            return eff
        let fty: i32 = fty_opt.unwrap()
        if fty == 0 or self.is_copy(fty as TypeId) != 0:
            return eff
        (eff - owning) | EFF_WRITE

    // #D5/P0: when the current function passes one of its own parameters as the
    // argument to `callee_pi` of `callee_sig`, record the effect-flow edge
    // [caller_sig, caller_pi, callee_sig, callee_pi]. `fixpoint_effect_flow` later
    // propagates the callee param's ownership-forcing effects (consume/escape_value)
    // backward onto the caller param, completing effects that single-pass inference
    // misses when the callee is a forward reference or mutual recursion. Only
    // param-rooted arguments produce an edge; a temporary/rvalue argument carries no
    // caller-place ownership to propagate.
    fn effect_arg_is_projection(node: i32) -> i32:
        if node <= 0:
            return 0
        let kind = self.ast.kind(node)
        if kind == NodeKind.NK_IDENT:
            return 0
        if kind == NodeKind.NK_GROUPED or kind == NodeKind.NK_NO_SUSPEND:
            return self.effect_arg_is_projection(self.ast.get_data0(node))
        1

    fn record_effect_edge(callee_sig: i32, callee_pi: i32, arg_node: i32):
        let caller_sig = self.current_fn_sig_idx
        if caller_sig < 0 or callee_sig < 0 or callee_pi < 0 or arg_node <= 0:
            return
        let root = self.place_root_sym(arg_node)
        if root == 0:
            return
        let caller_pi = self.param_index_for_sym(root)
        if caller_pi < 0:
            return
        self.effect_flow_edges.push(caller_sig)
        self.effect_flow_edges.push(caller_pi)
        self.effect_flow_edges.push(callee_sig)
        self.effect_flow_edges.push(callee_pi)
        self.effect_flow_projections.push(self.effect_arg_is_projection(arg_node))

    // #D5/P0 + D7: complete transitive write/consume/escape_value effects across the whole call
    // graph, so every sig_param_effects entry is final before any share-place
    // decision reads it. A greatest-fixpoint over the recorded edges: propagate the
    // ownership-forcing bits backward until stable. Reference/pointer params never
    // own, so they never receive these bits (mirrors the flush-time clamp). This
    // only ADDS data; nothing consumes the completed bits until the P1 flip, so P0
    // is behavior-neutral.
    mut fn fixpoint_effect_flow():
        let n = self.effect_flow_edges.len() as i32
        if n < 4:
            return
        var changed = 1
        var guard = 0
        while changed != 0 and guard < 4096:
            changed = 0
            guard = guard + 1
            var i = 0
            var edge_index = 0
            while i + 3 < n:
                let caller_sig = self.effect_flow_edges.get(i as i64)
                let caller_pi = self.effect_flow_edges.get((i + 1) as i64)
                let callee_sig = self.effect_flow_edges.get((i + 2) as i64)
                let callee_pi = self.effect_flow_edges.get((i + 3) as i64)
                i = i + 4
                let projection = if edge_index < self.effect_flow_projections.len() as i32: self.effect_flow_projections.get(edge_index as i64) else: 1
                edge_index = edge_index + 1
                let callee_eff = self.sig_param_effect(callee_sig, callee_pi)
                var trans = callee_eff & (EFF_WRITE | EFF_CONSUME | EFF_ESCAPE_VALUE)
                // D17: ownership-forcing effects do not cross a NON-COPY
                // projection edge — the callee consumes the FIELD, which blanks
                // it and WRITES the caller's root place. Copy-typed projections
                // keep the promotion (aliasing capture, nothing blanked).
                // Mirrors weaken_projection_owning_effects on the direct path so
                // the fixpoint cannot re-promote what direct noting demoted.
                let e_owning = trans & (EFF_CONSUME | EFF_ESCAPE_VALUE)
                if projection != 0 and e_owning != 0:
                    let edge_arg_ty = self.sig_param_type(callee_sig, callee_pi)
                    if edge_arg_ty > 0 and self.is_copy(edge_arg_ty as TypeId) == 0:
                        trans = (trans - e_owning) | EFF_WRITE
                if trans == 0:
                    continue
                let p_tid = self.sig_param_type(caller_sig, caller_pi)
                if p_tid > 0:
                    let p_tk = self.get_type_kind(self.resolve_alias(p_tid))
                    if p_tk == TypeKind.TY_REF or p_tk == TypeKind.TY_PTR:
                        continue
                let caller_eff = self.sig_param_effect(caller_sig, caller_pi)
                let merged = caller_eff | trans
                if merged != caller_eff:
                    self.set_sig_param_effect(caller_sig, caller_pi, merged)
                    // explain:effect — the transitive hop that first set the bit.
                    self.record_effect_provenance_edge(caller_sig, caller_pi, merged & (2147483647 - caller_eff), callee_sig, callee_pi)
                    changed = 1

    fn finalize_receiver_requirements():
        for si in 0..self.sig_receiver_modes.len() as i32:
            if self.sig_receiver_mode(si) == ReceiverMode.None or self.sig_get_param_count(si) <= 0:
                continue
            self.sig_receiver_required_effects.set_i32(si as i64, self.sig_param_effect(si, 0) & EFF_DECLARED_MASK)

    fn receiver_decl_node_for_sig(sig: i32) -> i32:
        if sig < 0 or sig >= self.sig_names.len() as i32:
            return 0
        let sym = self.sig_names.get(sig as i64)
        let direct = self.fn_decl_nodes.get(sym)
        if direct.is_some():
            return direct.unwrap()
        let specialization = self.concrete_specialization_by_sym.get(sym)
        if specialization.is_some():
            return self.concrete_specialization_nodes.get(specialization.unwrap() as i64)
        0

    fn receiver_required_effect_for_decl(node: i32) -> i32:
        var required = 0
        for si in 0..self.sig_names.len() as i32:
            if self.receiver_decl_node_for_sig(si) == node and self.sig_get_param_count(si) > 0:
                required = required | (self.sig_param_effect(si, 0) & EFF_DECLARED_MASK)
        required

    fn receiver_decl_has_effect_signature(node: i32) -> bool:
        for si in 0..self.sig_names.len() as i32:
            if self.receiver_decl_node_for_sig(si) == node and self.sig_get_param_count(si) > 0:
                return true
        false

    // A trait implementation's receiver contract is semantic authority even when
    // its generic body has no concrete signature. Return -1 when the declaration
    // is not a trait method or the trait itself has no explicit receiver mode.
    fn receiver_trait_contract_effect_for_decl(decl_index: i32, node: i32) -> i32:
        if not self.method_decl_impl_nodes.contains(decl_index): return -1
        let impl_node = self.method_decl_impl_nodes.get(decl_index).unwrap()
        let trait_sym = self.ast.get_data2(impl_node as NodeId)
        if trait_sym == 0 or not self.trait_lookup.contains(trait_sym): return -1
        let trait_index = self.trait_lookup.get(trait_sym).unwrap()
        let method_name = self.extract_decl_name_after(node, "fn")
        let start = self.trait_method_starts.get(trait_index as i64)
        let count = self.trait_method_counts.get(trait_index as i64)
        for i in 0..count:
            let method_index = start + i
            if self.pool_resolve(self.trait_method_names.get(method_index as i64)) != method_name: continue
            let param_count = self.trait_method_param_counts.get(method_index as i64)
            let param_start = self.trait_method_param_starts.get(method_index as i64)
            let mode = self.receiver_mode_from_param(param_start, param_count)
            if mode == ReceiverMode.Read: return EFF_READ
            if mode == ReceiverMode.Mut: return EFF_READ | EFF_WRITE
            if mode == ReceiverMode.Move: return EFF_READ | EFF_CONSUME
            return -1
        -1

    // D7 hard enforcement runs only after every body and concrete specialization
    // has contributed to the transitive effect fixed point. One diagnostic per
    // source declaration names the exact mode the compiler derived; there is no
    // declaration-spelling exemption and no warning/fallback mode.
    mut fn enforce_receiver_modes():
        let seen: HashMap[i32, i32] = HashMap.new()
        for si in 0..self.sig_receiver_modes.len() as i32:
            let declared = self.sig_receiver_mode(si)
            if declared == ReceiverMode.None or self.sig_get_param_count(si) <= 0:
                continue
            let node = self.receiver_decl_node_for_sig(si)
            if node <= 0 or seen.contains(node):
                continue
            seen.insert(node, 1)
            let required = self.receiver_required_effect_for_decl(node)
            let required_mode = receiver_required_mode_text(required)
            let name = self.pool_resolve(self.sig_names.get(si as i64))
            if declared == ReceiverMode.Missing:
                let keyword = if required_mode == "read": "fn" else: required_mode ++ " fn"
                self.emit_error(f"method receiver mode is missing; compiler effects require `{keyword}` for '{name}'", node)
            else if declared == ReceiverMode.Read and required_mode != "read":
                let keyword = if required_mode == "mut": "mut fn" else: "move fn"
                self.emit_error(f"read receiver is too weak; compiler effects require `{keyword}` for '{name}'", node)
            else if declared == ReceiverMode.Mut and required_mode == "move":
                self.emit_error(f"mut receiver is too weak; compiler effects require `move fn` for '{name}'", node)

fn receiver_required_mode_text(eff: i32) -> str:
    if (eff & (EFF_CONSUME | EFF_ESCAPE_VALUE)) != 0: return "move"
    if (eff & EFF_WRITE) != 0: return "mut"
    "read"

impl Sema:
    fn receiver_contract_error_count() -> i32:
        var errors = 0
        for si in 0..self.sig_receiver_modes.len() as i32:
            let declared = self.sig_receiver_mode(si)
            if declared == ReceiverMode.None:
                continue
            let eff = self.sig_receiver_required_effects.get(si as i64)
            if declared == ReceiverMode.Missing:
                errors = errors + 1
            else if declared == ReceiverMode.Read and (eff & (EFF_WRITE | EFF_CONSUME | EFF_ESCAPE_VALUE)) != 0:
                errors = errors + 1
            else if declared == ReceiverMode.Mut and (eff & (EFF_CONSUME | EFF_ESCAPE_VALUE)) != 0:
                errors = errors + 1
        errors

    fn sig_param_direct_effect(sig: i32, pi: i32) -> i32:
        if sig < 0 or sig >= self.sig_param_eff_starts.len() as i32:
            return 0
        let start = self.sig_param_eff_starts.get(sig as i64)
        let at = start + pi
        if at < 0 or at >= self.sig_param_direct_effects.len() as i32:
            return 0
        self.sig_param_direct_effects.get(at as i64)

    // Prove whether receiver ownership requirements have any all-root path to a
    // direct consume/escape seed. If every path crosses a projection, consuming a
    // field was incorrectly promoted to consuming the whole receiver.
    fn audit_receiver_projection_origins() -> str:
        let root_owned: Vec[i32] = Vec.new()
        for i in 0..self.sig_param_effects.len() as i32:
            let direct = if i < self.sig_param_direct_effects.len() as i32: self.sig_param_direct_effects.get(i as i64) else: 0
            root_owned.push(if (direct & (EFF_CONSUME | EFF_ESCAPE_VALUE)) != 0: 1 else: 0)
        var changed = true
        while changed:
            changed = false
            var ei = 0
            var edge_index = 0
            while ei + 3 < self.effect_flow_edges.len() as i32:
                let caller_sig = self.effect_flow_edges.get(ei as i64)
                let caller_pi = self.effect_flow_edges.get((ei + 1) as i64)
                let callee_sig = self.effect_flow_edges.get((ei + 2) as i64)
                let callee_pi = self.effect_flow_edges.get((ei + 3) as i64)
                ei = ei + 4
                let projection = if edge_index < self.effect_flow_projections.len() as i32: self.effect_flow_projections.get(edge_index as i64) else: 1
                edge_index = edge_index + 1
                if projection != 0:
                    continue
                let caller_start = self.sig_param_eff_starts.get(caller_sig as i64)
                let callee_start = self.sig_param_eff_starts.get(callee_sig as i64)
                let caller_at = caller_start + caller_pi
                let callee_at = callee_start + callee_pi
                if root_owned.get(callee_at as i64) == 0 or root_owned.get(caller_at as i64) != 0:
                    continue
                let caller_tid = self.sig_param_type(caller_sig, caller_pi)
                if caller_tid > 0:
                    let caller_kind = self.get_type_kind(self.resolve_alias(caller_tid))
                    if caller_kind == TypeKind.TY_REF or caller_kind == TypeKind.TY_PTR:
                        continue
                root_owned.set_i32(caller_at as i64, 1)
                changed = true

        var mismatches = 0
        var root_paths = 0
        var projection_only = 0
        var out = ""
        for si in 0..self.sig_receiver_modes.len() as i32:
            let declared = self.sig_receiver_mode(si)
            if declared == ReceiverMode.None or declared == ReceiverMode.Missing:
                continue
            let effect = self.sig_receiver_required_effects.get(si as i64)
            if (effect & (EFF_CONSUME | EFF_ESCAPE_VALUE)) == 0 or declared == ReceiverMode.Move:
                continue
            mismatches = mismatches + 1
            let at = self.sig_param_eff_starts.get(si as i64)
            let name = self.pool_resolve(self.sig_names.get(si as i64))
            if root_owned.get(at as i64) != 0:
                root_paths = root_paths + 1
                out = out ++ f"root-path\t{name}\n"
            else:
                projection_only = projection_only + 1
        f"receiver-projection-audit: mismatches={mismatches} projection-only={projection_only} root-paths={root_paths}\n" ++ out

    // D5 (superseded — docs/decisions.md): the effects-based share-place
    // classifier for FREE parameters is deleted. The signature states the
    // ownership mode: `&T` borrows, plain `T` consumes — a body edit can
    // never silently change a public calling convention again. Receiver
    // share-place (D12) is unaffected; it is declared, not inferred, and is
    // set from fn_param_uses_value_ref_abi at declaration finalize.

    // #D5/D6: dump the per-parameter ownership/ABI classification for every function
    // signature — the ground truth for share-place vs owned, without inferring it
    // from MIR. Answers "is this param a borrow (share-place) or owned?" directly.
    // Backs `--dump-abi`. Run after check so effects + value_ref_abi are final.
    mut fn dump_abi() -> str:
        var out = f"abi module sigs={self.sig_names.len() as i32}\n"
        for si in 0..self.sig_names.len() as i32:
            let fn_sym = self.sig_names.get(si as i64)
            let name = self.pool_resolve(fn_sym)
            let pc = self.sig_get_param_count(si)
            out = out ++ f"fn {name} [sig={si} params={pc}]\n"
            for pi in 0..pc:
                let ty = self.sig_param_type(si, pi)
                let eff = self.sig_param_effect(si, pi)
                let vra = self.sig_param_uses_value_ref_abi(si, pi)
                // D12: the mode outranks Copy-ness — a share-place receiver on
                // a Copy scalar is a borrow, not a copy; a consumed (move
                // self / escaping) param is OWNED even when the type is Copy.
                let cls =
                    if vra != 0: "SHARE-PLACE"
                    else if (eff & EFF_CONSUME) != 0 or (eff & EFF_ESCAPE_VALUE) != 0: "OWNED"
                    else if self.is_copy(ty as TypeId) != 0: "COPY"
                    else: "OWNED"
                out = out ++ f"  param[{pi}] ty={ty} eff=[" ++ sema_effect_bits_text(eff) ++ f"] value_ref_abi={vra} -> " ++ cls ++ "\n"
        out

    // #D5/P1: record a plain non-Copy value argument (with its file) for the
    // post-fixpoint ownership check.
    fn record_consume_call_site(arg_node: i32, callee_sig: i32, callee_pi: i32):
        if arg_node <= 0 or callee_sig < 0 or callee_pi < 0:
            return
        self.consume_call_sites.push(arg_node)
        self.consume_call_sites.push(callee_sig)
        self.consume_call_sites.push(callee_pi)
        self.consume_call_sites.push(self.local_file_id)
        // move-sites: liveness inputs — the arg's uses have already been
        // sequenced, so binding_use_seq here equals this arg's use position.
        // A FIELD-shaped arg also records its first field symbol, keying
        // liveness to the (root, field) path instead of the whole root.
        self.consume_call_sites.push(self.place_root_sym(arg_node))
        self.consume_call_sites.push(self.move_site_first_field_sym(arg_node))
        self.consume_call_sites.push(self.binding_use_seq)
        self.consume_call_sites.push(self.loop_depth)
        self.consume_call_sites.push(0)

    fn move_site_first_field_sym(arg_node: i32) -> i32:
        var n = arg_node
        while n > 0 and (self.ast.kind(n) == NodeKind.NK_GROUPED or self.ast.kind(n) == NodeKind.NK_NO_SUSPEND or self.ast.kind(n) == NodeKind.NK_MOVE_ARG or self.ast.kind(n) == NodeKind.NK_COPY_ARG):
            n = self.ast.get_data0(n)
        if n > 0 and self.ast.kind(n) == NodeKind.NK_FIELD_ACCESS:
            return self.ast.get_data1(n)
        0

    // move-sites: stamp the liveness verdict for every site recorded during the
    // body that just finished — once all of its uses have been sequenced. A
    // nested body (closure) stamps its own sites first; already-stamped entries
    // are never overwritten by the enclosing body's pass. Field-shaped args
    // consult the (root, field) path map; whole-binding args the root map.
    fn stamp_move_site_liveness(start: i32):
        var i = start
        while i + 8 < self.consume_call_sites.len() as i32:
            if self.consume_call_sites.get((i + 8) as i64) == 0:
                let root = self.consume_call_sites.get((i + 4) as i64)
                let field = self.consume_call_sites.get((i + 5) as i64)
                let site_seq = self.consume_call_sites.get((i + 6) as i64)
                var last = 0
                if root != 0 and field != 0:
                    let path_key = sema_pair_key(root, field)
                    if self.field_last_use.contains(path_key):
                        let entry = self.field_last_use.get(path_key).unwrap()
                        if sema_pair_hi(entry) == self.binding_use_epoch:
                            last = sema_pair_lo(entry)
                else: if root != 0 and self.binding_last_use.contains(root):
                    let entry = self.binding_last_use.get(root).unwrap()
                    if sema_pair_hi(entry) == self.binding_use_epoch:
                        last = sema_pair_lo(entry)
                if last != 0:
                    let verdict = if last > site_seq: 2 else: 1
                    self.consume_call_sites.set_i32((i + 8) as i64, verdict)
            i = i + 9

    // #D5/P1: with effects + share-place ABI final, a plain non-Copy argument passed
    // to an OWNED parameter (consume/escape_value → not share-place) must be given up
    // explicitly. Emit the "requires move/copy" error for each such NAMED binding
    // (an rvalue is consumed directly and needs nothing). Runs after
    // declared parameter modes (D5 superseded) — never mis-classifying a
    // forward-reference owned param as a borrow.
    mut fn finalize_call_site_ownership():
        let n = self.consume_call_sites.len() as i32
        var i = 0
        while i + 8 < n:
            let arg_node = self.consume_call_sites.get(i as i64)
            let callee_sig = self.consume_call_sites.get((i + 1) as i64)
            let callee_pi = self.consume_call_sites.get((i + 2) as i64)
            let file_id = self.consume_call_sites.get((i + 3) as i64)
            i = i + 9
            // #714 (D5 supersession, spec §3.8): a plain call is always legal;
            // the transfer was marked moved at check time and later uses diagnose
            // there. This pass keeps recording sites for move-sites analytics.
            let _ = arg_node
            let _ = file_id
            if self.sig_param_uses_value_ref_abi(callee_sig, callee_pi) != 0:
                continue

    fn get_sig(name: i32) -> i32:
        if self.sig_lookup.contains(name):
            return self.sig_lookup.get(name).unwrap()
        -1

    fn get_visible_sig(name: i32) -> i32:
        let direct = self.get_sig(name)
        if direct >= 0:
            return direct
        let target = self.pool_resolve_symbol(name)
        if target.len() == 0:
            return -1
        var i = self.sig_names.len() as i32 - 1
        while i >= 0:
            let sig_sym = self.sig_names.get(i as i64)
            if sig_sym == name or self.pool_resolve_symbol(sig_sym) == target:
                if self.symbol_visible_from_current(sig_sym) != 0:
                    return i
            i = i - 1
        -1

    fn generic_fn_node_matches_symbol(node: i32, sym: i32, target: &str) -> i32:
        if node == 0:
            return 0
        if self.ast.kind(node) != NodeKind.NK_FN_DECL:
            return 0
        let parsed = self.ast.get_data0(node)
        let source_name = self.extract_decl_name_after(node, "fn")
        if source_name.len() > 0:
            if source_name == target:
                return 1
            if parsed == sym or self.pool_resolve_symbol(parsed) == target:
                return 1
            let di2 = self.find_decl_index(node)
            let semantic2 = self.fn_decl_semantic_symbol_at(node, parsed, di2)
            if semantic2 != parsed and (semantic2 == sym or self.pool_resolve_symbol(semantic2) == target):
                return 1
            return 0
        if parsed == sym or self.pool_resolve_symbol(parsed) == target:
            return 1
        let di = self.find_decl_index(node)
        let semantic = self.fn_decl_semantic_symbol_at(node, parsed, di)
        if semantic == sym or self.pool_resolve_symbol(semantic) == target:
            return 1
        0

    fn fn_node_is_generic_template(node: i32, sym: i32) -> i32:
        if node == 0 or self.ast.kind(node) != NodeKind.NK_FN_DECL:
            return 0
        let meta = self.ast.find_fn_meta(node)
        if meta >= 0 and self.ast.fn_meta_tp_count(meta) > 0:
            return 1

        let impl_direct = self.impl_node_for_method_decl(node)
        if impl_direct != 0:
            let impl_direct_tp_meta = self.ast.find_impl_type_params(impl_direct)
            if impl_direct_tp_meta >= 0:
                let impl_direct_tp_count = self.ast.state.impl_type_params.get((impl_direct_tp_meta + 2) as i64)
                if impl_direct_tp_count > 0:
                    return 1
            let impl_direct_target = self.ast.find_impl_target_type_node(impl_direct as NodeId)
            if impl_direct_target != 0:
                let impl_direct_target_kind = self.ast.kind(impl_direct_target)
                if impl_direct_target_kind == NodeKind.NK_INDEX or impl_direct_target_kind == NodeKind.NK_TYPE_GENERIC:
                    return self.impl_target_has_bare_type_params(impl_direct)

        let decl_index = self.find_decl_index(node)
        let parsed = self.ast.get_data0(node)
        let semantic = self.fn_decl_semantic_symbol_at(node, parsed, decl_index)
        let effective = if semantic != 0: semantic else: sym
        if effective != 0 and self.method_impl_nodes.contains(effective):
            let impl_node = self.method_impl_nodes.get(effective).unwrap()
            let impl_tp_meta = self.ast.find_impl_type_params(impl_node)
            if impl_tp_meta >= 0:
                let impl_tp_count = self.ast.state.impl_type_params.get((impl_tp_meta + 2) as i64)
                if impl_tp_count > 0:
                    return 1

        var fn_name = self.extract_decl_name_after(node, "fn")
        if fn_name.len() == 0:
            fn_name = with_str_clone_ref(self.pool_resolve_symbol(parsed))
        for ci in 0..fn_name.len() as i32:
            if fn_name.byte_at(ci as i64) == 46:
                let owner_name = fn_name.slice(0, ci as i64)
                let owner_sym = self.pool_lookup_symbol(owner_name)
                if owner_sym != 0 and self.type_decl_nodes.contains(owner_sym):
                    let type_node = self.type_decl_nodes.get(owner_sym).unwrap()
                    if self.type_decl_tp_count(type_node) > 0:
                        return 1
                return 0
        0

    mut fn register_generic_fn_node(sym: i32, node: i32):
        for i in 0..self.generic_fn_candidate_syms.len() as i32:
            if self.generic_fn_candidate_syms.get(i as i64) == sym and self.generic_fn_candidate_nodes.get(i as i64) == node:
                return
        if not self.generic_fn_nodes.contains(sym):
            self.generic_fn_nodes.insert(sym, node)
        let prior = self.generic_fn_candidate_counts.get(sym)
        let next: i32 = if prior.is_some(): prior.unwrap() + 1 else: 1
        self.generic_fn_candidate_counts.insert(sym, next)
        self.generic_fn_candidate_syms.push(sym)
        self.generic_fn_candidate_nodes.push(node)

    fn generic_fn_candidate_key(sym: i32) -> i32:
        if self.generic_fn_candidate_counts.contains(sym):
            return sym
        let target = self.pool_resolve_symbol(sym)
        if target.len() == 0:
            return sym
        let canonical = self.pool_lookup_symbol(target)
        if canonical != 0 and self.generic_fn_candidate_counts.contains(canonical):
            return canonical
        sym

    fn generic_fn_registration_contains(sym: i32, node: i32) -> i32:
        let key = self.generic_fn_candidate_key(sym)
        for i in 0..self.generic_fn_candidate_syms.len() as i32:
            if self.generic_fn_candidate_syms.get(i as i64) == key and self.generic_fn_candidate_nodes.get(i as i64) == node:
                return 1
        0

    fn generic_fn_node_for_symbol(sym: i32) -> i32:
        if sym == 0:
            return 0
        let target = self.pool_resolve_symbol(sym)
        if target.len() == 0:
            return 0
        if self.generic_fn_nodes.contains(sym):
            let node = self.generic_fn_nodes.get(sym).unwrap()
            if self.generic_fn_node_matches_symbol(node, sym, target) != 0 and self.fn_node_is_generic_template(node, sym) != 0:
                return node
        let canonical = self.pool_lookup_symbol(target)
        if canonical != 0 and canonical != sym and self.generic_fn_nodes.contains(canonical):
            let node2 = self.generic_fn_nodes.get(canonical).unwrap()
            if self.generic_fn_node_matches_symbol(node2, sym, target) != 0 and self.fn_node_is_generic_template(node2, canonical) != 0:
                return node2
        let dot = sema_str_find_char(target, 46)
        if dot >= 0:
            let owner_name = target.slice(0, dot as i64)
            let method_name = target.slice((dot + 1) as i64, target.len() as i64)
            let owner_sym = self.pool_lookup_symbol(owner_name)
            let method_sym = self.pool_lookup_symbol(method_name)
            if owner_sym != 0 and method_sym != 0 and self.generic_fn_nodes.contains(method_sym):
                let method_node = self.generic_fn_nodes.get(method_sym).unwrap()
                let impl_node = self.impl_node_for_method_decl(method_node)
                if impl_node != 0:
                    let impl_owner_sym = self.ast.get_data0(impl_node)
                    if impl_owner_sym == owner_sym or self.canonical_symbol_by_text(impl_owner_sym) == owner_sym:
                        if self.fn_node_is_generic_template(method_node, method_sym) != 0:
                            return method_node
        0

    fn sig_return_type(idx: i32) -> i32:
        self.sig_ret_types.get(idx as i64)

    fn sig_param_type(idx: i32, param_i: i32) -> i32:
        let start = self.sig_param_starts.get(idx as i64)
        self.sig_params.get((start + param_i) as i64)

    fn sig_get_param_count(idx: i32) -> i32:
        self.sig_param_counts.get(idx as i64)

    fn sig_is_variadic(idx: i32) -> i32:
        self.sig_variadic.get(idx as i64)

    fn sig_idx_valid(idx: i32) -> i32:
        if idx < 0:
            return 0
        if idx >= self.sig_names.len() as i32:
            return 0
        1

    fn set_sig_return_type(idx: i32, ret: i32):
        if self.sig_idx_valid(idx) == 0:
            return
        self.sig_ret_types.set_i32(idx as i64, ret)
        let fn_tid: i32 = self.sig_type_ids.get(idx as i64)
        if fn_tid >= 0 and fn_tid < self.type_d2.len() as i32:
            self.type_d2.set_i32(fn_tid as i64, ret)

    fn copy_sig_alias(alias: i32, source_sig: i32):
        if self.sig_idx_valid(source_sig) == 0:
            return
        let fn_tid = self.sig_type_ids.get(source_sig as i64)
        let ret = self.sig_ret_types.get(source_sig as i64)
        let param_start = self.sig_param_starts.get(source_sig as i64)
        let param_count = self.sig_param_counts.get(source_sig as i64)
        let variadic = self.sig_variadic.get(source_sig as i64)
        self.add_sig(alias, fn_tid, ret, param_start, param_count, variadic)
        let alias_sig = self.get_sig(alias)
        if alias_sig < 0:
            return
        for pi in 0..param_count:
            self.set_sig_param_effect(alias_sig, pi, self.sig_param_effect(source_sig, pi))
            self.set_sig_param_view_origin(alias_sig, pi, self.sig_param_view_origin(source_sig, pi))
            self.set_sig_param_value_ref_abi(alias_sig, pi, self.sig_param_uses_value_ref_abi(source_sig, pi))

    fn signatures_match(a_sig: i32, b_sig: i32) -> i32:
        if self.sig_idx_valid(a_sig) == 0 or self.sig_idx_valid(b_sig) == 0:
            return 0
        if self.sig_return_type(a_sig) != self.sig_return_type(b_sig):
            return 0
        let a_count = self.sig_get_param_count(a_sig)
        if a_count != self.sig_get_param_count(b_sig):
            return 0
        for pi in 0..a_count:
            if self.sig_param_type(a_sig, pi) != self.sig_param_type(b_sig, pi):
                return 0
        if self.sig_is_variadic(a_sig) != self.sig_is_variadic(b_sig):
            return 0
        1

    fn fn_clause_group_index(dispatch_sym: i32) -> i32:
        if self.fn_clause_group_lookup.contains(dispatch_sym):
            return self.fn_clause_group_lookup.get(dispatch_sym).unwrap()
        -1

    fn ensure_fn_clause_group(dispatch_sym: i32) -> i32:
        let existing = self.fn_clause_group_index(dispatch_sym)
        if existing >= 0:
            return existing
        let idx = self.fn_clause_group_names.len() as i32
        self.fn_clause_group_lookup.insert(dispatch_sym, idx)
        self.fn_clause_group_names.push(dispatch_sym)
        self.fn_clause_group_starts.push(self.fn_clause_group_decls.len() as i32)
        self.fn_clause_group_counts.push(0)
        idx

    fn register_fn_clause_decl(dispatch_sym: i32, decl_node: i32):
        let group = self.ensure_fn_clause_group(dispatch_sym)
        let start = self.fn_clause_group_starts.get(group as i64)
        let count: i32 = self.fn_clause_group_counts.get(group as i64)
        for i in 0..count:
            if self.fn_clause_group_decls.get((start + i) as i64) == decl_node:
                return
        self.fn_clause_group_decls.push(decl_node)
        self.fn_clause_group_counts.set_i32(group as i64, count + 1)

    fn fn_clause_group_count() -> i32:
        self.fn_clause_group_names.len() as i32

    fn fn_clause_group_name(group: i32) -> i32:
        self.fn_clause_group_names.get(group as i64)

    fn fn_clause_group_clause_count(group: i32) -> i32:
        self.fn_clause_group_counts.get(group as i64)

    fn fn_clause_group_clause(group: i32, clause_i: i32) -> i32:
        let start = self.fn_clause_group_starts.get(group as i64)
        self.fn_clause_group_decls.get((start + clause_i) as i64)

    fn fn_is_clause_body_symbol(sym: i32) -> i32:
        if self.fn_clause_body_dispatch.contains(sym): 1 else: 0

    // ── Main entry point ─────────────────────────────────────────────

    mut fn check_module():
        self.prepare_for_comptime_transform()
        self.validate_no_std_requirements()
        self.check_top_level_let_values()
        self.check_type_decl_field_defaults()
        self.check_bodies()
        // #D5/P0: with every top-level body checked, complete transitive
        // write/consume/escape_value effects across the call graph so sig_param_effects is
        // final before any share-place decision (lowering/ABI) reads it.
        self.fixpoint_effect_flow()
        self.finalize_receiver_requirements()
        self.enforce_receiver_modes()
        // D5 superseded: free-parameter share-place is no longer inferred from
        // effects — the declared signature is authoritative (&T borrows, T owns).
        self.finalize_call_site_ownership()
        self.check_reachable_comptime_errors()

    mut fn prepare_for_comptime_transform():
        self.compute_method_origins()
        self.collect_declarations()
        self.build_ci_scoping()
        self.validate_copy_derives()
        self.validate_compiler_hooks()
        self.validate_generic_type_decls()

// ── Utility functions ────────────────────────────────────────────

fn sema_str_has_data(text: &str) -> i32:
    if text.len() <= 0:
        return 0
    let ptr_ptr = unsafe *(&text as *const *const *const u8)
    if ptr_ptr as i64 == 0:
        return 0
    let data_ptr = unsafe *ptr_ptr
    if data_ptr as i64 == 0:
        return 0
    1

fn sema_str_contains_char(text: &str, needle: i32) -> i32:
    if sema_str_has_data(text) == 0:
        return 0
    var i = 0
    while i < text.len() as i32:
        if text.byte_at(i as i64) == needle:
            return 1
        i = i + 1
    0

// ── "Did you mean?" suggestions ─────────────────────────────────

fn sema_levenshtein(a: &str, b: &str, max: i32) -> i32:
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

impl Sema:
    fn suggest_name(target: &str, node: i32) -> str:
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
                    best_name = with_str_clone_ref(name)
        // Search function signatures
        for si in 0..self.sig_names.len():
            let sym = self.sig_names.get(si)
            if self.is_ci_visible(sym) != 0:
                let name = self.pool_resolve(sym)
                if name.len() > 0:
                    let d = sema_levenshtein(target, name, max_dist)
                    if d < best_dist:
                        best_dist = d
                        best_name = with_str_clone_ref(name)
        best_name

    fn suggest_type_name(target: &str, node: i32) -> str:
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
                            best_name = with_str_clone_ref(name)
        best_name

    mut fn emit_error_with_suggestion(msg: &str, node: i32, suggestion: &str, origin_file: &str = __FILE__, origin_line: u32 = __LINE__, origin_fn: &str = __FN__):
        if self.suppress_errors != 0:
            return
        let start = self.ast.get_start(node)
        let end = self.ast.get_end(node)
        var diag = Diagnostic.err(msg, Span { file: self.local_file_id, start: start, end: end })
        diag.set_origin(origin_file, origin_fn, origin_line as i32, node)
        if suggestion.len() > 0:
            diag.add_help("did you mean '" ++ suggestion ++ "'?")
        self.diags.emit(move diag)

    // ── Type compatibility ───────────────────────────────────────────

    mut fn types_compatible_fast(expected: TypeId, actual: TypeId) -> i32:
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
        if exp_k == TypeKind.TY_FN and act_k == TypeKind.TY_FN:
            return self.callable_unsafe_coercion_ok(exp_r as i32, act_r as i32)
        if exp_k == TypeKind.TY_EXTERN_FN and act_k == TypeKind.TY_EXTERN_FN:
            if self.callable_unsafe_coercion_ok(exp_r as i32, act_r as i32) == 0:
                return 0
            return self.fn_types_compatible(exp_r, act_r)
        if (exp_k == TypeKind.TY_PTR or exp_k == TypeKind.TY_REF) and act_k == TypeKind.TY_FN:
            return 1
        if exp_k == TypeKind.TY_FN and (act_k == TypeKind.TY_PTR or act_k == TypeKind.TY_REF):
            return 1
        if self.is_option_pointer_type(exp_r) != 0 and (act_k == TypeKind.TY_PTR or act_k == TypeKind.TY_REF or act_k == TypeKind.TY_FN or act_k == TypeKind.TY_EXTERN_FN):
            let opt_payload = self.option_pointer_payload_type(exp_r)
            if opt_payload != 0:
                return self.types_compatible_fast(opt_payload, actual)
        if exp_k == TypeKind.TY_STRUCT and act_k == TypeKind.TY_STRUCT:
            return if self.get_type_d0(exp_r) == self.get_type_d0(act_r): 1 else: 0
        if exp_k == TypeKind.TY_ENUM and act_k == TypeKind.TY_ENUM:
            return if self.get_type_d0(exp_r) == self.get_type_d0(act_r): 1 else: 0
        if exp_k == TypeKind.TY_GENERIC_INST and act_k == TypeKind.TY_ENUM:
            if self.generic_inst_accepts_unit_enum_value(exp_r, act_r) != 0:
                return 1
        if exp_k == TypeKind.TY_ENUM and act_k == TypeKind.TY_GENERIC_INST:
            if self.generic_inst_accepts_unit_enum_value(act_r, exp_r) != 0:
                return 1
        if exp_k == TypeKind.TY_RANGE and act_k == TypeKind.TY_RANGE:
            if self.get_type_d1(exp_r) != self.get_type_d1(act_r):
                return 0
            return self.types_compatible_fast(self.get_type_d0(exp_r), self.get_type_d0(act_r))
        // TypeKind.TY_GENERIC_INST: compatible if same base and all args compatible
        if exp_k == TypeKind.TY_GENERIC_INST and act_k == TypeKind.TY_GENERIC_INST:
            if self.get_type_d0(exp_r) == self.get_type_d0(act_r):
                let gi_ac = self.get_type_d2(exp_r)
                if gi_ac == self.get_type_d2(act_r):
                    if self.type_symbol_is_std_box(self.get_type_d0(exp_r)) != 0 and gi_ac == 1 and self.type_symbol_is_std_box(self.get_type_d0(act_r)) != 0:
                        let box_exp_arg = self.get_generic_inst_arg(exp_r, 0)
                        let box_act_arg = self.get_generic_inst_arg(act_r, 0)
                        let box_exp_arg_r = self.resolve_alias(box_exp_arg as TypeId)
                        if self.get_type_kind(box_exp_arg_r) == TypeKind.TY_TRAIT_OBJ:
                            if self.type_implements_trait(box_act_arg, self.get_type_d0(box_exp_arg_r)) != 0:
                                return 1
                    var gi_all_match = 1
                    for gi_i in 0..gi_ac:
                        let gi_exp_arg = self.get_generic_inst_arg(exp_r, gi_i)
                        let gi_act_arg = self.get_generic_inst_arg(act_r, gi_i)
                        if gi_exp_arg != self.ty_void and gi_act_arg != self.ty_void:
                            if self.types_compatible_fast(gi_exp_arg, gi_act_arg) == 0:
                                gi_all_match = 0
                    return gi_all_match
            return 0
        0

    mut fn types_compatible(expected: TypeId, actual: TypeId) -> i32:
        if self.types_compatible_fast(expected, actual) != 0:
            return 1

        let exp_r = self.resolve_alias(expected)
        let act_r = self.resolve_alias(actual)
        let exp_k = self.get_type_kind(exp_r)
        let act_k = self.get_type_kind(act_r)

        if self.is_option_pointer_type(exp_r) != 0 and (act_k == TypeKind.TY_PTR or act_k == TypeKind.TY_REF or act_k == TypeKind.TY_FN or act_k == TypeKind.TY_EXTERN_FN):
            let opt_payload = self.option_pointer_payload_type(exp_r)
            if opt_payload != 0:
                return self.types_compatible(opt_payload, actual)

        // Structural compatibility for non-interned compound types.
        if exp_k == TypeKind.TY_PTR and act_k == TypeKind.TY_PTR:
            return self.pointer_pointees_compatible(exp_r, act_r)
        if exp_k == TypeKind.TY_PTR and act_k == TypeKind.TY_REF:
            return self.pointer_pointees_compatible(exp_r, act_r)
        if exp_k == TypeKind.TY_REF and act_k == TypeKind.TY_REF:
            if self.pointer_pointees_compatible(exp_r, act_r) != 0:
                return 1
            return self.ref_to_dyn_pointee_coercible(exp_r, act_r)
        if exp_k == TypeKind.TY_REF and act_k == TypeKind.TY_PTR:
            return self.pointer_pointees_compatible(exp_r, act_r)
        if exp_k == TypeKind.TY_FN and act_k == TypeKind.TY_FN:
            return self.callable_unsafe_coercion_ok(exp_r as i32, act_r as i32)
        if exp_k == TypeKind.TY_EXTERN_FN and act_k == TypeKind.TY_EXTERN_FN:
            if self.callable_unsafe_coercion_ok(exp_r as i32, act_r as i32) == 0:
                return 0
            return self.fn_types_compatible(exp_r, act_r)
        if exp_k == TypeKind.TY_SLICE and act_k == TypeKind.TY_SLICE:
            if self.get_type_d1(exp_r) != 0 and self.get_type_d1(act_r) == 0:
                return 0
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
                let exp_elem: i32 = self.type_extra.get((exp_start + ei) as i64)
                let act_elem: i32 = self.type_extra.get((act_start + ei) as i64)
                if self.types_compatible(exp_elem, act_elem) == 0:
                    return 0
            return 1

        // TypeKind.TY_GENERIC_INST structural comparison (different TypeIds, same structure)
        if exp_k == TypeKind.TY_GENERIC_INST and act_k == TypeKind.TY_GENERIC_INST:
            if self.get_type_d0(exp_r) == self.get_type_d0(act_r):
                let gi_ec = self.get_type_d2(exp_r)
                let gi_ac2 = self.get_type_d2(act_r)
                if gi_ec == gi_ac2:
                    if self.type_symbol_is_std_box(self.get_type_d0(exp_r)) != 0 and gi_ec == 1 and self.type_symbol_is_std_box(self.get_type_d0(act_r)) != 0:
                        let box_exp_arg = self.get_generic_inst_arg(exp_r, 0)
                        let box_act_arg = self.get_generic_inst_arg(act_r, 0)
                        let box_exp_arg_r = self.resolve_alias(box_exp_arg as TypeId)
                        if self.get_type_kind(box_exp_arg_r) == TypeKind.TY_TRAIT_OBJ:
                            if self.type_implements_trait(box_act_arg, self.get_type_d0(box_exp_arg_r)) != 0:
                                return 1
                    var gi_all_ok = 1
                    for gi_i in 0..gi_ec:
                        if self.types_compatible(self.get_generic_inst_arg(exp_r, gi_i), self.get_generic_inst_arg(act_r, gi_i)) == 0:
                            gi_all_ok = 0
                            break
                    if gi_all_ok != 0:
                        return 1
        // Auto-referencing: T → &T
        if exp_k == TypeKind.TY_REF:
            if self.get_type_d1(exp_r) == 0:
                if self.types_compatible(self.get_type_d0(exp_r), act_r) != 0:
                    return 1
        0

    // §10.6/§10.8: `&Concrete -> &dyn Trait` coerces when Concrete implements
    // Trait — the checker side of codegen's dyn-fat-pointer construction from
    // a ref place (mir_build_dyn_trait_value_from_ref_place). Mirrors the
    // Box[Concrete] -> Box[dyn Trait] case above. A mutable dyn ref still
    // requires a mutable source.
    mut fn ref_to_dyn_pointee_coercible(exp_r: TypeId, act_r: TypeId) -> i32:
        if self.get_type_d1(exp_r) != 0 and self.get_type_d1(act_r) == 0:
            return 0
        let exp_pointee = self.resolve_alias(self.get_type_d0(exp_r) as TypeId)
        if self.get_type_kind(exp_pointee) != TypeKind.TY_TRAIT_OBJ:
            return 0
        let act_pointee = self.get_type_d0(act_r)
        if act_pointee == 0:
            return 0
        if self.get_type_kind(self.resolve_alias(act_pointee as TypeId)) == TypeKind.TY_TRAIT_OBJ:
            return 0
        let dyn_trait_sym = self.get_type_d0(exp_pointee)
        if self.type_implements_trait(act_pointee, dyn_trait_sym) == 0:
            return 0
        // A generic-inst concrete (blanket impl) has no pre-monomorphized
        // Type__Arg.method functions; specialize the trait methods now so
        // codegen can build the vtable.
        let act_p_res = self.resolve_alias(act_pointee as TypeId) as i32
        if self.get_type_kind(act_p_res) == TypeKind.TY_GENERIC_INST:
            self.register_dyn_impl_specializations(act_p_res, dyn_trait_sym)
        1

    // Codegen queries (text-keyed: codegen and sema intern in different
    // pools). Returns the row index into the dyn_impl flat vecs, or -1.
    fn dyn_impl_method_row(concrete_resolved: i32, trait_text: &str, method_text: &str) -> i32:
        let trait_sym = self.pool_lookup_symbol(trait_text)
        if trait_sym == 0:
            return -1
        let key = sema_pair_key(concrete_resolved, trait_sym)
        if not self.dyn_impl_starts.contains(key):
            return -1
        let start = self.dyn_impl_starts.get(key).unwrap()
        let count = self.dyn_impl_counts.get(key).unwrap()
        for i in 0..count:
            if self.pool_resolve(self.dyn_impl_flat_method_names.get((start + i) as i64)) == method_text:
                return start + i
        -1

    fn dyn_impl_row_sig(row: i32): self.dyn_impl_flat_sigs.get(row as i64)
    fn dyn_impl_row_mono_sym(row: i32): self.dyn_impl_flat_mono_syms.get(row as i64)

    // Frozen twin for MIR lowering; sema's acceptance of the coercion during
    // checking preregistered any generic-inst impl answer it needs.
    fn ref_to_dyn_pointee_coercible_frozen(exp_r: TypeId, act_r: TypeId) -> i32:
        if self.get_type_d1(exp_r) != 0 and self.get_type_d1(act_r) == 0:
            return 0
        let exp_pointee = self.resolve_alias(self.get_type_d0(exp_r) as TypeId)
        if self.get_type_kind(exp_pointee) != TypeKind.TY_TRAIT_OBJ:
            return 0
        let act_pointee = self.get_type_d0(act_r)
        if act_pointee == 0:
            return 0
        if self.get_type_kind(self.resolve_alias(act_pointee as TypeId)) == TypeKind.TY_TRAIT_OBJ:
            return 0
        self.type_implements_trait_frozen(act_pointee, self.get_type_d0(exp_pointee))

    fn fn_types_compatible_frozen(expected: i32, actual: i32) -> i32:
        if self.get_type_d1(expected) != self.get_type_d1(actual):
            return 0
        let param_count = self.get_type_d1(expected)
        let exp_start = self.get_type_d0(expected)
        let act_start = self.get_type_d0(actual)
        for pi in 0..param_count:
            let exp_param = self.type_extra.get((exp_start + pi) as i64)
            let act_param = self.type_extra.get((act_start + pi) as i64)
            if self.types_compatible_frozen(exp_param, act_param) == 0:
                return 0
        self.types_compatible_frozen(self.get_type_d2(expected), self.get_type_d2(actual))

    fn pointer_pointees_compatible_frozen(exp_r: i32, act_r: i32) -> i32:
        let exp_mut = self.get_type_d1(exp_r)
        let act_mut = self.get_type_d1(act_r)
        if exp_mut != 0 and act_mut == 0:
            return 0
        let exp_pointee = self.get_type_d0(exp_r)
        if self.is_c_void_like_type(exp_pointee) != 0:
            return 1
        self.types_compatible_frozen(exp_pointee, self.get_type_d0(act_r))

    fn types_compatible_fast_frozen(expected: TypeId, actual: TypeId) -> i32:
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
                return self.types_compatible_fast_frozen(expected, act_repr)
        if exp_k == TypeKind.TY_FLOAT and act_k == TypeKind.TY_FLOAT:
            return 1
        if exp_k == TypeKind.TY_FLOAT and act_k == TypeKind.TY_INT:
            return 1
        if exp_k == TypeKind.TY_INT and act_k == TypeKind.TY_FLOAT:
            return 1
        if exp_k == TypeKind.TY_FN and act_k == TypeKind.TY_FN:
            return self.callable_unsafe_coercion_ok(exp_r as i32, act_r as i32)
        if exp_k == TypeKind.TY_EXTERN_FN and act_k == TypeKind.TY_EXTERN_FN:
            if self.callable_unsafe_coercion_ok(exp_r as i32, act_r as i32) == 0:
                return 0
            return self.fn_types_compatible_frozen(exp_r, act_r)
        if (exp_k == TypeKind.TY_PTR or exp_k == TypeKind.TY_REF) and act_k == TypeKind.TY_FN:
            return 1
        if exp_k == TypeKind.TY_FN and (act_k == TypeKind.TY_PTR or act_k == TypeKind.TY_REF):
            return 1
        if self.is_option_pointer_type(exp_r) != 0 and (act_k == TypeKind.TY_PTR or act_k == TypeKind.TY_REF or act_k == TypeKind.TY_FN or act_k == TypeKind.TY_EXTERN_FN):
            let opt_payload = self.option_pointer_payload_type(exp_r)
            if opt_payload != 0:
                return self.types_compatible_fast_frozen(opt_payload, actual)
        if exp_k == TypeKind.TY_STRUCT and act_k == TypeKind.TY_STRUCT:
            return if self.get_type_d0(exp_r) == self.get_type_d0(act_r): 1 else: 0
        if exp_k == TypeKind.TY_ENUM and act_k == TypeKind.TY_ENUM:
            return if self.get_type_d0(exp_r) == self.get_type_d0(act_r): 1 else: 0
        if exp_k == TypeKind.TY_GENERIC_INST and act_k == TypeKind.TY_ENUM:
            if self.generic_inst_accepts_unit_enum_value(exp_r, act_r) != 0:
                return 1
        if exp_k == TypeKind.TY_ENUM and act_k == TypeKind.TY_GENERIC_INST:
            if self.generic_inst_accepts_unit_enum_value(act_r, exp_r) != 0:
                return 1
        if exp_k == TypeKind.TY_RANGE and act_k == TypeKind.TY_RANGE:
            if self.get_type_d1(exp_r) != self.get_type_d1(act_r):
                return 0
            return self.types_compatible_fast_frozen(self.get_type_d0(exp_r), self.get_type_d0(act_r))
        if exp_k == TypeKind.TY_GENERIC_INST and act_k == TypeKind.TY_GENERIC_INST:
            if self.get_type_d0(exp_r) == self.get_type_d0(act_r):
                let gi_ac = self.get_type_d2(exp_r)
                if gi_ac == self.get_type_d2(act_r):
                    if self.type_symbol_is_std_box(self.get_type_d0(exp_r)) != 0 and gi_ac == 1 and self.type_symbol_is_std_box(self.get_type_d0(act_r)) != 0:
                        let box_exp_arg = self.get_generic_inst_arg(exp_r, 0)
                        let box_act_arg = self.get_generic_inst_arg(act_r, 0)
                        let box_exp_arg_r = self.resolve_alias(box_exp_arg as TypeId)
                        if self.get_type_kind(box_exp_arg_r) == TypeKind.TY_TRAIT_OBJ:
                            if self.type_implements_trait_frozen(box_act_arg, self.get_type_d0(box_exp_arg_r)) != 0:
                                return 1
                    var gi_all_match = 1
                    for gi_i in 0..gi_ac:
                        let gi_exp_arg = self.get_generic_inst_arg(exp_r, gi_i)
                        let gi_act_arg = self.get_generic_inst_arg(act_r, gi_i)
                        if gi_exp_arg != self.ty_void and gi_act_arg != self.ty_void:
                            if self.types_compatible_fast_frozen(gi_exp_arg, gi_act_arg) == 0:
                                gi_all_match = 0
                    return gi_all_match
            return 0
        0

    fn types_compatible_frozen(expected: TypeId, actual: TypeId) -> i32:
        if self.types_compatible_fast_frozen(expected, actual) != 0:
            return 1

        let exp_r = self.resolve_alias(expected)
        let act_r = self.resolve_alias(actual)
        let exp_k = self.get_type_kind(exp_r)
        let act_k = self.get_type_kind(act_r)

        if self.is_option_pointer_type(exp_r) != 0 and (act_k == TypeKind.TY_PTR or act_k == TypeKind.TY_REF or act_k == TypeKind.TY_FN or act_k == TypeKind.TY_EXTERN_FN):
            let opt_payload = self.option_pointer_payload_type(exp_r)
            if opt_payload != 0:
                return self.types_compatible_frozen(opt_payload, actual)

        if exp_k == TypeKind.TY_PTR and act_k == TypeKind.TY_PTR:
            return self.pointer_pointees_compatible_frozen(exp_r, act_r)
        if exp_k == TypeKind.TY_PTR and act_k == TypeKind.TY_REF:
            return self.pointer_pointees_compatible_frozen(exp_r, act_r)
        if exp_k == TypeKind.TY_REF and act_k == TypeKind.TY_REF:
            if self.pointer_pointees_compatible_frozen(exp_r, act_r) != 0:
                return 1
            // §10.6 ref-to-dyn coercion — mirrors the mut types_compatible arm.
            // bf6f09e2 created this frozen twin but never wired it in; the gap
            // made MirLower's autoderef probe (which gates on frozen compat)
            // treat an already-coercible `&Concrete` arg to a `&dyn Trait`
            // param as incompatible and eagerly spill it through the
            // lower_expr_place fallback, leaving an abandoned invalid
            // fat-&dyn -> thin-&Concrete RK_USE in the body.
            return self.ref_to_dyn_pointee_coercible_frozen(exp_r, act_r)
        if exp_k == TypeKind.TY_REF and act_k == TypeKind.TY_PTR:
            return self.pointer_pointees_compatible_frozen(exp_r, act_r)
        if exp_k == TypeKind.TY_FN and act_k == TypeKind.TY_FN:
            return self.callable_unsafe_coercion_ok(exp_r as i32, act_r as i32)
        if exp_k == TypeKind.TY_EXTERN_FN and act_k == TypeKind.TY_EXTERN_FN:
            if self.callable_unsafe_coercion_ok(exp_r as i32, act_r as i32) == 0:
                return 0
            return self.fn_types_compatible_frozen(exp_r, act_r)
        if exp_k == TypeKind.TY_SLICE and act_k == TypeKind.TY_SLICE:
            if self.get_type_d1(exp_r) != 0 and self.get_type_d1(act_r) == 0:
                return 0
            return self.types_compatible_frozen(self.get_type_d0(exp_r), self.get_type_d0(act_r))
        if exp_k == TypeKind.TY_ARRAY and act_k == TypeKind.TY_ARRAY:
            if self.get_type_d1(exp_r) != self.get_type_d1(act_r):
                return 0
            return self.types_compatible_frozen(self.get_type_d0(exp_r), self.get_type_d0(act_r))
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
                if self.types_compatible_frozen(exp_elem, act_elem) == 0:
                    return 0
            return 1

        if exp_k == TypeKind.TY_GENERIC_INST and act_k == TypeKind.TY_GENERIC_INST:
            if self.get_type_d0(exp_r) == self.get_type_d0(act_r):
                let gi_ec = self.get_type_d2(exp_r)
                let gi_ac2 = self.get_type_d2(act_r)
                if gi_ec == gi_ac2:
                    if self.type_symbol_is_std_box(self.get_type_d0(exp_r)) != 0 and gi_ec == 1 and self.type_symbol_is_std_box(self.get_type_d0(act_r)) != 0:
                        let box_exp_arg = self.get_generic_inst_arg(exp_r, 0)
                        let box_act_arg = self.get_generic_inst_arg(act_r, 0)
                        let box_exp_arg_r = self.resolve_alias(box_exp_arg as TypeId)
                        if self.get_type_kind(box_exp_arg_r) == TypeKind.TY_TRAIT_OBJ:
                            if self.type_implements_trait_frozen(box_act_arg, self.get_type_d0(box_exp_arg_r)) != 0:
                                return 1
                    var gi_all_ok = 1
                    for gi_i in 0..gi_ec:
                        if self.types_compatible_frozen(self.get_generic_inst_arg(exp_r, gi_i), self.get_generic_inst_arg(act_r, gi_i)) == 0:
                            gi_all_ok = 0
                            break
                    if gi_all_ok != 0:
                        return 1
        if exp_k == TypeKind.TY_REF:
            if self.get_type_d1(exp_r) == 0:
                if self.types_compatible_frozen(self.get_type_d0(exp_r), act_r) != 0:
                    return 1
        0

    // #604 stage 1: a Vec[T] / [T; N] argument may coerce to a []T / []mut T
    // parameter — the first collection→slice coercion (slice→slice compat,
    // including the mut gate, stays in types_compatible). Element types must
    // match EXACTLY: a `[]mut` write goes back into the collection, so no
    // element widening is sound; the same exactness keeps the immutable case
    // symmetric.
    fn can_coerce_collection_to_slice(expected: TypeId, actual: TypeId) -> i32:
        let exp_r = self.resolve_alias(expected)
        if self.get_type_kind(exp_r) != TypeKind.TY_SLICE:
            return 0
        let want_elem = self.resolve_alias(self.get_type_d0(exp_r) as TypeId) as i32
        let act_r = self.resolve_alias(actual)
        let act_k = self.get_type_kind(act_r)
        if act_k == TypeKind.TY_ARRAY:
            if (self.resolve_alias(self.get_type_d0(act_r) as TypeId) as i32) == want_elem:
                return 1
            return 0
        if act_k == TypeKind.TY_GENERIC_INST:
            if self.get_type_d0(act_r) == self.syms.vec and self.get_generic_inst_arg_count(act_r as i32) > 0:
                if (self.resolve_alias(self.get_generic_inst_arg(act_r as i32, 0) as TypeId) as i32) == want_elem:
                    return 1
        0

    fn generic_inst_accepts_unit_enum_value(generic_tid: TypeId, enum_tid: TypeId) -> i32:
        if self.get_type_kind(generic_tid) != TypeKind.TY_GENERIC_INST or self.get_type_kind(enum_tid) != TypeKind.TY_ENUM:
            return 0
        let base_sym = self.get_type_d0(generic_tid)
        if base_sym == 0 or self.get_type_d0(enum_tid) != base_sym:
            return 0
        if not self.type_decl_nodes.contains(base_sym):
            return 0
        let type_decl = self.type_decl_nodes.get(base_sym).unwrap()
        if self.type_decl_tp_count(type_decl) <= 0:
            return 0
        let extra_start = self.get_type_d1(enum_tid)
        let variant_count = self.get_type_d2(enum_tid)
        var pos = extra_start
        for _ in 0..variant_count:
            let payload_count = self.type_extra.get((pos + 1) as i64)
            if payload_count == 0:
                return 1
            pos = pos + 2 + payload_count
        0

    fn arithmetic_result_type(lhs: TypeId, rhs: TypeId) -> TypeId:
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

    fn bitwise_result_type(lhs: TypeId, rhs: TypeId) -> TypeId:
        if lhs == 0 or rhs == 0:
            return 0 as TypeId
        let lhs_numeric = self.numeric_operand_type(lhs as i32)
        let rhs_numeric = self.numeric_operand_type(rhs as i32)
        let lhs_resolved = self.resolve_alias(lhs_numeric as TypeId)
        let rhs_resolved = self.resolve_alias(rhs_numeric as TypeId)
        if self.get_type_kind(lhs_resolved) != TypeKind.TY_INT or self.get_type_kind(rhs_resolved) != TypeKind.TY_INT:
            return 0 as TypeId
        if self.get_type_d1(lhs_resolved) != self.get_type_d1(rhs_resolved):
            return 0 as TypeId
        let lhs_bits = self.get_type_d0(lhs_resolved)
        let rhs_bits = self.get_type_d0(rhs_resolved)
        if lhs_bits >= rhs_bits:
            return lhs_numeric as TypeId
        rhs_numeric as TypeId

    mut fn is_copy(tid: TypeId) -> i32:
        if tid == 0:
            return 1
        let resolved = self.resolve_alias(tid)
        let tk = self.get_type_kind(resolved)
        if tk == TypeKind.TY_ERR or tk == TypeKind.TY_INT or tk == TypeKind.TY_FLOAT or tk == TypeKind.TY_BOOL or tk == TypeKind.TY_VOID or tk == TypeKind.TY_NEVER:
            return 1
        // #747 / D28 ruling 1: str owns its buffer — moves, not copies.
        // The explicit arm matters: this function's tail DEFAULTS to Copy.
        if tk == TypeKind.TY_STR:
            return 0
        if tk == TypeKind.TY_PTR or tk == TypeKind.TY_REF or tk == TypeKind.TY_FN or tk == TypeKind.TY_EXTERN_FN or tk == TypeKind.TY_GENERIC_FN:
            return 1
        if tk == TypeKind.TY_STRUCT:
            let name = self.get_type_d0(resolved)
            // D29 scaffolding (#750): a shadowed sym's Copy/Drop verdicts come
            // from the tid's own tier — the flat caches would conflate them.
            if name > 0 and self.type_sym_is_shadowed(name) != 0:
                let want_std = self.type_tid_std_tier(resolved as i32)
                if self.select_trait_impl_tiered(name, self.syms.drop, want_std) != 0:
                    return 0
                return self.select_trait_impl_tiered(name, self.syms.copy_trait, want_std)
            if self.has_drop_method(name) != 0:
                if sema_debug_move_enabled() != 0:
                    with_eprint("[noncopy] type=" ++ self.pool_resolve(name) ++ " reason=drop")
                return 0
            // A distinct wrapper's Copy-ness follows its inner type — the
            // compiler knows the payload; requiring an explicit impl would be
            // ceremony (type NodeId = distinct i32 is Copy because i32 is).
            if name > 0 and self.distinct_type_names.contains(name):
                let distinct_inner = self.unwrap_builtin_arg_distinct(resolved as i32)
                if distinct_inner != resolved as i32:
                    return self.is_copy(distinct_inner as TypeId)
            if name > 0:
                return self.select_trait_impl(name, self.syms.copy_trait)
            return 0
        if tk == TypeKind.TY_ARRAY or tk == TypeKind.TY_TUPLE or tk == TypeKind.TY_RANGE:
            // Break copy-check recursion on cyclic type graphs.
            if self.copy_visit_stack.contains(resolved as i32):
                return 0
            self.copy_visit_stack.insert(resolved as i32)

            var out = 1
            if tk == TypeKind.TY_ARRAY:
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

            let _ = self.copy_visit_stack.remove(resolved as i32)
            return out
        if tk == TypeKind.TY_ENUM:
            // Enums are non-Copy by default; opt-in via `impl Copy for T`.
            let enum_name = self.get_type_d0(resolved)
            if enum_name > 0 and self.impl_lookup.contains(enum_name):
                let idx = self.impl_lookup.get(enum_name).unwrap()
                let start = self.impl_starts.get(idx as i64)
                let count = self.impl_counts.get(idx as i64)
                for di in 0..count:
                    if self.impl_extra.get((start + di) as i64) == self.syms.copy_trait:
                        return 1
            return 0
        if tk == TypeKind.TY_SLICE:
            return 1
        if tk == TypeKind.TY_GENERIC_INST:
            let generic_base = self.get_generic_inst_base(resolved as i32)
            let generic_base_name = self.pool_resolve(generic_base)
            if generic_base_name == "Sender" or generic_base_name == "Receiver":
                return 0
            if generic_base == self.syms.handle:
                return 1
            // Generic instances (Vec[T], etc.) are non-Copy by default.
            // Copy iff there is an explicit `impl[T: Copy] Copy for Base[T]` registered.
            // Do NOT call type_implements_trait(copy_trait) here — it just calls is_copy() back.
            return self.select_trait_impl_for_generic_inst(resolved as i32, self.syms.copy_trait)
        1

    fn has_drop_method(type_name: i32) -> i32:
        if type_name <= 0:
            return 0
        if self.drop_method_cache.contains(type_name):
            return self.drop_method_cache.get(type_name).unwrap()

        let has = self.select_trait_impl(type_name, self.syms.drop)
        // This read query memoizes into Sema's phase-local cache. HashMap is an
        // owning D22 handle, so copying the field would create a second owner.
        // Reborrow the field as an explicit raw place instead; Sema queries are
        // single-threaded and no safe cache borrow crosses this mutation.
        let cache = &raw const self.drop_method_cache as *const HashMap[i32, i32] as *mut HashMap[i32, i32]
        unsafe { (*cache).insert(type_name, has) }
        has

    fn record_drop_consumed_field(owner_sym: i32, field_sym: i32):
        if owner_sym == 0 or field_sym == 0:
            return
        for i in 0..self.drop_consumed_field_owner_syms.len() as i32:
            if self.drop_consumed_field_owner_syms.get(i as i64) == owner_sym and self.drop_consumed_field_syms.get(i as i64) == field_sym:
                return
        self.drop_consumed_field_owner_syms.push(owner_sym)
        self.drop_consumed_field_syms.push(field_sym)

    fn drop_consumed_field(owner_sym: i32, field_sym: i32) -> i32:
        if owner_sym == 0 or field_sym == 0:
            return 0
        for i in 0..self.drop_consumed_field_owner_syms.len() as i32:
            if self.drop_consumed_field_owner_syms.get(i as i64) == owner_sym and self.drop_consumed_field_syms.get(i as i64) == field_sym:
                return 1
        0

    // ── Borrow checking ──────────────────────────────────────────────

    fn expire_borrows_in_scope(scope_start: i32):
        var i = self.bind_names.len() as i32 - 1
        while i >= scope_start:
            // Annotated: copy the id out — an unannotated binding views the
            // element and the swap-remove below mutates the same receiver.
            let sym: i32 = self.bind_names.get(i as i64)
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
                        self.borrow_scope_depths.set_i32(bi as i64, self.borrow_scope_depths.get(last as i64))
                        self.borrow_creation_nodes.set_i32(bi as i64, self.borrow_creation_nodes.get(last as i64))
                    self.borrow_kinds.pop()
                    self.borrow_places.pop()
                    self.borrow_fields.pop()
                    self.borrow_refs.pop()
                    self.borrow_path_starts.pop()
                    self.borrow_path_counts.pop()
                    self.borrow_scope_depths.pop()
                    self.borrow_creation_nodes.pop()
                    bi = bi  // keep same type as else: branch for phi
                else:
                    bi = bi + 1
            i = i - 1
