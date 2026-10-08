// Type tags shared by semantic analysis and the frozen MIR type tables.
// Keep this vocabulary independent of the semantic-analysis driver.
pub enum TypeKind: i32:
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
    // C's va_list, modeled per target (#1104): a pointer on Darwin and
    // Windows, a 24-byte __va_list_tag on SysV x86_64, a 32-byte
    // struct on AAPCS64 Linux. Opaque to With code; Copy; passed to a
    // callee the way the target's C passes va_list (TypeLayout, FnAbi).
    TY_VA_LIST = 21
    // §4.3d (D78): a SIMD vector, `Vector[N, T]`: d0 = the lane type, d1 = N.
    // Copy; laid out as the target's vector of that shape (TypeLayout) and
    // lowered to LLVM `<N x T>`.
    TY_VECTOR = 22
    // §4.3d: `Mask[N, W]`, N lanes of a W-bit boolean (all ones or zero):
    // d0 = W (8, 16, 32 or 64), d1 = N. What a lane-wise comparison yields.
    TY_MASK = 23
    // §4.3d: a compile-time integer bound to a generic parameter — the lane
    // count `N` of `fn dot[N](a: Vector[N, f32])`, inferred from the
    // arguments (d0 = the value). Only ever a generic substitution, never
    // the type of a value.
    TY_CONST_INT = 24

pub type TypeId = i32

// §4.3d (D78): the vector operation Sema decided for a node
// (Sema.vector_ops); MirLower lowers it and never re-derives it.
pub enum VectorOp: i32:
    // `f32x4(a, b, c, d)` / `Vector[N, T](...)`: the call's arguments are
    // the lanes, in order.
    CONSTRUCT = 1
    // `f32x4.splat(s)`: the one argument in every lane.
    SPLAT = 2
    // `Vector[N, T].from_bits(u)` and `v.bits()`: the same bytes as the
    // other lane type.
    FROM_BITS = 3
    BITS = 4
    // `m.select(a, b)`: a's lane where m's is set, else b's.
    SELECT = 5
    // `m.all()` / `m.any()`.
    ALL = 6
    ANY = 7
    // `v.reduce_add()` … `v.reduce_xor()`.
    REDUCE_ADD = 8
    REDUCE_MUL = 9
    REDUCE_MIN = 10
    REDUCE_MAX = 11
    REDUCE_AND = 12
    REDUCE_OR = 13
    REDUCE_XOR = 14
    // `v.x`, `v.wzyx`: the lanes Sema.vector_swizzles names.
    SWIZZLE = 15
    // `m[i]`: a mask lane read as a bool (D80).
    MASK_LANE = 16

impl Copy for VectorOp

pub enum BorrowKind: i32:
    SHARED = 0
    EXCLUSIVE = 1

// §4.5 (D75, #1802): what a cast whose target relabels its source does with
// the source (Sema.cast_modes). The target states the mode, as a parameter's
// type does.
pub enum CastMode: i32:
    // An owned value crosses into or out of its distinct type: the source is
    // consumed and the result owns it.
    MOVE = 1
    // An owned place viewed as a view type (`n as &str`, `s as []u8`): the
    // result borrows the place.
    BORROW = 2
    // A cast through a reference (`r as str`, `r: &Name`): the result is the
    // same reference, relabeled — a view with the source's origins.
    REF_RELABEL = 3

// D61 (§15.4.7): how `:?` formats one registered type (Sema.debug_fmt_*).
pub enum DebugFmtKind: i32:
    // A formatter MirLower synthesizes: struct, enum, tuple, array, slice,
    // Vec, Box — each component formatted with `:?`.
    SYNTH = 1
    // An explicit `impl Debug`: its debug_str, at every depth.
    IMPL = 2
    // A std collection's formatter method (HashMap, BTreeMap).
    HELPER = 3

// ── Call intrinsic kinds ─────────────────────────────────────────
// Attached to TermKind.TK_CALL terminators to mark known container/builtin
// operations. Both LLVM and C backends read these instead of
// inferring builtin kind from method names at codegen time.

pub enum MirIntrinsic: i32:
    NONE
    VEC_NEW
    FIXED_STRING_NEW
    FIXED_STRING_LEN
    FIXED_STRING_LEN32
    FIXED_STRING_LEN64
    FIXED_STRING_CAPACITY
    FIXED_STRING_IS_EMPTY
    FIXED_STRING_CLEAR
    FIXED_STRING_PUSH_BYTE
    FIXED_STRING_PUSH_STR
    FIXED_STRING_AS_VIEW
    FIXED_STRING_EQUALS
    VEC_PUSH
    VEC_GET
    VEC_LEN
    VEC_IS_EMPTY
    VEC_SET
    VEC_REMOVE
    VEC_CLEAR
    VEC_POP
    MAP_NEW
    MAP_INSERT
    MAP_GET
    MAP_CONTAINS
    MAP_LEN
    MAP_REMOVE
    COLLECTION_LITERAL
    MAP_LITERAL
    OPT_IS_SOME
    OPT_UNWRAP
    OPT_EXPECT
    STR_LEN
    STR_BYTE_AT
    STR_SLICE
    STR_CONTAINS
    STR_CONTAINS_CHAR
    STR_STARTS_WITH
    STR_ENDS_WITH
    STR_FIND
    MAP_CLEAR
    VECITER_NEXT
    VEC_ITER
    OPT_IS_NONE
    STR_SPLIT
    STR_TO_UPPER
    STR_TO_LOWER
    STR_REPLACE
    STR_INDEX_OF
    MAP_INCREMENT
    MAP_DECREMENT
    MAP_UPDATE
    VEC_MAP
    VEC_FILTER
    VEC_FOLD
    ITER_MAP
    ITER_FILTER
    ITER_FILTER_MAP
    ITER_TAKE
    ITER_DROP
    ITER_TAKE_WHILE
    ITER_DROP_WHILE
    ITER_ZIP
    ITER_ENUMERATE
    ITER_CHAIN
    ITER_ZIP_WITH
    ITER_STEP_BY
    ITER_FLAT_MAP
    ITER_FOLD
    ITER_REDUCE
    ITER_SUM
    ITER_PRODUCT
    ITER_MIN
    ITER_MAX
    ITER_MIN_BY
    ITER_MAX_BY
    ITER_FIND
    ITER_POSITION
    ITER_ANY
    ITER_ALL
    ITER_NONE
    ITER_FOR_EACH
    ITER_COUNT
    ITER_COLLECT
    ITER_PARTITION
    ITER_UNZIP
    MAPITER_NEXT
    FILTERITER_NEXT
    FILTERMAPITER_NEXT
    TAKEITER_NEXT
    DROPITER_NEXT
    TAKEWHILEITER_NEXT
    DROPWHILEITER_NEXT
    ZIPITER_NEXT
    ENUMERATEITER_NEXT
    CHAINITER_NEXT
    ZIPWITHITER_NEXT
    STEPBYITER_NEXT
    FLATMAPITER_NEXT
    VEC_CONTAINS
    STR_REPEAT
    ARR_LEN
    GENERIC_CALL
    VEC_JOIN
    DYN_VTABLE_CMP
    DYN_DOWNCAST
    OPT_FILTER
    ROTATE_LEFT
    ROTATE_RIGHT
    VEC_WITH_CAPACITY
    FMT_TO_STR
    FMT_DEBUG_STR
    FMT_DEBUG
    FMT_SPEC
    INT_SWAP_BYTES
    POPCOUNT
    CLZ
    CTZ
    BITREVERSE
    MIN
    MAX
    ABS
    FMA
    ASM
    MULTI_INDEX
    MULTI_INDEX_SET
    FIBER_SPAWN
    FIBER_AWAIT
    FIBER_SELECT
    FIBER_CANCEL
    CHAN_CREATE
    CHAN_SEND
    CHAN_RECV
    CHAN_CLOSE
    ASYNC_BLOCK_SPAWN
    FIBER_IS_DONE
    FIBER_IS_CANCELLED
    FIBER_WAS_CANCELLED_RETURN
    FIBER_SET_CANCELLED_RETURN
    FIBER_WAIT_CANCELLED
    FIBER_CLEANUP_AWAIT
    SCOPE_CREATE
    SCOPE_AWAIT_ALL
    SCOPE_DESTROY
    THREAD_SCOPE_CREATE
    THREAD_SCOPE_JOIN_ALL
    THREAD_SCOPE_DESTROY
    ATOMIC_LOAD
    ATOMIC_STORE
    ATOMIC_SWAP
    ATOMIC_FETCH_ADD
    ATOMIC_FETCH_SUB
    ATOMIC_FETCH_AND
    ATOMIC_FETCH_OR
    ATOMIC_FETCH_XOR
    ATOMIC_FETCH_MIN
    ATOMIC_FETCH_MAX
    ATOMIC_CAS
    ATOMIC_CAS_WEAK
    ATOMIC_FENCE
    FMT_BUF_NEW
    FMT_BUF_WRITE_STR
    FMT_BUF_WRITE_FMT
    FMT_BUF_FINISH
    VEC_SLOT
    VECSLOT_GET
    VECSLOT_SET
    VEC_ITER_PLACE
    VECITERPLACE_NEXT
    MAP_ENTRY
    ENTRY_OR_INSERT
    ENTRY_GET
    ENTRY_SET
    VEC_GET_DISJOINT
    VEC_RANGE
    SPLIT_AT
    SPLIT_AT_MUT
    VECRANGE_GET
    VECRANGE_SET
    VECRANGE_LEN
    VEC_ITER_REF
    VECITERREF_NEXT
    VEC_GET_REF
    DYN_CALL
    SLOTMAP_NEW
    SLOTMAP_INSERT
    SLOTMAP_GET
    SLOTMAP_SLOT
    SLOTMAP_REMOVE
    SLOTMAP_REPLACE
    SLOTMAP_CONTAINS
    SLOTMAP_LEN
    SLOTMAP_GET_DISJOINT
    SLOTMAPSLOT_GET
    SLOTMAPSLOT_SET
    FIBER_SELECT_BIASED
    FIBER_DETACH
    FIBER_DETACH_CANCEL
    VEC_LEN32
    VEC_LEN64
    VEC_ULEN32
    MAP_LEN32
    MAP_LEN64
    MAP_ULEN32
    STR_LEN32
    STR_LEN64
    STR_ULEN32
    ARR_LEN32
    ARR_LEN64
    ARR_ULEN32
    VECRANGE_LEN32
    VECRANGE_LEN64
    VECRANGE_ULEN32
    SLOTMAP_LEN32
    SLOTMAP_LEN64
    SLOTMAP_ULEN32
    FMT_BUF_WRITE_STR_REF
    STR_CLONE_REF
    // A floating-point math builtin (`cos(x)` / `x.cos()`); the MathBuiltins
    // row id rides on the call (call_math_fn_ids) and picks the lowering.
    MATH_FN
    // D44: walk a map's table in place. (map) -> slot count; (map, slot) ->
    // occupied?; (map, slot) -> the slot's key / value, as a view when the
    // destination is `&T` and read through it when the destination is `T`.
    MAP_CAPACITY
    MAP_SLOT_OCCUPIED
    MAP_KEY_AT
    MAP_VALUE_AT
    MAP_TAKE_AT
    // D63: `f.clone()` on a callable value — copies the pair; an owned
    // environment (a `move ||` closure's heap cell) is cloned by the cell's
    // clone fn.
    CLOSURE_CLONE
    // D75 (§16.2b.5): C variadic definitions. VA_START starts the list in
    // its binding (the call destination); VA_ARG reads the next argument
    // through the list place (arg 0) as the destination's type and advances
    // it; VA_END ends the list at its binding's scope exit (DK_VA_END).
    VA_START
    VA_ARG
    VA_END
    // §4.3d (D78): vector operations Sema decided (Sema.vector_ops).
    // SIMD_BITCAST: `.bits()` / `from_bits` — arg 0 reinterpreted as the
    // destination vector type. SIMD_SELECT: (mask, a, b) -> a lane where the
    // mask lane is set, else b. SIMD_ALL / SIMD_ANY: (mask) -> bool.
    // SIMD_REDUCE_*: (vector) -> the lane type.
    SIMD_BITCAST
    SIMD_SELECT
    SIMD_ALL
    SIMD_ANY
    SIMD_REDUCE_ADD
    SIMD_REDUCE_MUL
    SIMD_REDUCE_MIN
    SIMD_REDUCE_MAX
    SIMD_REDUCE_AND
    SIMD_REDUCE_OR
    SIMD_REDUCE_XOR
    // (mask, index) -> the lane as a bool, the index range-checked.
    SIMD_MASK_LANE
    // (mask, index, bool) -> the mask with that lane set, range-checked.
    SIMD_MASK_LANE_SET
    // D111: (copy x) -> x as one more holder of every str it carries. MirLower
    // routes a consumed copy of a Copy type with drop glue through it; codegen
    // emits the copy glue (a retain per str).
    VALUE_COPY

// Copy: MirIntrinsic is a lightweight integer tag passed by value, stored in
// Vec/HashMap, and compared throughout MIR lowering and codegen.
impl Copy for MirIntrinsic

// D44: the std-only slot accessors a map traversal walks (std.collections).
pub fn mir_map_slot_intrinsic(name: &str) -> MirIntrinsic:
    if name == "slot_count": return MirIntrinsic.MAP_CAPACITY
    if name == "slot_live": return MirIntrinsic.MAP_SLOT_OCCUPIED
    if name == "slot_key": return MirIntrinsic.MAP_KEY_AT
    if name == "slot_value": return MirIntrinsic.MAP_VALUE_AT
    if name == "slot_take": return MirIntrinsic.MAP_TAKE_AT
    MirIntrinsic.NONE

pub fn mir_len_method_intrinsic(base: MirIntrinsic, method_name: &str) -> MirIntrinsic:
    if method_name == "len":
        return base
    if base == MirIntrinsic.VEC_LEN:
        if method_name == "len32": return MirIntrinsic.VEC_LEN32
        if method_name == "len64": return MirIntrinsic.VEC_LEN64
        if method_name == "ulen32": return MirIntrinsic.VEC_ULEN32
    if base == MirIntrinsic.MAP_LEN:
        if method_name == "len32": return MirIntrinsic.MAP_LEN32
        if method_name == "len64": return MirIntrinsic.MAP_LEN64
        if method_name == "ulen32": return MirIntrinsic.MAP_ULEN32
    if base == MirIntrinsic.STR_LEN:
        if method_name == "len32": return MirIntrinsic.STR_LEN32
        if method_name == "len64": return MirIntrinsic.STR_LEN64
        if method_name == "ulen32": return MirIntrinsic.STR_ULEN32
    if base == MirIntrinsic.ARR_LEN:
        if method_name == "len32": return MirIntrinsic.ARR_LEN32
        if method_name == "len64": return MirIntrinsic.ARR_LEN64
        if method_name == "ulen32": return MirIntrinsic.ARR_ULEN32
    if base == MirIntrinsic.VECRANGE_LEN:
        if method_name == "len32": return MirIntrinsic.VECRANGE_LEN32
        if method_name == "len64": return MirIntrinsic.VECRANGE_LEN64
        if method_name == "ulen32": return MirIntrinsic.VECRANGE_ULEN32
    if base == MirIntrinsic.SLOTMAP_LEN:
        if method_name == "len32": return MirIntrinsic.SLOTMAP_LEN32
        if method_name == "len64": return MirIntrinsic.SLOTMAP_LEN64
        if method_name == "ulen32": return MirIntrinsic.SLOTMAP_ULEN32
    MirIntrinsic.NONE

// D65 phase 5 (#2043): how a method call that is neither an ordinary call
// nor a plain intrinsic lowers. Sema decides it from the receiver type and
// the method it resolved (check_method_call_parts) and records it per call
// and instance; MirLower switches on the record and never compares a method
// or type name.
pub enum MethodLowering: i32:
    None = 0
    PtrAsOption
    ExplicitDrop
    OptMap
    OptAndThen
    OptOrElse
    OptFilter
    OptInspect
    OptCopied
    OptCloned
    OptZip
    OptUnzip
    OptFlatten
    OptTranspose
    ResMap
    ResMapErr
    ResContext
    ResWithContext
    ResAndThen
    ResOrElse
    ResInspect
    ResInspectErr
    ResOk
    ResErr
    ResTranspose
    TaskJoinCleanup
    VecSequence
    VecTraverse
    BTreeNew
    UnwrapOr
    UnwrapOrElse
    // `is_empty()` on a receiver with a `len` intrinsic and no `is_empty`
    // one (#1010); the call's intrinsic record is that `len`.
    IsEmptyViaLen

impl Copy for MethodLowering

// D65 phase 5 (#2043): which std generic a type is, by Sema's identity for
// the instance's declaration — never by a later stage reading its name.
pub enum StdGeneric: i32:
    None = 0
    Vec
    HashMap
    HashSet
    BTreeMap
    BTreeSet
    Option
    Result
    Sender
    Receiver
    Atomic
    SlotMap

impl Copy for StdGeneric
