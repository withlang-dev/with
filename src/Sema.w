// Sema — Semantic analysis: name resolution, type checking, and validation.
//
// Sema runs as a validation pass between parsing and codegen. It walks
// the AST, resolves all names, computes types for every expression, and
// reports type errors with source spans. Codegen continues to work as
// before — Sema is purely additive validation.

use Ast
use SemaTypes
use BorrowCfg
use Span
use Diagnostic
use InternPool
use render
use Overflow
use TargetSpec
use compiler.TrackedInputs
use compiler.BundleInterfaces
use compiler.ModuleSource
use FnAbi
use SemaCheck
use SemaDecl
use SemaVector
use std.collections.HashMap
use std.collections.HashSet
use compiler.Runtime

extern fn with_write(s: &str) -> Unit
extern fn with_eprint(s: &str) -> Unit
extern fn with_getenv_str(name: &str) -> str
extern fn with_clock_nanos() -> i64
extern fn with_str_clone_ref(s: &str) -> str
extern fn i64_to_string(n: i64) -> str

// WITH_PROFILE=1: one `[profile] sema.<phase>` line per check_module step,
// the same switch and format as the frontend's phase lines.
fn sema_profile_enabled() -> bool: with_getenv_str("WITH_PROFILE").len() > 0

fn sema_profile_report(name: &str, t0: i64):
    let ns = with_clock_nanos() - t0
    with_eprint(f"[profile] sema.{name}  {ns / 1000000}.{(ns % 1000000) / 1000} ms")
extern fn abort() -> Never

pub fn sema_phase_bug(message: &str, origin_file: &str = __FILE__, origin_line: u32 = __LINE__, origin_fn: &str = __FN__):
    with_eprint(f"{message} [{origin_file}:{origin_line} {origin_fn}]")
    abort()

type SemaSourceLocation {
    line: i32,
    col: i32,
}
impl Copy for SemaSourceLocation

// A field path rooted at a scoped binding, in borrow_path_data
// (field_move_path_for_expr); base_sym 0 names none.
type FieldMovePath {
    base_sym: i32,
    path_start: i32,
    path_count: i32,
}
impl Copy for FieldMovePath

pub enum VarState: i32:
    LIVE = 0
    MOVED = 1

pub type BindingProvenance {
    view_origin_mask: i32,
    // The subset of view_origin_mask whose parameters' OWN storage the
    // binding may point into (SemaCheck.compute_expr_storage_origin_mask);
    // set_binding_view_deps resets it to the whole mask (unproven is
    // storage), record_view_binding_from_expr narrows it.
    view_storage_mask: i32,
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
    BindingProvenance { view_origin_mask: 0, view_storage_mask: 0, view_dep_start: 0, view_dep_count: 0, effect_dep_sym: 0, is_ephemeral_value: 0, is_ephemeral_task: 0, is_non_send_task: 0, poisoned_origin_sym: 0, poisoned_origin_node: 0, poisoned_binding_node: 0 }

// D39 declared view origin (SemaCheck.declared_view_origin): a parameter
// index, or one of these.
pub const DECLARED_ORIGIN_NONE: i32 = -2
pub const DECLARED_ORIGIN_AMBIGUOUS: i32 = -1
// §21.1 rule 6: the resolved `from static` entry (resolve_declared_view_origins)
// — a view of static data, with no parameter or global origin. Below every
// parameter entry (-1 - index).
pub const FROM_STATIC_ENTRY: i32 = -1048576

pub fn sema_param_origin_bit(pi: i32) -> i32:
    if pi < 0:
        return 0
    if pi >= 31:
        return -1
    ((1 as i64) << (pi as u32)) as i32

pub fn sema_param_origin_mask_contains(mask: i32, pi: i32) -> i32:
    if mask == 0 or pi < 0:
        return 0
    if mask < 0:
        return 1
    if pi >= 31:
        return 0
    if (mask & sema_param_origin_bit(pi)) != 0: 1 else: 0

pub enum LabelFrameKind: i32:
    LFK_BOUNDARY = 0
    LFK_WHILE = 1
    LFK_FOR = 2
    LFK_BLOCK = 3
    LFK_LOOP = 4

pub type LabelRegistryState {
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

pub enum SemaMagicIdentKind: i32:
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
    // #1655: per-binding foreign-view poison (§16.2b.7) travels with the
    // field-move set so a domain-touching call on a diverging branch
    // leaves the fall-through path's views live.
    poison_syms: Vec[i32],
    poison_nodes: Vec[i32],
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
    va_start: i32,
    va_arg_method: i32,
    copy_trait: i32,
    clone_trait: i32,
    send_trait: i32,
    sync_trait: i32,
    scoped_send_trait: i32,
    deref_trait: i32,
    deref_method: i32,
    drop: i32,
    display_trait: i32,
    debug_trait: i32,
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
    keys: i32,
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
    zeroed: i32,
}

type SemaMethodLookup {
    sig_lookup: HashMap[i64, i32],
    fn_lookup: HashMap[i64, i32],
}

// Identity bits of a callable type beyond its signature (§16.11, #1832).
pub const CALLABLE_UNSAFE: i32 = 1
pub const CALLABLE_VARIADIC: i32 = 2

pub const GLOBAL_VALUE_DECL_DEF: i32 = 1
pub const GLOBAL_VALUE_DECL_EXTERN: i32 = 2
// D39: storage a bundle interface declares; the bundle's object defines it.
pub const GLOBAL_VALUE_DECL_INTERFACE: i32 = 3

// docs/completed/mutability.md §5 — per-parameter effect bits.
pub const EFF_READ: i32         = 1   // parameter is read
pub const EFF_WRITE: i32        = 2   // parameter place is mutated (implies read)
pub const EFF_CONSUME: i32      = 4   // parameter is moved/consumed in the body
pub const EFF_ESCAPE_VALUE: i32 = 8   // owned value escapes the call (return / global store)
pub const EFF_ESCAPE_VIEW: i32  = 16  // view into parameter escapes (return &param.field)
pub const EFF_RAW_PTR_VALIDITY: i32 = 32  // raw pointer parameter validity is caller-guaranteed
pub const EFF_DECLARED_MASK: i32 = EFF_READ | EFF_WRITE | EFF_CONSUME | EFF_ESCAPE_VALUE | EFF_ESCAPE_VIEW
// Closure capture summaries only (§12.4): the capture is a non-Copy place the
// non-move closure holds by place — a view of that local, not a snapshot.
pub const EFF_CAPTURE_BY_PLACE: i32 = 64
// §21.1 (D22, #1783): a view derived from the parameter is stored into the
// receiver's storage — the caller's place (D21), which outlives the call — so
// the caller ties its receiver to this argument's origins as `Vec.push` ties a
// container to its element.
pub const EFF_STORE_IN_RECEIVER: i32 = 128

pub enum ReceiverMode: i32:
    None = 0
    Read = 1
    Mut = 2
    Move = 3
    Missing = 4

impl Copy for ReceiverMode

pub enum WithFormKind: i32:
    Binding = 0
    Guarded = 1
    GuardedMut = 2

// D65 phase 5 (#1647): what a call whose callee is a bare name resolved
// to, recorded by check_call. MirLower dispatches on it in one ordered
// switch and never re-derives it from the name (a local lookup, a variant
// or type table hit, symbol text).
pub enum CallCalleeKind: i32:
    None = 0
    Function = 1
    Callable = 2
    Generic = 3
    Variant = 4
    Distinct = 5
    TypeConstructor = 6
    MathBuiltin = 7
    Intrinsic = 8
    SourceLocation = 9
    StdDrop = 10
    AtomicFence = 11
    TypeLevelBuiltin = 12

impl Copy for CallCalleeKind

// D65 phase 5 (#2043): which builtin a builtin call is, recorded by Sema
// where it checks the call; codegen's builtin dispatch switches on it and
// never on the callee's spelling.
pub enum CallBuiltin: i32:
    None = 0
    Src = 1
    Transmute = 2
    SizeOf = 3
    AlignOf = 4
    NameOf = 5
    EmbedFile = 6
    Chan = 7
    Channel = 8
    Send = 9
    Recv = 10
    Close = 11
    // Method-call builtins (check_method_call_parts records them).
    BoxNew = 12
    BoxIntoInner = 13
    AtomicNew = 14
    EndpointSend = 15
    EndpointRecv = 16
    EndpointClose = 17
    ScopeTrack = 18
    ScopeSpawn = 19
    ScopedJoin = 20
    // §4.4a `Enum.from_int(n)` on a discriminant enum.
    EnumFromInt = 21
    // D96: `with_key_hash[K](key)`, the body of `std.hash.hash_of`.
    KeyHash = 22
    // D109 (#2131): `offsetof[T](field)`, the field's byte offset in T's
    // layout for the compilation target.
    OffsetOf = 23

impl Copy for CallBuiltin

pub enum AllocConstructKind: i32:
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

pub fn sema_effect_bits_text(bits: i32) -> str:
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
    if (bits & EFF_STORE_IN_RECEIVER) != 0:
        if out.len() > 0: out = out ++ ", "
        out = out ++ "store_in_receiver"
    if out.len() == 0:
        return "none"
    out

// ── Sema state ───────────────────────────────────────────────────

// D22 Stage 2: one semantic record for a shared-reference expression that an
// independently resolved owned context will materialize. `exact_source_type`
// remains &T. `owned_value_type` is T, and `target_type` is the destination
// after any ordinary value coercion. A differing `post_copy_type` records that
// final coercion explicitly for later MIR/backend consumption.
pub type ContextualCopyAdjustment {
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
pub type ContextualJoinDecision {
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

// D51 §16.2b stage 2: a facade's facts, each with the node that stated it.
// Parameter positions are zero-based indices into the fn's signature; -1 is
// "none". Consumed by stage 3 (raw classification) and later stages.
pub type FacadeResource {
    name: i32,
    facade: i32,
    node: i32,
    decl: i32,            // the `c facade` block's declaration index: diagnostics name its file
    repr_tid: i32,
    producers: Vec[i32],  // one per `from` clause (fopen, fdopen, tmpfile → one FILE)
    out_params: Vec[i32], // parallel to producers; -1 for a direct return
    init: i32,
    preinit: i32,
    drop: i32,
    destroyers: Vec[i32],
    ok_consts: Vec[i32],       // `ok C1, C2, …` (§16.2b.4): the success statuses as stated, any of them success; empty without `ok`
    ok_node: i32,              // the `ok` clause (provenance, and a second one is refused), or 0
    borrows: Vec[i32],         // the parameter each `borrows` clause names
    borrows_owner: Vec[i32],   // parallel: the producer it names one of (a `from` index, or FACADE_DEP_INIT)
    borrows_nodes: Vec[i32],   // parallel: the clause (provenance, §16.2b.2)
    last_producer: i32,        // the producer clause stated last while collecting (-2: none yet)
    independent: i32,
    independent_node: i32,
    movable: i32,         // in-place resource declared `movable` (D54); pinned otherwise
    thread_caps: i32,     // bit0 creator, bit1 send, bit2 share, bit3 drop_any_thread
    abandon: i32,         // `abandon <fn>` (§16.2b.9): the `callbacks none` operation run before the destroyer on a drop path not proven callback-free, or 0
    abandon_node: i32,
    message: i32,         // `message <fn>` (ruling Amendment 3): the operation describing the most recent failure, or 0
    message_node: i32,
    handle: i32,          // 1 for a callback-scope `handle Name wraps *mut T` (§16.2b.9): no producer, destroyer or Drop; borrowed for the callback's invocation
}

pub type ForeignContract {
    decl: i32,            // the `c facade` block's declaration index: diagnostics name its file
    fn_sym: i32,
    facade: i32,
    node: i32,
    lend: i32,
    destroys: i32,
    consumes: Vec[i32],
    consumes_destroyed_by: Vec[i32],   // parallel to consumes; -1 = none
    retains: Vec[i32],
    retains_by: Vec[i32],
    returns_borrow_resource: i32,   // a resource, or `CStr` (the borrowed modeled text, §16.2b.8)
    returns_borrow_from: i32,       // the origin parameter, or -1
    returns_borrow_domain: i32,     // the origin foreign-state domain (`from domain D`, §16.2b.7), or 0
    returns_borrow_parent: i32,     // D85 (§16.2b.6): `from parent P of param N` — the parent resource P of the resource param N receives, or 0
    returns_static_tid: i32,
    preserves_params: Vec[i32],
    preserves_domains: Vec[i32],
    of_resource: i32,
    rename: i32,
    callback_thread_any: i32,
    callbacks_none: i32,             // clause node; 0 means conservatively reentrant
    callback_consumes: Vec[i32],
    callback_userdata_cb: Vec[i32],    // `callback param N userdata param M`: the callback parameter N …
    callback_userdata_of: Vec[i32],    // … and the userdata parameter M it receives (parallel)
    valid_on_failed: i32,              // `valid on failed`: presented on the failed-state resource too (§16.2b.4)
    nullable_params: Vec[i32],         // `nullable param N`: the facade establishes the parameter accepts NULL (§16.2b.8)
    bridged: i32,                      // #2223: a clause makes the function render through a bridge (Ast.facade_clause_bridges) — the one owner the renderer's lend item and facade_contract_presented read
    buffer_ptr: Vec[i32],              // D64 §16.2b.8: each `buffer param P …` pairing's pointer parameter …
    buffer_len: Vec[i32],              // … its length parameter (parallel) …
    buffer_inout: Vec[i32],            // … and 1 for `capacity param L inout`, 0 for `len param L` (parallel)
    buffer_elements: Vec[i32],         // explicit element count; otherwise bytes (D64)
    fixed_params: Vec[i32],            // D64 §16.2b.11: each `param N fixed <literal>` parameter …
    fixed_literals: Vec[i32],          // … and its literal node (parallel)
    ok_const: i32,                     // `ok CONST` on the fn item: its status contract (D64; ruling Amendment 3), the first constant of a list
    ok_count: i32,                     // how many constants the `ok` lists (Amendment 3: several on a status-returning operation)
    variadic_node: i32,                // D66 §16.2b.5: the `variadic param N selected by param P:` clause, or 0 …
    variadic_selector: i32,            // … its selector parameter P (-1: none) …
    variadic_case_syms: Vec[i32],      // … each case's imported constant …
    variadic_case_values: Vec[i64],    // … that constant's value (parallel) …
    variadic_case_tids: Vec[i32],      // … the presented type of the variadic argument (parallel) …
    variadic_case_kinds: Vec[i32],     // … and its kind: FACADE_VARIADIC_SCALAR or FACADE_VARIADIC_STR (parallel)
    variadic_slots: Vec[ForeignVariadicSlot], // resolved retained cases; no downstream AST interpretation
    returns_borrow_record: i32,        // D66 §16.2b.6: `returns borrow T from …` for an imported record T (the type's symbol), or 0
    argv_cb: Vec[i32],                 // D76 §16.2b.9: each `callback param N argv param A paired with argc param C as &[H]`: the callback parameter N …
    argv_index: Vec[i32],              // … A and C, indices into the callback's own parameters …
    argc_index: Vec[i32],
    argv_handle: Vec[i32],             // … the handle H (facade_resources index) …
    argv_nodes: Vec[i32],              // … and the clause (parallel)
    user_data_fn: i32,                 // D76 §16.2b.9: `user_data from <fn> as &U`: the C function that hands back the registered userdata, or 0 …
    user_data_handle: i32,             // … the callback-scope handle it takes (facade_resources index), or -1 …
    user_data_node: i32,               // … and the clause
}

// D66 §16.2b.5: what a variadic case's argument is.
pub const FACADE_VARIADIC_SCALAR: i32 = 1   // a scalar C type: passed as that type
pub const FACADE_VARIADIC_STR: i32 = 2      // `str`: a copied input string (§16.3c), passed as a call-scoped C string
pub const FACADE_VARIADIC_CALLBACK: i32 = 3
pub const FACADE_VARIADIC_RETAINED: i32 = 4
pub const FACADE_VARIADIC_USERDATA: i32 = 5 // the userdata setter a callback case implies (§16.2b.5): `&U`, the borrow the resource holds

pub type ForeignVariadicSlot {
    case_index: i32,
    clause: i32,
    resource: i32,
    retainer_param: i32,
    callback_type: i32,       // resolved C callable type, or 0 for retained data
    callback_userdata: i32,   // argument within that callable, or -1
    userdata_selector: i32,   // imported selector symbol, or 0
    userdata_value: i64,
}

// A callback method a facade rendered on a resource (stage 9, ruling
// §44-§51; FacadeRender.w facade_render_callback_methods), keyed by the
// method's symbol text (`Database.register`): the fn item, and the indices
// — in the rendered signature, `self` excluded — of the userdata parameter
// (-1: none typed), for the checks the rendered generic method cannot state
// itself: the userdata type is Send and Sync under `callback_thread any`.
pub type FacadeCallbackMethod {
    contract: i32,
    receiver_params: i32,
    userdata_param: i32,
    callback_param: i32,
    thread_any: i32,
    retained: i32,
    consumed: i32,
    nullable: i32,    // the callback is nullable (#1618): `Option[extern "C" fn(&U, …)]`, its userdata `Option[&U]`
    wrapped_params: Vec[i32],  // D76: the callbacks a generated wrapper serves (rendered indices), each `extern "C" fn(…, &U)` with `U` the userdata's
}

// D66 retained variadic pairs (#1652, §16.2b.9): what one operation of a
// resource that has a callback pair does to that pair, keyed by the concrete
// signature MIR records on the call (SemaFacade.w facade_index_pair_ops,
// facade_note_pair_op_sig). MIR proves the pair's state per place along
// every path (MirForeignPairs.w); Sema decides what each call means.
pub type FacadePairOp {
    contract: i32,      // foreign_contracts index
    resource: i32,      // facade_resources index
    action: i32,        // FOREIGN_PAIR_CALLBACK / _USERDATA / _RESET / _DESTROY / _INVOKE (ForeignPairState.w)
    slot: i32,          // the contract's variadic slot a setter serves, or -1
    userdata_tid: i32,  // the concrete `U` a setter installs (the specialization's), or 0
    guard_ok: i64,      // the setter's success status (`ok CONST` on the operation), or -1: uninterpreted
    invokes: i32,       // 1 unless the operation is `callbacks none`
    subject_param: i32, // the parameter that receives the resource the operation acts on
    retained_param: i32, // the parameter whose referent a userdata setter retains (its `&U`), or -1
}

// Context shared by free and receiver callback calls. Userdata is checked
// first so its type can give the callback its concrete C signature.
pub type FacadeCallbackCall {
    userdata_node: i32,
    userdata_type: i32,
    nullable: bool,
    valid: bool,
}

// A foreign-state domain (ruling §33-§37): ownerless C storage given an
// origin. `origin_sym` is the symbol views borrowed from it depend on, as
// they depend on a binding; `files` are the `<c_import …>` translations of
// the functions the declaring facade describes — the coarse library whose
// every operation touches the domain unless it `preserves` it (§34, §38).
pub type FacadeDomain {
    name: i32,
    kind: i32,          // process | thread | resource | static (sym)
    facade: i32,        // the facade that declared it first
    facades: Vec[i32],  // every facade declaring it: same name and kind name the same state (§35)
    blocks: Vec[i32],   // the `c facade` block nodes declaring it (a block declares it once)
    node: i32,
    origin_sym: i32,
    files: Vec[i32],
}

// What a call to signature `sig` does to foreign views (ruling §38): the
// parameters whose received resource's views it invalidates (a bit per
// parameter; every received resource unless `preserves param N`), the
// domains it invalidates (its library's, unless `preserves domain D`), and
// the domain its result borrows from (`returns borrow CStr from domain D`).
pub type FacadeCallEffect {
    sig: i32,
    fn_sym: i32,             // the C function (its facade fn item is `contract`)
    contract: i32,           // foreign_contracts index, or -1
    touch_params: i32,
    touch_domains: Vec[i32], // facade_domain_list indices
    borrow_domain: i32,      // facade_domain_list index, or -1
    borrow_param: i32,       // a presented call's origin parameter (a C string it is lent), or -1
    // A producer sig's C parameter per presented one (its out slot gone, an
    // init's preinit parameters ahead), as the mask was projected; empty for
    // every other call (facade_effect_source_param inverts their projection).
    param_sources: Vec[i32],
}

pub type Sema {
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
    // Impl targets resolved in the declaration's lexical module, before any
    // body can ask which concrete destructor a dynamic value may run.
    impl_decl_target_types: HashMap[i32, i32],
    // Temporary accumulators for cycle detection (accessed through self)
    cycle_dep_syms: Vec[i32],
    cycle_dep_nodes: Vec[i32],
    // Fallback pretty names keyed by symbol id.
    pretty_symbol_names: HashMap[i32, str],

    // Function signatures (parallel arrays)
    sig_names: Vec[i32],
    sig_text_index: HashMap[str, i32],  // resolved name text → newest signature; older ones chain through sig_text_prev
    sig_text_prev: Vec[i32],
    sig_type_ids: Vec[i32],
    sig_ret_types: Vec[i32],
    sig_param_starts: Vec[i32],
    sig_param_counts: Vec[i32],
    sig_variadic: Vec[i32],
    sig_params: Vec[i32],
    sig_lookup: HashMap[i32, i32],
    // An extern keeps its own signature when a curated wrapper takes its name.
    extern_decl_sigs: HashMap[i32, i32],
    // docs/completed/mutability.md Phase 4 — per-parameter effect bitsets.
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
    // Parallel to sig_param_view_origins: the origin parameters whose own
    // storage the returned view provably never points into — the result
    // views only what they view (SemaCheck.compute_expr_storage_origin_mask;
    // §21.1 Rule 6). A call records such a parameter's argument by its views
    // alone, never by its own place; 0 (unproven) keeps the place an origin.
    sig_param_view_through: Vec[i32],
    // D63 call-once: 1 when the body invokes this parameter more than once
    // (twice, or once inside a loop) — a consuming closure may not be
    // passed to it.
    sig_param_invoke_many: Vec[i32],
    // Per body: how many times each callable binding is invoked (symbol →
    // count; an invocation inside a loop counts twice).
    fn_param_invocations: HashMap[i32, i32],
    // Per body: the call that made a callable binding's count exceed one
    // (the site a `once` parameter's error names, §12.4).
    fn_param_many_nodes: HashMap[i32, i32],
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
    // (docs/spec/toolchain/deep-debugging-tools.md).
    consume_call_sites: Vec[i32],
    // move-sites: use sequencing. ONE persistent map per key kind, one owner —
    // bodies are separated by an epoch packed into every value (epoch*2^32 +
    // seq), never by swapping map headers (bit-copy map swaps are the #697
    // aliasing class and corrupted Sema state via stale-header inserts).
    binding_use_seq: i32,
    binding_use_epoch: i32,
    binding_epoch_counter: i32,
    binding_last_use: HashMap[i32, i64],
    // #1242: ident nodes that resolved to a module global (not a local or
    // parameter), keyed by node — the move checks consult it after scopes pop.
    global_value_ident_nodes: HashMap[i32, i32],
    // `const` globals: comptime values, exempt from the move-out check.
    const_global_syms: HashMap[i32, i32],
    // D88 (§4.2.1): a `const` declared without a type, by name: its
    // declaration, and the others of that name in other modules. Whether one
    // is an untyped numeric constant is its initializer's to say
    // (untyped_const_init).
    untyped_const_decls: HashMap[i32, i32],
    untyped_const_alt_decls: Vec[i32],
    // An identifier that names an untyped numeric constant -> the
    // initializer it stands for at that use. Its type there is the node's in
    // typed_expr_types; MIR lowers the initializer at that type.
    untyped_const_uses: HashMap[i32, i32],
    // D89 (§4.3): a field whose numeric type its uses decide. The frontend
    // checks such a program twice: once to hear what the uses demand
    // (collect_field_demands; each such field is a distinct alias of its
    // default type, so a demand names its field), and once with every
    // field at the type decided (field_decisions: per field, its type node,
    // the type, whether two were demanded, and the two with their uses).
    // An assignment's store: its operands were all evaluated before it
    // (#2099), so a view used only in them is not live across it.
    store_follows_operands: i32,
    collect_field_demands: i32,
    inferred_field_nodes: Vec[i32],
    inferred_field_aliases: Vec[i32],
    inferred_field_paths: Vec[str],
    field_demand_fields: Vec[i32],
    field_demand_types: Vec[i32],
    field_demand_uses: Vec[i32],
    field_decisions: Vec[i32],
    // D93 (§4.3c rule 1): a binding with no annotation whose initializer is
    // an element-form literal takes its type from its uses. The check hears
    // them (literal_demands: per demand, the `let`, the demanded type, the
    // use); a program with a demand is checked again with every such
    // binding at the type decided (literal_decisions; its layout is
    // literal_decisions_from_demands's).
    literal_demands: Vec[i32],
    // Every literal binding checked so far, as (function signature, name,
    // `let`) triples: a return is judged after the body's scopes have
    // closed, and a generic callee's body is checked in the middle of its
    // caller's.
    fn_literal_lets: Vec[i32],
    literal_decisions: Vec[i32],
    // The number of types when the first such binding was reached: the two
    // checks are the same check up to there, so a type below this mark has
    // one id in both, and a type above it is rebuilt from its structure.
    literal_watermark: i32,
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
    // The node that moves a binding (`move x`, a consuming use), for the
    // diagnostic of a view that outlives the move (§21.1 Rule 7); 0 when the
    // mover has none to give.
    move_site_node: i32,

    // Extern fn names
    extern_fn_names: HashMap[i32, i32],
    // "<module path>\n<name>" for every `extern fn` declaration site (#1695):
    // a module that declares an extern itself is classified by ITS
    // declaration, not by whichever other module (std.fs) declared the
    // same name last.
    extern_decl_sites: HashMap[str, i32],
    extern_var_texts: HashMap[str, i32],  // every collected extern var by name text (has_extern_var_decl)
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
    // Per declaration (#1451): enum TypeId -> start of its variants' values in
    // disc_value_list, in variant order.
    disc_value_starts: HashMap[i32, i32],
    disc_value_list: Vec[i64],
    disc_has_payload: HashMap[i32, i32],
    bitpacked_types: HashMap[i32, i32],  // type_id → 1 if bitpacked
    packed_types: HashMap[i32, i32],     // type_id → 1 if repr(packed)/@[packed]
    packed_caps: HashMap[i32, i32],      // type_id → N of @[repr(packed(N))] (§16.4)
    repr_c_types: HashMap[i32, i32],     // type_id → 1 if @[repr(C)] (or repr(packed))
    // §16.11: TY_FN/TY_EXTERN_FN type_id → 1 when the callable is unsafe to
    // call (carries a raw-pointer-validity precondition). Part of type identity.
    unsafe_fn_type_set: HashMap[i32, i32],
    // #1832: C variadic function-pointer types, `extern "C" fn(A, ...) -> R`.
    // Variadic-ness is part of the type's identity, and a variadic type is
    // always unsafe to call (§16.3c: a variadic call is raw).
    variadic_fn_type_set: HashMap[i32, i32],
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
    // D100 (§18.3): the `pub` fields, keyed by (type declaration node, field
    // name); a field not here is private to its package (sema_field_key).
    pub_field_keys: HashSet[i64],
    // §16.2b.3: the `T.zeroed()` calls on zero-valid C records; MIR
    // lowers each to the all-zero value of its type.
    zeroed_call_nodes: HashSet[i32],
    // D104 (§17.1): the static comptime-callability verdict per function
    // symbol, for `comptime fn` bodies (checked at the declaration): 1
    // callable, 0 not; and for a refusal, the chain of calls to the first
    // forbidden operation (`helper -> print (I/O)`). Plain functions called
    // at compile time are judged by the evaluator instead.
    comptime_callable_memo: HashMap[i32, i32],
    comptime_callable_chain: HashMap[i32, str],
    comptime_callable_visiting: HashSet[i32],
    // §4.9a (D103): expressions a demanded Option[T] converts to Some(expression);
    // MIR builds the Some around the lowered value. Keyed by expression node,
    // the Option type.
    value_to_option_nodes: HashMap[i32, i32],
    // The operand an operator is checking against its other operand's type:
    // not a demand site (§4.9a), so no conversion fires on it.
    operator_operand_nodes: HashSet[i32],
    type_tid_is_std: HashMap[i32, i32],
    // #751 / #1745: the template declaration (its TY_STRUCT/TY_ENUM tid) a
    // generic instance was made from — identity, not the short name, since
    // a user `type PullCore` beside std.task's `PullCore[G]` shares the
    // symbol. Recorded by resolve_generic_type and carried through
    // substitution; read by generic_inst_template_tid.
    generic_inst_templates: HashMap[i32, i32],
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
    // §4.5 (D75, #1802): the ownership mode of a cast whose target relabels
    // its source (CastMode, keyed by the NK_CAST node). Absent: an ordinary
    // value conversion. MirLower materializes the mode; it never re-derives it.
    cast_modes: HashMap[i32, i32],
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
    // D69 (§13.4) generator metadata. A `gen fn f(params) -> T` is three
    // functions: `f` builds the generator value — a compiler-generated struct
    // holding the arguments, which implements Gen[T]; its `each(body)` method
    // calls the producer `run(params, body)`, the lowered body of `f`, in
    // which every `yield e` calls `body(e)`. Keys: the gen fn's symbol, except
    // generator_state_yield_types (state type id) and generator_mir_only_fns
    // (run/each symbol → gen fn symbol; MIR-only functions codegen declares).
    generator_fn_yield_types: HashMap[i32, i32],
    generator_fn_state_types: HashMap[i32, i32],
    generator_fn_state_syms: HashMap[i32, i32],
    generator_fn_run_syms: HashMap[i32, i32],
    generator_fn_each_syms: HashMap[i32, i32],
    // Gen fns whose generator value holds a view of the borrowed receiver
    // (field 0 is &Self): the constructor stores its place, `each` passes
    // that place to the producer.
    generator_fn_receiver_views: HashMap[i32, i32],
    generator_mir_only_fns: HashMap[i32, i32],
    generator_state_yield_types: HashMap[i32, i32],
    // §13.6a: an NK_FOR whose iterable is an Option or Result is the
    // one-clause comprehension the parser recorded beside it: the NK_FOR
    // node -> that match node, which Sema checked and MIR lowers instead.
    for_carrier_matches: HashMap[i32, i32],
    // D69 (§13.4): `for x in g` over a Gen[T] runs its body as the `body`
    // closure of `g.each(body)`. Keyed by the NK_FOR node: the element type
    // T, the closure's type fn(T) -> bool, and the `each` callee (its
    // signature and specialization symbol for a generic impl). The body's
    // captures live in the closure capture summary under the same node.
    gen_for_elem_types: HashMap[i32, i32],
    gen_for_body_types: HashMap[i32, i32],
    gen_for_each_syms: HashMap[i32, i32],
    gen_for_each_sigs: HashMap[i32, i32],
    gen_for_each_monos: HashMap[i32, i32],
    // D65 (§13.5): the element type Sema bound each loop's pattern to — keyed
    // by the NK_FOR node, and a comprehension clause's by its iterable node.
    // MIR reads it; it re-derived one from the iterable's type.
    for_elem_types: HashMap[i32, i32],
    // §13.5 (#1837): the `.iter()` the compiler inserts for a loop over a
    // collection that is no Iter[T] — the callee, its signature, its
    // specialization symbol (a generic impl) and the iterator type it
    // returns, keyed like for_elem_types. MIR lowers exactly this call and
    // steps its result with `next()`.
    for_iter_fn_syms: HashMap[i32, i32],
    for_iter_sigs: HashMap[i32, i32],
    for_iter_monos: HashMap[i32, i32],
    for_iter_types: HashMap[i32, i32],
    // The concrete `next()` of a non-generic iterator that `.iter()`
    // returns (a generic one is demanded into iter_next_sigs/monos).
    for_iter_next_fns: HashMap[i32, i32],
    mutable_global_syms: HashMap[i32, i32],
    // docs/completed/mut.md Rev 8 §12 / §15.12 — symbols declared via `global X = ...`
    // (stable) recorded here. Used by check_assign to emit a specific
    // diagnostic on rebind attempts. `global var X = ...` does NOT register
    // here — it's rebindable.
    stable_global_syms: HashMap[i32, i32],
    global_value_decl_kinds: HashMap[i32, i32],
    // D39: a bundle interface's storage and constants live beside the flat
    // global scope, not in it — symbol → binding index and declaring module,
    // consulted by scope_lookup only from a module that imports theirs.
    interface_global_index: HashMap[i32, i32],
    interface_global_paths: HashMap[i32, str],
    // The same name exported by a second bundle (pcre2's and zlib's
    // UINT_MAX, both from limits.h): every further declaring module gets
    // its own binding, and scope_lookup picks the one the current module
    // imports. Parallel rows: symbol, binding index, declaring module.
    interface_global_alt_syms: Vec[i32],
    interface_global_alt_binds: Vec[i32],
    interface_global_alt_paths: Vec[str],
    // D39 lazy interface collection (SemaDecl.prepare_interface_demand):
    // per declaration, 1 when its module is a registered .wi section, and
    // 1 when the source can name it; the symbols the source names.
    decl_is_iface: Vec[i32],
    decl_iface_demanded: Vec[i32],
    iface_mentioned: HashMap[i32, i32],
    interface_eager: i32,            // 1: a bundle build or a .wi root — collect every interface declaration
    // every flat-scope global's declaring module and binding index (symbol
    // → path, symbol → index), and the globals a local binding is standing
    // in for while its scope lasts — a function's local may take the name
    // of a global its module cannot see (§18.1); the global's slot returns
    // when the scope ends
    global_value_decl_paths: HashMap[i32, str],
    global_value_decl_bindings: HashMap[i32, i32],
    shadowed_global_syms: Vec[i32],
    shadowed_global_indices: Vec[i32],
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
    // #1819 (§9.1c: globals are places; §21.1 rule 1): a call whose callee
    // writes a global — itself, or through its own calls — writes it at the
    // call site. Bodies are keyed by sema_global_effect_body: a signature
    // index, or a closure node. The write fact is the race proof's
    // (record_global_data_race_access); each is kept with the body it is in,
    // flattened as [body, sym, node, file]. Every resolved call is kept as
    // [caller body, call node, file, first target, target count, callee]
    // over global_call_targets (its callee, and each callable it is handed:
    // a closure, or a callable parameter of the caller, which the callee
    // may run), the callables it binds to the callee's parameters as [call,
    // parameter index, bound body], and a view of a global live across it
    // as [call, sym, view sym, view node, last use, flags] — judged once
    // every body is checked (check_calls_against_live_global_views), since a
    // callee's writes are known only then (forward references, recursion).
    global_write_records: Vec[i32],
    global_calls: Vec[i32],
    global_call_targets: Vec[i32],
    global_call_bindings: Vec[i32],
    global_view_call_checks: Vec[i32],
    // The body writes and calls are in when it is not the function being
    // checked: a closure (-2 - its node) or a default method checked for an
    // impl (its signature); -1 for the function (global_effect_body).
    current_effect_body: i32,
    // A function named as a value (`apply(change)`), keyed by the ident
    // node, to the signature Sema resolved it to (check_ident).
    fn_value_ident_sigs: HashMap[i32, i32],
    // #1827: how many of global_dispatchers expand_global_dispatchers has
    // given their call records; the rest are expanded on the next call.
    global_dispatchers_expanded: i32,
    // Dynamic drop traversal decisions: [dyn type, impl declaration, target
    // type], with the lookup context retained for the semantic inspector.
    global_drop_impl_targets: Vec[i32],
    global_drop_impl_contexts: Vec[str],
    // §21.1 rule 1: each declaration's resolved `writes` clause, keyed by
    // its node, as an index into declared_write_syms_flat holding the count
    // then the global symbols (resolve_declared_global_writes).
    declared_write_starts: HashMap[i32, i32],
    declared_write_syms_flat: Vec[i32],
    // #1903 (§21.1 rule 6): the globals a function's returned view views —
    // directly, or through a callee's returned view — keyed by signature, as
    // a chain over ret_global_origin_entries [sym, node, next]
    // (note_returned_global_origins). A call's result views them
    // (record_call_view_origins_args), so §21.1 rule 1 judges a write of
    // one while the result is live.
    ret_global_origin_heads: HashMap[i32, i32],
    ret_global_origin_entries: Vec[i32],
    // Each declaration's resolved `from` clause, keyed by its node, as an
    // index into declared_from_flat holding the count then the entries: a
    // parameter as -1 - its index, a global as its symbol
    // (resolve_declared_view_origins).
    declared_from_starts: HashMap[i32, i32],
    declared_from_flat: Vec[i32],
    // Recursion (#1903): a call that reads a callee's returned-view globals
    // before the callee's body is done (it calls back, directly or through
    // others) also ties its result to a placeholder standing for that
    // callee's final set — a symbol per signature, both ways mapped. The
    // sets are completed by a monotone fixpoint once every body is checked
    // (resolve_ret_global_origin_fixpoint); the signatures with a set, in the
    // order first met, are what it iterates. A write of a global while a
    // placeholder view is live is judged then, as [global, placeholder] with
    // the diagnostic a view of the global itself gets, built at the write
    // (judge_placeholder_writes); so is each `from` clause, as
    // [declaration, sig, file].
    ret_origin_placeholder_sigs: HashMap[i32, i32],
    ret_origin_placeholder_syms: HashMap[i32, i32],
    ret_global_origin_sigs: Vec[i32],
    ret_view_placeholder_writes: Vec[i32],
    ret_view_placeholder_diags: Vec[Diagnostic],
    declared_from_checks: Vec[i32],
    // #1827: bodies a call runs that the running program chooses — every
    // impl of a dyn method, every callable of a callable type, every drop a
    // type's drop runs — as [kind, a, b]; chained by `a` for lookup.
    global_dispatchers: Vec[i32],
    global_dispatcher_heads: HashMap[i32, i32],
    global_dispatcher_next: Vec[i32],
    // #1827: every callable value in this compilation — a closure (-2 - its
    // node) or a function named as a value (its signature) — with its
    // callable type, as [body, type]: what a call through a callable no
    // binding names may run.
    global_callable_values: Vec[i32],
    // #1827: an argument passed to a by-value parameter (moved into the
    // callee, which drops it), keyed by the argument node; the first
    // binding of the body being checked (a return drops every binding from
    // here); and, per type, whether its drop runs a user Drop impl (1/0).
    global_consumed_args: HashMap[i32, i32],
    current_fn_bind_start: i32,
    global_user_drop_types: HashMap[i32, i32],
    // #1847: a dyn method call whose method consumes its receiver (`move
    // self`), keyed by the call node.
    dyn_consuming_calls: HashMap[i32, i32],
    // #1860: a typed binding pattern's view type (`c: &Circle`), keyed by
    // the pattern node, and its active binding symbols (for the assign help).
    // The symbol marker expires when that binding leaves scope.
    dyn_downcast_binding_types: HashMap[i32, i32],
    dyn_downcast_binding_syms: HashMap[i32, i32],
    // The matches Sema proved exhaustive (a value position, a must-use
    // subject), keyed by the match node: their last arm's failure edge is
    // no path (MirLower.lower_match).
    exhaustive_matches: HashMap[i32, i32],

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
    // D72 (§2.5.1, #1431): struct name sym -> 1 when the struct carries the
    // hidden liveness byte (struct_needs_liveness_byte), 0 otherwise.
    liveness_byte_cache: HashMap[i32, i32],
    // is_copy cycle guard — HashSet (heap handle) so is_copy can be `&Self` and
    // mutate it through a copied handle (D7 interior-mutability recipe).
    copy_visit_stack: HashSet[i32],
    // type_needs_drop cycle guard — HashSet (heap handle) for `&Self` interior mut.
    needs_drop_visit: HashSet[i32],
    current_drop_type_sym: i32,
    pattern_subject_node: i32,         // subject expr of the pattern being checked (#1272 fix-its); 0 when none
    pattern_bind_mut: i32,             // 1 while checking a `var PATTERN` head: its bindings are mutable (#1354)
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
    // D32 (§2.2): one field-move diagnostic per node — the demand-site
    // error (D22 §13.6) and the implicit-move error claim the node here,
    // whichever fires first.
    field_move_diag_nodes: HashMap[i32, i32],
    // §10.3 (D74, #1710): the optional chains that read their base in place
    // (a Copy field, a borrowing method, a view). A chain absent here takes
    // its payload out of a temporary. Sema decides; MirLower reads.
    optional_chain_observing_nodes: HashMap[i32, i32],
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
    // §29.6 (D95): a binding a `let _ = x` dropped, and that `let`, for the
    // help on a later use.
    discard_lets: HashMap[i32, i32],
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
    // Loop move-state tracking (docs/completed/branch-merge-soundness.md §6.7 / #613):
    // per label frame: entry bind-count (outer/inner boundary), the offset of this
    // loop's break-flag region in loop_break_flat (-1 = none), and whether any
    // break to this frame was captured. loop_break_flat is a flat stack of
    // per-binding break-moved flags (VarState), one region per active loop. Loop
    // regions open and close strictly LIFO, so one flat stack with a per-frame
    // offset holds them, and loop_entry_flat reuses the same offset.
    label_loop_entry_binds: Vec[i32],
    label_break_off: Vec[i32],
    label_break_seen: Vec[i32],
    // #1733: every loop or labeled block a checked `break` exits, by node.
    // Whether a `while true` or `loop` falls through is this fact: a syntax
    // walk looking for the `break` missed one in a let-else's else branch.
    break_target_nodes: HashMap[i32, i32],
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
    // #1722: every block being checked, outermost first (check_block), and
    // the statement each is at — the current block is the last. A view's
    // later use may be in any of them up to the block that declares it.
    live_block_starts: Vec[i32],
    live_block_counts: Vec[i32],
    live_block_indexes: Vec[i32],
    live_block_tails: Vec[i32],
    live_block_depths: Vec[i32],
    // #1722: every loop being checked, outermost first: the part that runs
    // again (a `while` and its condition; a `loop`'s or `for`'s body), the
    // scope depth at its entry, and the loop_depth of its body. A view
    // declared outside a loop and used anywhere in it is used again after
    // a mutation in it, on the next iteration.
    live_loop_nodes: Vec[i32],
    live_loop_depths: Vec[i32],
    live_loop_body_depths: Vec[i32],
    // The first block and loop frame of the body being checked: a function,
    // closure, `async` or scope body (push_label_boundary) starts its own —
    // a generic callee checked in the middle of its caller must not see the
    // caller's blocks. live_floor_saved holds the enclosing body's pair.
    live_block_floor: i32,
    live_loop_floor: i32,
    live_floor_saved: Vec[i32],
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
    // A free math builtin call (`cos(x)`), keyed by the call node, to its
    // MathBuiltins row id. Sema decides once; MirLower reads, never re-derives.
    math_builtin_calls: HashMap[i32, i32],
    // §4.3d (D78): the SIMD vector facts Sema decides and MirLower
    // materializes (SemaVector.w). vector_ops: a construction, splat,
    // `select`, reduction, `.bits()`/`from_bits` or swizzle node → its
    // VectorOp. vector_swizzles: a swizzle/component node → its lane indices
    // (one decimal digit per lane, "3210" for `.wzyx`). vector_splats: a
    // scalar operand or literal broadcast to every lane → the vector type.
    // vector_conversions: a vector value an owned demand widens lane-wise
    // (§4.2.6) → the demanded vector type.
    vector_ops: HashMap[i32, i32],
    vector_swizzles: HashMap[i32, str],
    vector_splats: HashMap[i32, i32],
    vector_conversions: HashMap[i32, i32],
    // D75 (§16.2b.5): a `va_start()` call node (→ 1) and an `ap.arg[T]()`
    // call node (→ T), decided here; MirLower lowers them to VA_START and
    // VA_ARG and ends each started list with its binding scope.
    va_start_calls: HashMap[i32, i32],
    va_arg_calls: HashMap[i32, i32],
    // The initializer a `let`/`var` binding is checking, so `va_start()`
    // knows it names a variable (the only place a list starts).
    va_start_binding_value: i32,
    // #912: the iteration desugar's next() specialization, keyed by the FOR
    // node (loops) or the clause's iterable expression node (comprehensions).
    // A dedicated channel — keying resolved_call_sigs by an expression node
    // would clobber that expression's own call contract.
    iter_next_sigs: HashMap[i32, i32],
    iter_next_mono_syms: HashMap[i32, i32],
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
    // #2211: resolved name uses (node, kind, declaring module path, name) for
    // the analyzer's `reference` facts: a global read, a function taken as a
    // value, a type name — calls and methods have their own facts.
    name_use_nodes: Vec[i32],
    name_use_kinds: Vec[str],
    name_use_paths: Vec[str],
    name_use_names: Vec[str],
    name_use_from: Vec[str],
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
    // §11.7: node -> the comparison operator derived from the family's
    // primitive (`Ord.cmp` for the ordered four, `Eq.eq` for `!=`); the call
    // in operator_method_calls yields i32 / bool and MirLower applies the
    // derivation (`cmp(...) < 0`, `not eq(...)`).
    operator_method_derived: HashMap[i32, i32],
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
    // D61 (§15.4.7): the `:?` formatter registry. Every type an f-string
    // formats with `:?` that is not formatted inline (numbers, bool, str,
    // Unit, raw pointers, views of those) has one entry, and so does every
    // type inside it: an explicit `impl Debug` (its debug_str), a std
    // collection's formatter method, or a formatter MirLower synthesizes
    // after the specialization fixpoint. Entries are keyed by resolved
    // type and kept in registration order (the synthesized bodies' order).
    debug_fmt_index: HashMap[i32, i32],
    debug_fmt_tids: Vec[i32],
    debug_fmt_kinds: Vec[i32],
    debug_fmt_fns: Vec[i32],
    debug_fmt_sigs: Vec[i32],
    debug_fmt_monos: Vec[i32],
    // A Box entry's accessor (Box[T].as_ref, specialized): the formatter
    // reads the payload through the library's own view of it.
    debug_fmt_aux_fns: Vec[i32],
    debug_fmt_aux_sigs: Vec[i32],
    debug_fmt_aux_monos: Vec[i32],
    // Synthesized formatter symbol -> its entry (codegen declares these
    // MIR-only functions the way it declares generator producers).
    debug_fmt_synth_syms: HashMap[i32, i32],
    // debug_fmt_has_form's in-progress types (a recursion guard).
    debug_fmt_probe_visiting: HashMap[i32, i32],
    // Auto-deref adjustment sidecar: expression node -> contiguous step range.
    // Step fn 0 means builtin &/* deref; non-zero is a user Deref.deref fn.
    autoderef_step_starts: HashMap[i32, i32],
    autoderef_step_counts: HashMap[i32, i32],
    // #604 stage 1: call-arg nodes coerced collection→slice (1=imm, 3=mut);
    // consumed by MirLower.lower_call_arg to borrow the place instead of
    // moving the collection.
    slice_coerce_args: HashMap[i32, i32],
    // #1739: a sequence or map literal with no expected instance whose
    // declared destination names a collection with undecided type
    // arguments (a generic struct field `items: Vec[T]`): literal node ->
    // the collection base the literal builds (§4.3c rule 1 and 2).
    collection_literal_hints: HashMap[i32, i32],
    // §4.3a (#1478): `[value; N]` with a non-literal count keeps the count
    // expression as the literal's d2; its evaluated value, by literal node.
    // MirLower and the comptime evaluator read the count here.
    array_fill_counts: HashMap[i32, i32],
    // #1754: the if/match argument now being checked at a `&T` parameter;
    // its arms meet `T` and its join has no owned anchor.
    borrow_pointee_join_node: i32,
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
    // #1302: match / let-else nodes whose pattern CONSUMES the subject (an arm
    // binds a non-Copy value by value, or a Drop type is taken apart). Every
    // other by-value place subject is observed in place by MirLower.
    consuming_pattern_subjects: HashMap[i32, i32],
    // Regex literal metadata sidecars, keyed by NK_REGEX_LIT/NK_PAT_REGEX node.
    regex_capture_counts: HashMap[i32, i32],
    regex_capture_name_starts: HashMap[i32, i32],
    regex_capture_name_counts: HashMap[i32, i32],
    regex_capture_name_syms: Vec[i32],

    // Typed dump sidecar maps (keyed by span start byte offset)
    typed_expr_types: HashMap[i32, i32],
    typed_binding_types: HashMap[i32, i32],
    // D65 (#1647): the callable type an indirect call invokes — a call node
    // whose callee is a callable binding, a callable field or any other
    // callable-typed expression, keyed by the call node. Sema resolves the
    // callee here (check_call) and nowhere else; MirLower materializes the
    // call and `audit:resolution` verifies the MIR callee and argument count
    // against this fact. Absent for a call Sema resolved to a function symbol.
    call_callable_types: HashMap[i32, i32],
    // D65 phase 5: each call's CallCalleeKind (a call whose callee is a
    // name, or a type-level builtin), and the `T.new` a type-constructor
    // call `T(..)` resolved to.
    call_callee_kinds: HashMap[i32, i32],
    type_ctor_call_syms: HashMap[i32, i32],
    // The contents an `embed_file(path)` call embeds, read when Sema
    // evaluated the path (check_intrinsic_call); codegen emits it.
    embed_file_contents: HashMap[i32, str],
    // #2043: each method function's owner key (the symbol its method table
    // row is keyed by), its specializations included.
    method_owner_keys: HashMap[i32, i32],
    // #2043: each builtin call's CallBuiltin, by call node.
    call_builtins: HashMap[i32, i32],
    // D110: the builtin methods' declared signatures (BuiltinSigs.w), loaded
    // once: (owner sym, method sym) -> row, each row's parameter modes, the
    // receiver type names that share an owner (the iterator adapters), and
    // the row each checked builtin call resolved to (call node -> row).
    builtin_sig_index: HashMap[(i32, i32), i32],
    builtin_sig_modes: Vec[str],
    builtin_sig_owner_alias: HashMap[i32, i32],
    builtin_call_sigs: HashMap[i32, i32],
    // D109: each `offsetof[T](field)` call's field index in T's declaration,
    // by call node (Law 3: Sema names the field; codegen reads the layout).
    offsetof_field_indices: HashMap[i32, i32],
    // ... and the record it measures, by call node, as checked outside any
    // specialization (a specialization's own type comes from
    // specialization_type_args). Codegen reads it in every body, a module's
    // runtime initializer included, where no name resolves (#2131).
    offsetof_owner_types: HashMap[i32, i32],
    // #2043: each builtin method call's MirIntrinsic, keyed (instance, node).
    method_intrinsics: HashMap[i64, i32],
    // ... and its MethodLowering kind (present for every checked method call).
    method_lowerings: HashMap[i64, i32],
    // #2043: each method function's own name in its owner's table (`push`
    // for `Vec__i32.push`), recorded with its owner key.
    method_name_syms: HashMap[i32, i32],
    // #2043: an extern variable's declared type, keyed by its declaration.
    extern_var_type_ids: HashMap[i32, i32],
    // #2043: an impl's trait type argument (`impl Trait[i32] for T`) as the
    // default methods it instantiates bind it, keyed by the argument node.
    impl_trait_arg_type_ids: HashMap[i32, i32],

    // C11 6.5.2.2p6-7: the type each argument of a call to a C function is
    // passed as after the default argument promotions, keyed by the call
    // node: `[count, t0, t1, ...]` from the start. Every argument of an
    // unprototyped callee (#1831) — codegen builds the call's FnAbi from
    // exactly these types; for a variadic callee, the `...` arguments the
    // promotion changes, 0 elsewhere (#1849).
    c_promoted_arg_starts: HashMap[i32, i32],
    c_promoted_arg_data: Vec[i32],
    // Signatures declared without a prototype (`int f();`, whose c_import
    // NK_EXTERN_FN carries flag bit 1): C calls them with the promoted arguments
    // and the fixed-argument convention, never the variadic one (#1831).
    unprototyped_sigs: HashMap[i32, i32],

    // D65 (§12): an identifier naming a function, used as a value and typed
    // its With callable `fn(...)` (not an `extern "C" fn`): node -> 1.
    // MirLower marks its constant, and codegen builds the callable adapter.
    fn_callable_values: HashMap[i32, i32],

    // D51 stage 2: facade facts (SemaFacade.w).
    facade_resource_index: HashMap[i32, i32],   // resource sym -> facade_resources index
    facade_resources: Vec[FacadeResource],
    foreign_contract_index: HashMap[i32, i32],  // fn sym -> foreign_contracts index
    foreign_contracts: Vec[ForeignContract],
    facade_domains: HashMap[i32, i32],          // domain sym -> kind sym
    // Stage 7 (ruling §33-§38, spec §16.2b.7): the declared foreign-state
    // domains with their origin symbols, and per signature — a rendered
    // facade operation, or the raw C function itself — what a call
    // invalidates and what its result borrows from a domain
    // (SemaFacade.w facade_index_call_effects; SemaCheck.w
    // record_call_view_origins applies them). A view a call invalidated
    // records the call and the parameter or domain it came through, for
    // the diagnostic at its next use.
    facade_domain_list: Vec[FacadeDomain],
    facade_domain_index: HashMap[i32, i32],     // domain sym -> facade_domain_list index
    facade_domain_origin_index: HashMap[i32, i32], // origin sym -> facade_domain_list index
    facade_call_effects: Vec[FacadeCallEffect],
    facade_call_effect_index: HashMap[i32, i32],   // sig -> facade_call_effects index
    facade_touch_nodes: HashMap[i32, i32],         // call node -> facade_call_effects index
    facade_touch_hit_params: HashMap[i32, i32],    // poisoned view sym -> the parameter the origin came through (-1: a domain)
    current_facade_sym: i32,                       // the `c facade` block being collected
    current_facade_node: i32,                      // its node: two same-named blocks (one per runtime file) are two blocks
    // A text-view return on a function that is no resource's method is
    // presented at the call: the C name stays the surface and the call's
    // result is `Option[CStr]` in every module that imported it
    // (SemaFacade.w verify_facade_text_return; SemaCheck.w check_call).
    facade_presented_syms: HashMap[i32, i32],      // fn sym -> 1
    facade_bridge_of: HashMap[str, str],           // D64: C name -> the rendered free operation presented under it (`__with_facade_<name>`)
    facade_presented_calls: HashMap[i32, i32],     // call node -> 1
    // D65 phase 5 (#2043): a call whose value is a conversion of what its
    // callee returns, and the conversion function Sema chose for it (a
    // presented text view is `cstr_option_from_ptr` of C's pointer,
    // §16.2b.8). MirLower lowers the callee's call and then an ordinary
    // call of the conversion on its result; it knows nothing of why.
    call_value_conversions: HashMap[i32, i32],     // call node -> conversion fn sym
    // D65 phase 5 (#2043): a method call Sema resolved to another method
    // than the one its spelling names (a variadic contract's case, D66
    // §16.2b.5): the name of the method it calls. MirLower reads it in
    // place of the spelling.
    method_call_fields: HashMap[i32, i32],         // call node -> method name sym
    // D86 (§18.2): a call of `assert`/`require`/`check` (std.builtins or
    // std.testing) is a compiler-known form, not a function call: its
    // message is evaluated only when its condition is false (SemaCheck.w
    // check_call; MirLower.w lower_call; ComptimeEval.w eval_call).
    precondition_form_calls: HashMap[i32, i32],    // call node -> form fn sym
    // D66 (spec §16.2b.5): a discriminated variadic contract is presented
    // as one method or function per case, chosen at the call by the
    // selector's compile-time value (SemaFacade.w facade_variadic_retarget;
    // SemaCheck.w check_method_call / check_call record the choice as the
    // call's resolution: comp_resolved, method_call_fields).
    facade_variadic_ops: HashMap[str, i32],        // "Host.method" (hosted) or the presented free name -> foreign_contracts index
    facade_variadic_method_names: HashMap[i32, i32], // a hosted presented method's symbol -> 1 (the cheap pre-check)
    // §30 (spec §16.2b.6): ephemeral-storage errors whose ephemerality a
    // facade resource supplies, held until the facade facts exist
    // (SemaFacade.w report_facade_layout_errors).
    facade_layout_nodes: Vec[i32],
    facade_layout_tids: Vec[i32],
    facade_layout_containers: Vec[i32],
    facade_layout_files: Vec[i32],
    facade_layout_msgs: Vec[str],
    facade_convention_nodes: Vec[i32],
    // Stage 9 (ruling §44-§51, spec §16.2b.9-10): the callback methods the
    // facades rendered, by method symbol text (SemaFacade.w
    // index_facade_callback_methods; SemaCheck.w consults them at generic
    // call sites).
    facade_callback_methods: Vec[FacadeCallbackMethod],
    facade_callback_method_index: HashMap[i32, i32],   // the method's generic fn node -> facade_callback_methods index
    facade_c_invoked_userdata: HashMap[i32, i32],      // §12.4/§16.2b.9: a callback method's concrete signature -> its userdata parameter (signature index), which C invokes through the callback any number of times
    facade_pair_ops: Vec[FacadePairOp],                // D66 #1652: per concrete signature (facade_pair_op_by_sig)
    facade_pair_op_by_sig: HashMap[i32, i32],
    facade_pair_setter_contract: HashMap[i32, i32],    // a pair setter's generic fn node -> foreign_contracts index …
    facade_pair_setter_case: HashMap[i32, i32],        // … and the case it renders (parallel)
    facade_pair_resources: HashMap[i32, i32],          // resource type symbol -> facade_resources index, for resources with a callback pair
    facade_pair_retainers: HashMap[i32, i32],          // a local handed to a pair's userdata setter -> the resource local retaining it (§16.2b.9: alive while the resource is used)
    // D22 §13.6: field-access exprs whose base is a shared view and whose
    // field type is non-Copy — an owned demand on one is an error.
    view_projection_exprs: HashMap[i32, i32],
    // §3.8 join rule 3 (#1408): a non-Copy field place that is an arm of a
    // join with no owned anchor joins as a view of its place — field node ->
    // the `&F` it is typed as there. MirLower lowers it as `ref(shared, place)`.
    join_field_view_arms: HashMap[i32, i32],
    // §2.4: value nodes of drop-body self-field lets — MirLower binds these
    // by MOVE (never the alias path); the field glue skips them via
    // drop_consumed_field.
    drop_consumed_binding_values: HashMap[i32, i32],
    // #1244: initializer nodes of `let s: &T = place` — the annotation demands
    // a reference and the value is an owned T, so the binding BORROWS (§3.8
    // auto-referencing, the same rule as a call argument); MirLower emits the
    // shared ref instead of moving the bytes.
    auto_ref_binding_values: HashMap[i32, i32],
    // #1627: enum payload argument nodes auto-referenced against a `&T`
    // payload (`Some(ctx)` for `Option[&Ctx]`): each is a view of its place,
    // exactly as `&ctx` is (collect_expr_view_deps).
    auto_ref_payload_args: HashMap[i32, i32],
    // CLAUDE.md ceremony census: node -> pattern (1 `.clone()` on a str, 2 an
    // explicit `&` at a `&T` parameter, 3 `Some(x)` where Option is demanded).
    ceremony_sites: HashMap[i32, i32],
    // #1627/#1618: the `Some(...)` a nullable facade callback's userdata
    // argument is, while facade_prepare_callback_call checks it: the
    // parameter is `Option[&U]`, so its payload is borrowed, not moved.
    facade_userdata_ctor: i32,
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
    // §13.4 `g.pull()`: expr_may_suspend records the first suspension site it
    // finds at fn_symbol_may_suspend depth suspend_site_record_depth (-1: none).
    suspend_site_depth: i32,
    suspend_site_record_depth: i32,
    suspend_site_node: i32,
    // #916 (§14.7): the fn declarations whose body may suspend the calling
    // fiber — the least fixpoint settle_may_suspend_facts computes once
    // checking is done, keyed by declaration node so a generic template and
    // its specializations share one answer. While suspend_facts_settling is
    // set, fn_symbol_may_suspend reads this table instead of walking.
    suspend_fact_nodes: HashMap[i32, i32],
    suspend_facts_settling: i32,
    // #1985 (§14.3 INVARIANT 5): the callable summary — whether invoking a
    // callable value may suspend the calling fiber. While checking, an
    // identifier naming a callable binding records what it holds, keyed by
    // the identifier's node: a callable `let` (callable_ident_decls → its
    // declaration, whose values callable_value_* chain: the initializer and
    // every assignment), a parameter of the fn being checked (the caller
    // passed it, and answers for it), or a value Sema cannot see through (a
    // closure's parameter, a capture of one, a global). A fn declaration's
    // name needs no record.
    callable_ident_decls: HashMap[i32, i32],
    callable_param_idents: HashMap[i32, i32],
    callable_opaque_idents: HashMap[i32, i32],
    callable_let_decls: HashMap[i32, i32],
    callable_value_heads: HashMap[i32, i32],
    callable_value_nodes: Vec[i32],
    callable_value_next: Vec[i32],
    callable_value_visiting: HashMap[i32, i32],
    // Settled with suspend_fact_nodes: the (trait, method) pairs whose `dyn`
    // call may suspend (an implementation or the default body may), and the
    // call nodes that reach a may-suspend callable — through the callee
    // value, a `dyn` method, or a callable argument handed over.
    dyn_suspend_methods: HashMap[i64, i32],
    suspend_call_sites: HashMap[i32, i32],
    // §13.4 `g.pull()`: the generator value's type → its gen fn; a gen fn → its
    // first `yield` that hands out a view of its own locals (and that local);
    // each checked `g.pull()` node and its gen fn, judged once bodies are done.
    generator_state_fns: HashMap[i32, i32],
    generator_local_view_yields: HashMap[i32, i32],
    generator_local_view_origins: HashMap[i32, i32],
    gen_pull_nodes: Vec[i32],
    // The `g.pull()` calls of a generator value that is ephemeral (§13.4,
    // #1732): the pulled iterator views what the generator's view arguments
    // view, so the call carries those origins and is an ephemeral value.
    gen_pull_view_nodes: HashMap[i32, i32],
    // A method-call node Sema resolved to a free function that takes the
    // receiver as its first argument, by that parameter's declared mode
    // (§13.4 `g.pull()` is `gen_pull(g)`); MIR lowers the receiver as an
    // ordinary argument, never as a method receiver.
    receiver_arg_call_nodes: HashMap[i32, i32],
    gen_pull_fns: Vec[i32],
    eph_task_visiting: HashMap[i32, i32],
    typed_dump_seen_nodes: HashMap[i32, i32],
    typed_dump_visit_budget: i32,
    // Generic substitution map + specialization cache
    generic_subst_param_syms: Vec[i32],
    generic_subst_type_ids: Vec[i32],
    generic_specialization_cache: HashMap[str, i32],
    // The declaring module of each specialization's template, by mono
    // symbol (#1766): a `__sema__` symbol has no declaration node of its
    // own, and a backend resolving a name in its body frozen (a C emitter's
    // `sizeof[PullCore]` in gen_pull's instance) needs the module that
    // declared the code, not the module that instantiated it.
    specialization_source_paths: HashMap[i32, str],
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
    // #2145: the iterable a `for` or a comprehension clause is stepping
    // through directly. Its `v.iter()` is lowered by the loop, which binds
    // each element as a view; it is never the by-value library iterator.
    loop_iterable_node: i32,
    concrete_drop_sigs: HashMap[i32, i32],
    concrete_drop_mono_syms: HashMap[i32, i32],
    // #2137: structural equality has no AST call node either. A type whose
    // `==` is its own `eq` method, compared as a part of another value
    // (a field, an element, a payload), maps to that method's contract —
    // the method itself, or its specialization for a generic instance.
    concrete_eq_sigs: HashMap[i32, i32],
    concrete_eq_mono_syms: HashMap[i32, i32],
    // The same for `Ord.cmp` (`<` on a value holding the type) and for a
    // key projection, `Key.key` (§11.7, D96).
    concrete_cmp_sigs: HashMap[i32, i32],
    concrete_cmp_mono_syms: HashMap[i32, i32],
    concrete_key_sigs: HashMap[i32, i32],
    // explain:origin (analyze): each view binding's origins as Sema set them,
    // in order, per function (the binding table itself is popped with its
    // scope), and the first node that put a parameter in a returned view's
    // origins and in its storage set. Event: 1 bind, 2 store, 3 loop.
    view_fact_fns: Vec[i32],
    view_fact_syms: Vec[i32],
    view_fact_nodes: Vec[i32],
    view_fact_files: Vec[i32],
    view_fact_events: Vec[i32],
    view_fact_masks: Vec[i32],
    view_fact_storage: Vec[i32],
    view_fact_dep_starts: Vec[i32],
    view_fact_dep_counts: Vec[i32],
    view_fact_deps: Vec[i32],
    param_view_fact_sigs: Vec[i32],
    param_view_fact_params: Vec[i32],
    param_view_fact_storage: Vec[i32],
    param_view_fact_nodes: Vec[i32],
    param_view_fact_files: Vec[i32],
    concrete_key_mono_syms: HashMap[i32, i32],
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

    // docs/completed/mutability.md Phase 4 — per-function effect tracking during body analysis.
    // Cleared and set by check_fn_body_with_sig; used to accumulate effects as the body is checked.
    current_fn_param_syms: Vec[i32],   // param name symbols for the function being checked
    current_fn_param_effs: Vec[i32],   // accumulated effect bits per param
    current_fn_param_direct_effs: Vec[i32], // body-local effects, excluding propagated calls
    current_fn_param_origins: Vec[i32],// accumulated escape_view origin masks per param
    current_fn_param_storage_origins: Vec[i32], // the subset of those whose own storage the returned view may point into
    current_fn_param_view_nodes: Vec[i32], // representative return/view node for escape_view diagnostics
    current_fn_sig_idx: i32,           // sig index of current function (-1 if not in a fn body)
    current_fn_variadic: i32,          // 1 while checking a `...` definition body (never a closure in it)
    recording_propagated_effect: i32,

    // Closure capture summaries: closure node -> [capture_sym, effect_bits, type]*.
    // The type is recorded while the capture's scope is still available.
    closure_capture_summary_starts: HashMap[i32, i32],
    closure_capture_summary_counts: HashMap[i32, i32],
    closure_capture_summary_data: Vec[i32],
    // Binding -> originating closure node when initialized directly from a closure literal.
    binding_closure_nodes: HashMap[i32, i32],
    // D63: `f.clone()` call nodes on a callable value (MirLower lowers them
    // to the CLOSURE_CLONE intrinsic; a bare or view callable copies its
    // pair, an owned environment is cloned by its cell's clone fn).
    callable_clone_nodes: HashMap[i32, i32],
    // D63 call-site checks recorded while bodies are checked and run after
    // the effect fixpoint, when every callee's escape effects and call-once
    // flags are complete regardless of declaration order. Six ints per
    // record: closure node, callee sym, sig, param index, consumes (0/1),
    // by-place capture sym (0 when none).
    deferred_closure_arg_checks: Vec[i32],
    // D63 (§12.4): a callable parameter passed on to another callee's
    // parameter — it is invoked as often as that parameter is. Six ints per
    // record: caller sig, caller param index, callee sig, callee param index,
    // argument node, callee sym. Judged after the effect fixpoint.
    deferred_callable_forwards: Vec[i32],
    binding_view_dep_data: Vec[i32],
    // D65 phase 3 (#1647): Sema's category of each `let` it bound as a
    // view, by let node: 1 = a reference value (`&T`), 2 = a view of a
    // place (a recorded view projection or a field view, D22/D27). MIR
    // materializes 2 as an alias of the place, never as an owning local.
    view_bound_let_nodes: HashMap[i32, i32],
    // Expression-level view metadata for call expressions and view-producing nodes.
    expr_view_param_origins: HashMap[i32, i32],
    // The subset of a node's expr_view_param_origins whose parameters' own
    // storage the value may point into, recorded only where a recorder
    // proved it narrower (compute_expr_storage_origin_mask); absent means
    // the whole mask.
    expr_view_storage_origins: HashMap[i32, i32],
    // #962: a view produced from a statement temporary (`split(..).get(1)`,
    // `split(..)[1]`): node → the temporary's type. Fine inside the statement,
    // a use-after-free once bound or returned.
    expr_view_into_temporary: HashMap[i32, i32],
    expr_view_dep_starts: HashMap[i32, i32],
    expr_view_dep_counts: HashMap[i32, i32],
    expr_view_dep_data: Vec[i32],
    alloc_site_nodes: Vec[i32],
    alloc_site_kinds: Vec[i32],
    alloc_site_fn_syms: Vec[i32],
    alloc_site_elided: Vec[i32],
    current_no_alloc_depth: i32,
    current_fn_may_alloc: i32,
    // #1941: calls recorded while bodies are checked, resolved once every
    // body has published whether it allocates (resolve_allocating_callees).
    // Stride 5: owner fn, callee fn, call node, in @[no_alloc] context, file.
    alloc_callee_calls: Vec[i32],
    alloc_callee_calls_resolved: i32,
    current_fn_symbol: i32,
    // #1983: the specialization whose body is being checked (its mono
    // symbol), 0 outside one; and the type argument of each type-level
    // builtin call (`sizeof[T]()`) as checked in that specialization, keyed
    // pair(mono symbol, type-argument node). A frozen consumer reads the
    // fact instead of re-resolving the node under the instance's
    // substitution, which needs the mutable substitution stack.
    current_specialization_sym: i32,
    specialization_type_args: HashMap[i64, i32],
    // #1647 (D65): each runtime index expression's element place type and
    // the type of the base it indexes, as checked in the body that holds it,
    // keyed pair(specialization symbol or 0, index node). typed_expr_types
    // holds one type per node — a template's nodes carry whichever instance
    // was checked last — so MIR and the audit read the instance's answer
    // here (index_element_in_body).
    index_element_types: HashMap[i64, i32],
    index_base_types: HashMap[i64, i32],
    // ... and each source field access's position in the struct
    // declaration Sema resolved its owner to (field_decl_index_in_body).
    field_access_decl_indexes: HashMap[i64, i32],
    field_access_types: HashMap[i64, i32],
    field_access_owners: HashMap[i64, i32],

    // Current state
    source_text: str,
    tracked_input_root: str,
    tracked_input_paths: Vec[str],
    current_return_type: TypeId,
    current_gen_yield_type: TypeId,
    has_gen_yield_type: i32,
    in_pipeline_rhs: i32,
    match_in_stmt_pos: i32,
    // D43: the node whose type an unannotated function or closure will
    // inherit as its return type. Only a block, `if`, or `match` with this
    // exact id reacts, handing the role to its own tail or arms.
    infer_tail_node: i32,
    infer_tail_is_closure: i32,
    infer_tail_join: i32,
    // §9.1 / D43: the block that is a function's or closure's own body. Only
    // its tail, never an arm block's, is discarded when it is an assignment.
    body_tail_block: i32,
    // §9.1 / D73: the node that holds the body's tail — body_tail_block, or
    // the innermost block, `unsafe:` or `no_suspend` the tail reaches
    // through them and groupings (body_tail_holder_of). The discard verdict
    // applies to its assignment tail or child.
    body_tail_holder: i32,
    // §9.1 / D60: whether that body discards its own assignment tail — true
    // when the body has no declared return (D43 infers) or declares `Unit`.
    // Under a declared non-`Unit` return the tail is the body's value.
    body_tail_discards: bool,
    // §9.1: `main`, `@[entry]` and `test_*` functions do not infer; their
    // tail is statement position whatever expression it is (#1786: a tail
    // call's `str` was moved into the entry's return slot and leaked).
    body_tail_is_statement: bool,
    // The assignment tails Sema discarded (body tails only); MirLower lowers
    // exactly these in discard mode.
    discarded_tails: HashMap[i32, i32],
    // §9.1 / D60: the assignments whose value is the body's returned value —
    // the body tail under a declared non-`Unit` return, or an arm of a tail
    // `if`/`match` that the return takes. MirLower lowers each as its store
    // followed by a read of its place (tail_reads_place): 1 for the tail
    // (D60: a whole local moves), 2 for any other value position (D73: the
    // read is a view of the place, assign_reads_view).
    tail_read_assigns: HashMap[i32, i32],
    // Signatures whose parameter summaries a `c facade` declares
    // (facade_declare_view_of_param: constructors' dependency facts, text,
    // record and Borrowed<R> views): the body check merges its own findings
    // into them and never replaces them (D65: the facade fact is the owner;
    // the rendered body reads a raw pointer and can derive no foreign origin).
    facade_declared_effect_sigs: HashMap[i32, i32],
    // D85: (sig, param) -> the through bits a parent borrow declares
    // (facade_declare_view_through_param): the result views what the
    // parameter views, never its storage.
    facade_declared_through: HashMap[i64, i32],
    // D73: assignment node -> the whole non-Copy local it assigns, when its
    // view (assign_reads_view) is rooted at that local (a view origin).
    assign_view_targets: HashMap[i32, i32],
    // D55 (§18.2): the `if`/`match` node that is the argument of a generic
    // parameter bounded by Display (`print(match ..)`). Its arms join under
    // the ordinary rule; when nothing joins, the fix-it is the f-string.
    display_join_node: i32,
    // D73: 1 while an `if`/`match` join may take an assignment arm as a view
    // of its place; 0 for the tail join of an unannotated body, whose arms
    // join as values (D43, D60: the body returns a read of the place).
    join_assign_arms_as_views: i32,
    // #1196: signatures whose return type has been taken from their body. Until
    // then an unannotated signature reads as Unit, which a caller cannot tell
    // from a function that returns nothing.
    body_typed_sigs: HashMap[i32, i32],
    // Each top-level function declaration index by its semantic symbol
    // (prepare_body_order), for checking a body on demand.
    body_decl_by_fn: HashMap[i32, i32],
    // Calls checked against such a placeholder: (node, sig, callee symbol, file)
    // in fours. Whether the placeholder was wrong is known once every body is typed.
    untyped_callee_calls: Vec[i32],
    // The statement a block is checking: its value is discarded, so a callee
    // that is not typed yet costs a call in that position nothing.
    discarded_stmt_node: i32,
    // check_bodies order (#1196): per declaration 0 unchecked / 1 in progress /
    // 2 done; the node id its subtree starts after; and, for the functions that
    // take their type from their body (#1196) or return a view whose origins
    // their body decides (#1473), declaration index by name symbol, with
    // same-name declarations chained through body_typed_next.
    body_order_state: Vec[i32],
    body_order_lower: Vec[i32],
    // §9.5 (#1930): the struct or union declaration whose fields are in scope
    // by bare name in the body being checked (AstPool.receiver_field_owner),
    // 0 outside its own module's instance methods; and the field names a
    // binding in that body was refused for, whose bare uses then say nothing
    // more.
    receiver_field_owner: i32,
    receiver_field_shadowed: HashMap[i32, i32],
    // §18.1: module_self_name's last answer, for the module path it read.
    self_name_cache_path: str,
    self_name_cache: str,
    // §18.2: callee nodes `builtins.name` bound to a compiler intrinsic —
    // the intrinsic, whatever else the bare name names here.
    builtins_intrinsic_nodes: HashMap[i32, i32],
    body_typed_decls: HashMap[i32, i32],
    body_typed_next: Vec[i32],
    // §13.6a: one for-comprehension's desugar (AstPool.build_comprehension_match)
    // is a chain from its outermost clause match (the root): the inner clause
    // matches and the yield wrap `_Payload(E)` map to the root, and the root to
    // its carrier family (1 Option, 2 Result) and, for Result, the Err type
    // every clause shares. A failure arm's `___fail_i` value re-wraps the
    // clause's failure in the comprehension's carrier: that node -> family.
    comprehension_chain_roots: HashMap[i32, i32],
    comprehension_root_carriers: HashMap[i32, i32],
    comprehension_root_err_types: HashMap[i32, i32],
    comprehension_failure_rewraps: HashMap[i32, i32],
    // §13.6a: check_for typed this match subject (the NK_FOR's iterable)
    // before choosing the comprehension reading; check_match_expr takes the
    // type instead of checking the node a second time.
    prechecked_match_subject: i32,
    prechecked_match_subject_type: i32,
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
    // #943 / #914 D2: set while checking the operand of a unary `-`, so an
    // integer literal is range-checked as the magnitude of a negation rather
    // than as a standalone value. `2147483648` is not a valid i32, but
    // `-2147483648` is exactly i32::MIN.
    in_negated_literal_context: i32,
    // Active lexical unsafe blocks: 0 unused, 1 definite unsafe operation,
    // 2 a global read whose need depends on completed mutation facts.
    unsafe_scope_used: Vec[i32],
    unsafe_scope_nodes: Vec[i32],
    unsafe_global_scope_reads: Vec[i32], // [unsafe block node, global symbol]
    deferred_unsafe_global_scopes: Vec[i32],
    unsafe_global_scopes_resolved: i32,
    break_value_type: TypeId,
    has_break_value_type: i32,
    loop_depth: i32,
    // #1317: view bindings of the enclosing `for` loops. Their borrow of the
    // iterated place lasts the whole loop (the compiler-inserted iterator
    // reads it on every iteration), so it never expires at a lexical last use.
    // for_view_binding_depths[i] is the loop_depth of that loop's body.
    for_view_binding_syms: Vec[i32],
    for_view_binding_depths: Vec[i32],
    // D69 (#1734): 1 when the entry is a generator value's view held across
    // a loop over it — the generator runs while the body runs, so no
    // mutation of the viewed place in the body is harmless.
    for_view_binding_gen_loops: Vec[i32],
    // D69 (#1734): the places a generator call's view arguments name (the
    // referent of `&x`, a view argument, a borrowed receiver), keyed by the
    // call node: gen_call_view_place_nodes[start..start+count].
    gen_call_view_place_starts: HashMap[i32, i32],
    gen_call_view_place_counts: HashMap[i32, i32],
    gen_call_view_place_nodes: Vec[i32],
    stmt_pos_depth: i32,
    current_statement_expr_root: i32,
    current_value_expr_root: i32,
    closure_direct_arg_depth: i32,
    // > 0 while a closure body is checked: the parameter frame
    // (current_fn_param_syms, current_fn_sig_idx) is then the closure's
    // capture frame, not the enclosing function's.
    closure_body_depth: i32,
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
    ty_c_va_list: TypeId,
    ty_const_i8_ptr: TypeId,
    ty_field_info: TypeId,
    ty_variant_info: TypeId,

    // Per-module scoping: tracks which module each declaration belongs to
    // and which symbols are visible in each module context.
    decl_source_paths: Vec[str],     // one path per decl index (from Frontend)
    // D100 (§18.4): module path -> package key, from the Zcu (it can probe
    // for with.toml; Sema reads no files).
    package_keys: HashMap[str, str],
    decl_source_file_ids: Vec[i32],  // one file id per decl index (from Frontend)
    module_path_by_file: HashMap[i32, str], // #1362: file id -> declaring module path (lazy)
    decl_is_c_import: Vec[i32],      // 0 unless the decl came from a c_import; then 1 + the byte offset of that `use c_import` in its module (#1221: import order)
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
    module_import_selected: Vec[str], // aligned: the names a named import selects ("X,Y"), "" for a whole module (#1221)
    module_import_offsets: Vec[i32], // aligned: the `use`'s byte offset in its module — §18.2's import order (#1221)
    // D70 (§18.2): every import's namespace, c_imports included — parallel.
    ns_modules: Vec[i32],   // the importing module's index
    ns_names: Vec[str],     // the namespace name (`math`, `raylib`, an `as` name)
    ns_fulls: Vec[str],     // the module's dotted path (`std.math`), "" for a c_import
    ns_targets: Vec[i32],   // the imported module's index, -1 for a c_import
    ns_offsets: Vec[i32],   // the import's byte offset in its module
    module_index_by_path: HashMap[str, i32],   // path -> module index
    bundle_corpus: str,              // D39: the --bundle-corpus root, "" outside a bundle lane
    global_visible_module_paths: HashMap[str, i32], // prelude-visible modules
    engine_module_corpus: HashMap[str, i32], // #1362: engine corpus module path -> corpus id
    corpus_private_modules: HashMap[str, i32], // #2248: std modules loaded only through a corpus's own imports
    module_visibility_cache: HashMap[str, i32], // "from->to" -> visibility
    named_type_candidate_syms: Vec[i32],       // every registered named type symbol
    named_type_candidate_tids: Vec[i32],       // parallel type id for candidate
    named_type_candidate_paths: Vec[str],      // defining module path or "" for global
    named_type_candidate_pub: Vec[i32],        // parallel public flag
    named_type_candidate_ci: Vec[i32],         // parallel: 1 when a c_import expansion declared it
    named_type_candidate_heads: HashMap[i32, i32], // symbol -> newest candidate index
    named_type_candidate_next: Vec[i32],       // previous candidate for the same symbol
    // #1457: type names declared in more than one source file. A method of
    // such a type carries its declaration: its symbol and its method-table
    // key use the owner's identity symbol (`Name$m$<path hash>`, the way an
    // extension method's `$ext$` symbol does), so each module's `Item.total`
    // is its own (§18.1). Computed once from the decl table
    // (compute_method_origins) so the declaring side and the lookup side
    // read one answer.
    colliding_type_names: HashMap[i32, i32],   // name symbol -> 1
    type_identity_syms: HashMap[i64, i32],     // pair(name symbol, path symbol) -> identity symbol
    type_identity_tids: HashMap[i32, i32],     // identity symbol -> the declaration's TypeId
    type_identity_names: HashMap[i32, i32],    // identity symbol -> the declared name symbol
    impl_identity_traits: HashMap[i64, i32],   // pair(identity symbol, trait) -> 1: that declaration's direct impls
    decl_visibility_syms: Vec[i32],            // top-level symbol visibility candidates
    decl_visibility_paths: Vec[str],           // parallel declaring module path
    decl_visibility_pub: Vec[i32],             // parallel public flag
    decl_visibility_nodes: Vec[i32],           // parallel declaration node
    decl_visibility_index: HashMap[i32, i32],  // symbol → its newest record; older records chain through decl_visibility_prev
    decl_visibility_prev: Vec[i32],
    // #2249: the visibility explainer (`with analyze … explain:visible:<name>`):
    // every rule a verdict passed through, when on.
    visibility_explain_on: i32,
    visibility_explain_log: Vec[str],
    // #2248: the evaluator's own message for the last `comptime if`
    // condition that did not evaluate, so the report names the cause (an
    // unimported type) instead of "not comptime-evaluable".
    comptime_truthy_error: str,
    decl_visibility_node_index: HashMap[i32, i32], // declaration node → its record
    // #1350: fns the flat merge displaced to a module-qualified identity
    // (`name$in$<module>`), chained per short name like decl_visibility.
    displaced_fn_index: HashMap[i32, i32],     // short symbol → its newest record
    displaced_fn_record_of: HashMap[i32, i32], // displaced symbol → its record
    displaced_fn_syms: Vec[i32],               // displaced (module-qualified) symbol
    displaced_fn_paths: Vec[str],              // parallel declaring module path
    displaced_fn_pub: Vec[i32],                // parallel public flag
    displaced_fn_prev: Vec[i32],               // older record for the same short name
    displaced_global_syms: HashMap[i32, i32],  // #1703: displaced records that are module values, not fns
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

pub fn sema_debug_move_enabled -> i32:
    let raw = with_getenv_str("WITH_DEBUG_MOVE")
    if raw.len() == 0:
        return 0
    1

// WITH_DEBUG_BORROWS=1: the borrow table at every read and mutation check
// (SemaCheck.w check_read_against_views, register_view_binding_borrows).
pub fn sema_debug_borrows_enabled -> i32:
    if with_getenv_str("WITH_DEBUG_BORROWS").len() == 0: 0 else: 1

// WITH_DEBUG_PERMUTE_TAGS=1: a plain enum's variants get their tags in
// reverse declaration order (deep-debugging-tools.md, "Representation
// assumptions"). Meaning is unchanged: matching, Ord and every lookup go
// through the variant, so a program behaves the same, unless some code
// assumed a tag ("Some is 0", "the tag is the index") instead of asking.
pub fn sema_permute_tags_enabled -> bool: with_getenv_str("WITH_DEBUG_PERMUTE_TAGS").len() > 0

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
        let existing = self.pool.state.symbol_map.get(name)
        if existing.is_some():
            return existing.unwrap()

        let id = self.pool.state.symbol_texts.len() as i32
        let owned = sema_owned_text(name)
        self.pool.state.symbol_map.insert(with_str_clone_ref(owned), id)
        self.pool.state.symbol_texts.push(owned)
        id

pub fn sema_tier_path_is_std_implementation(path: &str) -> i32:
    if path.starts_with("lib/std/") or path.starts_with("<embedded-std>/"):
        return 1
    if path.contains("/lib/std/"):
        return 1
    0

// Separator-agnostic: a native Windows source path is backslash-separated.
fn sema_dirname(path: &str) -> str:
    var last_slash = -1
    for i in 0..path.len() as i32:
        if path[i] == '/' or path[i] == '\\':
            last_slash = i
    if last_slash <= 0: "" else: path.slice(0, last_slash as i64)

fn sema_vec_str_contains(v: &Vec[str], s: &str) -> i32:
    for i in 0..v.len() as i32:
        if v[i] == s:
            return 1
    0

// Whether a named import's selection ("X,Y") names `name`.
fn sema_selection_names(selected: &str, name: &str) -> bool:
    for part in selected.split(","):
        if part == name:
            return true
    false

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
    if name == "Eq" or name == "Ord" or name == "Key" or name == "Debug":
        return 1
    if name == "Display" or name == "Default" or name == "Drop":
        return 1
    if name == "c_void" or name == "assert_matches_failed":
        return 1
    0

pub fn sema_path_is_std_box_module(path: &str) -> i32:
    if path == "lib/std/box.w" or path == "<embedded-std>/std/box.w":
        return 1
    if path.ends_with("/lib/std/box.w") or path.ends_with("\\lib\\std\\box.w"):
        return 1
    0

pub fn sema_path_is_std_rc_module(path: &str) -> i32:
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

pub fn sema_tier_std_only_module(path: &str) -> i32:
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

pub fn sema_new_map_i32_i32 -> HashMap[i32, i32]:
    HashMap.new()

fn sema_new_map_i32_str -> HashMap[i32, str]:
    HashMap.new()

fn sema_new_map_str_i32 -> HashMap[str, i32]:
    HashMap.new()

pub fn sema_new_map_i64_i32 -> HashMap[i64, i32]:
    HashMap.new()

pub fn sema_new_vec_str -> Vec[str]:
    let out: Vec[str] = Vec.new()
    out

pub fn sema_new_vec_i32 -> Vec[i32]:
    let out: Vec[i32] = Vec.new()
    out

pub fn sema_owned_text(text: &str) -> str:
    if text.len() == 0:
        return ""
    with_str_clone_ref(text)

pub fn sema_clone_str_vec(values: &Vec[str]) -> Vec[str]:
    let out = sema_new_vec_str()
    for i in 0..values.len() as i32:
        out.push(sema_owned_text(values[i]))
    out

pub fn sema_clone_i32_vec(values: &Vec[i32]) -> Vec[i32]:
    let out: Vec[i32] = Vec.new()
    for i in 0..values.len() as i32:
        out.push(values[i])
    out

// Deep-clone a HashMap[str, str] so the destination owns independent backing
// arrays and string payloads. A plain `dst = src.field` only shallow-copies the
// map header, leaving both maps pointing at one buffer — two owners that
// double-free at teardown (Zcu.c_import_omitted_symbols aliased into the round's
// Sema was exactly this bug). Mirrors sema_clone_str_vec's owned-text policy.
pub fn sema_clone_str_str_hashmap(src: &HashMap[str, str]) -> HashMap[str, str]:
    var out: HashMap[str, str] = HashMap.new()
    for (k, v) in src: out.insert(sema_owned_text(k), sema_owned_text(v))
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

pub fn sema_pair_key(a: i32, b: i32) -> i64:
    (a as i64) * 4294967296 + (b as i64)

fn sema_exact_type_hash(kind: i32, d0: i32, d1: i32, d2: i32) -> i64:
    var h: u64 = 14695981039346656037
    h = (h ^ kind as u64) *% 1099511628211
    h = (h ^ d0 as u64) *% 1099511628211
    h = (h ^ d1 as u64) *% 1099511628211
    ((h ^ d2 as u64) *% 1099511628211) as i64

fn sema_pair_hi(key: i64): (key / 4294967296) as i32
fn sema_pair_lo(key: i64): (key % 4294967296) as i32

// Effect-provenance packing (docs/spec/toolchain/deep-debugging-tools.md, explain:effect).
// Key = (sig, pi, bit_idx) with pi < 2^16, bit_idx < 2^8; value = (kind, a, b)
// with a, b < 2^28. These fns are the only place the field widths appear;
// encode and decode both live here so they cannot drift apart.
pub fn effect_prov_key(sig: i32, pi: i32, bit_idx: i32) -> i64:
    (sig as i64) * 16777216 + (pi as i64) * 256 + bit_idx as i64

fn effect_prov_val(kind: i64, a: i32, b: i32) -> i64:
    kind * 72057594037927936 + (a as i64) * 268435456 + b as i64

pub fn effect_prov_val_kind(v: i64): v / 72057594037927936
pub fn effect_prov_val_a(v: i64): ((v / 268435456) % 268435456) as i32
pub fn effect_prov_val_b(v: i64): (v % 268435456) as i32

impl Sema:
    mut fn copy_module_graph_from(source: &Sema):
        let global_paths = sema_new_vec_str()
        for mi in 0..source.module_paths.len() as i32:
            let source_path = source.module_paths[mi]
            if source.global_visible_module_paths.contains(source_path):
                global_paths.push(sema_owned_text(source_path))
        self.copy_module_graph_parts(&source.module_paths, &source.module_import_starts, &source.module_import_counts, &source.module_import_targets, &source.module_import_paths, &source.module_import_selected, &source.module_import_offsets, &global_paths)
        self.copy_import_namespaces(source)

    // D70: std.math, whose transcendental functions are builtins (§17.6a).
    fn module_path_is_std_math(path: &str) -> bool: sema_std_module_dotted(path) == "std.math"

    // D70: the import namespaces of `source`'s module graph.
    mut fn copy_import_namespaces(source: &Sema):
        self.ns_modules = sema_clone_i32_vec(&source.ns_modules)
        self.ns_names = sema_clone_str_vec(&source.ns_names)
        self.ns_fulls = sema_clone_str_vec(&source.ns_fulls)
        self.ns_targets = sema_clone_i32_vec(&source.ns_targets)
        self.ns_offsets = sema_clone_i32_vec(&source.ns_offsets)

    mut fn copy_module_graph_parts(src_module_paths: &Vec[str], src_module_import_starts: &Vec[i32], src_module_import_counts: &Vec[i32], src_module_import_targets: &Vec[i32], src_module_import_paths: &Vec[str], src_module_import_selected: &Vec[str], src_module_import_offsets: &Vec[i32], global_paths: &Vec[str]):
        self.module_paths = sema_new_vec_str()
        self.module_import_starts = sema_new_vec_i32()
        self.module_import_counts = sema_new_vec_i32()
        self.module_import_targets = sema_new_vec_i32()
        self.module_import_paths = sema_new_vec_str()
        self.module_import_selected = sema_new_vec_str()
        self.module_import_offsets = sema_new_vec_i32()
        self.module_index_by_path = sema_new_map_str_i32()
        self.global_visible_module_paths = sema_new_map_str_i32()
        self.module_visibility_cache = sema_new_map_str_i32()

        for mi in 0..src_module_paths.len() as i32:
            let source_path = src_module_paths[mi]
            self.module_paths.push(sema_owned_text(source_path))
            self.module_index_by_path.insert(sema_owned_text(source_path), mi)

        for gi in 0..global_paths.len() as i32:
            self.global_visible_module_paths.insert(sema_owned_text(global_paths[gi]), 1)

        for i in 0..src_module_import_starts.len() as i32:
            self.module_import_starts.push(src_module_import_starts[i])
        for i in 0..src_module_import_counts.len() as i32:
            self.module_import_counts.push(src_module_import_counts[i])
        for i in 0..src_module_import_targets.len() as i32:
            self.module_import_targets.push(src_module_import_targets[i])
        for i in 0..src_module_import_paths.len() as i32:
            self.module_import_paths.push(sema_owned_text(src_module_import_paths[i]))
        for i in 0..src_module_import_selected.len() as i32:
            self.module_import_selected.push(sema_owned_text(src_module_import_selected[i]))
        for i in 0..src_module_import_offsets.len() as i32:
            self.module_import_offsets.push(src_module_import_offsets[i])
        self.record_engine_corpora()

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
        va_start: 0,
        va_arg_method: 0,
        copy_trait: 0,
        clone_trait: 0,
        send_trait: 0,
        sync_trait: 0,
        scoped_send_trait: 0,
        deref_trait: 0,
        deref_method: 0,
        drop: 0,
        display_trait: 0,
        debug_trait: 0,
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
        keys: 0,
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
        zeroed: 0,
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
    let extern_decl_sites = sema_new_map_str_i32()
    let extern_var_texts = sema_new_map_str_i32()
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
    let generator_fn_run_syms = sema_new_map_i32_i32()
    let generator_fn_each_syms = sema_new_map_i32_i32()
    let generator_fn_receiver_views = sema_new_map_i32_i32()
    let generator_mir_only_fns = sema_new_map_i32_i32()
    let generator_state_yield_types = sema_new_map_i32_i32()
    let for_carrier_matches = sema_new_map_i32_i32()
    let gen_for_elem_types = sema_new_map_i32_i32()
    let gen_for_body_types = sema_new_map_i32_i32()
    let gen_for_each_syms = sema_new_map_i32_i32()
    let gen_for_each_sigs = sema_new_map_i32_i32()
    let gen_for_each_monos = sema_new_map_i32_i32()
    let for_elem_types = sema_new_map_i32_i32()
    let for_iter_fn_syms = sema_new_map_i32_i32()
    let for_iter_sigs = sema_new_map_i32_i32()
    let for_iter_monos = sema_new_map_i32_i32()
    let for_iter_types = sema_new_map_i32_i32()
    let for_iter_next_fns = sema_new_map_i32_i32()
    let mutable_global_syms = sema_new_map_i32_i32()
    let stable_global_syms = sema_new_map_i32_i32()
    let global_value_decl_kinds = sema_new_map_i32_i32()
    let interface_global_index = sema_new_map_i32_i32()
    let interface_global_paths = sema_new_map_i32_str()
    let interface_global_alt_syms = sema_new_vec_i32()
    let interface_global_alt_binds = sema_new_vec_i32()
    let interface_global_alt_paths = sema_new_vec_str()
    let decl_is_iface = sema_new_vec_i32()
    let decl_iface_demanded = sema_new_vec_i32()
    let iface_mentioned = sema_new_map_i32_i32()
    let global_value_decl_paths = sema_new_map_i32_str()
    let global_value_decl_bindings = sema_new_map_i32_i32()
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
    let liveness_byte_cache = sema_new_map_i32_i32()
    let typed_expr_types = sema_new_map_i32_i32()
    let typed_binding_types = sema_new_map_i32_i32()
    let call_callable_types = sema_new_map_i32_i32()
    let fn_callable_values = sema_new_map_i32_i32()
    let view_projection_exprs = sema_new_map_i32_i32()
    let join_field_view_arms = sema_new_map_i32_i32()
    let drop_consumed_binding_values = sema_new_map_i32_i32()
    let auto_ref_binding_values = sema_new_map_i32_i32()
    let auto_ref_payload_args = sema_new_map_i32_i32()
    let ceremony_sites = sema_new_map_i32_i32()
    let typed_binding_names = sema_new_map_i32_i32()
    let typed_binding_muts = sema_new_map_i32_i32()
    let ephemeral_task_binding_nodes = sema_new_map_i32_i32()
    let typed_dump_seen_nodes = sema_new_map_i32_i32()
    let generic_specialization_cache = sema_new_map_str_i32()
    let specialization_source_paths: HashMap[i32, str] = HashMap.new()
    let generic_inst_cache = sema_new_map_i64_i32()
    let layout_size_cache: HashMap[i32, i64] = HashMap.new()
    let layout_align_cache: HashMap[i32, i64] = HashMap.new()
    let layout_field_offset_cache: HashMap[i64, i64] = HashMap.new()
    let is_copy_cache = sema_new_map_i32_i32()
    let needs_drop_result_cache = sema_new_map_i32_i32()
    let unwrapped_type_cache = sema_new_map_i32_i32()
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
        impl_decl_target_types: sema_new_map_i32_i32(),
        cycle_dep_syms: Vec.new(),
        cycle_dep_nodes: Vec.new(),
        pretty_symbol_names,
        sig_names: Vec.new(),
        sig_text_index: sema_new_map_str_i32(),
        sig_text_prev: Vec.new(),
        sig_type_ids: Vec.new(),
        sig_ret_types: Vec.new(),
        sig_param_starts: Vec.new(),
        sig_param_counts: Vec.new(),
        sig_variadic: Vec.new(),
        sig_params: Vec.new(),
        sig_lookup,
        extern_decl_sigs: sema_new_map_i32_i32(),
        sig_param_effects: Vec.new(),
        sig_param_direct_effects: Vec.new(),
        sig_param_view_origins: Vec.new(),
        sig_param_view_through: Vec.new(),
        sig_param_invoke_many: Vec.new(),
        fn_param_invocations: sema_new_map_i32_i32(),
        fn_param_many_nodes: sema_new_map_i32_i32(),
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
        global_value_ident_nodes: HashMap.new(),
        const_global_syms: HashMap.new(),
        untyped_const_decls: HashMap.new(),
        untyped_const_alt_decls: Vec.new(),
        untyped_const_uses: HashMap.new(),
        store_follows_operands: 0,
        collect_field_demands: 0,
        inferred_field_nodes: Vec.new(),
        inferred_field_aliases: Vec.new(),
        inferred_field_paths: Vec.new(),
        field_demand_fields: Vec.new(),
        field_demand_types: Vec.new(),
        field_demand_uses: Vec.new(),
        field_decisions: Vec.new(),
        literal_demands: Vec.new(),
        fn_literal_lets: Vec.new(),
        literal_watermark: 0,
        literal_decisions: Vec.new(),
        field_last_use: HashMap.new(),
        effect_prov: HashMap.new(),
        effect_note_origin_node: 0,
        move_site_node: 0,
        extern_fn_names,
        extern_decl_sites,
        extern_var_texts,
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
        disc_value_starts: sema_new_map_i32_i32(),
        disc_value_list: Vec.new(),
        disc_has_payload,
        bitpacked_types: sema_new_map_i32_i32(),
        packed_types: sema_new_map_i32_i32(),
        packed_caps: sema_new_map_i32_i32(),
        repr_c_types: sema_new_map_i32_i32(),
        unsafe_fn_type_set: sema_new_map_i32_i32(),
        variadic_fn_type_set: sema_new_map_i32_i32(),
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
        pub_field_keys: HashSet[i64].new(),
        zeroed_call_nodes: HashSet[i32].new(),
        comptime_callable_memo: HashMap.new(),
        comptime_callable_chain: HashMap.new(),
        comptime_callable_visiting: HashSet[i32].new(),
        value_to_option_nodes: HashMap.new(),
        operator_operand_nodes: HashSet.new(),
        type_tid_is_std: HashMap.new(),
        generic_inst_templates: HashMap.new(),
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
        cast_modes: sema_new_map_i32_i32(),
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
        generator_fn_run_syms,
        generator_fn_each_syms,
        generator_fn_receiver_views,
        generator_mir_only_fns,
        generator_state_yield_types,
        for_carrier_matches,
        gen_for_elem_types,
        gen_for_body_types,
        gen_for_each_syms,
        gen_for_each_sigs,
        gen_for_each_monos,
        for_elem_types,
        for_iter_fn_syms,
        for_iter_sigs,
        for_iter_monos,
        for_iter_types,
        for_iter_next_fns,
        mutable_global_syms,
        stable_global_syms,
        global_value_decl_kinds,
        interface_global_index,
        interface_global_paths,
        interface_global_alt_syms,
        interface_global_alt_binds,
        interface_global_alt_paths,
        decl_is_iface,
        decl_iface_demanded,
        iface_mentioned,
        interface_eager: 0,
        global_value_decl_paths,
        global_value_decl_bindings,
        shadowed_global_syms: Vec.new(),
        shadowed_global_indices: Vec.new(),
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
        global_write_records: Vec.new(),
        global_calls: Vec.new(),
        global_call_targets: Vec.new(),
        global_call_bindings: Vec.new(),
        global_view_call_checks: Vec.new(),
        current_effect_body: -1,
        fn_value_ident_sigs: sema_new_map_i32_i32(),
        global_dispatchers_expanded: 0,
        global_drop_impl_targets: Vec.new(),
        global_drop_impl_contexts: Vec.new(),
        declared_write_starts: sema_new_map_i32_i32(),
        declared_write_syms_flat: Vec.new(),
        ret_global_origin_heads: sema_new_map_i32_i32(),
        ret_global_origin_entries: Vec.new(),
        declared_from_starts: sema_new_map_i32_i32(),
        declared_from_flat: Vec.new(),
        ret_origin_placeholder_sigs: sema_new_map_i32_i32(),
        ret_origin_placeholder_syms: sema_new_map_i32_i32(),
        ret_global_origin_sigs: Vec.new(),
        ret_view_placeholder_writes: Vec.new(),
        ret_view_placeholder_diags: Vec.new(),
        declared_from_checks: Vec.new(),
        global_dispatchers: Vec.new(),
        global_dispatcher_heads: sema_new_map_i32_i32(),
        global_dispatcher_next: Vec.new(),
        global_callable_values: Vec.new(),
        global_consumed_args: sema_new_map_i32_i32(),
        current_fn_bind_start: 0,
        global_user_drop_types: sema_new_map_i32_i32(),
        dyn_consuming_calls: sema_new_map_i32_i32(),
        dyn_downcast_binding_types: sema_new_map_i32_i32(),
        dyn_downcast_binding_syms: sema_new_map_i32_i32(),
        exhaustive_matches: sema_new_map_i32_i32(),
        syms: sema_builtin_symbols_zero(),
        method_impl_nodes,
        method_decl_impl_nodes,
        method_decl_origins,
        method_has_inherent,
        method_symbol_flags,
        method_lookup,
        drop_method_cache,
        liveness_byte_cache,
        copy_visit_stack: HashSet.new(),
        needs_drop_visit: HashSet.new(),
        current_drop_type_sym: 0,
        pattern_subject_node: 0,
        pattern_bind_mut: 0,
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
        field_move_diag_nodes: sema_new_map_i32_i32(),
        optional_chain_observing_nodes: sema_new_map_i32_i32(),
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
        discard_lets: sema_new_map_i32_i32(),
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
        break_target_nodes: sema_new_map_i32_i32(),
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
        live_block_starts: Vec.new(),
        live_block_counts: Vec.new(),
        live_block_indexes: Vec.new(),
        live_block_tails: Vec.new(),
        live_block_depths: Vec.new(),
        live_loop_nodes: Vec.new(),
        live_loop_depths: Vec.new(),
        live_loop_body_depths: Vec.new(),
        live_block_floor: 0,
        live_loop_floor: 0,
        live_floor_saved: Vec.new(),
        capture_field_syms: Vec.new(),
        capture_field_kinds: Vec.new(),
        call_resolved_arg_starts: sema_new_map_i32_i32(),
        call_resolved_arg_counts: sema_new_map_i32_i32(),
        call_resolved_args_data: Vec.new(),
        call_resolved_default_arg_keys: sema_new_map_i64_i32(),
        resolved_call_sigs: sema_new_map_i32_i32(),
        resolved_call_mono_syms: sema_new_map_i32_i32(),
        math_builtin_calls: sema_new_map_i32_i32(),
        vector_ops: sema_new_map_i32_i32(),
        vector_swizzles: sema_new_map_i32_str(),
        vector_splats: sema_new_map_i32_i32(),
        vector_conversions: sema_new_map_i32_i32(),
        va_start_calls: sema_new_map_i32_i32(),
        va_arg_calls: sema_new_map_i32_i32(),
        va_start_binding_value: 0,
        iter_next_sigs: sema_new_map_i32_i32(),
        iter_next_mono_syms: sema_new_map_i32_i32(),
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
        name_use_nodes: sema_new_vec_i32(),
        name_use_kinds: sema_new_vec_str(),
        name_use_paths: sema_new_vec_str(),
        name_use_names: sema_new_vec_str(),
        name_use_from: sema_new_vec_str(),
        comptime_selected_branches: sema_new_map_i32_i32(),
        pipeline_method_calls: sema_new_map_i32_i32(),
        pipeline_call_return_types: sema_new_map_i32_i32(),
        pipeline_carrier_kinds: sema_new_map_i32_i32(),
        operator_method_calls: sema_new_map_i32_i32(),
        operator_method_reversed: sema_new_map_i32_i32(),
        operator_method_derived: sema_new_map_i32_i32(),
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
        debug_fmt_index: sema_new_map_i32_i32(),
        debug_fmt_tids: Vec.new(),
        debug_fmt_kinds: Vec.new(),
        debug_fmt_fns: Vec.new(),
        debug_fmt_sigs: Vec.new(),
        debug_fmt_monos: Vec.new(),
        debug_fmt_aux_fns: Vec.new(),
        debug_fmt_aux_sigs: Vec.new(),
        debug_fmt_aux_monos: Vec.new(),
        debug_fmt_synth_syms: sema_new_map_i32_i32(),
        debug_fmt_probe_visiting: sema_new_map_i32_i32(),
        autoderef_step_starts: sema_new_map_i32_i32(),
        autoderef_step_counts: sema_new_map_i32_i32(),
        slice_coerce_args: sema_new_map_i32_i32(),
        collection_literal_hints: sema_new_map_i32_i32(),
        array_fill_counts: sema_new_map_i32_i32(),
        borrow_pointee_join_node: 0,
        contextual_copy_adjustment_indices: sema_new_map_i64_i32(),
        contextual_copy_adjustments: Vec.new(),
        contextual_join_decision_indices: sema_new_map_i64_i32(),
        contextual_join_decisions: Vec.new(),
        contextual_join_arm_nodes: Vec.new(),
        contextual_join_arm_origin_nodes: Vec.new(),
        facade_resource_index: sema_new_map_i32_i32(),
        facade_resources: Vec.new(),
        foreign_contract_index: sema_new_map_i32_i32(),
        foreign_contracts: Vec.new(),
        facade_domains: sema_new_map_i32_i32(),
        facade_domain_list: Vec.new(),
        facade_domain_index: sema_new_map_i32_i32(),
        facade_domain_origin_index: sema_new_map_i32_i32(),
        facade_call_effects: Vec.new(),
        facade_call_effect_index: sema_new_map_i32_i32(),
        facade_touch_nodes: sema_new_map_i32_i32(),
        facade_touch_hit_params: sema_new_map_i32_i32(),
        current_facade_sym: 0,
        current_facade_node: 0,
        facade_presented_syms: sema_new_map_i32_i32(),
        facade_bridge_of: HashMap.new(),
        facade_presented_calls: sema_new_map_i32_i32(),
        call_value_conversions: sema_new_map_i32_i32(),
        method_call_fields: sema_new_map_i32_i32(),
        precondition_form_calls: sema_new_map_i32_i32(),
        facade_variadic_ops: HashMap.new(),
        facade_variadic_method_names: sema_new_map_i32_i32(),
        facade_layout_nodes: Vec.new(),
        facade_layout_tids: Vec.new(),
        facade_layout_containers: Vec.new(),
        facade_layout_files: Vec.new(),
        facade_layout_msgs: Vec.new(),
        facade_convention_nodes: Vec.new(),
        facade_callback_methods: Vec.new(),
        facade_callback_method_index: sema_new_map_i32_i32(),
        facade_c_invoked_userdata: sema_new_map_i32_i32(),
        facade_pair_ops: Vec.new(),
        facade_pair_op_by_sig: sema_new_map_i32_i32(),
        facade_pair_setter_contract: sema_new_map_i32_i32(),
        facade_pair_setter_case: sema_new_map_i32_i32(),
        facade_pair_resources: sema_new_map_i32_i32(),
        facade_pair_retainers: sema_new_map_i32_i32(),
        contextual_join_arm_types: Vec.new(),
        contextual_join_arm_kinds: Vec.new(),
        contextual_join_arm_roles: Vec.new(),
        contextual_join_origin_deps: Vec.new(),
        in_param_type_position: 0,
        autoderef_step_fns: Vec.new(),
        autoderef_step_tys: Vec.new(),
        pattern_value_syms: sema_new_map_i32_i32(),
        consuming_pattern_subjects: sema_new_map_i32_i32(),
        regex_capture_counts: sema_new_map_i32_i32(),
        regex_capture_name_starts: sema_new_map_i32_i32(),
        regex_capture_name_counts: sema_new_map_i32_i32(),
        regex_capture_name_syms: Vec.new(),
        typed_expr_types,
        typed_binding_types,
        call_callable_types,
        call_callee_kinds: sema_new_map_i32_i32(),
        type_ctor_call_syms: sema_new_map_i32_i32(),
        embed_file_contents: HashMap.new(),
        method_owner_keys: sema_new_map_i32_i32(),
        call_builtins: sema_new_map_i32_i32(),
        builtin_sig_index: HashMap.new(),
        builtin_sig_modes: sema_new_vec_str(),
        builtin_sig_owner_alias: sema_new_map_i32_i32(),
        builtin_call_sigs: sema_new_map_i32_i32(),
        offsetof_field_indices: sema_new_map_i32_i32(),
        offsetof_owner_types: sema_new_map_i32_i32(),
        method_intrinsics: sema_new_map_i64_i32(),
        method_lowerings: sema_new_map_i64_i32(),
        method_name_syms: sema_new_map_i32_i32(),
        extern_var_type_ids: sema_new_map_i32_i32(),
        impl_trait_arg_type_ids: sema_new_map_i32_i32(),

        c_promoted_arg_starts: sema_new_map_i32_i32(),
        c_promoted_arg_data: Vec.new(),
        unprototyped_sigs: sema_new_map_i32_i32(),

        fn_callable_values,

        view_projection_exprs,
        join_field_view_arms,
        drop_consumed_binding_values,
        auto_ref_binding_values,
        auto_ref_payload_args,
        ceremony_sites,
        facade_userdata_ctor: 0,
        typed_binding_names,
        typed_binding_muts,
        ephemeral_task_binding_nodes,
        assign_target_revive_sym: 0,
        suspend_visiting: sema_new_map_i32_i32(),
        suspend_site_depth: 0,
        suspend_site_record_depth: -1,
        suspend_site_node: 0,
        suspend_fact_nodes: sema_new_map_i32_i32(),
        suspend_facts_settling: 0,
        callable_ident_decls: sema_new_map_i32_i32(),
        callable_param_idents: sema_new_map_i32_i32(),
        callable_opaque_idents: sema_new_map_i32_i32(),
        callable_let_decls: sema_new_map_i32_i32(),
        callable_value_heads: sema_new_map_i32_i32(),
        callable_value_nodes: Vec.new(),
        callable_value_next: Vec.new(),
        callable_value_visiting: sema_new_map_i32_i32(),
        dyn_suspend_methods: HashMap.new(),
        suspend_call_sites: sema_new_map_i32_i32(),
        generator_state_fns: sema_new_map_i32_i32(),
        generator_local_view_yields: sema_new_map_i32_i32(),
        generator_local_view_origins: sema_new_map_i32_i32(),
        gen_pull_nodes: Vec.new(),
        gen_pull_view_nodes: sema_new_map_i32_i32(),
        receiver_arg_call_nodes: sema_new_map_i32_i32(),
        gen_pull_fns: Vec.new(),
        eph_task_visiting: sema_new_map_i32_i32(),
        typed_dump_seen_nodes,
        typed_dump_visit_budget: 0,
        generic_subst_param_syms: Vec.new(),
        generic_subst_type_ids: Vec.new(),
        generic_specialization_cache,
        specialization_source_paths,
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
        loop_iterable_node: 0,
        concrete_drop_sigs: sema_new_map_i32_i32(),
        concrete_drop_mono_syms: sema_new_map_i32_i32(),
        concrete_eq_sigs: sema_new_map_i32_i32(),
        concrete_eq_mono_syms: sema_new_map_i32_i32(),
        concrete_cmp_sigs: sema_new_map_i32_i32(),
        concrete_cmp_mono_syms: sema_new_map_i32_i32(),
        concrete_key_sigs: sema_new_map_i32_i32(),
        view_fact_fns: Vec.new(),
        view_fact_syms: Vec.new(),
        view_fact_nodes: Vec.new(),
        view_fact_files: Vec.new(),
        view_fact_events: Vec.new(),
        view_fact_masks: Vec.new(),
        view_fact_storage: Vec.new(),
        view_fact_dep_starts: Vec.new(),
        view_fact_dep_counts: Vec.new(),
        view_fact_deps: Vec.new(),
        param_view_fact_sigs: Vec.new(),
        param_view_fact_params: Vec.new(),
        param_view_fact_storage: Vec.new(),
        param_view_fact_nodes: Vec.new(),
        param_view_fact_files: Vec.new(),
        concrete_key_mono_syms: sema_new_map_i32_i32(),
        generic_inst_cache,
        layout_size_cache,
        layout_align_cache,
        layout_field_offset_cache,
        is_copy_cache,
        needs_drop_result_cache,
        unwrapped_type_cache,
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
        current_fn_param_storage_origins: Vec.new(),
        current_fn_param_view_nodes: Vec.new(),
        current_fn_sig_idx: -1,
        current_fn_variadic: 0,
        recording_propagated_effect: 0,
        closure_capture_summary_starts: sema_new_map_i32_i32(),
        closure_capture_summary_counts: sema_new_map_i32_i32(),
        closure_capture_summary_data: Vec.new(),
        binding_closure_nodes: sema_new_map_i32_i32(),
        callable_clone_nodes: sema_new_map_i32_i32(),
        deferred_closure_arg_checks: Vec.new(),
        deferred_callable_forwards: Vec.new(),
        binding_view_dep_data: Vec.new(),
        view_bound_let_nodes: sema_new_map_i32_i32(),
        expr_view_param_origins: sema_new_map_i32_i32(),
        expr_view_storage_origins: sema_new_map_i32_i32(),
        expr_view_into_temporary: sema_new_map_i32_i32(),
        expr_view_dep_starts: sema_new_map_i32_i32(),
        expr_view_dep_counts: sema_new_map_i32_i32(),
        expr_view_dep_data: Vec.new(),
        alloc_site_nodes: Vec.new(),
        alloc_site_kinds: Vec.new(),
        alloc_site_fn_syms: Vec.new(),
        alloc_site_elided: Vec.new(),
        current_no_alloc_depth: 0,
        current_fn_may_alloc: 0,
        alloc_callee_calls: Vec.new(),
        alloc_callee_calls_resolved: 0,
        current_fn_symbol: 0,
        current_specialization_sym: 0,
        specialization_type_args: sema_new_map_i64_i32(),
        index_element_types: sema_new_map_i64_i32(),
        index_base_types: sema_new_map_i64_i32(),
        field_access_decl_indexes: sema_new_map_i64_i32(),
        field_access_types: sema_new_map_i64_i32(),
        field_access_owners: sema_new_map_i64_i32(),
        source_text: "",
        tracked_input_root: "",
        tracked_input_paths: sema_new_vec_str(),
        current_return_type: 0,
        current_gen_yield_type: 0,
        has_gen_yield_type: 0,
        in_pipeline_rhs: 0,
        match_in_stmt_pos: 0,
        infer_tail_node: 0,
        infer_tail_is_closure: 0,
        infer_tail_join: 0,
        body_tail_block: 0,
        body_tail_holder: 0,
        body_tail_discards: true,
        body_tail_is_statement: false,
        discarded_tails: sema_new_map_i32_i32(),
        tail_read_assigns: sema_new_map_i32_i32(),
        facade_declared_effect_sigs: sema_new_map_i32_i32(),
        facade_declared_through: sema_new_map_i64_i32(),
        assign_view_targets: sema_new_map_i32_i32(),
        display_join_node: 0,
        join_assign_arms_as_views: 0,
        body_typed_sigs: sema_new_map_i32_i32(),
        body_decl_by_fn: sema_new_map_i32_i32(),
        untyped_callee_calls: Vec.new(),
        discarded_stmt_node: 0,
        body_order_state: Vec.new(),
        body_order_lower: Vec.new(),
        receiver_field_owner: 0,
        receiver_field_shadowed: sema_new_map_i32_i32(),
        self_name_cache_path: "",
        self_name_cache: "",
        builtins_intrinsic_nodes: sema_new_map_i32_i32(),
        body_typed_decls: sema_new_map_i32_i32(),
        body_typed_next: Vec.new(),
        comprehension_chain_roots: sema_new_map_i32_i32(),
        comprehension_root_carriers: sema_new_map_i32_i32(),
        comprehension_root_err_types: sema_new_map_i32_i32(),
        comprehension_failure_rewraps: sema_new_map_i32_i32(),
        prechecked_match_subject: 0,
        prechecked_match_subject_type: 0,
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
        in_negated_literal_context: 0,
        unsafe_scope_used: Vec.new(),
        unsafe_scope_nodes: Vec.new(),
        unsafe_global_scope_reads: Vec.new(),
        deferred_unsafe_global_scopes: Vec.new(),
        unsafe_global_scopes_resolved: 0,
        break_value_type: 0,
        has_break_value_type: 0,
        loop_depth: 0,
        for_view_binding_syms: Vec.new(),
        for_view_binding_depths: Vec.new(),
        for_view_binding_gen_loops: Vec.new(),
        gen_call_view_place_starts: sema_new_map_i32_i32(),
        gen_call_view_place_counts: sema_new_map_i32_i32(),
        gen_call_view_place_nodes: Vec.new(),
        stmt_pos_depth: 0,
        current_statement_expr_root: 0,
        current_value_expr_root: 0,
        closure_direct_arg_depth: 0,
        closure_body_depth: 0,
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
        ty_usize: 0, ty_isize: 0, ty_c_va_list: 0, ty_const_i8_ptr: 0,
        ty_field_info: 0, ty_variant_info: 0,
        decl_source_paths: sema_new_vec_str(),
        package_keys: HashMap[str, str].new(),
        decl_source_file_ids: Vec.new(),
        module_path_by_file: HashMap.new(),
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
        module_import_selected: sema_new_vec_str(),
        module_import_offsets: Vec.new(),
        ns_modules: Vec.new(),
        ns_names: sema_new_vec_str(),
        ns_fulls: sema_new_vec_str(),
        ns_targets: Vec.new(),
        ns_offsets: Vec.new(),
        module_index_by_path: sema_new_map_str_i32(),
        bundle_corpus: "",
        global_visible_module_paths: sema_new_map_str_i32(),
        engine_module_corpus: sema_new_map_str_i32(),
        corpus_private_modules: sema_new_map_str_i32(),
        module_visibility_cache: sema_new_map_str_i32(),
        named_type_candidate_syms: Vec.new(),
        named_type_candidate_tids: Vec.new(),
        named_type_candidate_paths: sema_new_vec_str(),
        named_type_candidate_pub: Vec.new(),
        named_type_candidate_ci: Vec.new(),
        named_type_candidate_heads: sema_new_map_i32_i32(),
        named_type_candidate_next: Vec.new(),
        colliding_type_names: sema_new_map_i32_i32(),
        type_identity_syms: sema_new_map_i64_i32(),
        type_identity_tids: sema_new_map_i32_i32(),
        type_identity_names: sema_new_map_i32_i32(),
        impl_identity_traits: sema_new_map_i64_i32(),
        decl_visibility_syms: Vec.new(),
        decl_visibility_paths: sema_new_vec_str(),
        decl_visibility_pub: Vec.new(),
        decl_visibility_nodes: Vec.new(),
        decl_visibility_index: sema_new_map_i32_i32(),
        visibility_explain_on: 0,
        visibility_explain_log: sema_new_vec_str(),
        comptime_truthy_error: "",
        decl_visibility_prev: Vec.new(),
        decl_visibility_node_index: sema_new_map_i32_i32(),
        displaced_fn_index: sema_new_map_i32_i32(),
        displaced_fn_record_of: sema_new_map_i32_i32(),
        displaced_fn_syms: Vec.new(),
        displaced_fn_paths: sema_new_vec_str(),
        displaced_fn_pub: Vec.new(),
        displaced_fn_prev: Vec.new(),
        displaced_global_syms: sema_new_map_i32_i32(),
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
            if text[i] == 40:
                paren = i
                break
        if paren <= 0:
            return
        let fn_name = text.slice(0, paren as i64)
        var idx = 0
        var got = 0
        var j = paren + 1
        while j < n:
            let c = text[j]
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
    s.ty_c_va_list = s.add_type(TypeKind.TY_VA_LIST, 0, 0, 0)
    s.ty_const_i8_ptr = s.add_type(TypeKind.TY_PTR, s.ty_i8, 0, 0)
    let cstr_field_names: Vec[str] = Vec.new()
    cstr_field_names.push("ptr")
    cstr_field_names.push("len")
    let cstr_field_types: Vec[i32] = Vec.new()
    cstr_field_types.push(s.ty_const_i8_ptr as i32)
    cstr_field_types.push(s.ty_i64 as i32)
    s.ty_cstr = s.register_builtin_struct_type("CStr", cstr_field_names, cstr_field_types, 2) as TypeId
    s.ty_cstr_view = s.add_type(TypeKind.TY_REF, s.ty_cstr, 0, 0)
    // A `CStr` is a view of NUL-terminated bytes something else owns — a C
    // string literal's static storage, a `CString`, a modeled resource or a
    // foreign-state domain (D51 §41, spec §16.2b.8) — never the owner, so
    // the value is ephemeral (§5): it takes the origins of what produced it,
    // cannot be stored past them, and a borrowed `CStr` a facade returns is
    // kept inside its origin's life by the ordinary view analysis.
    s.ephemeral_types.insert(s.pool_intern("CStr"), 1)

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
    s.register_prim("c_va_list", s.ty_c_va_list)
    s.init_builtin_reflection_types()
    s.register_vector_aliases()
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
        self.record_named_type_with_pub(sym, tid, 1, 0)

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
                self.named_type_candidate_syms[candidate_index],
                candidate_index,
            )

    // `decl_node` is the declaring type declaration, 0 for a builtin.
    mut fn record_named_type_with_pub(sym: i32, tid: i32, is_pub: i32, decl_node: i32) -> Unit:
        self.named_types.insert(sym, tid)
        // #1457: the declaration an identity symbol names, for the stages
        // that receive a method symbol and need its owner's type.
        if decl_node != 0 and self.colliding_type_names.contains(sym):
            let identity = self.type_identity_symbol(sym, self.current_module_path)
            if identity != sym:
                self.type_identity_tids.insert(identity, tid)
                self.type_identity_names.insert(identity, sym)
        self.index_named_type_candidate(sym, self.named_type_candidate_syms.len() as i32)
        self.named_type_candidate_syms.push(sym)
        self.named_type_candidate_tids.push(tid)
        let path = self.current_module_path.clone()
        self.named_type_candidate_paths.push(sema_owned_text(path))
        self.named_type_candidate_pub.push(is_pub)
        let di = if decl_node != 0: self.find_decl_index(decl_node) else: -1
        let from_c_import = di >= 0 and di < self.decl_is_c_import.len() as i32 and self.decl_is_c_import[di] != 0
        self.named_type_candidate_ci.push(if from_c_import: 1 else: 0)

    // The modules that write `use c_import(...)`, by path symbol. Registered
    // before declarations are collected: a c_import expansion's types are
    // resolved during collection (#1372). build_ci_scoping adds the rest of
    // the c_import scoping facts after collection.
    mut fn register_c_import_modules():
        for di in 0..self.ast.decl_count():
            if di < self.decl_source_paths.len() as i32 and self.ast.kind(self.ast.get_decl(di)) == NodeKind.NK_C_IMPORT:
                let path_sym = self.pool_intern(self.decl_source_paths[di])
                self.ci_modules.insert(path_sym, 1)

    fn current_module_uses_c_import() -> bool:
        if self.current_module_path.len() == 0:
            return false
        let path_sym = self.pool_lookup_symbol(self.current_module_path)
        path_sym != 0 and self.ci_modules.contains(path_sym)

    fn record_decl_visibility(sym: i32, node: i32, is_pub: i32) -> Unit:
        if sym == 0:
            return
        let record = self.decl_visibility_syms.len() as i32
        self.decl_visibility_syms.push(sym)
        let path = self.current_module_path.clone()
        self.decl_visibility_paths.push(sema_owned_text(path))
        self.decl_visibility_pub.push(is_pub)
        self.decl_visibility_nodes.push(node)
        // Indexed: a lookup walks this symbol's records newest-first, never
        // the whole table (it scanned every declaration per identifier).
        self.decl_visibility_prev.push(if self.decl_visibility_index.contains(sym): self.decl_visibility_index.get(sym).unwrap() else: -1)
        self.decl_visibility_index.insert(sym, record)
        if node != 0:
            self.decl_visibility_node_index.insert(node, record)

    // #1350: the frontend displaced this fn (or, #1703, this module value) to
    // `short$in$<module>` (frontend_displace_fn_decl) because another
    // module's declaration took the short name. Chain it under the short name
    // for resolve_displaced_fn_ident; diagnostics keep the short spelling.
    // False when `sym` is not a displaced identity.
    mut fn record_displaced_fn(sym: i32, is_pub: i32) -> bool:
        let name: str = with_str_clone_ref(self.pool_resolve(sym))
        let infix = name.index_of("$in$")
        if infix <= 0:
            return false
        let short_name = name.slice(0, infix)
        self.set_pretty_symbol(sym, short_name)
        let path = with_str_clone_ref(self.current_module_path)
        if self.displaced_fn_record_of.contains(sym):
            let existing: i32 = self.displaced_fn_record_of.get(sym).unwrap()
            self.displaced_fn_paths[existing] = sema_owned_text(path)
            self.displaced_fn_pub[existing] = is_pub
            return true
        let short_sym = self.pool_intern(short_name)
        let record = self.displaced_fn_syms.len() as i32
        self.displaced_fn_syms.push(sym)
        self.displaced_fn_paths.push(sema_owned_text(path))
        self.displaced_fn_pub.push(is_pub)
        self.displaced_fn_prev.push(if self.displaced_fn_index.contains(short_sym): self.displaced_fn_index.get(short_sym).unwrap() else: -1)
        self.displaced_fn_index.insert(short_sym, record)
        self.displaced_fn_record_of.insert(sym, record)
        true

    // #1350: a bare name some module's displaced fn declares binds, in order:
    // a lexical binding (untouched); the current module's own declaration;
    // the flat winner when it is visible here; else a displaced declaration
    // this module can see. The ident node is rewritten to the chosen
    // identity, so MIR, comptime and codegen read the declaration Sema
    // checked — never a short-name re-resolution.
    mut fn resolve_displaced_fn_ident(sym: i32, node: i32) -> i32:
        if sym == 0 or not self.displaced_fn_index.contains(sym):
            return sym
        // D70: a namespace access already names its declaration.
        if node > 0 and self.ast.is_namespace_bound(node as NodeId):
            return sym
        if self.name_has_displaced_global(sym):
            return self.resolve_displaced_global_ident(sym, node)
        if self.scope_lookup(sym) >= 0:
            return sym
        let head: i32 = self.displaced_fn_index.get(sym).unwrap()
        var chosen = 0
        // #1882: a c_import's displaced definition carries its importer's
        // path, but it is the importer's IMPORT (tier 3), not its own
        // declaration (tier 2): the module's own `fn twice` outranks the
        // header's `twice`, which its namespace still names (D70).
        var own_import = 0
        var i = head
        while i >= 0 and chosen == 0:
            if self.displaced_fn_paths[i] == self.current_module_path:
                if self.ci_syms.contains(self.displaced_fn_syms[i]):
                    if own_import == 0: own_import = self.displaced_fn_syms[i]
                else:
                    chosen = self.displaced_fn_syms[i]
            i = self.displaced_fn_prev[i]
        if chosen == 0 and own_import != 0:
            var own = if self.decl_visibility_index.contains(sym): self.decl_visibility_index.get(sym).unwrap() else: -1
            while own >= 0:
                if self.decl_visibility_paths[own] == self.current_module_path:
                    return sym
                own = self.decl_visibility_prev[own]
            chosen = own_import
        if chosen == 0:
            // §18.2 tier 3 (Eric's ruling, #1221/#993): of the fns the
            // current module's explicit imports provide, the import written
            // last shadows the others — `use a.helper` then `use b.helper`
            // calls b's, whatever order the flat merge kept.
            let cands: Vec[i32] = Vec.new()
            let cand_paths = sema_new_vec_str()
            let cand_pub: Vec[i32] = Vec.new()
            var r = if self.decl_visibility_index.contains(sym): self.decl_visibility_index.get(sym).unwrap() else: -1
            while r >= 0:
                // The current module's own fn keeps the short name (tier 2).
                if self.decl_visibility_paths[r] == self.current_module_path:
                    return sym
                cands.push(sym)
                cand_paths.push(sema_owned_text(self.decl_visibility_paths[r]))
                cand_pub.push(self.decl_visibility_pub[r])
                r = self.decl_visibility_prev[r]
            i = head
            while i >= 0:
                cands.push(self.displaced_fn_syms[i])
                cand_paths.push(sema_owned_text(self.displaced_fn_paths[i]))
                cand_pub.push(self.displaced_fn_pub[i])
                i = self.displaced_fn_prev[i]
            let imported = self.last_import_provider(sym, &cands, &cand_paths, &cand_pub)
            if imported >= 0:
                chosen = cands[imported]
                if chosen == sym:
                    return sym
        if chosen == 0:
            if self.decl_visibility_index.contains(sym) and self.symbol_visible_from_current(sym) != 0:
                return sym
            i = head
            while i >= 0 and chosen == 0:
                if self.decl_visible_from_current_gated(self.displaced_fn_paths[i], self.displaced_fn_pub[i], sym) != 0:
                    chosen = self.displaced_fn_syms[i]
                i = self.displaced_fn_prev[i]
        if chosen == 0:
            return sym
        if node != 0 and self.ast.kind(node) == NodeKind.NK_IDENT and self.ast.get_data0(node) == sym:
            self.ast.set_data0(node as NodeId, chosen)
        chosen

    fn name_has_displaced_global(short_sym: i32) -> bool:
        var i = if self.displaced_fn_index.contains(short_sym): self.displaced_fn_index.get(short_sym).unwrap() else: -1
        while i >= 0:
            if self.displaced_global_syms.contains(self.displaced_fn_syms[i]):
                return true
            i = self.displaced_fn_prev[i]
        false

    // #1703/#1221 (§18.2, §18.3): a bare name some module value was displaced
    // from (Zcu.displace_colliding_globals). The flat declaration keeps the
    // short name; each other one is `name$in$<module>`. A reference binds by
    // §18.2 precedence: a lexical binding (untouched); the current module's
    // own declaration (tier 2); the explicit imports that provide the name
    // (tier 3), where the import written last shadows the others (Eric's
    // ruling on #1221) — a `use c_import(...)` takes its place in that order,
    // `use m` provides m's public names, and `use m.X` / `use m.{X}` provides
    // X alone; else the one declaration the std fallback reaches (D29: two
    // std candidates there are an ambiguity). The ident is rewritten to the
    // chosen identity, as for a displaced fn.
    mut fn resolve_displaced_global_ident(sym: i32, node: i32) -> i32:
        let bound = self.scope_name_map.get(sym)
        if bound.is_some() and not self.binding_index_is_global(bound.unwrap(), sym):
            return sym
        if self.current_module_path.len() == 0:
            return sym
        let cands: Vec[i32] = Vec.new()
        let cand_paths = sema_new_vec_str()
        let cand_pub: Vec[i32] = Vec.new()
        let flat_path = self.global_value_decl_paths.get(sym)
        if bound.is_some() and flat_path.is_some():
            cands.push(sym)
            cand_paths.push(sema_owned_text(flat_path.unwrap()))
            cand_pub.push(self.decl_record_pub(sym, flat_path.unwrap()))
        var i = self.displaced_fn_index.get(sym).unwrap()
        while i >= 0:
            let dsym = self.displaced_fn_syms[i]
            if self.displaced_global_syms.contains(dsym):
                cands.push(dsym)
                cand_paths.push(sema_owned_text(self.displaced_fn_paths[i]))
                cand_pub.push(self.displaced_fn_pub[i])
            i = self.displaced_fn_prev[i]
        for ci in 0..cands.len() as i32:
            if cand_paths[ci] == self.current_module_path and not self.ci_syms.contains(cands[ci]):
                return self.bind_displaced_global_ident(sym, node, cands[ci])
        let imported = self.last_import_provider(sym, &cands, &cand_paths, &cand_pub)
        if imported >= 0:
            return self.bind_displaced_global_ident(sym, node, cands[imported])
        let fallback: Vec[i32] = Vec.new()
        for ci in 0..cands.len() as i32:
            if not self.ci_syms.contains(cands[ci]) and self.decl_visible_from_current_gated(cand_paths[ci], cand_pub[ci], sym) != 0:
                fallback.push(ci)
        if fallback.len() == 0:
            return sym
        if fallback.len() > 1:
            self.emit_ambiguous_fallback_use(with_str_clone_ref(self.pool_resolve(sym)), node, &cand_paths, &fallback)
        self.bind_displaced_global_ident(sym, node, cands[fallback[0]])

    // §18.2 tier 3 under Eric's #1221 ruling: of the candidates an explicit
    // import of the current module provides, the one whose import is written
    // last. -1 when no explicit import provides the name.
    fn last_import_provider(sym: i32, cands: &Vec[i32], paths: &Vec[str], pubs: &Vec[i32]) -> i32:
        let name: str = with_str_clone_ref(self.pool_resolve(sym))
        var best = -1
        var best_pos = -1
        for ci in 0..cands.len() as i32:
            let pos = self.import_position_of(cands[ci], paths[ci], pubs[ci], name)
            if pos > best_pos:
                best_pos = pos
                best = ci
        best

    // Where the current module's last explicit import providing `name` from
    // candidate `c` is written (its byte offset), or -1 when none does. A
    // c_import's declarations are provided by that `use c_import` of their
    // importing module (Zcu records its offset in decl_is_c_import).
    fn import_position_of(c: i32, path: &str, is_pub: i32, name: &str) -> i32:
        if self.ci_syms.contains(c):
            if path != self.current_module_path:
                return -1
            let decl = self.decl_node_of(c, path)
            let di = if decl != 0: self.find_decl_index(decl) else: -1
            if di < 0 or di >= self.decl_is_c_import.len() as i32 or self.decl_is_c_import[di] == 0:
                return -1
            return self.decl_is_c_import[di] - 1
        if path == self.current_module_path or self.decl_visible_from_current(path, is_pub) == 0:
            return -1
        self.current_import_position(path, name)

    // The offset of the current module's last `use` of the module at `path`
    // that provides `name` — a whole-module import, or a named import that
    // selects it — or -1. Direct edges only: imports are not transitive, and
    // the prelude edge is tier 4, not an explicit import.
    fn current_import_position(path: &str, name: &str) -> i32:
        let cur = self.module_index_by_path.get(with_str_clone_ref(self.current_module_path))
        let target = self.module_index_by_path.get(path)
        if not cur.is_some() or not target.is_some():
            return -1
        let from: i32 = cur.unwrap()
        let to: i32 = target.unwrap()
        if from < 0 or from >= self.module_import_starts.len() as i32:
            return -1
        var best = -1
        let start = self.module_import_starts[from]
        for ei in 0..self.module_import_counts[from]:
            let idx = start + ei
            if self.module_import_targets[idx] != to or idx >= self.module_import_offsets.len() as i32:
                continue
            let text = self.module_import_paths[idx]
            if text == "std.prelude" or text == "std.prelude_core" or text == "std.prelude_alloc":
                continue
            let selected = if idx < self.module_import_selected.len() as i32: self.module_import_selected[idx].clone() else: ""
            if (selected.len() == 0 or sema_selection_names(selected, name)) and self.module_import_offsets[idx] > best:
                best = self.module_import_offsets[idx]
        best

    mut fn bind_displaced_global_ident(sym: i32, node: i32, chosen: i32) -> i32:
        if chosen != sym and node != 0 and self.ast.kind(node) == NodeKind.NK_IDENT and self.ast.get_data0(node) == sym:
            self.ast.set_data0(node as NodeId, chosen)
        chosen

    // The public flag of `sym`'s declaration in the module at `path`.
    fn decl_record_pub(sym: i32, path: &str) -> i32:
        var i = if self.decl_visibility_index.contains(sym): self.decl_visibility_index.get(sym).unwrap() else: -1
        while i >= 0:
            if self.decl_visibility_paths[i] == path:
                return self.decl_visibility_pub[i]
            i = self.decl_visibility_prev[i]
        0

    // D29 (§18.2 tier 5): two standard-library candidates for one name, and
    // no import that decides it, is a hard ambiguity at the use; each
    // candidate is offered as the import that picks it.
    mut fn emit_ambiguous_fallback_use(name: &str, node: i32, paths: &Vec[str], fallback: &Vec[i32]):
        if self.suppress_errors != 0:
            return
        var listed = ""
        for fi in 0..fallback.len() as i32:
            let path = paths[fallback[fi]]
            let dotted = sema_std_module_dotted(path)
            let mod_name = if dotted.len() > 0: dotted else: path.clone()
            listed = listed ++ (if fi > 0: " | " else: "") ++ "use " ++ mod_name ++ "." ++ name
        self.emit_error("'" ++ name ++ "' is ambiguous: several standard-library modules provide it; candidates: " ++ listed, node)

    // The declaration node of `sym` in the module at `path`.
    fn decl_node_of(sym: i32, path: &str) -> i32:
        var i = if self.decl_visibility_index.contains(sym): self.decl_visibility_index.get(sym).unwrap() else: -1
        while i >= 0:
            if self.decl_visibility_paths[i] == path and self.decl_visibility_nodes[i] != 0:
                return self.decl_visibility_nodes[i]
            i = self.decl_visibility_prev[i]
        0

    // D100: a module path's package; a path the Zcu never saw is the
    // program's (std's when it is a std path).
    fn vis_note(text: &str):
        if self.visibility_explain_on != 0: self.visibility_explain_log.push(with_str_clone_ref(text))

    // `with analyze file.w 'explain:visible:<name>'` (#2249): every
    // declaration `name` could resolve to from the root module — values and
    // types — with its module, package, engine id, prelude-closure and
    // corpus-private marks, then the verdict and every rule and walk edge it
    // passed through. A hunt that was "toggle a rule and rebuild" is one run.
    pub mut fn explain_visibility(name: &str) -> str:
        let sym = self.pool_lookup_symbol(name)
        if sym == 0: return "explain:visible " ++ name ++ "\n  no declaration or use of that name anywhere in the compilation\n"
        var out = "explain:visible " ++ name ++ "\n"
        let saved_module = with_str_clone_ref(self.current_module_path)
        if self.module_paths.len() > 0: self.current_module_path = with_str_clone_ref(self.module_paths[0])
        out = out ++ "  from module " ++ self.current_module_path ++ " (package " ++ self.package_of(self.current_module_path) ++ ")\n"
        var candidates = 0
        var vi = if self.decl_visibility_index.contains(sym): self.decl_visibility_index.get(sym).unwrap() else: -1
        while vi >= 0:
            candidates = candidates + 1
            let path = with_str_clone_ref(self.decl_visibility_paths[vi])
            let is_pub: i32 = self.decl_visibility_pub[vi] + 0
            out = out ++ self.explain_one_candidate("value", sym, path, is_pub)
            vi = if vi < self.decl_visibility_prev.len() as i32: self.decl_visibility_prev[vi] else: -1
        var ti = self.named_type_candidate_head(sym)
        while ti >= 0:
            candidates = candidates + 1
            let path = with_str_clone_ref(self.named_type_candidate_paths[ti])
            out = out ++ self.explain_one_candidate("type", sym, path, self.named_type_candidate_pub[ti])
            ti = self.named_type_candidate_next[ti]
        var di = if self.displaced_fn_index.contains(sym): self.displaced_fn_index.get(sym).unwrap() else: -1
        while di >= 0:
            candidates = candidates + 1
            let path = with_str_clone_ref(self.displaced_fn_paths[di])
            let dpub: i32 = self.displaced_fn_pub[di] + 0
            out = out ++ self.explain_one_candidate("displaced value (#1350: another std module declares the name)", sym, path, dpub)
            di = self.displaced_fn_prev[di]
        if candidates == 0: out = out ++ "  no declaration of that name in any loaded module\n"
        // The §18.2 fallback bridge: the module a bare, displaced std name
        // resolves to from user code, with the bridge's own reasoning.
        self.visibility_explain_log = sema_new_vec_str()
        self.visibility_explain_on = 1
        let bridge = self.std_fallback_bridge_path(sym)
        self.visibility_explain_on = 0
        for line in self.visibility_explain_log: out = out ++ "  " ++ line ++ "\n"
        out = out ++ "  fallback bridge: " ++ (if bridge.len() > 0: "resolves the bare name to " ++ bridge else: "names no module (the bare name does not resolve through it)".to_owned()) ++ "\n"
        self.current_module_path = saved_module
        out

    mut fn explain_one_candidate(what: &str, sym: i32, path: &str, is_pub: i32) -> str:
        var out = "  " ++ what ++ " declared in " ++ (if path.len() > 0: with_str_clone_ref(path) else: "<no module path: the registration-time module was unset>".to_owned()) ++ " (package " ++ self.package_of(path) ++ f", pub={is_pub}, engine={self.engine_corpus_id(path)}, prelude-closure={self.module_in_prelude_closure(path)}, corpus-private={if self.corpus_private_modules.contains(path): 1 else: 0})\n"
        self.visibility_explain_log = sema_new_vec_str()
        self.visibility_explain_on = 1
        self.module_visibility_cache = sema_new_map_str_i32()
        let verdict = self.decl_visible_from_current_gated(path, is_pub, sym)
        self.visibility_explain_on = 0
        for line in self.visibility_explain_log: out = out ++ "    " ++ line ++ "\n"
        out ++ f"    verdict: {verdict}\n"

    // `with analyze file.w explain:modules`: why each module is in the
    // compilation — its package, engine id, prelude-closure and
    // corpus-private marks, and the modules that import it (the chain that
    // pulled it in). The loaded set is what two compiler generations
    // disagreed on (#2248).
    pub fn explain_modules() -> str:
        var out = "explain:modules\n"
        for mi in 0..self.module_paths.len() as i32:
            let path = with_str_clone_ref(self.module_paths[mi])
            var importers = ""
            for from in 0..self.module_paths.len() as i32:
                if from >= self.module_import_starts.len() as i32: continue
                let start = self.module_import_starts[from]
                for ei in 0..self.module_import_counts[from]:
                    if self.module_import_targets[start + ei] == mi:
                        importers = importers ++ (if importers.len() > 0: ", " else: "") ++ self.module_paths[from]
            out = out ++ f"  [{mi}] " ++ path ++ " package=" ++ self.package_of(path) ++ f" engine={self.engine_corpus_id(path)} prelude-closure={self.module_in_prelude_closure(path)} corpus-private={if self.corpus_private_modules.contains(path): 1 else: 0}" ++ (if importers.len() > 0: " imported-by: " ++ importers else: " imported-by: (root)") ++ "\n"
        out
    // #2211: one resolved name use, for the analyzer's `reference` facts. The
    // referencing module is the current one; `node` is 0 for a type name
    // (resolved without a node).
    fn record_name_use(node: i32, kind: &str, path: &str, name: &str):
        if path.len() == 0: return
        self.name_use_nodes.push(node)
        self.name_use_kinds.push(with_str_clone_ref(kind))
        self.name_use_paths.push(with_str_clone_ref(path))
        self.name_use_names.push(with_str_clone_ref(name))
        self.name_use_from.push(with_str_clone_ref(self.current_module_path))

    // The module path of the newest declaration of `sym`, "" when unknown.
    fn decl_path_of_symbol(sym: i32) -> str:
        match self.decl_visibility_index.get(sym):
            Some(i) => with_str_clone_ref(self.decl_visibility_paths[*i])
            None => ""

    fn package_of(path: &str) -> str:
        if self.package_keys.contains(path): return self.package_keys.get(path).unwrap().clone()
        if sema_tier_path_is_std_implementation(path) != 0: "<std>" else: "<program>"

    fn decl_visible_from_current(target_path: &str, is_pub: i32) -> i32:
        if target_path.len() == 0:
            return 1
        if self.current_module_path.len() == 0:
            return 1
        if target_path == self.current_module_path:
            return 1
        if sema_path_is_compiler_hook_runner(self.current_module_path) != 0:
            return 1
        // The std tier is one implementation: its modules read each other's
        // private declarations (a migrated engine corpus is generated that
        // way, D39). #1520: this used to extend to every path under a
        // `src/`, `build/` or `rt/` directory — the compiler's own tree,
        // guessed from the directory name — so a user project laid out as
        // `src/a.w`, `src/b.w` had privacy only when checked from inside
        // `src/`. The compiler tree now conforms to §18.3 like any project.
        if sema_tier_path_is_std_implementation(self.current_module_path) != 0 and sema_tier_path_is_std_implementation(target_path) != 0:
            return 1
        // #2248: a std module loaded only for a corpus's sake is not part of
        // any program's namespace (record_engine_corpora).
        if self.corpus_private_modules.contains(target_path): self.vis_note("  refused: the module is corpus-private (#2248: loaded only for a corpus)")
        if self.corpus_private_modules.contains(target_path):
            return 0
        // D100 (§18.3): without `pub`, a declaration is visible throughout
        // its package — `pub` is what other packages need. It waives `pub`,
        // not the import: the module must still be visible from here.
        if is_pub == 0 and self.package_of(target_path) != self.package_of(self.current_module_path): self.vis_note("  refused: not pub and another package (D100 §18.3): " ++ self.package_of(target_path) ++ " vs " ++ self.package_of(self.current_module_path))
        if is_pub == 0 and self.package_of(target_path) != self.package_of(self.current_module_path):
            return 0
        self.module_is_visible_from_current(target_path)

    // D29 scaffolding (#750): name-aware visibility. Three rules on top of
    // decl_visible_from_current, applied before its internal-boundary and
    // reachability shortcuts:
    //   1. std blindness — a std implementation module never resolves a
    //      user-tier declaration. The flat merge let newer user decls hijack
    //      std-internal references (user `type Regex` rebound regex.w).
    //   2. engine corpora are never ambient (§18.2: "Engine packages are
    //      ordinary explicit dependencies and are never ambient") — a
    //      migrated corpus a .wo bundle provides (std.re, std.zl,
    //      std.tommyds, std.c_algorithms: engine_corpus_id) resolves from
    //      user code only through the user's own `use` of one of its
    //      modules. The prelude's std.regex importing std.re.* made
    //      u128_mul_would_overflow and c_int callable with no import, and a
    //      facade the user imports (std.zlib) re-exports nothing (#1362).
    //   3. prelude gate — a prelude-closure declaration is ambient only for
    //      the §18.2 enumerated names; any other resolves from user code
    //      only through an explicit import path (never the synthetic prelude
    //      edge), or through the fallback bridge (std_fallback_bridge_path).
    //      Replaced by the §18.2 fallback tier (#752, after #751).
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
        self.vis_note("gate: current=" ++ self.current_module_path ++ " target=" ++ target_path ++ f" current-std={current_is_std} target-std={target_is_std} pub={is_pub}")
        if current_is_std != 0 and target_is_std == 0:
            self.vis_note("  refused: a std module never resolves a user-tier declaration")
            return 0
        if current_is_std == 0 and target_is_std != 0 and sema_prelude_gate_allows_name(self.pool_resolve(sym)) != 0: self.vis_note("  §18.2 enumerated prelude name: the gate allows it")
        if current_is_std == 0 and target_is_std != 0 and sema_prelude_gate_allows_name(self.pool_resolve(sym)) == 0:
            self.vis_note(f"  not an enumerated prelude name; engine={self.engine_corpus_id(target_path)} prelude-closure={self.module_in_prelude_closure(target_path)} corpus-private={if self.corpus_private_modules.contains(target_path): 1 else: 0}")
            if self.engine_corpus_id(target_path) != 0 or self.module_in_prelude_closure(target_path) != 0:
                if self.module_visible_no_prelude(target_path) == 0:
                    self.vis_note("  refused: an engine or prelude-closure module needs an explicit import path (no-prelude walk found none)")
                    return 0
        if target_is_std == 0 and self.unselected_import_path(target_path, sym).len() > 0:
            self.vis_note("  refused: the import of that module selects names and not this one (#1744)")
            return 0
        self.decl_visible_from_current(target_path, is_pub)

    // #1744 (§18.2): a named import introduces the names it selects. When
    // the current module imports a (non-std) module only by named imports,
    // a name none of them selects is not visible through them: the import
    // text of the last such `use` (for the diagnostic), "" when the name is
    // selected, the module is imported whole, or it is not a direct import.
    // A std module keeps every public name available through the §18.2
    // fallback tier. A displaced identity (`name$in$module`, #1350) is
    // judged by its short name.
    fn unselected_import_path(target_path: &str, sym: i32) -> str:
        let cur = self.module_index_by_path.get(with_str_clone_ref(self.current_module_path))
        let target = self.module_index_by_path.get(target_path)
        if not cur.is_some() or not target.is_some():
            return ""
        let from: i32 = cur.unwrap()
        let to: i32 = target.unwrap()
        if from < 0 or from >= self.module_import_starts.len() as i32 or from == to:
            return ""
        var name: str = with_str_clone_ref(self.pool_resolve(sym))
        let infix = name.index_of("$in$")
        if infix > 0:
            name = name.slice(0, infix)
        // A method is reached through a value or its type's name: the
        // selection governs the names a module spells, and a type name it
        // spells is judged on its own (`UserService.builder().with_config()`
        // calls a method of a type the import never names).
        if name.index_of(".") > 0:
            return ""
        var excluded_by = ""
        let start = self.module_import_starts[from]
        for ei in 0..self.module_import_counts[from]:
            let idx = start + ei
            if self.module_import_targets[idx] != to:
                continue
            let text = self.module_import_paths[idx]
            if text == "std.prelude" or text == "std.prelude_core" or text == "std.prelude_alloc":
                continue
            let selected = if idx < self.module_import_selected.len() as i32: self.module_import_selected[idx].clone() else: ""
            if selected.len() == 0 or sema_selection_names(selected, name):
                return ""
            excluded_by = with_str_clone_ref(text)
        excluded_by

    fn module_in_prelude_closure(path: &str) -> i32:
        if self.global_visible_module_paths.contains(path): 1 else: 0

    // #1362: the engine corpus a module belongs to, 0 for any other module.
    fn engine_corpus_id(path: &str) -> i32:
        let found = self.engine_module_corpus.get(path)
        if found.is_some(): found.unwrap() else: 0

    // A std module whose directory holds a bundle root (`bundle.w`, written
    // by build/corpora.w) belongs to a migrated corpus: registered as an
    // interface section where a .wo bundle provides it, a source file where
    // the corpus compiles from the tree (stage1, a bundle build).
    mut fn record_engine_corpora():
        self.engine_module_corpus = sema_new_map_str_i32()
        let corpus_ids = sema_new_map_str_i32()
        for mi in 0..self.module_paths.len() as i32:
            let path = sema_owned_text(self.module_paths[mi])
            let canonical = codegen_canonical_module_path(path)
            if not canonical.starts_with("<embedded-std>/std/"):
                continue
            let dir = sema_dirname(canonical)
            if dir == "<embedded-std>/std":
                continue
            if not corpus_ids.contains(dir):
                let is_engine = bundle_interface_registered(dir ++ "/bundle.w") or module_source_read(sema_dirname(path) ++ "/bundle.w").text.len() > 0
                corpus_ids.insert(sema_owned_text(dir), if is_engine: corpus_ids.len() as i32 + 1 else: 0)
            let id: i32 = corpus_ids.get(dir).unwrap()
            if id != 0:
                self.engine_module_corpus.insert(sema_owned_text(path), id)
        // #2248 (D39 §3.4): a corpus presents its surface, never its
        // body-only imports. A std module that only corpus modules (or
        // other such modules) import is loaded for the corpus's sake —
        // stage1 compiles the corpus from source and loads std.re's
        // std.libc and its std.os; the release compiler, serving the corpus
        // as an interface, loads neither — and is private to it: never
        // visible to user code, so both generations resolve the same names.
        // A fixpoint: a module is private when every importer is an engine
        // or private module; one the user (or the prelude closure) imports
        // is not.
        self.corpus_private_modules = sema_new_map_str_i32()
        let count = self.module_paths.len() as i32
        var changed = true
        while changed:
            changed = false
            for mi in 0..count:
                let path = sema_owned_text(self.module_paths[mi])
                if self.corpus_private_modules.contains(path) or self.engine_corpus_id(path) != 0: continue
                if sema_tier_path_is_std_implementation(path) == 0 or self.global_visible_module_paths.contains(path): continue
                var importers = 0
                var all_corpus = true
                for from in 0..count:
                    if from >= self.module_import_starts.len() as i32: continue
                    let start = self.module_import_starts[from]
                    for ei in 0..self.module_import_counts[from]:
                        if self.module_import_targets[start + ei] != mi: continue
                        importers = importers + 1
                        let from_path = sema_owned_text(self.module_paths[from])
                        if self.engine_corpus_id(from_path) == 0 and not self.corpus_private_modules.contains(from_path):
                            all_corpus = false
                if importers > 0 and all_corpus:
                    self.corpus_private_modules.insert(path, 1)
                    changed = true

    // Reachability over explicit import edges only: the synthetic prelude
    // edge and the global prelude-closure shortcut are excluded, so this
    // answers "did the user actually import a path to this module?". An
    // engine corpus module is entered only from the start module itself or
    // from its own corpus (#1362): importing a facade over it (std.zlib)
    // does not import it.
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
            let cached: i32 = self.module_visibility_cache.get(cache_key).unwrap()
            self.vis_note("  walk " ++ cache_key ++ f": cached verdict {cached}")
            return cached
        let start_idx: i32 = self.module_index_by_path.get(with_str_clone_ref(self.current_module_path)).unwrap()
        let target_idx: i32 = self.module_index_by_path.get(target_path).unwrap()
        let seen: HashMap[i32, i32] = sema_new_map_i32_i32()
        let stack: Vec[i32] = Vec.new()
        stack.push(start_idx)
        while stack.len() as i32 > 0:
            let last = stack.len() as i32 - 1
            let current: i32 = stack[last]
            stack.pop()
            if seen.contains(current):
                continue
            seen.insert(current, 1)
            if current == target_idx:
                self.vis_note("  walk reached " ++ target_path)
                self.module_visibility_cache.insert(sema_owned_text(cache_key), 1)
                return 1
            // D39 §3.4: a bundle corpus module compiled in-unit (--emit-c,
            // #955) presents the surface its .wi would — its corpus siblings
            // reach the importer, its body-only imports (std.libc) do not.
            let corpus_boundary = current != start_idx and self.module_in_bundle_corpus(current)
            let current_engine = if current == start_idx: -1 else: self.engine_corpus_id(self.module_paths[current])
            // §18.1/§18.2: a name reaches a module only through its own
            // `use`, never through what an imported user module imported.
            // The walk followed every module's edges, so `use compiler.Link`
            // made Link's `use std.string.StringBuilder` resolve
            // StringBuilder in the importer with no import of its own
            // (#1955). As in module_is_visible_from_current, the walk
            // continues only through the std tier (§18.2 tier 5, #752) and,
            // compiled in-unit, through a bundle corpus's own modules (D39
            // §3.4 above).
            let current_is_std = current >= 0 and current < self.module_paths.len() as i32 and sema_tier_path_is_std_implementation(self.module_paths[current]) != 0
            if current != start_idx and not current_is_std and not self.module_in_bundle_corpus(current):
                continue
            if current >= 0 and current < self.module_import_starts.len() as i32:
                let edge_start = self.module_import_starts[current]
                let edge_count = self.module_import_counts[current]
                for ei in 0..edge_count:
                    let idx = edge_start + ei
                    if idx >= 0 and idx < self.module_import_paths.len() as i32:
                        let ip: str = with_str_clone_ref(self.module_import_paths[idx])
                        if ip == "std.prelude" or ip == "std.prelude_core" or ip == "std.prelude_alloc":
                            self.vis_note("    no-prelude walk: skip " ++ self.module_paths[self.module_import_targets[idx]] ++ " (the synthetic prelude edge)")
                            continue
                        let target = self.module_import_targets[idx]
                        if corpus_boundary and not self.module_in_bundle_corpus(target):
                            self.vis_note("    no-prelude walk: skip " ++ self.module_paths[target] ++ " (in-unit corpus boundary)")
                            continue
                        if current_engine >= 0 and target >= 0 and target < self.module_paths.len() as i32:
                            let target_engine = self.engine_corpus_id(self.module_paths[target])
                            // D39 §3.4: a corpus presents its surface — its
                            // siblings — and never its body-only imports,
                            // whether it came as an interface (which never
                            // loads them) or from source (stage1 has no
                            // bundle slot). From inside a corpus the walk
                            // continues only within it: std.re's std.libc
                            // import pulled std.os into every program's bare
                            // names on stage1 and not on the release compiler
                            // (#2248).
                            if target_engine != 0 and target_engine != current_engine:
                                self.vis_note("    no-prelude walk: skip " ++ self.module_paths[target] ++ f" (corpus boundary: engine {current_engine} -> {target_engine})")
                                continue
                        self.vis_note("    no-prelude walk: " ++ self.module_paths[current] ++ " -> " ++ self.module_paths[target])
                        stack.push(target)
        self.vis_note("  no-prelude walk: " ++ target_path ++ " not reached from " ++ self.current_module_path)
        self.module_visibility_cache.insert(sema_owned_text(cache_key), 0)
        0

    fn module_in_bundle_corpus(module_idx: i32) -> bool:
        self.bundle_corpus.len() > 0 and module_idx >= 0 and module_idx < self.module_paths.len() as i32 and bundle_corpus_contains(self.bundle_corpus, codegen_canonical_module_path(self.module_paths[module_idx]))

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
        var i = if self.decl_visibility_index.contains(sym): self.decl_visibility_index.get(sym).unwrap() else: -1
        while i >= 0:
            saw_candidate = 1
            let path = self.decl_visibility_paths[i]
            let is_pub = self.decl_visibility_pub[i]
            // Another module's C expansion is an import, reached only by the
            // c_import rule above, never by package-wide visibility (D100).
            let record_di = self.find_decl_index(self.decl_visibility_nodes[i])
            let imported_c = path != self.current_module_path and record_di >= 0 and record_di < self.decl_is_c_import.len() as i32 and self.decl_is_c_import[record_di] != 0
            if not imported_c and self.decl_visible_from_current_gated(path, is_pub, sym) != 0:
                return 1
            i = self.decl_visibility_prev[i]
        if saw_candidate == 0:
            return 1
        if self.std_fallback_bridge_path(sym).len() > 0: 1 else: 0

    // #1362 bridge, until the §18.2 fallback tier lands (#752): a name that
    // resolved from user code only because an engine corpus declared it too
    // (std.string's is_alnum beside std.re.defs', reached over the prelude
    // edge) keeps resolving — to the unique public declaration of a
    // non-engine std module, the declaration §18.2's tier 5 names. Closing
    // the engine leak never turns such a program into an error; a name
    // with no engine twin keeps the prelude gate (#750). Returns that
    // declaration's module path, "" when the bridge does not apply.
    fn std_fallback_bridge_path(sym: i32) -> str:
        if sym == 0 or self.current_module_path.len() == 0 or sema_tier_path_is_std_implementation(self.current_module_path) != 0:
            return ""
        let paths = sema_new_vec_str()
        let pubs: Vec[i32] = Vec.new()
        var i = if self.decl_visibility_index.contains(sym): self.decl_visibility_index.get(sym).unwrap() else: -1
        while i >= 0:
            paths.push(sema_owned_text(self.decl_visibility_paths[i]))
            pubs.push(self.decl_visibility_pub[i])
            i = self.decl_visibility_prev[i]
        i = self.named_type_candidate_head(sym)
        while i >= 0:
            paths.push(sema_owned_text(self.named_type_candidate_paths[i]))
            pubs.push(self.named_type_candidate_pub[i])
            i = self.named_type_candidate_next[i]
        i = if self.displaced_fn_index.contains(sym): self.displaced_fn_index.get(sym).unwrap() else: -1
        while i >= 0:
            paths.push(sema_owned_text(self.displaced_fn_paths[i]))
            pubs.push(self.displaced_fn_pub[i])
            i = self.displaced_fn_prev[i]
        // A bare name that two std modules declare is displaced (#1350); the
        // fallback tier names the one non-engine std module declaring it.
        // This used to require the engine twin to be "ambient" (reachable
        // through the std-tier walk) — a proxy for "the prelude's closure
        // loaded the corpus" that was always true, until D39 §3.4's corpus
        // boundary made a corpus never ambient (#2248) and the proxy went
        // false for every program (#2249, `is_alnum`). The engine twin's
        // reachability says nothing about the std module's; the unique
        // non-engine std declaration is the answer on its own.
        var engine_twin = ""
        let modules = sema_new_vec_str()
        for pi in 0..paths.len() as i32:
            let path = paths[pi]
            if pubs[pi] == 0 or sema_tier_path_is_std_implementation(path) == 0:
                self.vis_note("  bridge: skip " ++ path ++ (if pubs[pi] == 0: " (not pub)" else: " (not std)"))
                continue
            if self.engine_corpus_id(path) != 0:
                engine_twin = sema_owned_text(path)
            else if self.corpus_private_modules.contains(path):
                self.vis_note("  bridge: skip " ++ path ++ " (corpus-private, #2248)")
            else if sema_vec_str_contains(&modules, path) == 0:
                modules.push(sema_owned_text(path))
        self.vis_note(f"  bridge: {modules.len()} non-engine std module(s) declare it" ++ (if engine_twin.len() > 0: "; engine twin " ++ engine_twin else: "; no engine twin"))
        // Only a name an engine twin displaced takes the bridge: a std name
        // nothing displaces resolves (or not) through the gate alone.
        if engine_twin.len() > 0 and modules.len() as i32 == 1: sema_owned_text(modules[0]) else: ""

    fn decl_node_visible_from_current(node: i32) -> i32:
        if node == 0:
            return 1
        let record = self.decl_visibility_node_index.get(node)
        if record.is_some():
            let i: i32 = record.unwrap()
            let path = self.decl_visibility_paths[i]
            // #1744: a named import that does not select it hides it too.
            if sema_tier_path_is_std_implementation(path) == 0 and path != self.current_module_path and self.unselected_import_path(path, self.decl_visibility_syms[i]).len() > 0:
                return 0
            return self.decl_visible_from_current(path, self.decl_visibility_pub[i])
        1

    fn has_extern_var_decl(sym: i32) -> i32:
        if self.extern_var_texts.contains(self.pool_resolve(sym)): 1 else: 0

    fn private_symbol_path_from_current(sym: i32) -> str:
        var i = if self.decl_visibility_index.contains(sym): self.decl_visibility_index.get(sym).unwrap() else: -1
        while i >= 0:
            let path = self.decl_visibility_paths[i]
            let is_pub = self.decl_visibility_pub[i]
            if path.len() > 0 and path != self.current_module_path and is_pub == 0 and self.module_is_visible_from_current(path) != 0:
                return with_str_clone_ref(path)
            i = self.decl_visibility_prev[i]
        ""

    // D29 scaffolding (#750): when a name failed resolution only because the
    // prelude gate requires an import, name the exact use line. The message
    // suffix "; add: use <module>.<name>" is a stable contract consumed by
    // tools/insert_std_uses.w and the migrator's self-fix pass. The prelude
    // closure's modules are offered first; a name only a deeper std module
    // declares (a bundle corpus's u128_mul_would_overflow, #1362) offers
    // those, displaced declarations (#1350) included.
    fn std_gated_import_note(sym: i32) -> str:
        if sym == 0:
            return ""
        let name = self.pool_resolve(sym)
        if name.len() == 0 or sema_prelude_gate_allows_name(name) != 0:
            return ""
        let paths = sema_new_vec_str()
        var i = 0
        while i < self.named_type_candidate_syms.len() as i32:
            if self.named_type_candidate_syms[i] == sym and self.named_type_candidate_pub[i] != 0:
                paths.push(sema_owned_text(self.named_type_candidate_paths[i]))
            i = i + 1
        i = 0
        while i < self.decl_visibility_syms.len() as i32:
            if self.decl_visibility_syms[i] == sym and self.decl_visibility_pub[i] != 0:
                paths.push(sema_owned_text(self.decl_visibility_paths[i]))
            i = i + 1
        i = if self.displaced_fn_index.contains(sym): self.displaced_fn_index.get(sym).unwrap() else: -1
        while i >= 0:
            if self.displaced_fn_pub[i] != 0:
                paths.push(sema_owned_text(self.displaced_fn_paths[i]))
            i = self.displaced_fn_prev[i]
        var modules = sema_new_vec_str()
        for round in 0..2:
            let closure_only = 1 - round
            if modules.len() as i32 > 0:
                break
            for path in paths:
                if sema_tier_path_is_std_implementation(path) != 0 and (closure_only == 0 or self.module_in_prelude_closure(path) != 0):
                    let dotted = sema_std_module_dotted(path)
                    if dotted.len() > 0 and sema_vec_str_contains(&modules, dotted) == 0:
                        modules.push(sema_owned_text(dotted))
        if modules.len() as i32 == 0:
            return ""
        if modules.len() as i32 == 1:
            return "; add: use " ++ modules[0] ++ "." ++ name
        var listed = ""
        for mi in 0..modules.len() as i32:
            if mi > 0:
                listed = listed ++ " | "
            listed = listed ++ "use " ++ modules[mi] ++ "." ++ name
        "; candidates: " ++ listed

    mut fn emit_private_symbol_error(sym: i32, node: i32) -> Unit:
        let name: str = with_str_clone_ref(self.pool_resolve(sym))
        // #1744: a name its module's named imports do not select.
        var i = if self.decl_visibility_index.contains(sym): self.decl_visibility_index.get(sym).unwrap() else: -1
        while i >= 0:
            let decl_path = self.decl_visibility_paths[i]
            if self.decl_visibility_pub[i] != 0 and sema_tier_path_is_std_implementation(decl_path) == 0:
                let by = self.unselected_import_path(decl_path, sym)
                if by.len() > 0:
                    let infix = name.index_of("$in$")
                    let short = if infix > 0: name.slice(0, infix) else: name.clone()
                    self.emit_error("'" ++ short ++ "' is not imported: `use " ++ by ++ "` names only what it selects (§18.2); add `" ++ short ++ "` to that import, or import the whole module", node)
                    return
            i = self.decl_visibility_prev[i]
        let gate_note = self.std_gated_import_note(sym)
        if gate_note.len() > 0:
            self.emit_error("'" ++ name ++ "' requires an explicit import (§18.1)" ++ gate_note, node)
            return
        let path = self.private_symbol_path_from_current(sym)
        if path.len() > 0:
            self.emit_error("symbol '" ++ name ++ "' is private to its package (declared in '" ++ path ++ "', §18.3)", node)
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
            let cached: i32 = self.module_visibility_cache.get(cache_key).unwrap()
            self.vis_note("  walk " ++ cache_key ++ f": cached verdict {cached}")
            return cached
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
            let current: i32 = stack[last]
            stack.pop()
            if seen.contains(current):
                continue
            seen.insert(current, 1)
            if current == target_idx:
                self.vis_note("  walk reached " ++ target_path)
                self.module_visibility_cache.insert(sema_owned_text(cache_key), 1)
                return 1
            if current >= 0 and current < self.module_import_starts.len() as i32:
                let edge_start = self.module_import_starts[current]
                let edge_count = self.module_import_counts[current]
                for ei in 0..edge_count:
                    // Spec §18.2: imports are explicit — a name reaches a module
                    // only through its own `use` (or the prelude / std fallback
                    // tiers), never through what an imported module imported.
                    // Through a std module the walk continues: every public
                    // std declaration is the lowest resolution tier (§18.2 tier 5,
                    // #752), so what std.build imports is reachable from build.w.
                    if current == start_idx or sema_tier_path_is_std_implementation(self.module_paths[current]) != 0:
                        let target = self.module_import_targets[(edge_start + ei)]
                        // D39 §3.4: a corpus presents its surface, never its
                        // body-only imports — from inside a corpus the walk
                        // stays within it, and it never enters one from
                        // outside, the same whether the corpus came as an
                        // interface or from source (#2248: on stage1 std.re's
                        // std.libc import reached std.os for every program).
                        if current != start_idx and target >= 0 and target < self.module_paths.len() as i32:
                            if self.engine_corpus_id(self.module_paths[target]) != self.engine_corpus_id(self.module_paths[current]):
                                self.vis_note("    std-tier walk: skip " ++ self.module_paths[target] ++ f" (corpus boundary: engine {self.engine_corpus_id(self.module_paths[current])} -> {self.engine_corpus_id(self.module_paths[target])})")
                                continue
                        self.vis_note("    std-tier walk: " ++ self.module_paths[current] ++ " -> " ++ self.module_paths[target])
                        stack.push(target)
        self.vis_note("  std-tier walk: " ++ target_path ++ " not reached from " ++ self.current_module_path)
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
            let path = self.named_type_candidate_paths[i]
            if path.len() > 0:
                let cand_std = if sema_tier_path_is_std_implementation(path) != 0: 1 else: 0
                if cand_std == want_std:
                    return self.named_type_candidate_tids[i]
            i = self.named_type_candidate_next[i]
        if self.named_types.contains(sym): self.named_types.get(sym).unwrap() else: 0

    // The scoped-binding tier of type-name lookup. `named_types` has two
    // kinds of writer: record_named_type_with_pub, which also records a
    // candidate (module path, pub) for every declaration, and the scoped
    // bindings written straight into the table and removed when their
    // scope ends: `Self` inside an impl or a method body
    // (SemaCheck.w bind/restore of syms.self_type, SemaDecl.w, and the
    // comptime and MIR specializers) and a generic type parameter during
    // specialization (tp_sym). A scoped binding has no candidate, so it is
    // the only way `named_types` can name a tid no candidate carries: that
    // is this tier, and it is not a visibility fallback. A declaration
    // always has a candidate with its tid, so an unimported module
    // declaration never resolves here (#1955 was the import walk, not this
    // tier; `with-stage1 check rt/rt_core.w` under lldb takes it only for
    // sym `Self`, with saw_recorded = 0). Its inputs are arguments so -O1
    // keeps them readable in lldb.
    fn scoped_type_binding(sym: i32, named_tid: i32, saw_recorded: i32, saw_named_tid: i32) -> i32:
        if named_tid != 0 and (saw_recorded == 0 or saw_named_tid == 0): named_tid else: 0

    fn lookup_named_type_filtered(sym: i32, gated: i32) -> i32:
        let named_tid = if self.named_types.contains(sym): self.named_types.get(sym).unwrap() else: 0
        var global_tid = 0
        var saw_recorded = 0
        var saw_named_tid = 0
        // The scoped tier first (#1967): `Self` and a generic type parameter
        // are inserted into named_types directly, with no module candidate,
        // and are lexically closer than any module's declaration — a visible
        // module's `pub type T` must not shadow the `T` of `fn f[T]`.
        var i = self.named_type_candidate_head(sym)
        while i >= 0:
            saw_recorded = 1
            if named_tid != 0 and self.named_type_candidate_tids[i] == named_tid:
                saw_named_tid = 1
            i = self.named_type_candidate_next[i]
        let scoped = self.scoped_type_binding(sym, named_tid, saw_recorded, saw_named_tid)
        if scoped != 0:
            return scoped
        i = self.named_type_candidate_head(sym)
        while i >= 0:
            let candidate_tid = self.named_type_candidate_tids[i]
            let candidate_path = self.named_type_candidate_paths[i]
            let candidate_pub = self.named_type_candidate_pub[i]
            // A C declaration another module's expansion made is an import,
            // not that module's declaration (§18.2: imports are not
            // transitive): it reaches this module only by the c_import rule
            // below, never by D100's package-wide visibility.
            let imported_c = self.named_type_candidate_ci[i] != 0 and candidate_path != self.current_module_path
            let candidate_visible = if imported_c: 0 else if gated != 0: self.decl_visible_from_current_gated(candidate_path, candidate_pub, sym) else: self.decl_visible_from_current(candidate_path, candidate_pub)
            if candidate_path.len() == 0:
                if global_tid == 0:
                    global_tid = candidate_tid
            else if candidate_visible != 0:
                self.record_name_use(0, "type", candidate_path, self.pool_resolve(sym))
                return candidate_tid
            i = self.named_type_candidate_next[i]
        // A module that uses c_import shares the program's C declarations,
        // as symbol_visible_from_current already lets it for values
        // (is_ci_visible, "a c_import symbol is visible when the current
        // module itself uses c_import"). The frontend emits a shared C
        // declaration once, into the first importing module, and a later
        // importer's expansion names it: the root's <stdlib.h> named the
        // `c_ulonglong` its imported module's <stdio.h> had emitted, and
        // type lookup alone applied module privacy to it (#1372). A
        // declaration visible by the ordinary rules — the module's own
        // first (§18.1) — wins over this.
        if self.current_module_uses_c_import():
            i = self.named_type_candidate_head(sym)
            while i >= 0:
                if self.named_type_candidate_ci[i] != 0:
                    return self.named_type_candidate_tids[i]
                i = self.named_type_candidate_next[i]
        if gated != 0 and saw_recorded != 0:
            let bridged = self.std_fallback_bridge_path(sym)
            if bridged.len() > 0:
                i = self.named_type_candidate_head(sym)
                while i >= 0:
                    if self.named_type_candidate_paths[i] == bridged:
                        return self.named_type_candidate_tids[i]
                    i = self.named_type_candidate_next[i]
        // The builtin tier: a candidate recorded before any module path
        // existed (primitives, FieldInfo/VariantInfo) has the empty path and
        // is visible everywhere, after every module candidate so a module's
        // own declaration shadows it.
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
            let field_sym = self.pool_intern(field_names[fi])
            self.type_extra.push(field_sym)
            self.type_extra.push(field_types[fi])
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
        self.syms.va_start = self.pool_intern("va_start")
        self.syms.va_arg_method = self.pool_intern("arg")
        self.syms.copy_trait = self.pool_intern("Copy")
        self.syms.clone_trait = self.pool_intern("Clone")
        self.syms.send_trait = self.pool_intern("Send")
        self.syms.sync_trait = self.pool_intern("Sync")
        self.syms.scoped_send_trait = self.pool_intern("ScopedSend")
        self.syms.deref_trait = self.pool_intern("Deref")
        self.syms.deref_method = self.pool_intern("deref")
        self.syms.regex = self.pool_intern("Regex")
        self.syms.drop = self.pool_intern("Drop")
        self.syms.display_trait = self.pool_intern("Display")
        self.syms.debug_trait = self.pool_intern("Debug")
        self.syms.self_type = self.pool_intern("Self")
        self.syms.vec = self.pool_intern("Vec")
        self.syms.fixed_string = self.pool_intern("FixedString")
        self.syms.veciter = self.pool_intern("VecIter")
        self.syms.mapiter = self.pool_intern("MappedIter")
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
        self.syms.keys = self.pool_intern("keys")
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
        self.syms.zeroed = self.pool_intern("zeroed")
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
        if text[i] == 10:
            offsets.push(i as i32 + 1)
    offsets

impl Sema:
    mut fn prepare_source_line_offsets():
        self.source_line_offsets = Vec.new()
        self.source_line_offsets.push(sema_source_line_offsets(self.source_text))
        for si in 0..self.source_texts.len() as i32:
            self.source_line_offsets.push(sema_source_line_offsets(self.source_texts[si]))

    fn source_location_for_file_id(file_id: i32, offset: i32) -> SemaSourceLocation:
        var source_index = 0
        if file_id != 0:
            for si in 0..self.source_text_file_ids.len() as i32:
                if self.source_text_file_ids[si] == file_id:
                    source_index = si + 1
                    break
        if source_index >= self.source_line_offsets.len() as i32:
            sema_phase_bug("source line offsets were not prepared before MIR lowering")
        let offsets = self.source_line_offsets[source_index]
        var clamped = offset
        if clamped < 0:
            clamped = 0
        let source_len = if source_index == 0: self.source_text.len() as i32 else: self.source_texts[(source_index - 1)].len() as i32
        if clamped > source_len:
            clamped = source_len
        var lo = 0
        var hi = offsets.len() as i32
        while lo < hi:
            let mid = lo + (hi - lo) / 2
            if offsets[mid] <= clamped:
                lo = mid + 1
            else:
                hi = mid
        let line = if lo > 0: lo - 1 else: 0
        SemaSourceLocation { line, col: clamped - offsets[line] }

    fn source_text_view_for_file_id(file_id: i32) -> &str:
        if file_id == 0:
            return &self.source_text
        for si in 0..self.source_text_file_ids.len() as i32:
            if self.source_text_file_ids[si] == file_id:
                return self.source_texts[si]
        ""

    fn source_text_for_file_id(file_id: i32) -> str:
        with_str_clone_ref(self.source_text_view_for_file_id(file_id))

    fn source_text_for_decl_node(node: i32) -> &str:
        let di = self.find_decl_index(node)
        if di >= 0 and di < self.decl_source_file_ids.len() as i32:
            let file_id = self.decl_source_file_ids[di]
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
        let text = self.source_text_for_decl_node(node)
        if text.len() == 0:
            return ""
        let source_len = text.len() as i32
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
        let snippet = text.slice(start as i64, end as i64)
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
        let text = self.source_text_for_decl_node(node)
        if text.len() == 0:
            return ""
        let source_len = text.len() as i32
        var start = self.ast.get_start(node)
        var end = self.ast.get_end(node)
        if start < 0:
            start = 0
        if end > source_len:
            end = source_len
        if end <= start:
            return ""
        extract_fn_param_name_in_text(text.slice(start as i64, end as i64), param_index)

    // ── Type management ──────────────────────────────────────────────

    fn exact_type_components_match(tid: i32, kind: i32, d0: i32, d1: i32, d2: i32) -> bool:
        self.type_kinds[tid] == kind and
            self.type_d0[tid] == d0 and
            self.type_d1[tid] == d1 and
            self.type_d2[tid] == d2

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
            existing = self.exact_type_cache_next[existing]
        self.exact_type_cache_next.push(head)
        self.exact_type_cache_heads.insert(key, tid)

    mut fn rebuild_exact_type_cache():
        self.exact_type_cache_heads = sema_new_map_i64_i32()
        self.exact_type_cache_next = Vec.new()
        for tid in 0..self.type_kinds.len() as i32:
            self.index_exact_type(
                tid,
                self.type_kinds[tid],
                self.type_d0[tid],
                self.type_d1[tid],
                self.type_d2[tid],
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
            if self.type_extra[(extra_start + i)] != values[i]:
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
            ti = self.exact_type_cache_next[ti]
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
            if self.type_kinds[ti] != TypeKind.TY_TUPLE:
                continue
            if self.type_d1[ti] != elem_count:
                continue
            let te_start = self.type_d0[ti]
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
            self.type_extra.push(elems[ei])
        self.add_type(TypeKind.TY_TUPLE, te_start, elem_count, 0)

    fn find_fn_type_of_kind(kind: i32, params: &Vec[i32], param_count: i32, ret: TypeId) -> TypeId:
        self.find_fn_type_of_kind_u(kind, params, param_count, ret, 0)

    // §16.11: unsafe-ness is part of callable type identity, so two signatures
    // that differ only in unsafe-ness are distinct types; so is variadic-ness
    // (#1832). `flags`: CALLABLE_UNSAFE | CALLABLE_VARIADIC.
    fn find_fn_type_of_kind_u(kind: i32, params: &Vec[i32], param_count: i32, ret: TypeId, flags: i32) -> TypeId:
        let type_count = self.type_kinds.len() as i32
        for ti in 0..type_count:
            if self.type_kinds[ti] != kind:
                continue
            if self.type_d1[ti] != param_count:
                continue
            if self.type_d2[ti] != ret as i32:
                continue
            if self.callable_type_flags(ti) != flags:
                continue
            let te_start = self.type_d0[ti]
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

    fn ensure_callable_type(kind: i32, params: &Vec[i32], param_count: i32, ret: TypeId, flags: i32) -> TypeId:
        let existing = self.find_fn_type_of_kind_u(kind, params, param_count, ret, flags)
        if existing != 0:
            return existing
        if self.types_frozen != 0:
            return 0 as TypeId
        let te_start = self.type_extra.len() as i32
        for pi in 0..param_count:
            self.type_extra.push(params[pi])
        let tid = self.add_type(kind, te_start, param_count, ret as i32)
        if (flags & CALLABLE_UNSAFE) != 0:
            self.unsafe_fn_type_set.insert(tid as i32, 1)
        if (flags & CALLABLE_VARIADIC) != 0:
            self.variadic_fn_type_set.insert(tid as i32, 1)
        tid

    // The identity bits of a callable type beyond its signature.
    fn callable_type_flags(tid: i32) -> i32:
        (if self.unsafe_fn_type_set.contains(tid): CALLABLE_UNSAFE else: 0) | (if self.variadic_fn_type_set.contains(tid): CALLABLE_VARIADIC else: 0)

    // #1832: whether a callable type is a C variadic function pointer.
    fn fn_type_is_variadic(tid: i32) -> bool:
        tid != 0 and self.variadic_fn_type_set.contains(self.resolve_alias(tid as TypeId) as i32)

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
        self.type_extra[(te_start + param_i)]

    fn callable_fn_param_type(tid: TypeId, param_i: i32) -> i32:
        self.fn_type_param_type(self.callable_fn_type(tid), param_i)

    fn callable_any_fn_param_type(tid: TypeId, param_i: i32) -> i32:
        self.fn_type_param_type(self.callable_any_fn_type(tid), param_i)

    // §16.11: the unsafe twin of a callable type — the same parameters and
    // result, unsafe to call. A function whose direct call needs `unsafe`
    // has this type as a value (#1829).
    fn unsafe_callable_type(tid: i32) -> i32:
        let resolved = self.resolve_alias(tid as TypeId) as i32
        let kind = self.get_type_kind(resolved)
        if (kind != TypeKind.TY_FN and kind != TypeKind.TY_EXTERN_FN) or self.fn_type_is_unsafe(resolved) != 0:
            return resolved
        let param_count = self.get_type_d1(resolved)
        let start = self.get_type_d0(resolved)
        let params: Vec[i32] = Vec.new()
        for pi in 0..param_count:
            params.push(self.type_extra[(start + pi)])
        self.ensure_callable_type(kind, params, param_count, self.get_type_d2(resolved) as TypeId, CALLABLE_UNSAFE) as i32

    // #1832: the C variadic function-pointer type of a variadic function's
    // signature: its fixed parameters, then `...`.
    fn variadic_callable_type(tid: i32) -> i32:
        let resolved = self.resolve_alias(tid as TypeId) as i32
        let param_count = self.get_type_d1(resolved)
        let start = self.get_type_d0(resolved)
        let params: Vec[i32] = Vec.new()
        for pi in 0..param_count:
            params.push(self.type_extra[(start + pi)])
        self.ensure_callable_type(TypeKind.TY_EXTERN_FN, params, param_count, self.get_type_d2(resolved) as TypeId, CALLABLE_UNSAFE | CALLABLE_VARIADIC) as i32

    // §16.11: a safe callable type cannot accept an unsafe callable value; safe→
    // unsafe widening and same-unsafe-ness are allowed.
    fn callable_unsafe_coercion_ok(expected: i32, actual: i32) -> i32:
        if self.fn_type_is_unsafe(expected) == 0 and self.fn_type_is_unsafe(actual) != 0:
            return 0
        1

    // A `fn` value is assignable to a `fn` type only when the signatures are
    // the same: the same parameter count, each parameter and the result
    // identical (an integer of another width is a different ABI: an i32
    // result read as i64 is garbage, #1772), plus the §16.11 unsafe rule.
    // An unresolved side (type 0) is not yet known and does not decide.
    fn fn_types_assignable(expected: i32, actual: i32) -> i32:
        if self.callable_unsafe_coercion_ok(expected, actual) == 0:
            return 0
        let param_count = self.get_type_d1(expected)
        if param_count != self.get_type_d1(actual):
            return 0
        let exp_start = self.get_type_d0(expected)
        let act_start = self.get_type_d0(actual)
        for pi in 0..param_count:
            let exp_param = self.type_extra[(exp_start + pi)]
            let act_param = self.type_extra[(act_start + pi)]
            if exp_param != 0 and act_param != 0 and not self.types_identical(exp_param, act_param):
                return 0
        let exp_ret = self.get_type_d2(expected)
        let act_ret = self.get_type_d2(actual)
        if exp_ret != 0 and act_ret != 0 and not self.types_identical(exp_ret, act_ret):
            return 0
        1

    mut fn fn_types_compatible(expected: i32, actual: i32) -> i32:
        if self.get_type_d1(expected) != self.get_type_d1(actual) or self.fn_type_is_variadic(expected) != self.fn_type_is_variadic(actual):
            return 0
        let param_count = self.get_type_d1(expected)
        let exp_start = self.get_type_d0(expected)
        let act_start = self.get_type_d0(actual)
        for pi in 0..param_count:
            let exp_param: i32 = self.type_extra[(exp_start + pi)]
            let act_param: i32 = self.type_extra[(act_start + pi)]
            if self.types_compatible(exp_param, act_param) == 0:
                return 0
        self.types_compatible(self.get_type_d2(expected), self.get_type_d2(actual))

    // Whether `a` and `b` are the same type. types_compatible is an
    // assignability test — every integer accepts every integer, every fn
    // type every fn type — so a place that needs one exact type (a closure's
    // declared result against the result its context expects, §12) asks this.
    fn types_identical(a: i32, b: i32) -> bool:
        let ar = self.resolve_alias(a as TypeId) as i32
        let br = self.resolve_alias(b as TypeId) as i32
        if ar == br:
            return true
        let kind = self.get_type_kind(ar as TypeId)
        if kind != self.get_type_kind(br as TypeId):
            return false
        let a0 = self.get_type_d0(ar as TypeId)
        let b0 = self.get_type_d0(br as TypeId)
        let a1 = self.get_type_d1(ar as TypeId)
        let b1 = self.get_type_d1(br as TypeId)
        if kind == TypeKind.TY_BOOL or kind == TypeKind.TY_VOID or kind == TypeKind.TY_STR or kind == TypeKind.TY_NEVER or kind == TypeKind.TY_VA_LIST:
            return true
        // An integer's width and signedness; a float's width.
        if kind == TypeKind.TY_INT or kind == TypeKind.TY_FLOAT:
            return a0 == b0 and a1 == b1
        // A mask's lane width and count; a vector's lane type and count.
        if kind == TypeKind.TY_MASK:
            return a0 == b0 and a1 == b1
        if kind == TypeKind.TY_VECTOR:
            return a1 == b1 and self.types_identical(a0, b0)
        if kind == TypeKind.TY_STRUCT or kind == TypeKind.TY_ENUM or kind == TypeKind.TY_TRAIT_OBJ:
            return a0 == b0
        // The pointee or element, and the mutability, length or inclusivity.
        if kind == TypeKind.TY_REF or kind == TypeKind.TY_PTR or kind == TypeKind.TY_ARRAY or kind == TypeKind.TY_SLICE or kind == TypeKind.TY_RANGE:
            return a1 == b1 and self.types_identical(a0, b0)
        if kind == TypeKind.TY_TUPLE:
            if a1 != b1:
                return false
            for i in 0..a1:
                if not self.types_identical(self.type_extra[(a0 + i)], self.type_extra[(b0 + i)]):
                    return false
            return true
        if kind == TypeKind.TY_GENERIC_INST:
            let count = self.get_generic_inst_arg_count(ar)
            if count != self.get_generic_inst_arg_count(br) or self.canonical_symbol_by_text(a0) != self.canonical_symbol_by_text(b0):
                return false
            for i in 0..count:
                if not self.types_identical(self.get_generic_inst_arg(ar, i), self.get_generic_inst_arg(br, i)):
                    return false
            return true
        if kind == TypeKind.TY_FN or kind == TypeKind.TY_EXTERN_FN:
            if a1 != b1 or self.callable_type_flags(ar) != self.callable_type_flags(br):
                return false
            for i in 0..a1:
                if not self.types_identical(self.type_extra[(a0 + i)], self.type_extra[(b0 + i)]):
                    return false
            return self.types_identical(self.get_type_d2(ar as TypeId), self.get_type_d2(br as TypeId))
        false

pub fn sema_generic_inst_hash(base_sym: i32, args: &Vec[i32], arg_count: i32) -> i64:
    var h: i64 = base_sym as i64
    for ai in 0..arg_count:
        h = (h *% 31) +% (args[ai] as i64)
    h

impl Sema:
    fn find_generic_inst_type(base_sym: i32, args: &Vec[i32], arg_count: i32) -> TypeId:
        let key = sema_generic_inst_hash(base_sym, args, arg_count)
        if self.generic_inst_cache.contains(key):
            let cached = self.generic_inst_cache.get(key).unwrap()
            if cached >= 0 and cached < self.type_kinds.len() as i32:
                if self.type_kinds[cached] == TypeKind.TY_GENERIC_INST:
                    let cached_base = self.type_d0[cached]
                    let canonical_base = self.canonical_symbol_by_text(base_sym)
                    if (cached_base == base_sym or self.canonical_symbol_by_text(cached_base) == canonical_base) and self.type_d2[cached] == arg_count:
                        let cached_start = self.type_d1[cached]
                        if self.type_extra_matches(cached_start, args, arg_count) != 0:
                            return cached as TypeId
        let canonical_base2 = self.canonical_symbol_by_text(base_sym)
        let type_count = self.type_kinds.len() as i32
        for ti in 0..type_count:
            if self.type_kinds[ti] != TypeKind.TY_GENERIC_INST:
                continue
            let seen_base = self.type_d0[ti]
            if seen_base != base_sym and self.canonical_symbol_by_text(seen_base) != canonical_base2:
                continue
            if self.type_d2[ti] != arg_count:
                continue
            let te_start = self.type_d1[ti]
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
            self.type_extra.push(args[ai])
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
            if self.type_kinds[ti] == TypeKind.TY_RANGE:
                if self.type_d0[ti] == elem_tid as i32:
                    if self.type_d1[ti] == inclusive:
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
            self.generic_enum_payload_cache_values.push(payloads[pi])
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

    // A generic inst whose template reflects fields/variants now but whose
    // caches were filled when it reflected none (see eager_type_caches_pass).
    fn generic_inst_prereg_pending(tid: i32) -> i32:
        if self.type_reflection_field_count(tid) > 0 and not self.generic_struct_field_index_type_cache.contains(sema_pair_key(tid, 0)):
            return 1
        if self.type_reflection_variant_count(tid) > 0:
            let first_variant = self.type_reflection_variant_name(tid, 0)
            if first_variant != 0 and not self.generic_enum_payload_cache_starts.contains(sema_pair_key(tid, first_variant)):
                return 1
        0

    mut fn preregister_mir_types():
        let vec_sym = self.syms.vec
        let vi_sym = self.syms.veciter
        let hashmap_sym = self.syms.hashmap
        let option_sym = self.syms.option

        // For every Vec[T] type registered, also register VecIter[T].
        // For every HashMap[K, V], register Option[V] so MIR/codegen can
        // materialize aggregate map-get results after type freezing.
        // #2000: each through ensure_generic_inst_type, which finds an
        // existing instance by identity. generic_inst_cache is a memo a
        // comptime evaluation empties (prepare_comptime_eval_copy); reading
        // its absence as "no such instance" made a second Option[i32] beside
        // the one a body had already joined at.
        let type_count = self.type_kinds.len() as i32
        for ti in 0..type_count:
            if self.type_kinds[ti] == TypeKind.TY_GENERIC_INST:
                if self.type_d0[ti] == vec_sym and self.type_d2[ti] >= 1:
                    let vi_args: Vec[i32] = Vec.new()
                    vi_args.push(self.type_extra[self.type_d1[ti]])
                    let _ = self.ensure_generic_inst_type(vi_sym, &vi_args, 1)
                if self.type_d0[ti] == hashmap_sym and self.type_d2[ti] >= 2:
                    let opt_args: Vec[i32] = Vec.new()
                    opt_args.push(self.type_extra[self.type_d1[ti] + 1])
                    let _ = self.ensure_generic_inst_type(option_sym, &opt_args, 1)

        // Vec[str] for str.split(), and VecIter[str] for its .iter().
        let str_args: Vec[i32] = Vec.new()
        str_args.push(self.ty_str as i32)
        let _vec_str = self.ensure_generic_inst_type(vec_sym, &str_args, 1)
        let _vi_str = self.ensure_generic_inst_type(vi_sym, &str_args, 1)

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
            var prereg_progress = false
            for lti in 0..lt_n:
                if not self.layout_size_cache.contains(lti):
                    let lt_sz = self.type_layout_size_of(lti)
                    let lt_al = self.type_layout_align_of(lti)
                    let lt_cp = self.is_copy(lti as TypeId)
                    let lt_nd = self.type_needs_drop(lti)
                    let lt_uw = self.try_unwrapped_type(lti)
                    // A loop over this type binds these element views (`&T`, a map
                    // traversal tuple); build them while types are mutable. Each
                    // loop's element type itself is for_elem_types (D65).
                    self.infer_for_element_type(lti)
                    if self.type_kinds[lti] == TypeKind.TY_GENERIC_INST:
                        self.preregister_generic_struct_fields(lti)
                        self.preregister_generic_enum_payloads(lti)
                    self.layout_size_cache.insert(lti, lt_sz)
                    self.layout_align_cache.insert(lti, lt_al)
                    self.is_copy_cache.insert(lti, lt_cp)
                    self.needs_drop_result_cache.insert(lti, lt_nd)
                    self.unwrapped_type_cache.insert(lti, lt_uw)
                    let field_count = self.type_reflection_field_count(lti)
                    for fi in 0..field_count:
                        self.layout_field_offset_cache.insert(sema_pair_key(lti, fi), self.type_layout_struct_field_offset(lti, fi))
                    // #1964: codegen builds a tuple's body at these offsets.
                    if self.type_kinds[lti] == TypeKind.TY_TUPLE:
                        for ei in 0..self.type_d1[lti]:
                            self.layout_field_offset_cache.insert(sema_pair_key(lti, ei), self.type_layout_tuple_elem_offset(lti, ei))
            // #742: an inst first cached while its template was not yet
            // resolvable (an import-gated std generic reached through a method
            // return, #911) registered zero fields. Visibility can be
            // established by caching a LATER type in this same pass, so sweep
            // after the pass, not inside it, and pass again while a sweep fills
            // something — codegen's frozen read must never miss. The
            // compute-on-miss fallback that used to repair this at codegen time
            // was a mutable Sema re-entry after freeze.
            for pti in 0..lt_n:
                if self.type_kinds[pti] == TypeKind.TY_GENERIC_INST and self.generic_inst_prereg_pending(pti) != 0:
                    self.preregister_generic_struct_fields(pti)
                    self.preregister_generic_enum_payloads(pti)
                    prereg_progress = true
            if self.type_kinds.len() as i32 == lt_n and not prereg_progress:
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
        if self.atomic_payload_type_is_valid(args[0]) == 0:
            self.emit_error("Atomic[T] requires integer or pointer T", node)
            return 0
        1

    mut fn resolve_generic_type(node: i32) -> i32:
        var gi_base_sym = self.ast.get_data0(node)
        if self.is_vector_symbol(gi_base_sym) or self.is_mask_symbol(gi_base_sym):
            let vg_count = self.ast.get_data2(node)
            let vg_start = self.ast.get_data1(node)
            let vg_a0 = if vg_count > 0: self.ast.get_extra(vg_start) else: 0
            let vg_a1 = if vg_count > 1: self.ast.get_extra(vg_start + 1) else: 0
            return self.resolve_vector_generic(gi_base_sym, vg_count, vg_a0, vg_a1, node)
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
            if self.private_symbol_path_from_current(gi_base_sym).len() > 0:
                self.emit_private_symbol_error(gi_base_sym, node)
                return 0
            let gi_gate_note = self.std_gated_import_note(gi_base_sym)
            if gi_gate_note.len() > 0:
                self.emit_error("'" ++ self.pool_resolve_symbol(gi_base_sym) ++ "' requires an explicit import (§18.1)" ++ gi_gate_note, node)
                return 0
            if not self.type_decl_nodes.contains(gi_base_sym):
                if self.require_alloc_tier_for_symbol(gi_base_sym, node) == 0:
                    return 0
                if self.require_std_tier_for_symbol(gi_base_sym, node) == 0:
                    return 0
                // While the type declarations are being collected, a generic
                // declared further down is not registered yet: defer, as a
                // plain named type does (resolve_type_expr). The deferred pass
                // (resolve_deferred_non_generic_type_decls) resolves the slot
                // once every declaration is in, and reports a name that is
                // still unknown then (#1440: declaration order must not
                // matter).
                if self.collecting_types != 0:
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
        let inst = self.ensure_generic_inst_type(gi_base_sym, gi_args, gi_arg_count) as i32
        if inst != 0 and gi_base_tid != 0 and not self.generic_inst_templates.contains(inst):
            self.generic_inst_templates.insert(inst, gi_base_tid)
        inst

    // The inst accessors are kind-guarded: reading base/count/args from a
    // NON-inst type returned whatever number lived in its d-slots — garbage
    // that happened to be harmless under one type-table layout and a live
    // type id under another (#682-inc1 bring-up: a pending unannotated
    // `Vec.new()` receiver typed push literals as u7 through exactly this).
    fn get_generic_inst_base(tid: i32) -> i32:
        if self.get_type_kind(tid as TypeId) != TypeKind.TY_GENERIC_INST:
            return 0
        self.get_type_d0(tid)

    // The template declaration's tid of a generic instance (#751, #1745):
    // the one recorded when the instance was resolved, else the symbol's
    // template as reflection finds it (an instance minted without a type
    // expression — an intrinsic's result, a builtin container).
    fn generic_inst_template_tid(tid: i32) -> i32:
        let resolved = self.resolve_alias(tid as TypeId) as i32
        if self.get_type_kind(resolved as TypeId) != TypeKind.TY_GENERIC_INST:
            return 0
        if self.generic_inst_templates.contains(resolved):
            return self.generic_inst_templates.get(resolved).unwrap()
        // #1647 / #1745: only a generic declaration can be an instance's
        // template. Name visibility from wherever the question is asked (a
        // user module's `type PullCore { .. }` beside std.task's private
        // `PullCore[G]`) must not pick a non-generic namesake.
        let base_sym = self.get_type_d0(resolved)
        var generic_only = 0
        var i = self.named_type_candidate_head(base_sym)
        while i >= 0:
            let candidate_tid = self.resolve_alias(self.named_type_candidate_tids[i] as TypeId) as i32
            let decl = self.type_decl_nodes_by_tid.get(candidate_tid) ?? 0
            if decl != 0 and self.type_decl_tp_count(decl) > 0 and candidate_tid != generic_only:
                if generic_only != 0:
                    generic_only = -1
                    break
                generic_only = candidate_tid
            i = self.named_type_candidate_next[i]
        if generic_only > 0:
            return generic_only
        self.type_reflection_base_template(base_sym)

    // The declaring node of a generic instance's template: by the recorded
    // template's identity first; the flat symbol-keyed map (the newest
    // declaration of that name in any module) only for an instance with no
    // recorded template.
    fn generic_inst_decl_node(tid: i32) -> i32:
        let resolved = self.resolve_alias(tid as TypeId) as i32
        let template = self.generic_inst_template_tid(resolved)
        if template != 0:
            let template_resolved = self.resolve_alias(template as TypeId) as i32
            if self.type_decl_nodes_by_tid.contains(template_resolved):
                return self.type_decl_nodes_by_tid.get(template_resolved).unwrap()
        var base_sym = self.get_generic_inst_base(resolved)
        if base_sym == 0:
            return 0
        if not self.type_decl_nodes.contains(base_sym):
            let canonical = self.canonical_symbol_by_text(base_sym)
            if canonical != 0 and self.type_decl_nodes.contains(canonical):
                base_sym = canonical
        if self.type_decl_nodes.contains(base_sym): self.type_decl_nodes.get(base_sym).unwrap() else: 0

    fn get_generic_inst_arg_count(tid: i32) -> i32:
        if self.get_type_kind(tid as TypeId) != TypeKind.TY_GENERIC_INST:
            return 0
        self.get_type_d2(tid)

    fn get_generic_inst_arg(tid: i32, index: i32) -> i32:
        if self.get_type_kind(tid as TypeId) != TypeKind.TY_GENERIC_INST:
            return 0
        let extra_start = self.get_type_d1(tid)
        self.type_extra[(extra_start + index)]

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

    // An integer or float type itself. A `repr` enum is numeric to an
    // operator (numeric_operand_type) but is not a number an untyped literal
    // may become: `[0, K.A]` stays an array of integers, never of `K`
    // (D71: a discriminant enum is made from an integer with `from_int`).
    fn is_plain_numeric_type(tid: i32) -> bool:
        let kind = self.get_type_kind(self.resolve_alias(tid as TypeId))
        kind == TypeKind.TY_INT or kind == TypeKind.TY_FLOAT

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

    // The literal suffix that spells primitive numeric type `tid`, or
    // LiteralSuffix.None for any other type (an enum, a distinct type).
    fn literal_suffix_for_type(tid: i32) -> i32:
        if tid == 0:
            return LiteralSuffix.None
        let resolved = self.resolve_alias(tid as TypeId)
        for suffix in LiteralSuffix.I8 as i32..LiteralSuffix.F64 as i32 + 1:
            let spelled = self.literal_suffix_type(suffix)
            if spelled != 0 and self.resolve_alias(spelled as TypeId) == resolved:
                return suffix
        LiteralSuffix.None

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

    // #943 / #914 D2: does this literal fit `tid` when it is the magnitude of
    // a negation? The positive and negative ranges are not symmetric — at
    // `bits` the largest magnitude is 2^(bits-1) negative but 2^(bits-1)-1
    // positive — so MIN is expressible only through this path.
    fn int_literal_fits_type_negated(node: i32, tid: i32) -> bool:
        let resolved = self.resolve_alias(tid as TypeId)
        let kind = self.get_type_kind(resolved)
        if kind == TypeKind.TY_FLOAT:
            return true
        if kind != TypeKind.TY_INT:
            return false
        if self.get_type_d1(resolved) == 0:
            // Unsigned: negation is rejected by check_unary with its own
            // message. Defer to the ordinary check so the diagnostic stays
            // "cannot negate an unsigned value" rather than a fit error.
            return self.int_literal_fits_type(node, tid)
        let bits = self.get_type_d0(resolved)
        if self.ast.has_int_literal_exact(node as NodeId):
            return exact_int_fits_signed_negative_bits(self.ast.int_literal_exact_value(node as NodeId), bits)
        let value = self.ast.int_lit_value(node as NodeId)
        if value < 0:
            return self.int_literal_fits_type(node, tid)
        if bits >= 64:
            return true
        exact_int_uword_lte(value, exact_int_pow2_word(bits - 1))

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
        else if not (if self.in_negated_literal_context != 0: self.int_literal_fits_type_negated(node, expected) else: self.int_literal_fits_type(node, expected)):
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

pub fn sema_node_is_numeric_literal(ast: AstPool, node: i32) -> bool:
    if node == 0:
        return false
    let kind = ast.kind(node)
    kind == NodeKind.NK_INT_LIT or kind == NodeKind.NK_FLOAT_LIT

// A bitwise operand written as an int literal under grouping and `~` wrappers
// (`(~1)`, `~0x3c`) adapts to the other operand's integer type exactly like a
// bare literal; the mixed-signedness rule is for concretely typed operands.
pub fn sema_node_is_bitwise_adaptable_literal(ast: AstPool, node: i32) -> bool:
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
        // D102 (§16.6): an `extern "C" fn` is never null; the nullable form is
        // `Option` of it, which is_option_pointer_type admits.
        if kind == TypeKind.TY_PTR or self.is_option_pointer_type(resolved) != 0:
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
            return ok_payloads[0]
        let some_payloads = self.enum_variant_payload_types(tid, self.syms.some)
        if some_payloads.len() as i32 == 1:
            return some_payloads[0]
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
                let subst_sym = subst_syms[si]
                if subst_sym == d0:
                    return subst_tids[si]
            let d0_text = self.pool_resolve_symbol(d0)
            if d0_text.len() == 0:
                return tid
            var found = 0
            var found_count = 0
            for si2 in 0..count:
                let subst_sym2 = subst_syms[si2]
                if self.pool_resolve_symbol(subst_sym2) == d0_text:
                    found = subst_tids[si2]
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
            let subbed_inst = self.ensure_generic_inst_type(d0, sub_args, gi_ac) as i32
            // The substituted instance is of the same declaration.
            if subbed_inst != 0 and self.generic_inst_templates.contains(tid) and not self.generic_inst_templates.contains(subbed_inst):
                self.generic_inst_templates.insert(subbed_inst, self.generic_inst_templates.get(tid).unwrap())
            return subbed_inst
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
                let orig = self.type_extra[(te_start_orig + ei)]
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
        self.type_kinds[tid]

    fn get_type_name_for_lsp(tid: i32) -> str:
        if tid <= 0 or tid >= self.type_kinds.len() as i32:
            return ""
        let kind = self.type_kinds[tid]
        if kind == TypeKind.TY_STR:
            return "str"
        if kind == TypeKind.TY_INT:
            return "i32"
        if kind == TypeKind.TY_FLOAT:
            return "f64"
        if kind == TypeKind.TY_BOOL:
            return "bool"
        if kind == TypeKind.TY_STRUCT or kind == TypeKind.TY_ENUM or kind == TypeKind.TY_ALIAS or kind == TypeKind.TY_GENERIC_INST:
            return with_str_clone_ref(self.pool_resolve(self.type_d0[tid]))
        ""

    fn get_type_d0(tid: TypeId) -> i32:
        if tid < 0 or tid >= self.type_d0.len() as i32:
            return 0
        self.type_d0[tid]

    fn get_type_d1(tid: TypeId) -> i32:
        if tid < 0 or tid >= self.type_d1.len() as i32:
            return 0
        self.type_d1[tid]

    fn get_type_d2(tid: TypeId) -> i32:
        if tid < 0 or tid >= self.type_d2.len() as i32:
            return 0
        self.type_d2[tid]

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

    fn type_is_c_va_list(tid: i32) -> i32:
        if tid == 0:
            return 0
        if self.get_type_kind(self.resolve_alias(tid as TypeId)) == TypeKind.TY_VA_LIST: 1 else: 0

    // Only C's array-decay mode aliases the caller's storage. The indirect
    // struct mode keeps value semantics and codegen supplies its copy.
    fn callable_type_resolved(tid: i32) -> i32:
        var resolved = self.resolve_alias(tid)
        var kind = self.get_type_kind(resolved)
        if kind == TypeKind.TY_PTR or kind == TypeKind.TY_REF:
            resolved = self.resolve_alias(self.get_type_d0(resolved))
            kind = self.get_type_kind(resolved)
        if kind == TypeKind.TY_FN or kind == TypeKind.TY_EXTERN_FN: resolved else: 0

    fn type_uses_c_va_list_place(tid: i32) -> i32:
        if self.type_is_c_va_list(tid) != 0 and fn_abi_c_va_list_uses_caller_place(target_spec_os(), target_spec_arch()): 1 else: 0

    fn callable_param_uses_value_ref_abi(tid: i32, pi: i32) -> i32:
        let resolved = self.callable_type_resolved(tid)
        if resolved == 0 or pi < 0 or pi >= self.get_type_d1(resolved): return 0
        self.type_uses_c_va_list_place(self.type_extra[self.get_type_d0(resolved) + pi])

    fn sig_param_is_c_va_list_by_place(sig_idx: i32, pi: i32) -> i32:
        self.type_uses_c_va_list_place(self.sig_param_type(sig_idx, pi))

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

    // A reference views its pointee in place and cannot convert it (§4.2.6
    // converts values): a `&i32` accepted as `&i64` read eight bytes of a
    // four-byte place, and a `&u32` as `&i32` rereads the bits with the other
    // sign. The numeric pointees of two references must have one layout.
    fn ref_numeric_pointees_differ(exp_r: i32, act_r: i32) -> i32:
        let ep = self.resolve_alias(self.get_type_d0(exp_r) as TypeId)
        let ap = self.resolve_alias(self.get_type_d0(act_r) as TypeId)
        let ek = self.get_type_kind(ep)
        let ak = self.get_type_kind(ap)
        if ek == TypeKind.TY_INT and ak == TypeKind.TY_INT:
            return if self.get_type_d0(ep) != self.get_type_d0(ap) or self.get_type_d1(ep) != self.get_type_d1(ap): 1 else: 0
        if ek == TypeKind.TY_FLOAT and ak == TypeKind.TY_FLOAT:
            return if self.get_type_d0(ep) != self.get_type_d0(ap): 1 else: 0
        if (ek == TypeKind.TY_INT and ak == TypeKind.TY_FLOAT) or (ek == TypeKind.TY_FLOAT and ak == TypeKind.TY_INT): 1 else: 0

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
        let start: i32 = self.scope_starts[len - 1]
        // Expire borrows for bindings leaving scope
        self.expire_borrows_in_scope(start)
        // Remove bindings from map and parallel arrays
        let reported_pending_calls: Vec[i32] = Vec.new()
        while self.bind_names.len() as i32 > start:
            let removed_sym: i32 = self.bind_names[self.bind_names.len() - 1]
            let removed_node = self.binding_decl_node(removed_sym)
            self.check_live_views_for_origin(removed_sym, removed_node)
            self.poison_live_views_for_origin(removed_sym, removed_node)
            if self.pending_generic_binding_base.contains(removed_sym):
                let pending_call = if self.pending_generic_binding_call.contains(removed_sym): self.pending_generic_binding_call.get(removed_sym).unwrap() else: 0
                let report_key = if pending_call != 0: pending_call else: removed_sym
                var already_reported = 0
                for rpi in 0..reported_pending_calls.len() as i32:
                    if reported_pending_calls[rpi] == report_key:
                        already_reported = 1
                if already_reported == 0:
                    reported_pending_calls.push(report_key)
                    self.emit_pending_generic_binding_error(removed_sym)
                self.pending_generic_binding_base.remove(removed_sym)
                self.pending_generic_binding_call.remove(removed_sym)
                self.pending_generic_binding_decl.remove(removed_sym)
            self.clear_moved_fields_for_binding(removed_sym)
            self.scope_name_map.remove(removed_sym)
            let shadow_top = self.shadowed_global_syms.len() as i32 - 1
            if shadow_top >= 0 and self.shadowed_global_syms[shadow_top] == removed_sym:
                self.scope_name_map.insert(removed_sym, self.shadowed_global_indices[shadow_top])
                self.shadowed_global_syms.pop()
                self.shadowed_global_indices.pop()
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
            self.dyn_downcast_binding_syms.remove(removed_sym)
            self.clear_binding_view_deps(removed_sym)
        self.scope_starts.pop()

    fn is_discard_binding_symbol(sym: i32) -> i32:
        if sym == 0:
            return 1
        if self.discard_sym != 0 and sym == self.discard_sym:
            return 1
        0

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

    // §9.5 (#1930), §29.8: in its type's own module's instance method a
    // receiver field is in scope by its bare name, so a parameter or local
    // binding of that name would shadow it.
    mut fn refuse_receiver_field_shadow(sym: i32, node: i32):
        if self.receiver_field_owner == 0 or not self.ast.receiver_type_has_field(self.receiver_field_owner, sym):
            return
        let name: str = with_str_clone_ref(self.pool_resolve(sym))
        let owner: str = with_str_clone_ref(self.pool_resolve(self.ast.get_data0(self.receiver_field_owner)))
        self.receiver_field_shadowed.insert(sym, 1)
        // A destructuring shorthand binds the field's own name: bind it under
        // another (`{ repr: r }`).
        let fix = if self.ast.kind(node) == NodeKind.NK_PAT_STRUCT: f"bind the field under another name, e.g. `{name}: {name.slice(0, 1)}`" else: f"rename the binding, e.g. `new_{name}`"
        self.emit_error_with_help(f"shadowing is not allowed for '{name}': it names a field of the receiver `{owner}`, which this method reaches by its bare name (§9.5)", node, f"{fix}; the field is `{name}` or `self.{name}`")


    mut fn scope_put_at(sym: i32, tid: i32, is_mut: i32, node: i32):
        if self.is_discard_binding_symbol(sym) != 0:
            return
        self.refuse_receiver_field_shadow(sym, node)
        let existing = self.scope_name_map.get(sym)
        if existing.is_some():
            let idx: i32 = existing.unwrap()
            if self.binding_is_unseen_global(idx, sym):
                self.shadow_unseen_global(sym, idx, tid, is_mut)
                return
            let name: str = with_str_clone_ref(self.pool_resolve(sym))
            self.emit_error("shadowing is not allowed for '" ++ name ++ "'" ++ self.shadowed_binding_origin_note(sym, idx), node)
            return
        if self.scope_lookup(sym) >= 0:
            let name: str = with_str_clone_ref(self.pool_resolve(sym))
            self.emit_error("shadowing is not allowed for '" ++ name ++ "'" ++ self.shadowed_binding_origin_note(sym, if existing.is_some(): existing.unwrap() else: -1), node)
            return
        self.scope_insert_at(sym, tid, is_mut)

    // A flat-scope global of a module the current one never imports is not
    // in scope here (§18.1: the walk over explicit import edges, never the
    // prelude's closure — through it every program reaches std.regex's
    // engine), so a local may take its name; with the current module
    // unknown (the comptime pre-pass) the local wins as well — the main
    // pass reports a true same-module shadowing. Every other collision — a
    // local, or a global the module imports — is shadowing.
    fn binding_is_unseen_global(idx: i32, sym: i32) -> bool:
        // A bundle interface's global (a corpus' `pub let`, std.re's PACKAGE)
        // is another module's declaration by construction.
        if self.interface_global_index.contains(sym) and self.interface_global_index.get(sym).unwrap() == idx:
            return true
        for ai in 0..self.interface_global_alt_binds.len() as i32:
            if self.interface_global_alt_binds[ai] == idx:
                return true
        if not self.global_value_decl_bindings.contains(sym) or self.global_value_decl_bindings.get(sym).unwrap() != idx:
            return false
        let path = self.global_value_decl_paths.get(sym).unwrap()
        // §18.2 name precedence: a current-module declaration (tier 2) beats
        // an explicit import (tier 3), so a global another module declared —
        // seen or not — is shadowed by this module's own declaration of the
        // name (#1703: std.re's `pub let PACKAGE` vs a program's
        // `const PACKAGE`), never a "shadowing is not allowed" error.
        self.current_module_path.len() == 0 or path != self.current_module_path

    // A flat-scope global (§9.1c, D52) — a module's `let`/`var`, or a
    // bundle interface's storage — is referenced in place by every body,
    // a closure's included: it is never a capture (#1313). A local that
    // shadows an unseen global holds the same symbol at another index.
    fn binding_index_is_global(idx: i32, sym: i32) -> bool:
        if self.global_value_decl_bindings.contains(sym):
            let bind: i32 = self.global_value_decl_bindings.get(sym).unwrap()
            if bind == idx: return true
        if self.interface_global_index.contains(sym):
            let bind: i32 = self.interface_global_index.get(sym).unwrap()
            if bind == idx: return true
        for ai in 0..self.interface_global_alt_binds.len() as i32:
            if self.interface_global_alt_binds[ai] == idx: return true
        false

    // The local takes the name; pop_scope gives the global its slot back.
    mut fn shadow_unseen_global(sym: i32, global_idx: i32, tid: i32, is_mut: i32):
        self.shadowed_global_syms.push(sym)
        self.shadowed_global_indices.push(global_idx)
        self.scope_insert_at(sym, tid, is_mut)

    mut fn scope_put_consuming_rebind_at(sym: i32, tid: i32, is_mut: i32, node: i32) -> i32:
        if self.is_discard_binding_symbol(sym) != 0:
            return 1
        self.refuse_receiver_field_shadow(sym, node)
        let existing = self.scope_name_map.get(sym)
        if not existing.is_some():
            self.scope_insert_at(sym, tid, is_mut)
            return 1
        let idx: i32 = existing.unwrap()
        if self.binding_is_unseen_global(idx, sym):
            self.shadow_unseen_global(sym, idx, tid, is_mut)
            return 1
        let current_start = if self.scope_starts.len() > 0: self.scope_starts[(self.scope_starts.len() - 1)] else: 0
        if idx < current_start or self.bind_states[idx] != VarState.MOVED:
            let name: str = with_str_clone_ref(self.pool_resolve(sym))
            self.emit_error("shadowing is not allowed for '" ++ name ++ "'" ++ self.shadowed_binding_origin_note(sym, if existing.is_some(): existing.unwrap() else: -1), node)
            return 0
        self.bind_types[idx] = tid
        self.bind_muts[idx] = is_mut
        self.bind_states[idx] = VarState.LIVE
        self.bind_is_task[idx] = 0
        self.bind_task_used[idx] = 0
        self.bind_is_scoped_task[idx] = 0
        self.bind_is_view_bound[idx] = 0
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
        // A bundle interface's storage and constants (D39) are reachable
        // only through an import, so they stay out of the flat global scope:
        // pcre2's NULL, BUFSIZ or CHAR_MAX reach every program through the
        // prelude's std.regex and would otherwise collide with any program's
        // own — a c_import's NULL, a local named stdout.
        let decl_path = self.decl_source_path_for_node(node)
        if bundle_interface_text(decl_path).len() > 0:
            // One binding per declaring module: the first declaring module
            // takes the primary slot, every other one an alternate row
            // (pcre2's and zlib's UINT_MAX); a repeat from the same module
            // is the same declaration collected again.
            var known = false
            if self.interface_global_index.contains(sym):
                known = self.interface_global_paths.get(sym).unwrap() == decl_path
                if not known:
                    for ai in 0..self.interface_global_alt_syms.len() as i32:
                        if self.interface_global_alt_syms[ai] == sym and self.interface_global_alt_paths[ai] == decl_path:
                            known = true
            if not known:
                let bind_index = self.bind_names.len() as i32
                if not self.interface_global_index.contains(sym):
                    self.interface_global_index.insert(sym, bind_index)
                    self.interface_global_paths.insert(sym, sema_owned_text(decl_path))
                else:
                    self.interface_global_alt_syms.push(sym)
                    self.interface_global_alt_binds.push(bind_index)
                    self.interface_global_alt_paths.push(sema_owned_text(decl_path))
                self.bind_names.push(sym)
                self.bind_types.push(tid)
                self.bind_muts.push(is_mut)
                self.bind_states.push(VarState.LIVE)
                self.bind_is_task.push(0)
                self.bind_task_used.push(0)
                self.bind_is_scoped_task.push(0)
                self.bind_is_view_bound.push(0)
                self.bind_provenance.push(binding_provenance_empty())
                self.global_value_decl_kinds.insert(sym, decl_kind)
            return
        let existing_opt = self.scope_name_map.get(sym)
        if not existing_opt.is_some():
            self.global_value_decl_bindings.insert(sym, self.bind_names.len() as i32)
            self.scope_insert_at(sym, tid, is_mut)
            self.global_value_decl_kinds.insert(sym, decl_kind)
            self.global_value_decl_paths.insert(sym, sema_owned_text(decl_path))
            return

        let existing_idx: i32 = existing_opt.unwrap()
        let existing_kind = self.global_value_decl_kind(sym)
        if existing_kind == 0:
            let name: str = with_str_clone_ref(self.pool_resolve(sym))
            self.emit_error("shadowing is not allowed for '" ++ name ++ "'" ++ self.shadowed_binding_origin_note(sym, existing_idx), node)
            return

        // Only an extern declaration may coexist with another declaration of
        // the same global; two definitions, or a definition beside interface
        // storage (D39), is one symbol declared twice.
        if existing_kind != GLOBAL_VALUE_DECL_EXTERN and decl_kind != GLOBAL_VALUE_DECL_EXTERN:
            let name: str = with_str_clone_ref(self.pool_resolve(sym))
            self.emit_error("shadowing is not allowed for '" ++ name ++ "'" ++ self.shadowed_binding_origin_note(sym, existing_idx), node)
            return

        let existing_mut = self.bind_muts[existing_idx]
        if existing_mut != is_mut:
            let name: str = with_str_clone_ref(self.pool_resolve(sym))
            self.emit_error("conflicting global declaration for '" ++ name ++ "'", node)
            return

        let existing_tid = self.bind_types[existing_idx]
        if self.global_value_decl_types_compatible(existing_tid, tid) == 0:
            let name: str = with_str_clone_ref(self.pool_resolve(sym))
            self.emit_error("conflicting global declaration for '" ++ name ++ "'", node)
            return

        if existing_tid == 0 and tid != 0:
            self.bind_types[existing_idx] = tid

        if existing_kind == GLOBAL_VALUE_DECL_EXTERN and decl_kind != GLOBAL_VALUE_DECL_EXTERN:
            self.global_value_decl_kinds.insert(sym, decl_kind)

    fn scope_lookup(sym: i32) -> i32:
        let opt = self.scope_name_map.get(sym)
        if opt.is_some():
            return self.bind_types[opt.unwrap()]
        // An interface global resolves only from a known module that
        // imports its own by an explicit path (never through the prelude's
        // closure, and never in the comptime pre-pass, where the module is
        // unknown): a program's const of the same name must win.
        let iface = self.interface_global_index.get(sym)
        if iface.is_some() and self.current_module_path.len() > 0:
            if self.module_visible_no_prelude(self.interface_global_paths.get(sym).unwrap()) != 0:
                return self.bind_types[iface.unwrap()]
            // The same name from another bundle's module (pcre2's and
            // zlib's UINT_MAX): the one this module imports.
            for ai in 0..self.interface_global_alt_syms.len() as i32:
                if self.interface_global_alt_syms[ai] == sym and self.module_visible_no_prelude(self.interface_global_alt_paths[ai]) != 0:
                    return self.bind_types[self.interface_global_alt_binds[ai]]
        -1

    mut fn scope_update_type(sym: i32, tid: i32):
        let opt = self.scope_name_map.get(sym)
        if opt.is_some():
            let idx: i32 = opt.unwrap()
            self.bind_types[idx] = tid
        for ii in 0..self.implicit_binding_syms.len() as i32:
            if self.implicit_binding_syms[ii] == sym:
                self.implicit_binding_types[ii] = tid

    // Whether `sym` currently names a parameter or a local: a binding made
    // inside any scope below the module-level one.
    fn scope_binding_is_local(sym: i32) -> bool:
        let opt = self.scope_name_map.get(sym)
        opt.is_some() and self.scope_starts.len() > 1 and opt.unwrap() >= self.scope_starts[1]

    fn scope_lookup_mut(sym: i32) -> i32:
        let opt = self.scope_name_map.get(sym)
        if opt.is_some():
            return self.bind_muts[opt.unwrap()]
        0

    fn scope_lookup_state(sym: i32) -> i32:
        let opt = self.scope_name_map.get(sym)
        if opt.is_some():
            return self.bind_states[opt.unwrap()]
        VarState.LIVE

    fn moved_field_path_matches(idx: i32, base_sym: i32, path_start: i32, path_count: i32) -> i32:
        if idx < 0 or idx >= self.moved_field_base_syms.len() as i32:
            return 0
        if self.moved_field_base_syms[idx] != base_sym:
            return 0
        if self.moved_field_path_counts[idx] != path_count:
            return 0
        let stored_start = self.moved_field_path_starts[idx]
        for pi in 0..path_count:
            if self.moved_field_path_syms[(stored_start + pi)] != self.borrow_path_data[(path_start + pi)]:
                return 0
        1

    fn moved_field_path_has_prefix(idx: i32, base_sym: i32, path_start: i32, path_count: i32) -> i32:
        if idx < 0 or idx >= self.moved_field_base_syms.len() as i32:
            return 0
        if self.moved_field_base_syms[idx] != base_sym:
            return 0
        let stored_count = self.moved_field_path_counts[idx]
        if stored_count < path_count:
            return 0
        let stored_start = self.moved_field_path_starts[idx]
        for pi in 0..path_count:
            if self.moved_field_path_syms[(stored_start + pi)] != self.borrow_path_data[(path_start + pi)]:
                return 0
        1

    // The field path an expression names, rooted at a scoped binding, as a
    // record: base_sym 0 when it names none. #1631: this was one i64 with
    // path_start in 16 bits (and its overflow leaking into path_count), but
    // borrow_path_data is append-only for the whole compilation and passes
    // 65535 entries in any compiler-sized check; a masked start then read a
    // stale path, and a sibling field read after `move s.f` was "use of
    // moved value" whenever the stale bytes held `f`'s symbol — a verdict
    // that flipped with unrelated source text (src/main.w:3003 on one tree,
    // :2008 on another).
    fn field_move_path_for_expr(node: i32) -> FieldMovePath:
        let none = FieldMovePath { base_sym: 0, path_start: 0, path_count: 0 }
        let base_sym = self.place_root_sym(node)
        if base_sym == 0:
            return none
        if self.scope_has(base_sym) == 0:
            return none
        let path_start = self.borrow_path_data.len() as i32
        let path_count = self.borrow_collect_path(node)
        if path_count <= 0:
            return none
        FieldMovePath { base_sym, path_start, path_count }

    fn mark_field_moved(node: i32):
        let path = self.field_move_path_for_expr(node)
        if path.base_sym == 0:
            return
        let base_sym = path.base_sym
        let path_start = path.path_start
        let path_count = path.path_count
        for i in 0..self.moved_field_base_syms.len() as i32:
            if self.moved_field_path_matches(i, base_sym, path_start, path_count) != 0:
                return
        let stored_start = self.moved_field_path_syms.len() as i32
        for pi in 0..path_count:
            self.moved_field_path_syms.push(self.borrow_path_data[(path_start + pi)])
        self.moved_field_base_syms.push(base_sym)
        self.moved_field_path_starts.push(stored_start)
        self.moved_field_path_counts.push(path_count)
        if self.marking_explicit_move != 0:
            self.explicitly_partial_syms.insert(base_sym, 1)

    fn field_is_moved(node: i32) -> i32:
        let path = self.field_move_path_for_expr(node)
        if path.base_sym == 0:
            return 0
        let base_sym = path.base_sym
        let path_start = path.path_start
        let path_count = path.path_count
        for i in 0..self.moved_field_base_syms.len() as i32:
            if self.moved_field_path_matches(i, base_sym, path_start, path_count) != 0:
                return 1
        0

    mut fn remove_moved_field_entry(idx: i32):
        let last = self.moved_field_base_syms.len() as i32 - 1
        if idx < 0 or idx > last:
            return
        if idx != last:
            self.moved_field_base_syms[idx] = self.moved_field_base_syms[last]
            self.moved_field_path_starts[idx] = self.moved_field_path_starts[last]
            self.moved_field_path_counts[idx] = self.moved_field_path_counts[last]
        self.moved_field_base_syms.pop()
        self.moved_field_path_starts.pop()
        self.moved_field_path_counts.pop()

    // #782: whether any field path rooted at this binding is currently
    // moved-out (the whole value is no longer intact).
    fn binding_has_moved_field(sym: i32) -> i32:
        for i in 0..self.moved_field_base_syms.len() as i32:
            if self.moved_field_base_syms[i] == sym:
                return 1
        0

    // First moved field's leaf sym for diagnostics (0 when unknown).
    fn first_moved_field_sym(sym: i32) -> i32:
        for i in 0..self.moved_field_base_syms.len() as i32:
            if self.moved_field_base_syms[i] == sym:
                let count: i32 = self.moved_field_path_counts[i]
                if count > 0:
                    let start: i32 = self.moved_field_path_starts[i]
                    return self.moved_field_path_syms[(start + count - 1)]
        0

    mut fn clear_moved_fields_for_binding(sym: i32):
        var i = self.moved_field_base_syms.len() as i32 - 1
        while i >= 0:
            if self.moved_field_base_syms[i] == sym:
                self.remove_moved_field_entry(i)
            i = i - 1
        let _ = self.explicitly_partial_syms.remove(sym)

    mut fn clear_moved_fields_for_place_expr(node: i32):
        let path = self.field_move_path_for_expr(node)
        if path.base_sym == 0:
            return
        let base_sym = path.base_sym
        let path_start = path.path_start
        let path_count = path.path_count
        var i = self.moved_field_base_syms.len() as i32 - 1
        while i >= 0:
            if self.moved_field_path_has_prefix(i, base_sym, path_start, path_count) != 0:
                self.remove_moved_field_entry(i)
            i = i - 1

    fn scope_lookup_is_task(sym: i32) -> i32:
        let opt = self.scope_name_map.get(sym)
        if opt.is_some():
            return self.bind_is_task[opt.unwrap()]
        0

    mut fn scope_mark_task_used(sym: i32):
        let opt = self.scope_name_map.get(sym)
        if opt.is_some():
            let idx: i32 = opt.unwrap()
            self.bind_task_used[idx] = 1

    fn scope_lookup_task_used(sym: i32) -> i32:
        let opt = self.scope_name_map.get(sym)
        if opt.is_some():
            return self.bind_task_used[opt.unwrap()]
        0

    mut fn scope_set_is_task(sym: i32, is_task: i32):
        let opt = self.scope_name_map.get(sym)
        if opt.is_some():
            let idx: i32 = opt.unwrap()
            self.bind_is_task[idx] = is_task

    fn scope_lookup_is_scoped_task(sym: i32) -> i32:
        let opt = self.scope_name_map.get(sym)
        if opt.is_some():
            return self.bind_is_scoped_task[opt.unwrap()]
        0

    mut fn scope_set_is_scoped_task(sym: i32, is_scoped_task: i32):
        let opt = self.scope_name_map.get(sym)
        if opt.is_some():
            let idx: i32 = opt.unwrap()
            self.bind_is_scoped_task[idx] = is_scoped_task

    fn scope_lookup_is_ephemeral_task(sym: i32) -> i32:
        let opt = self.scope_name_map.get(sym)
        if opt.is_some():
            return self.bind_provenance[opt.unwrap()].is_ephemeral_task
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
            return self.bind_provenance[opt.unwrap()].is_non_send_task
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
            return self.bind_provenance[opt.unwrap()].is_ephemeral_value
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
            return self.bind_provenance[opt.unwrap()].effect_dep_sym
        0

    fn scope_is_view_bound(sym: i32) -> i32:
        let opt = self.scope_name_map.get(sym)
        if opt.is_some():
            return self.bind_is_view_bound[opt.unwrap()]
        0

    mut fn scope_set_is_view_bound(sym: i32):
        let opt = self.scope_name_map.get(sym)
        if opt.is_some():
            let idx: i32 = opt.unwrap()
            self.bind_is_view_bound[idx] = 1

    mut fn scope_set_state(sym: i32, state: i32):
        if sema_debug_move_enabled() != 0:
            let dbg_name = with_str_clone_ref(self.pool_resolve(sym))
            with_eprint(f"[state] sym=" ++ dbg_name ++ f" -> {state}")
        let opt = self.scope_name_map.get(sym).copied()
        if opt.is_some():
            if state == VarState.MOVED:
                self.check_live_views_for_origin(sym, self.move_site_node)
                self.clear_moved_fields_for_binding(sym)
            else if state == VarState.LIVE:
                self.clear_moved_fields_for_binding(sym)
            self.bind_states[opt.unwrap()] = state

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
            let start = self.move_control_flow_binding_starts[ci]
            if bind_idx < start and self.move_control_flow_supports_drop_flags[ci] == 0:
                return 1
            ci = ci + 1
        0

    // Snapshot current bind_states so early-returning if/else branches don't
    // permanently mark outer variables as MOVED.
    fn save_scope_states() -> Vec[i32]:
        let count = self.bind_states.len() as i32
        var snapshot: Vec[i32] = Vec.new()
        for i in 0..count:
            snapshot.push(self.bind_states[i])
        snapshot

    mut fn restore_scope_states(snapshot: &Vec[i32]):
        let count = snapshot.len() as i32
        for i in 0..count:
            self.bind_states[i] = snapshot[i]

    // #695: partial (field/index) move state lives in the moved_field_* parallel
    // arrays, SEPARATE from bind_states. check_if_expr / match / loop merge
    // bind_states across branches with divergence handling, but not these — so a
    // field moved on a divergent (returning) branch wrongly poisoned the
    // fall-through. These mirror save/restore/merge for the field-move set.
    // A placeholder snapshot for a slot filled only on some paths.
    fn empty_moved_field_state() -> MovedFieldSnap:
        MovedFieldSnap { base: Vec.new(), starts: Vec.new(), counts: Vec.new(), syms: Vec.new(), poison_syms: Vec.new(), poison_nodes: Vec.new() }

    fn save_moved_field_state() -> MovedFieldSnap:
        MovedFieldSnap {
            base: sema_clone_i32_vec(&self.moved_field_base_syms),
            starts: sema_clone_i32_vec(&self.moved_field_path_starts),
            counts: sema_clone_i32_vec(&self.moved_field_path_counts),
            syms: sema_clone_i32_vec(&self.moved_field_path_syms),
            poison_syms: self.snapshot_poison_syms(),
            poison_nodes: self.snapshot_poison_nodes(),
        }

    mut fn restore_moved_field_state(snap: &MovedFieldSnap):
        self.moved_field_base_syms = sema_clone_i32_vec(&snap.base)
        self.moved_field_path_starts = sema_clone_i32_vec(&snap.starts)
        self.moved_field_path_counts = sema_clone_i32_vec(&snap.counts)
        self.moved_field_path_syms = sema_clone_i32_vec(&snap.syms)
        self.restore_poison(&snap.poison_syms, &snap.poison_nodes)

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
    fn moved_field_entry_present(base: &Vec[i32], starts: &Vec[i32], counts: &Vec[i32], path_syms: &Vec[i32], base_sym: i32, src_start: i32, src_count: i32, src_syms: &Vec[i32]) -> bool:
        for i in 0..base.len() as i32:
            if base[i] != base_sym:
                continue
            if counts[i] != src_count:
                continue
            let dst_start = starts[i]
            var same = true
            for k in 0..src_count:
                if path_syms[(dst_start + k)] != src_syms[(src_start + k)]:
                    same = false
                    break
            if same:
                return true
        false

    mut fn set_moved_field_union(a: &MovedFieldSnap, b: &MovedFieldSnap):
        var base: Vec[i32] = Vec.new()
        var starts: Vec[i32] = Vec.new()
        var counts: Vec[i32] = Vec.new()
        var path_syms: Vec[i32] = Vec.new()
        for i in 0..a.base.len() as i32:
            starts.push(path_syms.len() as i32)
            counts.push(a.counts[i])
            base.push(a.base[i])
            let s = a.starts[i]
            let c = a.counts[i]
            for k in 0..c:
                path_syms.push(a.syms[(s + k)])
        for i in 0..b.base.len() as i32:
            let bs = b.starts[i]
            let bc = b.counts[i]
            if self.moved_field_entry_present(&base, &starts, &counts, &path_syms, b.base[i], bs, bc, &b.syms):
                continue
            starts.push(path_syms.len() as i32)
            counts.push(bc)
            base.push(b.base[i])
            for k in 0..bc:
                path_syms.push(b.syms[(bs + k)])
        self.moved_field_base_syms = move base
        self.moved_field_path_starts = move starts
        self.moved_field_path_counts = move counts
        self.moved_field_path_syms = move path_syms
        // Poisoned at the join iff poisoned at some non-divergent exit.
        var poison_syms: Vec[i32] = Vec.new()
        var poison_nodes: Vec[i32] = Vec.new()
        for i in 0..a.poison_syms.len() as i32:
            if a.poison_syms[i] != 0:
                poison_syms.push(a.poison_syms[i])
                poison_nodes.push(a.poison_nodes[i])
            else if i < b.poison_syms.len() as i32:
                poison_syms.push(b.poison_syms[i])
                poison_nodes.push(b.poison_nodes[i])
            else:
                poison_syms.push(0)
                poison_nodes.push(0)
        self.restore_poison(&poison_syms, &poison_nodes)

    fn snapshot_poison_syms() -> Vec[i32]:
        var out: Vec[i32] = Vec.new()
        for i in 0..self.bind_provenance.len() as i32:
            out.push(self.bind_provenance[i].poisoned_origin_sym)
        out

    fn snapshot_poison_nodes() -> Vec[i32]:
        var out: Vec[i32] = Vec.new()
        for i in 0..self.bind_provenance.len() as i32:
            out.push(self.bind_provenance[i].poisoned_origin_node)
        out

    mut fn restore_poison(path_syms: &Vec[i32], nodes: &Vec[i32]):
        for i in 0..path_syms.len() as i32:
            if i >= self.bind_provenance.len() as i32:
                break
            let slot_idx = i as i64
            with self.bind_provenance.slot(slot_idx) as mut slot:
                var provenance = slot.get()
                provenance.poisoned_origin_sym = path_syms[i]
                provenance.poisoned_origin_node = nodes[i]
                slot.set(provenance)

    // Conservative union of move-state across two control-flow branches, for the
    // MaybeUninitialized use-checking half (see docs/completed/branch-merge-soundness.md). A
    // binding is MOVED after the construct iff it is MOVED on ANY non-diverging
    // branch (so a value moved on one path cannot be used after — use-after-move
    // soundness); divergent branches (TY_NEVER) contribute nothing. If both branches
    // diverge the continuation is unreachable, so fall back to the entry state.
    fn merge_branch_move_states(entry: &Vec[i32], a: &Vec[i32], a_diverges: i32, b: &Vec[i32], b_diverges: i32) -> Vec[i32]:
        var out: Vec[i32] = Vec.new()
        let n = entry.len() as i32
        if a_diverges != 0 and b_diverges != 0:
            for i in 0..n:
                out.push(entry[i])
            return out
        for i in 0..n:
            var moved = 0
            if a_diverges == 0 and i < a.len() as i32 and a[i] == VarState.MOVED:
                moved = 1
            if b_diverges == 0 and i < b.len() as i32 and b[i] == VarState.MOVED:
                moved = 1
            out.push(if moved != 0: VarState.MOVED else: VarState.LIVE)
        out

    // Pointwise union for accumulating a join over N branches/arms (e.g. match): a
    // binding is MOVED in the result iff MOVED in either input. Seed the accumulator
    // with the entry state (the implicit no-match/fallthrough path) and fold each
    // non-diverging arm exit into it; see docs/completed/branch-merge-soundness.md.
    fn union_move_states(base: &Vec[i32], other: &Vec[i32]) -> Vec[i32]:
        var out: Vec[i32] = Vec.new()
        let n = base.len() as i32
        for i in 0..n:
            let bv = base[i]
            let ov = if i < other.len() as i32: other[i] else: VarState.LIVE
            out.push(if bv == VarState.MOVED or ov == VarState.MOVED: VarState.MOVED else: VarState.LIVE)
        out

    // ── Loop move-state (#613, docs/completed/branch-merge-soundness.md §6.7) ──────────────

    mut fn emit_loop_carried_move_error(bind_idx: i32, loop_node: i32):
        let sym = self.bind_names[bind_idx]
        let name: str = with_str_clone_ref(self.pool_resolve(sym))
        self.emit_error_with_help("use of moved value: `" ++ name ++ "` is moved inside a loop and not reinitialized before the loop repeats", loop_node, "reinitialize `" ++ name ++ "` on every path before the loop repeats, or move it only on a path that exits the loop")

    // Allocate this loop's break-flag region in loop_break_flat (called by each loop
    // construct after push_label_frame). One VarState slot per outer binding, init
    // LIVE; freed in finalize_loop_move_state.
    mut fn alloc_loop_break_region(frame_idx: i32):
        if frame_idx < 0 or frame_idx >= self.label_break_off.len() as i32:
            return
        let count: i32 = self.label_loop_entry_binds[frame_idx]
        self.label_break_off[frame_idx] = self.loop_break_flat.len() as i32
        var i = 0
        while i < count:
            self.loop_break_flat.push(VarState.LIVE)
            // Capture the loop-entry move-state (fresh push keeps loop_entry_flat in
            // lockstep with loop_break_flat, so label_break_off indexes both). A
            // binding already MOVED here was moved *before* the loop, not across a
            // back-edge — the continue check must not flag it (#696).
            let es = if i < self.bind_states.len() as i32: self.bind_states[i] else: VarState.LIVE
            self.loop_entry_flat.push(es)
            i = i + 1

    // At a `break`, union the current move-state of the target loop's outer bindings
    // into that loop's break-flag region (the union of move-states over all breaks to
    // that loop), used to compute the post-loop state.
    mut fn capture_loop_break_move_state(frame_idx: i32):
        if frame_idx < 0 or frame_idx >= self.label_break_off.len() as i32:
            return
        let off: i32 = self.label_break_off[frame_idx]
        if off < 0:
            return
        let boundary: i32 = self.label_loop_entry_binds[frame_idx]
        var i = 0
        while i < boundary:
            if i < self.bind_states.len() as i32 and self.bind_states[i] == VarState.MOVED and self.type_needs_drop(self.bind_types[i]) != 0:
                self.loop_break_flat[(off + i)] = VarState.MOVED
            i = i + 1
        self.label_break_seen[frame_idx] = 1

    // The ONE loop back-edge carried-move predicate. A binding is used moved on the
    // next iteration iff it was LIVE at loop entry but MOVED at the back-edge, and
    // its type needs drop (a moved-out POD value is a non-destructive copy today,
    // #607, so only Drop/transitive-Drop moves are errors). Both back-edges — the
    // fall-through (finalize_loop_move_state) and `continue`
    // (check_loop_continue_carried_move) — MUST call this; re-inlining the condition
    // per edge is exactly how #696 happened (the continue edge dropped the
    // entry==LIVE guard). `needs_drop` is passed in (callers already compute it) so
    // this stays a pure predicate. See docs/meetings/README.md.
    fn is_loop_carried_move(entry_state: i32, cur_state: i32, needs_drop: i32) -> i32:
        if entry_state == VarState.LIVE and cur_state == VarState.MOVED and needs_drop != 0: 1 else: 0

    // A `continue` jumps to the loop's back-edge: any outer binding moved (and not
    // reinitialized) at the continue would be used moved on the next iteration.
    mut fn check_loop_continue_carried_move(frame_idx: i32, node: i32):
        if frame_idx < 0 or frame_idx >= self.label_loop_entry_binds.len() as i32:
            return
        let boundary: i32 = self.label_loop_entry_binds[frame_idx]
        let off = if frame_idx < self.label_break_off.len() as i32: self.label_break_off[frame_idx] else: -1
        let trace_move = runtime_getenv("WITH_TRACE_MOVE").len() > 0
        if trace_move:
            with_eprint(f"[trace-move] continue back-edge: frame={frame_idx} bindings={boundary}")
        var i = 0
        while i < boundary:
            let entry_state = if off >= 0 and (off + i) < self.loop_entry_flat.len() as i32: self.loop_entry_flat[(off + i)] else: VarState.LIVE
            let cur_state = if i < self.bind_states.len() as i32: self.bind_states[i] else: VarState.LIVE
            let nd = self.type_needs_drop(self.bind_types[i])
            if trace_move and (entry_state == VarState.MOVED or cur_state == VarState.MOVED):
                let nm = self.pool_resolve(self.bind_names[i])
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
                let e_state = entry[i]
                let cur_state = if i < self.bind_states.len() as i32: self.bind_states[i] else: VarState.LIVE
                let nd = self.type_needs_drop(self.bind_types[i])
                if trace_move and (e_state == VarState.MOVED or cur_state == VarState.MOVED):
                    let nm = self.pool_resolve(self.bind_names[i])
                    with_eprint(f"[trace-move]   #{i} `{nm}` entry={e_state} body_end={cur_state} needs_drop={nd} carried_move={self.is_loop_carried_move(e_state, cur_state, nd)}")
                if self.is_loop_carried_move(e_state, cur_state, nd) != 0:
                    self.emit_loop_carried_move_error(i, loop_node)
                i = i + 1
        var post: Vec[i32] = if has_condition_exit != 0:
            let body_end = self.save_scope_states()
            self.union_move_states(entry, &body_end)
        else:
            self.union_move_states(entry, entry)
        if frame_idx >= 0 and frame_idx < self.label_break_seen.len() as i32 and self.label_break_seen[frame_idx] != 0:
            let off = self.label_break_off[frame_idx]
            if off >= 0:
                var brk: Vec[i32] = Vec.new()
                var i = 0
                while i < entry_count:
                    let v = if (off + i) < self.loop_break_flat.len() as i32: self.loop_break_flat[(off + i)] else: VarState.LIVE
                    brk.push(v)
                    i = i + 1
                post = self.union_move_states(&post, &brk)
        // Free this loop's break-flag and entry-state regions (both are the top of
        // their flat stacks and share the same offset).
        if frame_idx >= 0 and frame_idx < self.label_break_off.len() as i32:
            let off: i32 = self.label_break_off[frame_idx]
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
                provenance.view_storage_mask = 0
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
            self.binding_view_dep_data.push(deps[i])
        let opt = self.scope_name_map.get(sym)
        if opt.is_some():
            let idx = opt.unwrap()
            let slot_idx = idx as i64
            with self.bind_provenance.slot(slot_idx) as mut slot:
                var provenance = slot.get()
                provenance.view_origin_mask = param_mask
                provenance.view_storage_mask = param_mask
                provenance.view_dep_start = start
                provenance.view_dep_count = deps.len() as i32
                provenance.poisoned_origin_sym = 0
                provenance.poisoned_origin_node = 0
                provenance.poisoned_binding_node = 0
                slot.set(provenance)

    // Narrows the storage subset of a binding's origin mask; called after
    // set_binding_view_deps, which resets it to the whole mask.
    fn set_binding_view_storage_mask(sym: i32, storage_mask: i32):
        let opt = self.scope_name_map.get(sym)
        if opt.is_none():
            return
        let slot_idx = opt.unwrap() as i64
        with self.bind_provenance.slot(slot_idx) as mut slot:
            var provenance = slot.get()
            if provenance.view_origin_mask >= 0 and storage_mask >= 0:
                provenance.view_storage_mask = storage_mask & provenance.view_origin_mask
                slot.set(provenance)

    fn binding_view_storage_mask(sym: i32) -> i32:
        let opt = self.scope_name_map.get(sym)
        if opt.is_some():
            return self.bind_provenance[opt.unwrap()].view_storage_mask
        0

    // #625 (viral-escape): union additional view origins into a binding that
    // already exists — used when a store (Vec.push / HashMap.insert) adds the
    // pushed element's borrow origins to the container binding, so a later escape
    // of the container is caught by the ephemeral-escape checks.
    // One row of `sym`'s view facts as they stand now (explain:origin).
    fn note_view_fact(sym: i32, node: i32, event: i32):
        if sym == 0: return
        self.view_fact_fns.push(self.current_fn_symbol)
        self.view_fact_syms.push(sym)
        self.view_fact_nodes.push(node)
        self.view_fact_files.push(self.local_file_id)
        self.view_fact_events.push(event)
        self.view_fact_masks.push(self.binding_view_origin_mask(sym))
        self.view_fact_storage.push(self.binding_view_storage_mask(sym))
        self.view_fact_dep_starts.push(self.view_fact_deps.len() as i32)
        let count = self.binding_view_dep_count(sym)
        for di in 0..count: self.view_fact_deps.push(self.binding_view_dep_at(sym, di))
        self.view_fact_dep_counts.push(count)

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
            merged = self.push_unique_i32(move merged, deps[i])
        let merged_mask = self.binding_view_origin_mask(sym) | param_mask
        self.set_binding_view_deps(sym, merged_mask, merged)
        self.note_view_fact(sym, 0, 2)

    fn binding_view_origin_mask(sym: i32) -> i32:
        let opt = self.scope_name_map.get(sym)
        if opt.is_some():
            return self.bind_provenance[opt.unwrap()].view_origin_mask
        0

    fn binding_view_dep_count(sym: i32) -> i32:
        let opt = self.scope_name_map.get(sym)
        if opt.is_some():
            return self.bind_provenance[opt.unwrap()].view_dep_count
        0

    fn binding_view_dep_at(sym: i32, idx: i32) -> i32:
        let opt = self.scope_name_map.get(sym)
        if not opt.is_some():
            return 0
        let provenance = self.bind_provenance[opt.unwrap()]
        let count = provenance.view_dep_count
        if idx < 0 or idx >= count:
            return 0
        let start = provenance.view_dep_start
        self.binding_view_dep_data[(start + idx)]

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
            return self.bind_provenance[opt.unwrap()].poisoned_origin_sym
        0

    fn binding_poisoned_origin_node(sym: i32) -> i32:
        let opt = self.scope_name_map.get(sym)
        if opt.is_some():
            return self.bind_provenance[opt.unwrap()].poisoned_origin_node
        0

    fn binding_poisoned_binding_node(sym: i32) -> i32:
        let opt = self.scope_name_map.get(sym)
        if opt.is_some():
            return self.bind_provenance[opt.unwrap()].poisoned_binding_node
        0

    fn poison_live_views_for_origin(origin_sym: i32, origin_node: i32):
        if origin_sym == 0:
            return
        for bi in 0..self.bind_names.len() as i32:
            let view_sym = self.bind_names[bi]
            if view_sym == origin_sym:
                continue
            if self.bind_states[bi] != VarState.LIVE:
                continue
            if self.binding_depends_on_origin(view_sym, origin_sym) != 0:
                self.mark_binding_poisoned_by_origin(view_sym, origin_sym, origin_node)
                continue
            // A value expression that mentions `&raw const origin` poisons the
            // binding only if the binding can hold a view: a reference, an
            // ephemeral value, or a Drop value that may retain one. A Copy value
            // read through the dereference (`g = (*(&raw const a as *const S)).n`)
            // is independent of `a`; poisoning it made a later read of `g`
            // "may originate from `a`" (§21.1 Rule 6) in another function.
            let view_ty = self.bind_types[bi]
            let can_hold_view = view_ty != 0 and (self.get_type_kind(self.resolve_alias(view_ty as TypeId)) == TypeKind.TY_REF or self.type_has_drop_impl(view_ty) != 0 or self.type_is_ephemeral_value(view_ty) != 0)
            if can_hold_view and self.binding_value_depends_on_origin(view_sym, origin_sym) != 0:
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
        if self.impl_extra_is_std[record_idx] == want_std: 1 else: 0

    fn type_has_drop_impl(tid: i32) -> i32:
        if tid == 0:
            return 0
        let resolved = self.resolve_alias(tid as TypeId)
        // A reference or raw pointer is Copy and owns nothing (§3): it never
        // has a Drop impl, whatever its pointee has. get_type_name names the
        // pointee, which made a `&Db` field Drop — moved and blanked out of a
        // `mut self` receiver instead of copied (#1492).
        let kind = self.get_type_kind(resolved)
        if kind == TypeKind.TY_REF or kind == TypeKind.TY_PTR:
            return 0
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
            let start = self.impl_starts[idx]
            let count = self.impl_counts[idx]
            for i in 0..count:
                if self.impl_extra[(start + i)] == self.syms.drop:
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
        // D63: a callable value may own its environment (a `move ||` closure's
        // heap cell); its drop glue frees it. A bare function or a view
        // closure carries a tag the glue reads as "nothing to free".
        if tk == TypeKind.TY_FN:
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
                if self.type_needs_drop(self.type_extra[(te_start + ei)]) != 0:
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

    // D72 (§2.5.1, #1431): a `Drop` struct whose all-zero storage can be a
    // live value (`Fd { n: 0 }`) cannot use its storage as the reset
    // sentinel; the compiler appends a hidden liveness byte that a
    // construction sets, the reset-on-move blank clears with the rest of the
    // storage, and the guarded drop reads through the ordinary all-zero test.
    // A struct with a field that is non-null whenever the value is live and
    // that nothing can zero while it stays live — a raw pointer (a facade
    // resource's repr), a reference, an extern callable, a view — keeps the
    // storage test and gains no byte. D82 (§2.2, #1944): an owning field is
    // not such a field. An explicit `move v.text` vacates it to its empty
    // value while `v` stays live and its destructor still runs, so a
    // droppable field — a str, a container, a Box, a callable, another Drop
    // value — proves nothing about the whole: a `Drop` struct whose only
    // non-zero fields can be vacated carries the byte. Decided per
    // declaration, so every instance of a generic struct agrees; a type
    // parameter counts as a live-zero field (the byte is added, never
    // withheld, when the answer depends on the argument). Explicit layouts
    // (packed, bitpacked, repr(C), aligned fields), unions, distinct types
    // and facade resources (whose `live` field is this byte, D51) are never
    // changed.
    mut fn struct_needs_liveness_byte(name_sym: i32) -> i32:
        if name_sym == 0:
            return 0
        let cached = self.liveness_byte_cache.get(name_sym)
        if cached.is_some():
            return cached.unwrap()
        // Recorded before the walk: a self-referential field reads as 0.
        self.liveness_byte_cache.insert(name_sym, 0)
        let result = self.struct_decl_needs_liveness_byte(name_sym)
        self.liveness_byte_cache.insert(name_sym, result)
        result

    fn struct_liveness_byte_frozen(name_sym: i32) -> i32:
        self.liveness_byte_cache.get(name_sym) ?? 0

    mut fn struct_decl_needs_liveness_byte(name_sym: i32) -> i32:
        if not self.type_decl_nodes.contains(name_sym) or self.distinct_type_names.contains(name_sym) or self.facade_resource_index.contains(name_sym):
            return 0
        let decl: i32 = self.type_decl_nodes.get(name_sym).unwrap()
        let packed = self.ast.get_data2(decl)
        if type_decl_sub_kind(packed) != TypeDeclKind.Struct or type_decl_is_packed(packed) != 0 or type_decl_is_bitpacked(packed) != 0 or type_decl_is_repr_c(packed) != 0:
            return 0
        if not self.named_types.contains(name_sym) or self.type_has_drop_impl(self.named_types.get(name_sym).unwrap()) == 0:
            return 0
        let extra_start = self.ast.get_data1(decl)
        let field_count = self.ast.get_extra(extra_start)
        for fi in 0..field_count:
            if field_align_value(self.ast.get_extra(extra_start + 1 + field_count * 3 + fi)) != 0:
                return 0
            if self.type_node_zero_is_sentinel(self.ast.get_extra(extra_start + 1 + fi * 3 + 1), decl) != 0:
                return 0
        1

    // Whether a field of this declared type is non-zero whenever it holds a
    // value AND can never be zeroed while the enclosing value is live, so
    // the enclosing struct's zero storage is the sentinel. A droppable field
    // fails the second half (D82): `move v.field` resets it to its empty
    // value with `v` live, so it never proves the whole.
    mut fn type_node_zero_is_sentinel(node: i32, decl: i32) -> i32:
        if node == 0:
            return 0
        let kind = self.ast.kind(node)
        if kind == NodeKind.NK_TYPE_PTR or kind == NodeKind.NK_TYPE_REF or kind == NodeKind.NK_TYPE_EXTERN_FN or kind == NodeKind.NK_TYPE_SLICE or kind == NodeKind.NK_TYPE_TRAIT_OBJ:
            return 1
        // A `fn` value may own a closure environment (D63): droppable.
        if kind == NodeKind.NK_TYPE_OPTIONAL or kind == NodeKind.NK_TYPE_FN:
            return 0
        if kind == NodeKind.NK_TYPE_ARRAY:
            return self.type_node_zero_is_sentinel(self.ast.get_data0(node), decl)
        if kind == NodeKind.NK_TYPE_TUPLE:
            let start = self.ast.get_data0(node)
            let count = self.ast.get_data1(node)
            for ei in 0..count:
                if self.type_node_may_need_drop(self.ast.get_extra(start + ei), decl) != 0:
                    return 0
            for ei in 0..count:
                if self.type_node_zero_is_sentinel(self.ast.get_extra(start + ei), decl) != 0:
                    return 1
            return 0
        if kind == NodeKind.NK_TYPE_NAMED:
            let sym = self.ast.get_data0(node)
            let tp_start = self.type_decl_tp_start(decl)
            for ti in 0..self.type_decl_tp_count(decl):
                if self.ast.get_extra(tp_start + ti) == sym:
                    return 0
            // Every primitive is live at zero (a number) or droppable (str).
            if self.primitive_type_by_sym(sym) != 0:
                return 0
            let named = self.lookup_named_type_visible(sym)
            if named == 0:
                return 0
            return self.type_zero_is_sentinel(named)
        // A generic instance — a container, a Box, an Rc, a user generic —
        // is droppable or depends on its argument; a type this walk cannot
        // classify is treated the same way. The byte is added, never
        // withheld.
        0

    // Whether a field of this declared type may need drop glue, so an
    // explicit `move` of it is a vacate that resets its storage. Answers 1
    // whenever the walk cannot prove otherwise.
    mut fn type_node_may_need_drop(node: i32, decl: i32) -> i32:
        if node == 0:
            return 0
        let kind = self.ast.kind(node)
        if kind == NodeKind.NK_TYPE_PTR or kind == NodeKind.NK_TYPE_REF or kind == NodeKind.NK_TYPE_EXTERN_FN or kind == NodeKind.NK_TYPE_SLICE or kind == NodeKind.NK_TYPE_TRAIT_OBJ:
            return 0
        if kind == NodeKind.NK_TYPE_OPTIONAL or kind == NodeKind.NK_TYPE_ARRAY:
            return self.type_node_may_need_drop(self.ast.get_data0(node), decl)
        if kind == NodeKind.NK_TYPE_TUPLE:
            let start = self.ast.get_data0(node)
            for ei in 0..self.ast.get_data1(node):
                if self.type_node_may_need_drop(self.ast.get_extra(start + ei), decl) != 0:
                    return 1
            return 0
        if kind == NodeKind.NK_TYPE_NAMED:
            let sym = self.ast.get_data0(node)
            let tp_start = self.type_decl_tp_start(decl)
            for ti in 0..self.type_decl_tp_count(decl):
                if self.ast.get_extra(tp_start + ti) == sym:
                    return 1
            let prim = self.primitive_type_by_sym(sym)
            if prim != 0:
                return if self.get_type_kind(self.resolve_alias(prim as TypeId)) == TypeKind.TY_STR: 1 else: 0
            let named = self.lookup_named_type_visible(sym)
            if named == 0:
                return 1
            return self.type_needs_drop(named)
        1

    // The same for a resolved type: a droppable type proves nothing (D82);
    // otherwise a pointer-shaped type, or an aggregate holding one, is
    // non-zero whenever live.
    mut fn type_zero_is_sentinel(tid: i32) -> i32:
        if tid == 0:
            return 0
        let resolved = self.resolve_alias(tid as TypeId)
        if self.type_needs_drop(resolved as i32) != 0:
            return 0
        let tk = self.get_type_kind(resolved)
        if tk == TypeKind.TY_PTR or tk == TypeKind.TY_REF or tk == TypeKind.TY_SLICE or tk == TypeKind.TY_EXTERN_FN or tk == TypeKind.TY_GENERIC_FN or tk == TypeKind.TY_TRAIT_OBJ:
            return 1
        if tk == TypeKind.TY_ARRAY or tk == TypeKind.TY_RANGE:
            return self.type_zero_is_sentinel(self.get_type_d0(resolved))
        if tk == TypeKind.TY_TUPLE:
            let te_start = self.get_type_d0(resolved)
            for ei in 0..self.get_type_d1(resolved):
                if self.type_zero_is_sentinel(self.type_extra[(te_start + ei)]) != 0:
                    return 1
            return 0
        if tk == TypeKind.TY_GENERIC_INST:
            let base_sym = self.get_generic_inst_base(resolved as i32)
            if self.named_types.contains(base_sym) and self.get_type_kind(self.resolve_alias(self.named_types.get(base_sym).unwrap())) == TypeKind.TY_STRUCT:
                return self.struct_zero_is_sentinel(base_sym)
            return 0
        if tk == TypeKind.TY_STRUCT:
            return self.struct_zero_is_sentinel(self.get_type_d0(resolved))
        0

    // A plain (non-droppable) struct is the sum of its fields. A Drop
    // struct never reaches here as a field: it is droppable, so a vacate
    // can zero it (D82).
    mut fn struct_zero_is_sentinel(name_sym: i32) -> i32:
        if name_sym == 0 or not self.type_decl_nodes.contains(name_sym):
            return 0
        let decl: i32 = self.type_decl_nodes.get(name_sym).unwrap()
        if type_decl_sub_kind(self.ast.get_data2(decl)) != TypeDeclKind.Struct:
            return 0
        let extra_start = self.ast.get_data1(decl)
        let field_count = self.ast.get_extra(extra_start)
        for fi in 0..field_count:
            if self.type_node_zero_is_sentinel(self.ast.get_extra(extra_start + 1 + fi * 3 + 1), decl) != 0:
                return 1
        0

    // Whether a value of this type transitively carries a USER Drop impl
    // (W, Vec[W], Holder{item: W}). Narrower than `type_needs_drop`: pure
    // memory-managed types (str, Vec[str], HashMap[str, str]) answer 0 —
    // their cleanup is invisible, so a field let may observe them (D22),
    // while a user-Drop-bearing field stays an explicit ownership transfer
    // (err_use_after_move_*_field pins).
    // The same, seeing no destructor through a reference or raw pointer: a
    // `&W` field owns nothing, so the value's own drop runs no destructor
    // of W. `type_has_drop_impl(&W)` answers as for `W` (get_type_name looks
    // through references, #1492), so this walks the shape itself.
    mut fn type_owns_user_drop(tid: i32) -> i32:
        if tid == 0:
            return 0
        let resolved = self.resolve_alias(tid as TypeId)
        let tk = self.get_type_kind(resolved)
        if tk == TypeKind.TY_REF or tk == TypeKind.TY_PTR:
            return 0
        if self.type_has_drop_impl(resolved as i32) != 0:
            return 1
        if self.needs_drop_visit.contains(resolved as i32):
            return 0
        self.needs_drop_visit.insert(resolved as i32)
        var result = 0
        if tk == TypeKind.TY_GENERIC_INST:
            for ai in 0..self.get_generic_inst_arg_count(resolved as i32):
                if self.type_owns_user_drop(self.get_generic_inst_arg(resolved as i32, ai)) != 0:
                    result = 1
                    break
        else if tk == TypeKind.TY_TUPLE:
            let te_start = self.get_type_d0(resolved)
            for ei in 0..self.get_type_d1(resolved):
                if self.type_owns_user_drop(self.type_extra[(te_start + ei)]) != 0:
                    result = 1
                    break
        else if tk == TypeKind.TY_ARRAY or tk == TypeKind.TY_RANGE:
            result = self.type_owns_user_drop(self.get_type_d0(resolved))
        else:
            for fi in 0..self.type_reflection_field_count(resolved as i32):
                let fty = self.type_reflection_field_type(resolved as i32, fi)
                if self.type_owns_user_drop(fty) != 0:
                    result = 1
                    break
            var vidx = 0
            while vidx < self.type_reflection_variant_count(resolved as i32) and result == 0:
                for pi in 0..self.type_reflection_variant_payload_count(resolved as i32, vidx):
                    let pty = self.type_reflection_variant_payload_type(resolved as i32, vidx, pi)
                    if self.type_owns_user_drop(pty) != 0:
                        result = 1
                        break
                vidx = vidx + 1
        let _ = self.needs_drop_visit.remove(resolved as i32)
        result

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
                if self.type_carries_user_drop(self.type_extra[(te_start + ei)]) != 0:
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

    // `moved`: `origin_node` moves or consumes the origin (a `move`, a
    // consuming call, a `move fn` receiver) while the view still lives; the
    // error is that site. Otherwise the origin went out of scope first.
    mut fn emit_implicit_drop_view_use_error(view_sym: i32, origin_sym: i32, origin_node: i32, moved: bool):
        let view_name = self.pool_resolve(view_sym)
        let origin_name = self.pool_resolve(origin_sym)
        let view_node = self.binding_decl_node(view_sym)
        let primary_node = if moved and origin_node != 0: origin_node else: if view_node != 0: view_node else: origin_node
        let primary_start = if primary_node != 0: self.ast.get_start(primary_node) else: 0
        let primary_end = if primary_node != 0: self.ast.get_end(primary_node) else: 0
        let fate = if moved: "moved" else: "destroyed"
        var diag = Diagnostic.err("implicit drop of `" ++ view_name ++ "` uses `&" ++ origin_name ++ "` after `" ++ origin_name ++ "` is " ++ fate ++ " (§21.1 Rule 7)", Span { file: self.local_file_id, start: primary_start, end: primary_end })
        if view_node != 0:
            diag.add_label(Span { file: self.local_file_id, start: self.ast.get_start(view_node), end: self.ast.get_end(view_node) }, "Drop value retaining the borrow is declared here")
        if origin_node != 0:
            let what = if moved: "`" ++ origin_name ++ "` is moved here while `" ++ view_name ++ "` still borrows it" else: "`" ++ origin_name ++ "` is destroyed before `" ++ view_name ++ "` drops"
            diag.add_label(Span { file: self.local_file_id, start: self.ast.get_start(origin_node), end: self.ast.get_end(origin_node) }, what)
        if moved:
            diag.add_help("drop or finish with `" ++ view_name ++ "` before `" ++ origin_name ++ "` is moved or consumed")
        else:
            diag.add_help("declare `" ++ view_name ++ "` after `" ++ origin_name ++ "`, or clear/drop `" ++ view_name ++ "` before `" ++ origin_name ++ "` goes out of scope")
        // §8, §57: a facade resource that depends on the origin says why.
        diag = self.with_facade_dependency_notes(move diag, self.scope_lookup(view_sym))
        self.diags.emit(move diag)

    // D51 stage 7 (ruling §38, spec §16.2b.7): a view a foreign call
    // invalidated — a resource it received without `preserves param N`, or a
    // domain of its library it did not `preserves` — is used afterwards.
    // The diagnostic names the call, what the view borrowed from, and the
    // clause that would state preservation (§57).
    mut fn emit_facade_invalidated_view_error(view_sym: i32, origin_sym: i32, call_node: i32, binding_node: i32, use_node: i32):
        let view_name = self.pool_resolve(view_sym)
        let fx: i32 = self.facade_touch_nodes.get(call_node).unwrap()
        let fname: str = self.pool_resolve(self.facade_call_effects[fx].fn_sym)
        let ci = self.facade_call_effects[fx].contract
        let pi: i32 = if self.facade_touch_hit_params.contains(view_sym): self.facade_touch_hit_params.get(view_sym).unwrap() else: -1
        let is_domain = self.facade_domain_origin_index.contains(origin_sym)
        var origin_text = "`" ++ self.pool_resolve(origin_sym) ++ "`"
        var clause = f"preserves param {pi}"
        if is_domain:
            let di: i32 = self.facade_domain_origin_index.get(origin_sym).unwrap()
            let dn: str = self.pool_resolve(self.facade_domain_list[di].name)
            origin_text = "foreign-state domain `" ++ dn ++ "`"
            clause = "preserves domain " ++ dn
        let primary_start = if use_node != 0: self.ast.get_start(use_node) else: 0
        let primary_end = if use_node != 0: self.ast.get_end(use_node) else: 0
        var diag = Diagnostic.err("view `" ++ view_name ++ "` borrows from " ++ origin_text ++ ", which `" ++ fname ++ "` may have invalidated (§16.2b.7)", Span { file: self.local_file_id, start: primary_start, end: primary_end })
        if binding_node != 0:
            diag.add_label(Span { file: self.local_file_id, start: self.ast.get_start(binding_node), end: self.ast.get_end(binding_node) }, "view borrowed here")
        if call_node != 0:
            diag.add_label(Span { file: self.local_file_id, start: self.ast.get_start(call_node), end: self.ast.get_end(call_node) }, "`" ++ fname ++ "` is called here; its effect on " ++ origin_text ++ " is unknown, and unknown effect means invalidate")
        if use_node != 0:
            diag.add_label(Span { file: self.local_file_id, start: self.ast.get_start(use_node), end: self.ast.get_end(use_node) }, "used here after the call")
        if ci >= 0:
            let facade: str = self.pool_resolve(self.foreign_contracts[ci].facade)
            diag.add_help("state `" ++ clause ++ "` on fn " ++ fname ++ " in facade " ++ facade ++ " if it leaves that storage valid, or copy `" ++ view_name ++ "` out (`to_owned()`) before the call")
        else:
            diag.add_help("describe " ++ fname ++ " with an fn item in a facade and state `" ++ clause ++ "` if it leaves that storage valid, or copy `" ++ view_name ++ "` out (`to_owned()`) before the call")
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
        if self.facade_touch_nodes.contains(origin_node):
            self.emit_facade_invalidated_view_error(view_sym, origin_sym, origin_node, binding_node, use_node)
            return
        var diag = Diagnostic.err("view `" ++ view_name ++ "` may originate from `" ++ origin_name ++ "`, which no longer lives here (§21.1 Rule 6)", Span { file: self.local_file_id, start: primary_start, end: primary_end })
        if binding_node != 0:
            diag.add_label(Span { file: self.local_file_id, start: self.ast.get_start(binding_node), end: self.ast.get_end(binding_node) }, "view origin was recorded here")
        if origin_node != 0:
            diag.add_label(Span { file: self.local_file_id, start: self.ast.get_start(origin_node), end: self.ast.get_end(origin_node) }, "`" ++ origin_name ++ "` is dropped at the end of its scope before this use")
        if use_node != 0:
            diag.add_label(Span { file: self.local_file_id, start: self.ast.get_start(use_node), end: self.ast.get_end(use_node) }, "view is used here after a possible origin died")
        diag.add_help("copy the data out before the origin's scope ends, or declare `" ++ origin_name ++ "` in the outer scope")
        diag = self.with_facade_dependency_notes(move diag, self.scope_lookup(view_sym))
        self.diags.emit(move diag)

    fn binding_decl_node(sym: i32) -> i32:
        if self.binding_decl_nodes.contains(sym):
            return self.binding_decl_nodes.get(sym).unwrap()
        0

    fn binding_has_active_borrow_from(view_sym: i32, origin_sym: i32) -> i32:
        for bi in 0..self.borrow_refs.len() as i32:
            let ref_sym: i32 = self.borrow_refs[bi]
            let place_sym: i32 = self.borrow_places[bi]
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
            let view_sym: i32 = self.bind_names[bi]
            if view_sym == origin_sym:
                continue
            if self.bind_states[bi] != VarState.LIVE:
                continue
            let view_ty: i32 = self.bind_types[bi]
            // Rule 7's "variable implementing Drop" is any value whose drop
            // runs a destructor retaining the borrow: `Option[S]`, `(i32,
            // Option[S])` or `Vec[S]` of an ephemeral Drop `S` (a dependent
            // facade resource) as much as `S` itself. Shallow
            // type_has_drop_impl let an `Option[S]` declared before its
            // origin drop after it.
            let view_has_drop = self.type_owns_user_drop(view_ty)
            let active_view = self.binding_depends_on_origin(view_sym, origin_sym) != 0 and self.binding_has_active_borrow_from(view_sym, origin_sym) != 0
            // Rule 7 reads the holder's recorded origins as well as its
            // initializer: a view stored into it later (`h.v.push(&n)`,
            // `h.keep(&n)`, #1783) is what its destructor reads.
            let drop_retains = view_has_drop != 0 and (self.binding_value_depends_on_origin(view_sym, origin_sym) != 0 or self.binding_depends_on_origin(view_sym, origin_sym) != 0)
            if active_view or drop_retains:
                let err_node = if node != 0: node else: self.binding_decl_node(view_sym)
                let moved = node != 0 and node == self.move_site_node
                if view_has_drop != 0:
                    self.emit_implicit_drop_view_use_error(view_sym, origin_sym, err_node, moved)
                    return
                if self.suppress_errors != 0:
                    return
                let view_name: str = with_str_clone_ref(self.pool_resolve(view_sym))
                let origin_name: str = with_str_clone_ref(self.pool_resolve(origin_sym))
                let start = self.ast.get_start(err_node)
                let end = self.ast.get_end(err_node)
                var diag = Diagnostic.err("view '" ++ view_name ++ "' may outlive its origin '" ++ origin_name ++ "'", Span { file: self.local_file_id, start: start, end: end })
                diag = self.with_copy_view_fixit(move diag, view_sym, true)
                diag = self.with_facade_dependency_notes(move diag, view_ty)
                self.diags.emit(move diag)
                return

    fn set_expr_view_deps(expr_node: i32, param_mask: i32, deps: &Vec[i32]):
        if expr_node == 0:
            return
        self.expr_view_storage_origins.remove(expr_node)
        if param_mask == 0 and deps.len() == 0:
            self.expr_view_param_origins.remove(expr_node)
            self.expr_view_dep_starts.remove(expr_node)
            self.expr_view_dep_counts.remove(expr_node)
            return
        self.expr_view_param_origins.insert(expr_node, param_mask)
        let start = self.expr_view_dep_data.len() as i32
        for i in 0..deps.len() as i32:
            self.expr_view_dep_data.push(deps[i])
        self.expr_view_dep_starts.insert(expr_node, start)
        self.expr_view_dep_counts.insert(expr_node, deps.len() as i32)

    fn expr_view_origin_mask(expr_node: i32) -> i32:
        if self.expr_view_param_origins.contains(expr_node):
            return self.expr_view_param_origins.get(expr_node).unwrap()
        0

    // Narrows the storage subset of a node's recorded origins; called after
    // set_expr_view_deps, which resets it to the whole mask.
    fn set_expr_view_storage_mask(expr_node: i32, storage_mask: i32):
        if expr_node == 0 or not self.expr_view_param_origins.contains(expr_node):
            return
        let whole = self.expr_view_origin_mask(expr_node)
        if whole < 0 or storage_mask < 0:
            return
        self.expr_view_storage_origins.insert(expr_node, storage_mask & whole)

    fn expr_view_storage_mask(expr_node: i32) -> i32:
        if self.expr_view_storage_origins.contains(expr_node):
            return self.expr_view_storage_origins.get(expr_node).unwrap()
        self.expr_view_origin_mask(expr_node)

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
        self.expr_view_dep_data[(start + idx)]

    fn set_closure_capture_summary(closure_node: i32, capture_syms: &Vec[i32], capture_effs: &Vec[i32]):
        if closure_node == 0:
            return
        let start = self.closure_capture_summary_data.len() as i32
        let count = if capture_syms.len() < capture_effs.len(): capture_syms.len() as i32 else: capture_effs.len() as i32
        for i in 0..count:
            self.closure_capture_summary_data.push(capture_syms[i])
            self.closure_capture_summary_data.push(capture_effs[i])
            self.closure_capture_summary_data.push(self.scope_lookup(capture_syms[i]))
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
        self.closure_capture_summary_data[(start + idx * 3)]

    // 1 when calling the closure moves capture `idx` out of its place (§12.4:
    // the body consumes or returns it) — MirLower keeps that local's drop
    // guard, since the body blanks the place through the capture (#1481).
    fn closure_capture_consumes(closure_node: i32, idx: i32) -> i32:
        if (self.closure_capture_summary_eff(closure_node, idx) & (EFF_CONSUME | EFF_ESCAPE_VALUE)) != 0: 1 else: 0

    // D62/D65: Sema's capture mode for capture `idx` of a closure — by place
    // (a pointer to the creating frame's slot, Copy or not) unless the
    // closure is `move`, which takes the value. Every downstream stage reads
    // this; none re-reads the closure's spelling.
    fn closure_capture_by_place(closure_node: i32, idx: i32) -> bool:
        (self.closure_capture_summary_eff(closure_node, idx) & EFF_CAPTURE_BY_PLACE) != 0

    // D63: the closure value owns its environment — some capture is held by
    // value, not by place (a `move` closure with captures).
    fn closure_env_owned(closure_node: i32) -> bool:
        for ci in 0..self.closure_capture_summary_count(closure_node):
            if not self.closure_capture_by_place(closure_node, ci): return true
        false

    fn closure_capture_summary_eff(closure_node: i32, idx: i32) -> i32:
        if not self.closure_capture_summary_starts.contains(closure_node):
            return 0
        let count = self.closure_capture_summary_count(closure_node)
        if idx < 0 or idx >= count:
            return 0
        let start = self.closure_capture_summary_starts.get(closure_node).unwrap()
        self.closure_capture_summary_data[(start + idx * 3 + 1)]

    fn closure_capture_summary_type(closure_node: i32, idx: i32) -> i32:
        if not self.closure_capture_summary_starts.contains(closure_node):
            return 0
        if idx < 0 or idx >= self.closure_capture_summary_count(closure_node):
            return 0
        let start = self.closure_capture_summary_starts.get(closure_node).unwrap()
        self.closure_capture_summary_data[(start + idx * 3 + 2)]

    fn is_mutable_global(sym: i32) -> i32:
        if self.mutable_global_syms.contains(sym): return 1
        0

    // docs/completed/mut.md Rev 8 §15.12 — declared via `global X = ...`, no `var`.
    // Rebinding such a symbol is the §15.12 diagnostic.
    fn is_stable_global(sym: i32) -> i32:
        if self.stable_global_syms.contains(sym): return 1
        0

    fn is_active_async_scope_symbol(sym: i32) -> i32:
        var i = self.async_scope_names.len() as i32 - 1
        while i >= 0:
            if self.async_scope_names[i] == sym:
                return 1
            i = i - 1
        0

    fn is_active_sync_scope_symbol(sym: i32) -> i32:
        var i = self.sync_scope_names.len() as i32 - 1
        while i >= 0:
            if self.sync_scope_names[i] == sym:
                return 1
            i = i - 1
        0

    // ── Function signature management ────────────────────────────────

    fn add_sig(name: i32, fn_tid: i32, ret: i32, param_start: i32, param_count: i32, variadic: i32):
        let idx = self.sig_names.len() as i32
        self.sig_names.push(name)
        // get_visible_sig matches by resolved text; chain the signatures
        // sharing one, newest first.
        let text = sema_owned_text(self.pool_resolve(name))
        self.sig_text_prev.push(if self.sig_text_index.contains(text): self.sig_text_index.get(text).unwrap() else: -1)
        self.sig_text_index.insert(text, idx)
        self.sig_type_ids.push(fn_tid)
        self.sig_ret_types.push(ret)
        self.sig_param_starts.push(param_start)
        self.sig_param_counts.push(param_count)
        self.sig_variadic.push(variadic)
        // docs/completed/mutability.md Phase 4 — per-parameter effect storage.
        self.sig_param_eff_starts.push(self.sig_param_effects.len() as i32)
        for pi in 0..param_count:
            self.sig_param_effects.push(0)
            self.sig_param_direct_effects.push(0)
            self.sig_param_view_origins.push(0)
            self.sig_param_view_through.push(0)
            self.sig_param_invoke_many.push(0)
            self.sig_value_ref_abi_params.push(0)
        self.sig_receiver_modes.push(ReceiverMode.None as i32)
        self.sig_receiver_required_effects.push(0)
        self.sig_lookup.insert(name, idx)

    mut fn set_sig_receiver_mode(si: i32, mode: ReceiverMode):
        if si < 0 or si >= self.sig_receiver_modes.len() as i32:
            return
        self.sig_receiver_modes[si] = mode as i32

    fn sig_receiver_mode(si: i32) -> ReceiverMode:
        if si < 0 or si >= self.sig_receiver_modes.len() as i32:
            return ReceiverMode.None
        self.sig_receiver_modes[si] as ReceiverMode

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
        let start = self.sig_param_eff_starts[si]
        let count = self.sig_param_counts[si]
        if pi < 0 or pi >= count:
            return 0
        self.sig_value_ref_abi_params[(start + pi)]

    mut fn set_sig_param_value_ref_abi(si: i32, pi: i32, value: i32):
        if si < 0 or si >= self.sig_param_eff_starts.len() as i32:
            return
        let start: i32 = self.sig_param_eff_starts[si]
        let count = self.sig_param_counts[si]
        if pi < 0 or pi >= count:
            return
        self.sig_value_ref_abi_params[(start + pi)] = value

    fn sig_param_effect(si: i32, pi: i32) -> i32:
        if si < 0 or si >= self.sig_param_eff_starts.len() as i32:
            return 0
        let start = self.sig_param_eff_starts[si]
        let count = self.sig_param_counts[si]
        if pi < 0 or pi >= count:
            return 0
        self.sig_param_effects[(start + pi)]

    mut fn set_sig_param_effect(si: i32, pi: i32, eff: i32):
        if si < 0 or si >= self.sig_param_eff_starts.len() as i32:
            return
        let start: i32 = self.sig_param_eff_starts[si]
        let count = self.sig_param_counts[si]
        if pi < 0 or pi >= count:
            return
        // A validity requirement is stronger than the observational read
        // category, whether found in the body or added by the fixed point.
        self.sig_param_effects[(start + pi)] = if (eff & EFF_RAW_PTR_VALIDITY) != 0: eff & ~EFF_READ else: eff

    mut fn set_sig_param_direct_effect(si: i32, pi: i32, eff: i32):
        if si < 0 or si >= self.sig_param_eff_starts.len() as i32:
            return
        let start: i32 = self.sig_param_eff_starts[si]
        let count = self.sig_param_counts[si]
        if pi < 0 or pi >= count or start + pi >= self.sig_param_direct_effects.len() as i32:
            return
        self.sig_param_direct_effects[(start + pi)] = eff

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
        let start = self.sig_param_eff_starts[si]
        let count = self.sig_param_counts[si]
        if pi < 0 or pi >= count:
            return 0
        self.sig_param_view_origins[(start + pi)]

    fn sig_param_invoke_many_at(si: i32, pi: i32) -> i32:
        if si < 0 or si >= self.sig_param_eff_starts.len() as i32:
            return 0
        let start = self.sig_param_eff_starts[si]
        let count = self.sig_param_counts[si]
        if pi < 0 or pi >= count or start + pi >= self.sig_param_invoke_many.len() as i32:
            return 0
        self.sig_param_invoke_many[(start + pi)]

    mut fn set_sig_param_invoke_many(si: i32, pi: i32, many: i32):
        if si < 0 or si >= self.sig_param_eff_starts.len() as i32:
            return
        let start: i32 = self.sig_param_eff_starts[si]
        let count = self.sig_param_counts[si]
        if pi < 0 or pi >= count or start + pi >= self.sig_param_invoke_many.len() as i32:
            return
        self.sig_param_invoke_many[(start + pi)] = many

    mut fn set_sig_param_view_origin(si: i32, pi: i32, mask: i32):
        if si < 0 or si >= self.sig_param_eff_starts.len() as i32:
            return
        let start: i32 = self.sig_param_eff_starts[si]
        let count = self.sig_param_counts[si]
        if pi < 0 or pi >= count:
            return
        self.sig_param_view_origins[(start + pi)] = mask

    fn sig_param_view_through(si: i32, pi: i32) -> i32:
        if si < 0 or si >= self.sig_param_eff_starts.len() as i32:
            return 0
        let start = self.sig_param_eff_starts[si]
        let count = self.sig_param_counts[si]
        if pi < 0 or pi >= count:
            return 0
        self.sig_param_view_through[(start + pi)]

    mut fn set_sig_param_view_through(si: i32, pi: i32, mask: i32):
        if si < 0 or si >= self.sig_param_eff_starts.len() as i32:
            return
        let start: i32 = self.sig_param_eff_starts[si]
        let count = self.sig_param_counts[si]
        if pi < 0 or pi >= count:
            return
        self.sig_param_view_through[(start + pi)] = mask

    fn param_index_for_sym(sym: i32) -> i32:
        let name = self.pool_resolve(sym)
        for pi in 0..self.current_fn_param_syms.len() as i32:
            let param_sym = self.current_fn_param_syms[pi]
            if param_sym == sym or self.pool_resolve(param_sym) == name:
                return pi
        -1

    mut fn note_param_effect(sym: i32, eff0: i32):
        if self.current_fn_sig_idx < 0 or sym == 0:
            return
        var eff = eff0
        // §12.4 / D63 (#1698): a callable parameter carried out of the call —
        // inside a returned value, or stored into the receiver — is the
        // callable itself escaping: a non-`move` closure argument "may not be
        // stored, returned, or captured by a `move ||` closure", which the
        // call site refuses on EFF_ESCAPE_VALUE (finalize_closure_arg_checks),
        // and the effect fixpoint carries to every caller that passes it on.
        if (eff & (EFF_ESCAPE_VIEW | EFF_STORE_IN_RECEIVER)) != 0 and self.callable_param_is_view(sym, self.scope_lookup(sym)):
            eff = eff | EFF_ESCAPE_VALUE
        let pi = self.param_index_for_sym(sym)
        if pi >= 0:
            let cur: i32 = self.current_fn_param_effs[pi]
            self.current_fn_param_effs[pi] = cur | eff
            // explain:effect provenance — record the FIRST setter of each
            // ownership-forcing bit. The origin node is carried in
            // effect_note_origin_node (set by note_place_effect and the other
            // node-bearing noters; 0 when unknown).
            let new_bits = eff & (EFF_CONSUME | EFF_ESCAPE_VALUE | EFF_WRITE | EFF_RAW_PTR_VALIDITY) & (2147483647 - cur)
            if new_bits != 0:
                self.record_effect_provenance_direct(self.current_fn_sig_idx, pi, new_bits, self.effect_note_origin_node)
            if self.recording_propagated_effect == 0:
                let direct: i32 = self.current_fn_param_direct_effs[pi]
                self.current_fn_param_direct_effs[pi] = direct | eff
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
        if (bits & EFF_RAW_PTR_VALIDITY) != 0:
            self.record_effect_provenance_bit(sig, pi, 3, 1, node, self.local_file_id)

    fn record_effect_provenance_edge(sig: i32, pi: i32, bits: i32, callee_sig: i32, callee_pi: i32):
        if (bits & EFF_CONSUME) != 0:
            self.record_effect_provenance_bit(sig, pi, 0, 2, callee_sig, callee_pi)
        if (bits & EFF_ESCAPE_VALUE) != 0:
            self.record_effect_provenance_bit(sig, pi, 1, 2, callee_sig, callee_pi)
        if (bits & EFF_WRITE) != 0:
            self.record_effect_provenance_bit(sig, pi, 2, 2, callee_sig, callee_pi)
        if (bits & EFF_RAW_PTR_VALIDITY) != 0:
            self.record_effect_provenance_bit(sig, pi, 3, 2, callee_sig, callee_pi)

    fn record_effect_provenance_bit(sig: i32, pi: i32, bit_idx: i32, kind: i64, a: i32, b: i32):
        let key = effect_prov_key(sig, pi, bit_idx)
        if self.effect_prov.contains(key):
            return
        self.effect_prov.insert(key, effect_prov_val(kind, a, b))

    // `mask`: the parameters the returned view may originate from;
    // `storage_mask`: the subset whose own storage it may point into.
    fn note_param_view_fact(pi: i32, storage: bool, node: i32):
        self.param_view_fact_sigs.push(self.current_fn_sig_idx)
        self.param_view_fact_params.push(pi)
        self.param_view_fact_storage.push(if storage: 1 else: 0)
        self.param_view_fact_nodes.push(node)
        self.param_view_fact_files.push(self.local_file_id)

    mut fn note_param_view_origin(sym: i32, mask: i32, storage_mask: i32, origin_node: i32):
        if self.current_fn_sig_idx < 0 or sym == 0 or mask == 0:
            return
        let pi = self.param_index_for_sym(sym)
        if pi >= 0:
            let cur: i32 = self.current_fn_param_origins[pi]
            self.current_fn_param_origins[pi] = cur | mask
            let cur_storage: i32 = self.current_fn_param_storage_origins[pi]
            self.current_fn_param_storage_origins[pi] = cur_storage | storage_mask
            if origin_node != 0 and self.current_fn_param_view_nodes[pi] == 0:
                self.current_fn_param_view_nodes[pi] = origin_node
            // explain:origin: the first node to put this parameter in the
            // returned view's origins, and the first to put it in its storage.
            if origin_node != 0 and (cur & mask) != mask:
                self.note_param_view_fact(pi, false, origin_node)
            if origin_node != 0 and storage_mask != 0 and (cur_storage & storage_mask) != storage_mask:
                self.note_param_view_fact(pi, true, origin_node)
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
        let caller_pi = if root != 0: self.param_index_for_sym(root) else: -1
        if caller_pi >= 0:
            self.record_effect_edge_for_param(caller_sig, caller_pi, callee_sig, callee_pi, self.effect_arg_is_projection(arg_node))
        // Raw pointer copies keep the same validity obligation. Snapshot
        // their parameter origins while the local binding facts are live.
        let raw_origins = self.raw_pointer_param_origin_mask(arg_node)
        for pi in 0..self.current_fn_param_syms.len() as i32:
            if pi != caller_pi and (raw_origins & sema_param_origin_bit(pi)) != 0:
                self.record_effect_edge_for_param(caller_sig, pi, callee_sig, callee_pi, 1)

    fn record_effect_edge_for_param(caller_sig: i32, caller_pi: i32, callee_sig: i32, callee_pi: i32, projection: i32):
        self.effect_flow_edges.push(caller_sig)
        self.effect_flow_edges.push(caller_pi)
        self.effect_flow_edges.push(callee_sig)
        self.effect_flow_edges.push(callee_pi)
        self.effect_flow_projections.push(projection)

    // #D5/P0 + D7: complete transitive write/consume/escape_value effects across the whole call
    // graph, so every sig_param_effects entry is final before any share-place
    // decision reads it. A greatest-fixpoint over the recorded edges: propagate the
    // ownership-forcing bits backward until stable. Reference/pointer params never
    // own, so they never receive these bits (mirrors the flush-time clamp). This
    // only ADDS data; nothing consumes the completed bits until the P1 flip, so P0
    // is behavior-neutral.
    fn effect_edge_projection(edge_index: i32) -> i32:
        if edge_index < self.effect_flow_projections.len() as i32: self.effect_flow_projections[edge_index] else: 1

    // The ownership-forcing effects one recorded edge carries from the callee
    // parameter back to the caller parameter — ONE rule, read by the fixpoint
    // and by audit:effects (#927: the audit recomputed the transfer without
    // the D17 projection rule below and reported the demoted consume bit as
    // "missing" on every `param.field` passed to a consuming parameter).
    // D17: ownership-forcing effects do not cross a NON-COPY projection edge —
    // the callee consumes the FIELD, which blanks it and WRITES the caller's
    // root place. Copy-typed projections keep the promotion (aliasing
    // capture, nothing blanked). Mirrors weaken_projection_owning_effects on
    // the direct path so the fixpoint cannot re-promote what direct noting
    // demoted.
    // `callee_param_is_copy` is the Copy-ness of the callee parameter's type,
    // supplied by the caller: is_copy (computing, pre-freeze) in the fixpoint,
    // is_copy_frozen (read-only) in the audit.
    fn effect_edge_transfer(caller_sig: i32, caller_pi: i32, callee_sig: i32, callee_pi: i32, projection: i32, callee_param_is_copy: i32) -> i32:
        let callee_eff = self.sig_param_effect(callee_sig, callee_pi)
        var trans = callee_eff & (EFF_WRITE | EFF_CONSUME | EFF_ESCAPE_VALUE | EFF_RAW_PTR_VALIDITY)
        let e_owning = trans & (EFF_CONSUME | EFF_ESCAPE_VALUE)
        if projection != 0 and e_owning != 0 and callee_param_is_copy == 0:
            trans = (trans - e_owning) | EFF_WRITE
        // References and pointers never own through a parameter. They can
        // still carry a pointee-validity contract, including &*T.
        let caller_ty = self.sig_param_type(caller_sig, caller_pi)
        if caller_ty > 0:
            let caller_kind = self.get_type_kind(self.resolve_alias(caller_ty))
            if caller_kind == TypeKind.TY_REF or caller_kind == TypeKind.TY_PTR:
                trans = trans & EFF_RAW_PTR_VALIDITY
        if self.type_is_raw_pointer_value(caller_ty) == 0:
            trans = trans & ~EFF_RAW_PTR_VALIDITY
        trans

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
                let caller_sig: i32 = self.effect_flow_edges[i]
                let caller_pi: i32 = self.effect_flow_edges[(i + 1)]
                let callee_sig: i32 = self.effect_flow_edges[(i + 2)]
                let callee_pi: i32 = self.effect_flow_edges[(i + 3)]
                i = i + 4
                let projection = self.effect_edge_projection(edge_index)
                edge_index = edge_index + 1
                let edge_arg_ty = self.sig_param_type(callee_sig, callee_pi)
                let edge_arg_is_copy = if edge_arg_ty > 0: self.is_copy(edge_arg_ty as TypeId) else: 1
                let trans = self.effect_edge_transfer(caller_sig, caller_pi, callee_sig, callee_pi, projection, edge_arg_is_copy)
                if trans == 0:
                    continue
                let caller_eff = self.sig_param_effect(caller_sig, caller_pi)
                let merged = caller_eff | trans
                if merged != caller_eff:
                    self.set_sig_param_effect(caller_sig, caller_pi, merged)
                    // explain:effect — the transitive hop that first set the bit.
                    self.record_effect_provenance_edge(caller_sig, caller_pi, merged & (2147483647 - caller_eff), callee_sig, callee_pi)
                    changed = 1

    mut fn finalize_receiver_requirements():
        for si in 0..self.sig_receiver_modes.len() as i32:
            if self.sig_receiver_mode(si) == ReceiverMode.None or self.sig_get_param_count(si) <= 0:
                continue
            self.sig_receiver_required_effects[si] = self.sig_param_effect(si, 0) & EFF_DECLARED_MASK

    fn receiver_decl_node_for_sig(sig: i32) -> i32:
        if sig < 0 or sig >= self.sig_names.len() as i32:
            return 0
        let sym = self.sig_names[sig]
        let direct = self.fn_decl_nodes.get(sym)
        if direct.is_some():
            return direct.unwrap()
        let specialization = self.concrete_specialization_by_sym.get(sym)
        if specialization.is_some():
            return self.concrete_specialization_nodes[specialization.unwrap()]
        0

    fn sig_is_drop_body(sig: i32) -> bool:
        let node = self.receiver_decl_node_for_sig(sig)
        if node == 0: return false
        let impl_node = self.impl_node_for_method_decl(node)
        if impl_node != 0 and self.ast.get_data2(impl_node) == self.syms.drop: return true
        self.drop_owner_for_fn_symbol(self.sig_names[sig]) != 0

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
        let start = self.trait_method_starts[trait_index]
        let count = self.trait_method_counts[trait_index]
        for i in 0..count:
            let method_index = start + i
            if self.pool_resolve(self.trait_method_names[method_index]) != method_name: continue
            let param_count = self.trait_method_param_counts[method_index]
            let param_start = self.trait_method_param_starts[method_index]
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
            let name: str = self.pool_resolve(self.sig_names[si])
            if declared == ReceiverMode.Missing:
                let keyword = if required_mode == "read": "fn" else: required_mode ++ " fn"
                self.emit_error(f"method receiver mode is missing; compiler effects require `{keyword}` for '{name}'", node)
            else if declared == ReceiverMode.Read and required_mode != "read":
                let keyword = if required_mode == "mut": "mut fn" else: "move fn"
                self.emit_error(f"read receiver is too weak; compiler effects require `{keyword}` for '{name}'", node)
            else if declared == ReceiverMode.Mut and required_mode == "move":
                self.emit_error(f"mut receiver is too weak; compiler effects require `move fn` for '{name}'", node)

pub fn receiver_required_mode_text(eff: i32) -> str:
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
            let eff = self.sig_receiver_required_effects[si]
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
        let start = self.sig_param_eff_starts[sig]
        let at = start + pi
        if at < 0 or at >= self.sig_param_direct_effects.len() as i32:
            return 0
        self.sig_param_direct_effects[at]

    // Prove whether receiver ownership requirements have any all-root path to a
    // direct consume/escape seed. If every path crosses a projection, consuming a
    // field was incorrectly promoted to consuming the whole receiver.
    fn audit_receiver_projection_origins() -> str:
        let root_owned: Vec[i32] = Vec.new()
        for i in 0..self.sig_param_effects.len() as i32:
            let direct = if i < self.sig_param_direct_effects.len() as i32: self.sig_param_direct_effects[i] else: 0
            root_owned.push(if (direct & (EFF_CONSUME | EFF_ESCAPE_VALUE)) != 0: 1 else: 0)
        var changed = true
        while changed:
            changed = false
            var ei = 0
            var edge_index = 0
            while ei + 3 < self.effect_flow_edges.len() as i32:
                let caller_sig = self.effect_flow_edges[ei]
                let caller_pi = self.effect_flow_edges[(ei + 1)]
                let callee_sig = self.effect_flow_edges[(ei + 2)]
                let callee_pi = self.effect_flow_edges[(ei + 3)]
                ei = ei + 4
                let projection = if edge_index < self.effect_flow_projections.len() as i32: self.effect_flow_projections[edge_index] else: 1
                edge_index = edge_index + 1
                if projection != 0:
                    continue
                let caller_start = self.sig_param_eff_starts[caller_sig]
                let callee_start = self.sig_param_eff_starts[callee_sig]
                let caller_at = caller_start + caller_pi
                let callee_at = callee_start + callee_pi
                if root_owned[callee_at] == 0 or root_owned[caller_at] != 0:
                    continue
                let caller_tid = self.sig_param_type(caller_sig, caller_pi)
                if caller_tid > 0:
                    let caller_kind = self.get_type_kind(self.resolve_alias(caller_tid))
                    if caller_kind == TypeKind.TY_REF or caller_kind == TypeKind.TY_PTR:
                        continue
                root_owned[caller_at] = 1
                changed = true

        var mismatches = 0
        var root_paths = 0
        var projection_only = 0
        var out = ""
        for si in 0..self.sig_receiver_modes.len() as i32:
            let declared = self.sig_receiver_mode(si)
            if declared == ReceiverMode.None or declared == ReceiverMode.Missing:
                continue
            let effect = self.sig_receiver_required_effects[si]
            if (effect & (EFF_CONSUME | EFF_ESCAPE_VALUE)) == 0 or declared == ReceiverMode.Move:
                continue
            mismatches = mismatches + 1
            let at = self.sig_param_eff_starts[si]
            let name = self.pool_resolve(self.sig_names[si])
            if root_owned[at] != 0:
                root_paths = root_paths + 1
                out = out ++ f"root-path\t{name}\n"
            else:
                projection_only = projection_only + 1
        f"receiver-projection-audit: mismatches={mismatches} projection-only={projection_only} root-paths={root_paths}\n" ++ out

    // D5 (superseded — docs/meetings/2026-07-05-D5-historical-share-place-free-parameter-design-superseded.md): the effects-based share-place
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
            let fn_sym = self.sig_names[si]
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
    mut fn stamp_move_site_liveness(start: i32):
        var i = start
        while i + 8 < self.consume_call_sites.len() as i32:
            if self.consume_call_sites[(i + 8)] == 0:
                let root = self.consume_call_sites[(i + 4)]
                let field = self.consume_call_sites[(i + 5)]
                let site_seq = self.consume_call_sites[(i + 6)]
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
                    self.consume_call_sites[(i + 8)] = verdict
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
            let arg_node = self.consume_call_sites[i]
            let callee_sig = self.consume_call_sites[(i + 1)]
            let callee_pi = self.consume_call_sites[(i + 2)]
            let file_id = self.consume_call_sites[(i + 3)]
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
        var i = if self.sig_text_index.contains(target): self.sig_text_index.get(target).unwrap() else: -1
        while i >= 0:
            if self.symbol_visible_from_current(self.sig_names[i]) != 0:
                return i
            i = self.sig_text_prev[i]
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
                let impl_direct_tp_count = self.ast.state.impl_type_params[(impl_direct_tp_meta + 2)]
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
                let impl_tp_count = self.ast.state.impl_type_params[(impl_tp_meta + 2)]
                if impl_tp_count > 0:
                    return 1

        var fn_name = self.extract_decl_name_after(node, "fn")
        if fn_name.len() == 0:
            fn_name = with_str_clone_ref(self.pool_resolve_symbol(parsed))
        for ci in 0..fn_name.len() as i32:
            if fn_name[ci] == 46:
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
            if self.generic_fn_candidate_syms[i] == sym and self.generic_fn_candidate_nodes[i] == node:
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
            if self.generic_fn_candidate_syms[i] == key and self.generic_fn_candidate_nodes[i] == node:
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
        self.sig_ret_types[idx]

    fn sig_param_type(idx: i32, param_i: i32) -> i32:
        let start = self.sig_param_starts[idx]
        self.sig_params[(start + param_i)]

    fn sig_get_param_count(idx: i32) -> i32:
        self.sig_param_counts[idx]

    fn sig_is_variadic(idx: i32) -> i32:
        self.sig_variadic[idx]

    fn sig_is_unprototyped(idx: i32) -> bool: self.unprototyped_sigs.contains(idx)

    // The promoted argument types Sema recorded for a call (#1831, #1849);
    // empty for a call that has none.
    fn c_promoted_arg_types(call_node: i32) -> Vec[i32]:
        let out: Vec[i32] = Vec.new()
        let start = self.c_promoted_arg_starts.get(call_node) ?? -1
        if start < 0:
            return out
        for i in 0..self.c_promoted_arg_data[start]:
            out.push(self.c_promoted_arg_data[(start + 1 + i)])
        out

    fn sig_idx_valid(idx: i32) -> i32:
        if idx < 0:
            return 0
        if idx >= self.sig_names.len() as i32:
            return 0
        1

    mut fn set_sig_return_type(idx: i32, ret: i32):
        if self.sig_idx_valid(idx) == 0:
            return
        self.sig_ret_types[idx] = ret
        let fn_tid: i32 = self.sig_type_ids[idx]
        if fn_tid >= 0 and fn_tid < self.type_d2.len() as i32:
            self.type_d2[fn_tid] = ret

    mut fn copy_sig_alias(alias: i32, source_sig: i32):
        if self.sig_idx_valid(source_sig) == 0:
            return
        let fn_tid = self.sig_type_ids[source_sig]
        let ret = self.sig_ret_types[source_sig]
        let param_start = self.sig_param_starts[source_sig]
        let param_count: i32 = self.sig_param_counts[source_sig]
        let variadic = self.sig_variadic[source_sig]
        self.add_sig(alias, fn_tid, ret, param_start, param_count, variadic)
        let alias_sig = self.get_sig(alias)
        if alias_sig < 0:
            return
        for pi in 0..param_count:
            self.set_sig_param_effect(alias_sig, pi, self.sig_param_effect(source_sig, pi))
            self.set_sig_param_view_origin(alias_sig, pi, self.sig_param_view_origin(source_sig, pi))
            self.set_sig_param_view_through(alias_sig, pi, self.sig_param_view_through(source_sig, pi))
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

    mut fn register_fn_clause_decl(dispatch_sym: i32, decl_node: i32):
        let group = self.ensure_fn_clause_group(dispatch_sym)
        let start = self.fn_clause_group_starts[group]
        let count: i32 = self.fn_clause_group_counts[group]
        for i in 0..count:
            if self.fn_clause_group_decls[(start + i)] == decl_node:
                return
        self.fn_clause_group_decls.push(decl_node)
        self.fn_clause_group_counts[group] = count + 1

    fn fn_clause_group_count() -> i32:
        self.fn_clause_group_names.len() as i32

    fn fn_clause_group_name(group: i32) -> i32:
        self.fn_clause_group_names[group]

    fn fn_clause_group_clause_count(group: i32) -> i32:
        self.fn_clause_group_counts[group]

    fn fn_clause_group_clause(group: i32, clause_i: i32) -> i32:
        let start = self.fn_clause_group_starts[group]
        self.fn_clause_group_decls[(start + clause_i)]

    fn fn_is_clause_body_symbol(sym: i32) -> i32:
        if self.fn_clause_body_dispatch.contains(sym): 1 else: 0

    // ── Main entry point ─────────────────────────────────────────────

    mut fn check_module():
        let profile = sema_profile_enabled()
        var t = with_clock_nanos()
        self.prepare_for_comptime_transform()
        self.validate_no_std_requirements()
        if profile:
            t = with_clock_nanos()
        self.check_top_level_let_values()
        if profile:
            sema_profile_report("top_level_let_values", t)
            t = with_clock_nanos()
        self.check_type_decl_field_defaults()
        if profile:
            sema_profile_report("type_decl_field_defaults", t)
            t = with_clock_nanos()
        let types_before = self.type_kinds.len()
        let symbols_before = self.pool.state.symbol_texts.len()
        let sigs_before = self.sig_names.len()
        let diags_start = self.diags.items.len() as i32
        self.check_bodies()
        if profile:
            sema_profile_report("bodies", t)
            // What body checking adds to the module-wide tables: every entry
            // is numbered in check order, which is what a parallel check
            // would have to reproduce.
            with_eprint(f"[profile] sema.bodies.added types={self.type_kinds.len() - types_before} symbols={self.pool.state.symbol_texts.len() - symbols_before} sigs={self.sig_names.len() - sigs_before}")
            t = with_clock_nanos()
        // Complete transitive effects before any deferred acceptance verdict
        // reads a callee's parameter contract.
        self.fixpoint_effect_flow()
        self.enforce_raw_pointer_contracts()
        // D63: a callable parameter passed on is invoked as often as the
        // parameter it reaches; settled before closure arguments are judged.
        self.propagate_callable_forwards()
        // D63: closure arguments are judged against their callee's complete
        // escape effects and call-once flags, whatever the declaration order.
        self.finalize_closure_arg_checks()
        self.check_generator_pulls()
        self.finalize_receiver_requirements()
        self.enforce_receiver_modes()
        // D5 superseded: free-parameter share-place is no longer inferred from
        // effects — the declared signature is authoritative (&T borrows, T owns).
        self.finalize_call_site_ownership()
        self.finalize_unsafe_global_scope_checks()
        self.check_reachable_comptime_errors()
        self.diags.sort_from(diags_start)
        if profile:
            sema_profile_report("effects_receivers_ownership", t)

    mut fn prepare_for_comptime_transform():
        let profile = sema_profile_enabled()
        var t = with_clock_nanos()
        self.compute_method_origins()
        if profile:
            sema_profile_report("method_origins", t)
            t = with_clock_nanos()
        self.collect_declarations()
        if profile:
            sema_profile_report("collect_declarations", t)
            t = with_clock_nanos()
        self.build_ci_scoping()
        self.validate_copy_derives()
        self.validate_compiler_hooks()
        self.validate_generic_type_decls()
        if profile:
            sema_profile_report("ci_scoping_copy_hooks_generics", t)

// ── Utility functions ────────────────────────────────────────────

// §18.2: the standard library's prelude module, std.builtins.
pub fn sema_path_is_std_builtins(path: &str) -> bool:
    path == "lib/std/builtins.w" or path == "<embedded-std>/std/builtins.w" or path.ends_with("/lib/std/builtins.w")

// §18.1: a module without a `module` header names itself by its file's
// stem, each character that cannot appear in an identifier replaced by `_`
// and a leading digit prefixed with `_`.
pub fn sema_module_stem_self_name(path: &str) -> str:
    var start = 0
    for i in 0..path.len() as i32:
        if path[i] == '/': start = i + 1
    var end = path.len() as i32
    if path.ends_with(".wi"): end = end - 3
    else if path.ends_with(".w"): end = end - 2
    if end <= start:
        return ""
    var out = ""
    for i in start..end:
        let c = path[i]
        let ident_char = (c >= 'a' and c <= 'z') or (c >= 'A' and c <= 'Z') or (c >= '0' and c <= '9') or c == '_'
        out = out ++ (if ident_char: path.slice(i as i64, (i + 1) as i64) else: "_")
    if path[start] >= '0' and path[start] <= '9':
        out = "_" ++ out
    out

pub fn sema_str_has_data(text: &str) -> i32:

    if text.len() <= 0:
        return 0
    let data_ptr = unsafe *(text as *const str as *const *const u8)
    if data_ptr as i64 == 0:
        return 0
    1

pub fn sema_str_contains_char(text: &str, needle: i32) -> i32:
    if sema_str_has_data(text) == 0:
        return 0
    var i = 0
    while i < text.len() as i32:
        if text[i] == needle:
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
            let cost = if a[(i - 1)] == b[(j - 1)]: 0 else: 1
            let del = prev[j] + 1
            let ins = cur[(j - 1)] + 1
            let sub = prev[(j - 1)] + cost
            var best = del
            if ins < best: best = ins
            if sub < best: best = sub
            cur.push(best)
            if best < row_min: row_min = best
        prev = cur
        if row_min > max: return max + 1
    prev[bl]

impl Sema:
    fn suggest_name(target: &str, node: i32) -> str:
        if target.len() == 0: return ""
        let max_dist = if target.len() as i32 <= 3: 1 else: 2
        var best_name = ""
        var best_dist = max_dist + 1
        // Search scope bindings
        for idx in 0..self.bind_names.len():
            let sym = self.bind_names[idx]
            let name = self.pool_resolve(sym)
            if name.len() > 0:
                let d = sema_levenshtein(target, name, max_dist)
                if d < best_dist:
                    best_dist = d
                    best_name = with_str_clone_ref(name)
        // Search function signatures
        for si in 0..self.sig_names.len():
            let sym = self.sig_names[si]
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
            let tk = self.type_kinds[ti]
            if tk == TypeKind.TY_STRUCT as i32 or tk == TypeKind.TY_ENUM as i32:
                let sym = self.type_d0[ti]
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
        var diag = Diagnostic.err(msg, self.diagnostic_node_span(node))
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
        // §4 (#1220): a float where an integer is demanded is a narrowing
        // (truncate or round: two meanings), spelled with `as`; accepted here,
        // it surfaced as codegen's "wrong argument type" with no location.
        if exp_k == TypeKind.TY_FN and act_k == TypeKind.TY_FN:
            return self.fn_types_assignable(exp_r as i32, act_r as i32)
        if exp_k == TypeKind.TY_EXTERN_FN and act_k == TypeKind.TY_EXTERN_FN:
            if self.callable_unsafe_coercion_ok(exp_r as i32, act_r as i32) == 0:
                return 0
            return self.fn_types_compatible(exp_r, act_r)
        // §4.3d: a vector converts lane-wise under §4.2.6, so its lanes are
        // assignable as scalars are (reject_implicit_numeric_narrowing
        // refuses the narrowings); the lane counts agree. A mask is exact.
        if exp_k == TypeKind.TY_VECTOR and act_k == TypeKind.TY_VECTOR:
            if self.get_type_d1(exp_r) != self.get_type_d1(act_r):
                return 0
            let exp_lane_k = self.get_type_kind(self.resolve_alias(self.get_type_d0(exp_r) as TypeId))
            let act_lane_k = self.get_type_kind(self.resolve_alias(self.get_type_d0(act_r) as TypeId))
            return if exp_lane_k == act_lane_k: 1 else: 0
        if exp_k == TypeKind.TY_MASK and act_k == TypeKind.TY_MASK:
            return if self.get_type_d0(exp_r) == self.get_type_d0(act_r) and self.get_type_d1(exp_r) == self.get_type_d1(act_r): 1 else: 0
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
            if self.ref_numeric_pointees_differ(exp_r, act_r) != 0:
                return 0
            if self.pointer_pointees_compatible(exp_r, act_r) != 0:
                return 1
            return self.ref_to_dyn_pointee_coercible(exp_r, act_r)
        if exp_k == TypeKind.TY_REF and act_k == TypeKind.TY_PTR:
            return self.pointer_pointees_compatible(exp_r, act_r)
        if exp_k == TypeKind.TY_FN and act_k == TypeKind.TY_FN:
            return self.fn_types_assignable(exp_r as i32, act_r as i32)
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
                let exp_elem: i32 = self.type_extra[(exp_start + ei)]
                let act_elem: i32 = self.type_extra[(act_start + ei)]
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
            if self.pool_resolve(self.dyn_impl_flat_method_names[(start + i)]) == method_text:
                return start + i
        -1

    fn dyn_impl_row_sig(row: i32): self.dyn_impl_flat_sigs[row]
    fn dyn_impl_row_mono_sym(row: i32): self.dyn_impl_flat_mono_syms[row]

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
        if self.get_type_d1(expected) != self.get_type_d1(actual) or self.fn_type_is_variadic(expected) != self.fn_type_is_variadic(actual):
            return 0
        let param_count = self.get_type_d1(expected)
        let exp_start = self.get_type_d0(expected)
        let act_start = self.get_type_d0(actual)
        for pi in 0..param_count:
            let exp_param = self.type_extra[(exp_start + pi)]
            let act_param = self.type_extra[(act_start + pi)]
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
        // §4 (#1220): a float where an integer is demanded is a narrowing
        // (truncate or round: two meanings), spelled with `as`; accepted here,
        // it surfaced as codegen's "wrong argument type" with no location.
        if exp_k == TypeKind.TY_FN and act_k == TypeKind.TY_FN:
            return self.fn_types_assignable(exp_r as i32, act_r as i32)
        if exp_k == TypeKind.TY_EXTERN_FN and act_k == TypeKind.TY_EXTERN_FN:
            if self.callable_unsafe_coercion_ok(exp_r as i32, act_r as i32) == 0:
                return 0
            return self.fn_types_compatible_frozen(exp_r, act_r)
        // §4.3d: the twin of types_compatible_fast's vector and mask rule.
        if exp_k == TypeKind.TY_VECTOR and act_k == TypeKind.TY_VECTOR:
            if self.get_type_d1(exp_r) != self.get_type_d1(act_r):
                return 0
            let exp_lane_k = self.get_type_kind(self.resolve_alias(self.get_type_d0(exp_r) as TypeId))
            let act_lane_k = self.get_type_kind(self.resolve_alias(self.get_type_d0(act_r) as TypeId))
            return if exp_lane_k == act_lane_k: 1 else: 0
        if exp_k == TypeKind.TY_MASK and act_k == TypeKind.TY_MASK:
            return if self.get_type_d0(exp_r) == self.get_type_d0(act_r) and self.get_type_d1(exp_r) == self.get_type_d1(act_r): 1 else: 0
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
            if self.ref_numeric_pointees_differ(exp_r, act_r) != 0:
                return 0
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
            return self.fn_types_assignable(exp_r as i32, act_r as i32)
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
                let exp_elem = self.type_extra[(exp_start + ei)]
                let act_elem = self.type_extra[(act_start + ei)]
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
            let payload_count = self.type_extra[(pos + 1)]
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
        // Only over int (#1711): a float against Unit, bool or str has no
        // arithmetic type. Answering the float made every caller that asks
        // "does this promote?" accept it — a D43 tail join of `f64` and
        // `Unit` arms inferred `f64`, and `let x: f64 = true` type-checked.
        if lk == TypeKind.TY_FLOAT and rk == TypeKind.TY_INT:
            return lhs_numeric as TypeId
        if rk == TypeKind.TY_FLOAT and lk == TypeKind.TY_INT:
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
        // D111 (supersedes D28 ruling 1): a str is a value — passing one
        // copies it. The buffer is shared and counted, so a copy is a retain
        // (codegen's copy glue) and a str still has drop glue (the release).
        if tk == TypeKind.TY_STR:
            return 1
        // D63 (§12.4 "The callable type"): `fn(A) -> R` is not Copy, bare
        // functions included — a `move ||` closure owns its environment and
        // Copy is a property of the type, not of a value's provenance.
        // `let g = f` moves f; a call through a binding observes it.
        if tk == TypeKind.TY_FN:
            return 0
        if tk == TypeKind.TY_PTR or tk == TypeKind.TY_REF or tk == TypeKind.TY_EXTERN_FN or tk == TypeKind.TY_GENERIC_FN:
            return 1
        // c_va_list is C's va_list: opaque bytes a migrated body hands on
        // (gzprintf passes it to gzvprintf, then va_ends it) — Copy, as in C.
        if tk == TypeKind.TY_VA_LIST:
            return 1
        // §4.3d: Vector and Mask are Copy.
        if tk == TypeKind.TY_VECTOR or tk == TypeKind.TY_MASK:
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
                    if self.is_copy(self.type_extra[(tuple_te_start + ei)]) == 0:
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
                let start = self.impl_starts[idx]
                let count = self.impl_counts[idx]
                for di in 0..count:
                    if self.impl_extra[(start + di)] == self.syms.copy_trait:
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
            if self.drop_consumed_field_owner_syms[i] == owner_sym and self.drop_consumed_field_syms[i] == field_sym:
                return
        self.drop_consumed_field_owner_syms.push(owner_sym)
        self.drop_consumed_field_syms.push(field_sym)

    fn drop_consumed_field(owner_sym: i32, field_sym: i32) -> i32:
        if owner_sym == 0 or field_sym == 0:
            return 0
        for i in 0..self.drop_consumed_field_owner_syms.len() as i32:
            if self.drop_consumed_field_owner_syms[i] == owner_sym and self.drop_consumed_field_syms[i] == field_sym:
                return 1
        0

    // ── Borrow checking ──────────────────────────────────────────────

    mut fn expire_borrows_in_scope(scope_start: i32):
        var i = self.bind_names.len() as i32 - 1
        while i >= scope_start:
            // Annotated: copy the id out — an unannotated binding views the
            // element and the swap-remove below mutates the same receiver.
            let sym: i32 = self.bind_names[i]
            // Remove borrows whose ref_binding is this sym
            var bi = 0
            while bi < self.borrow_refs.len() as i32:
                if self.borrow_refs[bi] == sym:
                    // Swap-remove
                    let last = self.borrow_refs.len() as i32 - 1
                    if bi < last:
                        self.borrow_kinds[bi] = self.borrow_kinds[last]
                        self.borrow_places[bi] = self.borrow_places[last]
                        self.borrow_fields[bi] = self.borrow_fields[last]
                        self.borrow_refs[bi] = self.borrow_refs[last]
                        self.borrow_path_starts[bi] = self.borrow_path_starts[last]
                        self.borrow_path_counts[bi] = self.borrow_path_counts[last]
                        self.borrow_scope_depths[bi] = self.borrow_scope_depths[last]
                        self.borrow_creation_nodes[bi] = self.borrow_creation_nodes[last]
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

impl Sema:
    // One signature's receiver requirement from its finalized param[0]
    // effect — what finalize_receiver_requirements does for every signature
    // that existed when it ran; specializations created later ask for it
    // themselves (#1600, #1613).
    mut fn finalize_receiver_requirement_for(si: i32):
        if si < 0 or si >= self.sig_receiver_modes.len() as i32:
            return
        if self.sig_receiver_mode(si) == ReceiverMode.None or self.sig_get_param_count(si) <= 0:
            return
        while self.sig_receiver_required_effects.len() as i32 <= si:
            self.sig_receiver_required_effects.push(0)
        self.sig_receiver_required_effects[si] = self.sig_param_effect(si, 0) & EFF_DECLARED_MASK
    // Where the binding a declaration would shadow came from — the module
    // whose global it is, a bundle interface's storage, or this scope — so
    // the diagnostic names the collision instead of a bare name (#1703).
    fn shadowed_binding_origin_note(sym: i32, idx: i32) -> str:
        if self.global_value_decl_bindings.contains(sym) and self.global_value_decl_bindings.get(sym).unwrap() == idx:
            return " (a global of module " ++ self.global_value_decl_paths.get(sym).unwrap() ++ ")"
        if self.interface_global_index.contains(sym) and self.interface_global_index.get(sym).unwrap() == idx:
            return " (a bundle interface global)"
        for ai in 0..self.interface_global_alt_binds.len() as i32:
            if self.interface_global_alt_binds[ai] == idx:
                return " (a bundle interface global)"
        " (bound earlier in this scope)"

pub fn sema_field_key(decl_node: i32, field: i32) -> i64: (decl_node as i64) * 4294967296 + field as i64
