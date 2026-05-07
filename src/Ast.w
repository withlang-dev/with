// Ast — AST node types for the With language.
//
// The AST is produced by the parser and consumed by later passes
// (type checking, lowering, codegen). Nodes are stored in an AstPool
// using index-based references (i32 handles) instead of pointers.
// This follows a SoA (Struct of Arrays) approach for cache-friendly
// access and avoids the need for heap-allocated pointer trees.

use Span
use Token

extern fn with_eprint(s: str) -> void
extern fn with_alloc(size: i64) -> *mut u8

// ── Node kinds ───────────────────────────────────────────────────

type NodeId = distinct i32
impl Copy for NodeId

enum NodeKind: i32:
    // Declarations
    NK_FN_DECL = 1
    NK_TYPE_DECL = 2
    NK_USE_DECL = 3
    NK_LET_DECL = 4
    NK_EXTERN_FN = 5
    NK_C_IMPORT = 6
    NK_TRAIT_DECL = 7
    NK_IMPL_DECL = 8
    NK_POISONED_DECL = 9
    NK_EXTERN_VAR = 10
    // Expressions
    NK_INT_LIT = 20
    NK_FLOAT_LIT = 21
    NK_STRING_LIT = 22
    NK_BOOL_LIT = 23
    NK_IDENT = 24
    NK_BINARY = 25
    NK_UNARY = 26
    NK_CALL = 27
    NK_FIELD_ACCESS = 28
    NK_INDEX = 29
    NK_BLOCK = 30
    NK_IF_EXPR = 31
    NK_RETURN = 32
    NK_LET_BINDING = 33
    NK_ASSIGN = 34
    NK_WHILE = 35
    NK_LOOP = 36
    NK_FOR = 37
    NK_BREAK = 38
    NK_CONTINUE = 39
    NK_MATCH = 40
    NK_TUPLE = 41
    NK_ARRAY_LIT = 42
    NK_STRUCT_LIT = 43
    NK_CLOSURE = 44
    NK_CAST = 45
    NK_DEFER = 46
    NK_PIPELINE = 47
    NK_RANGE = 48
    NK_GROUPED = 49
    NK_C_STRING_LIT = 50
    NK_VARIANT_SHORTHAND = 51
    NK_WITH_EXPR = 52
    NK_RECORD_UPDATE = 53
    NK_ENUM_VARIANT = 54
    NK_SLICE = 55
    NK_OPTIONAL_CHAIN = 56
    NK_AWAIT = 57
    NK_ASYNC_BLOCK = 58
    NK_SPAWN = 59
    NK_YIELD = 60
    NK_COMPTIME = 61
    NK_LET_ELSE = 62
    NK_TUPLE_DESTRUCTURE = 63
    NK_ARRAY_COMPREHENSION = 64
    NK_ASYNC_SCOPE = 65
    NK_SELECT_AWAIT = 66
    NK_ERRDEFER = 67
    NK_NULL_LIT = 68
    NK_POISONED_EXPR = 69
    NK_UNSAFE_BLOCK = 70
    NK_COMPTIME_ERROR = 71
    NK_FSTRING = 72       // d0=segment_count, d1=0, extra=[seg_kind, seg_data...]
    NK_FSTRING_SPEC = 73  // d0=packed_flags, d1=width, d2=precision
    // NK_WITH_IMPLICIT: d0=source_expr, d1=body, d2=binding_name_sym
    NK_WITH_IMPLICIT = 76
    NK_COMPUTED_FIELD_ACCESS = 74  // d0=expr(node), d1=field_expr(node), d2=0
    NK_ASM_EXPR = 75  // d0=template(string_sym), d1=constraints(string_sym), d2=flags (bit0=volatile, bit1=has_output)
    // NK_MULTI_INDEX: d0=base_expr, d1=specs_extra_start, d2=specs_count
    NK_MULTI_INDEX = 77
    // NK_INDEX_SPEC: d0=start_or_expr, d1=stop, d2=step_and_kind (kind * INDEX_KIND_SHIFT + step_node)
    NK_INDEX_SPEC = 78
    // Labels and unstructured jumps. Values are appended after existing
    // expression/pattern nodes to avoid renumbering bootstrap-visible kinds.
    // NK_LABEL: d0=label_sym, d1=statement, d2=0
    // NK_GOTO:  d0=label_sym, d1=0, d2=0
    NK_LABEL = 115
    NK_GOTO = 116
    // NK_WITH_TUPLE: d0=source_expr, d1=body_expr, d2=extra_start
    // Extra: [name_count, is_mut, sym0, sym1, ...]
    NK_WITH_TUPLE = 117
    // docs/mutability.md — call-site passing mode wrappers.
    // NK_COPY_ARG: d0=inner(node), d1=0, d2=0  (explicit copy at call site)
    // NK_MOVE_ARG: d0=inner(node), d1=0, d2=0  (explicit move at call site)
    NK_COPY_ARG = 118
    NK_MOVE_ARG = 119
    // NK_REGEX_LIT: d0=pattern_sym, d1=flags_sym, d2=0
    NK_REGEX_LIT = 120
    // Type expressions
    NK_TYPE_NAMED = 80
    NK_TYPE_GENERIC = 81
    NK_TYPE_REF = 82
    NK_TYPE_PTR = 83
    NK_TYPE_FN = 84
    NK_TYPE_TUPLE = 85
    NK_TYPE_OPTIONAL = 86
    NK_TYPE_ARRAY = 87
    NK_TYPE_SLICE = 88
    NK_TYPE_TRAIT_OBJ = 89
    NK_TYPE_INFERRED = 90
    NK_TYPE_ASSOC = 91  // d0=base_sym (e.g. Self), d1=assoc_sym (e.g. Output), d2=0
    NK_TYPE_TYPEOF = 92 // d0=expr(node), d1=0, d2=0
    // Patterns (for match arms)
    NK_PAT_WILDCARD = 100
    NK_PAT_IDENT = 101
    NK_PAT_INT = 102
    NK_PAT_BOOL = 103
    NK_PAT_STRING = 104
    NK_PAT_VARIANT = 105
    NK_PAT_TUPLE = 106
    NK_PAT_STRUCT = 107
    NK_PAT_RANGE = 108
    NK_PAT_OR = 109
    NK_MATCH_ARM = 110
    NK_PAT_ENUM_SHORTHAND = 111
    NK_PAT_AT_BINDING = 112
    NK_PAT_SLICE = 113
    NK_PAT_TYPED_BIND = 114
    NK_PAT_REGEX = 121
    NK_DO_WHILE = 122

// With-expression binding encoding in d2:
// - positive value: immutable binding symbol id
// - negative value: mutable binding symbol id
fn encode_with_binding(sym: i32, is_mut: i32) -> i32:
    if is_mut != 0 and sym > 0:
        return 0 - sym
    sym

fn decode_with_binding_sym(encoded: i32) -> i32:
    if encoded < 0:
        return 0 - encoded
    encoded

fn decode_with_binding_is_mut(encoded: i32) -> i32:
    if encoded < 0:
        return 1
    0

// Type decl sub-kinds (stored in data2 field)
enum TypeDeclKind: i32:
    Alias = 0
    Struct = 1
    Enum = 2
    Distinct = 3
    DiscEnum = 4
    Opaque = 5
    Union = 6

// Type decl flag bits (combined with TypeDeclKind via arithmetic)
const TDK_FLAG_EPHEMERAL: i32 = 8
const TDK_FLAG_PACKED: i32 = 16
const TDK_FLAG_BITPACKED: i32 = 32

fn pack_type_decl_kind(sub_kind: i32, is_ephemeral: i32) -> i32:
    if is_ephemeral != 0:
        return sub_kind + TDK_FLAG_EPHEMERAL
    sub_kind

fn type_decl_sub_kind(packed: i32) -> i32:
    packed % TDK_FLAG_EPHEMERAL

fn type_decl_is_ephemeral(packed: i32) -> i32:
    (packed / TDK_FLAG_EPHEMERAL) % 2

fn type_decl_is_packed(packed: i32) -> i32:
    (packed / TDK_FLAG_PACKED) % 2

fn type_decl_is_bitpacked(packed: i32) -> i32:
    (packed / TDK_FLAG_BITPACKED) % 2

// Fn decl flag bits (stored in data2 field)
@[flags]
enum FnFlags: i32:
    PUB = 1
    ASYNC = 2
    GEN = 4
    COMPTIME = 8
    TAILREC = 16
    MUST_USE = 32
    VARIADIC = 64
    INLINE = 128
    NOINLINE = 256
    PANIC_HANDLER = 512
    ENTRY = 1024
    NO_MAIN = 2048
    TEST = 4096
    BEFORE = 8192
    AFTER = 16384
    BENCH = 32768
// Metadata packing unit used to encode required-parameter count into
// fn_meta flags without affecting existing FnFlags.* parity checks.
const FN_META_REQUIRED_UNIT: i32 = 65536
const FN_PARAM_STRIDE: i32 = 3
const FN_PARAM_FLAG_NOALIAS: i32 = 1
const FN_PARAM_FLAG_IMPLICIT: i32 = 2
// docs/mut.md Rev 8 §5.1 — receiver-place mode `mut self: Self`.
// Set by the parser when the param name is `self` and was preceded by `mut`.
// Stored as a flag bit so callers can detect a mutating receiver without
// reparsing. No semantic effect during the bridge phase (P1..P11);
// at P11 sema reads this bit to require a mutable place at the call site.
const FN_PARAM_FLAG_MUT_SELF: i32 = 4
// docs/mutability.md — receiver-mode `self: &Self` (read-only view).
// Set when param name is `self` and the declared type is a reference (&Self).
const FN_PARAM_FLAG_REF_SELF: i32 = 8
// docs/mutability.md — receiver-mode `move self: Self` (consuming).
// Set when param name is `self` and was preceded by `move`.
const FN_PARAM_FLAG_MOVE_SELF: i32 = 16

// Multi-index spec kind constants (stored in NK_INDEX_SPEC.d2 high bits)
const INDEX_SCALAR: i32 = 0
const INDEX_SLICE: i32 = 1
const INDEX_ELLIPSIS: i32 = 2
const INDEX_NEWAXIS: i32 = 3
const INDEX_KIND_SHIFT: i32 = 268435456  // 1 << 28

fn fn_param_is_noalias(flags: i32) -> i32:
    (flags / FN_PARAM_FLAG_NOALIAS) % 2

fn fn_param_is_implicit(flags: i32) -> i32:
    (flags / FN_PARAM_FLAG_IMPLICIT) % 2

fn fn_param_is_mut_self(flags: i32) -> i32:
    (flags / FN_PARAM_FLAG_MUT_SELF) % 2

fn fn_param_is_ref_self(flags: i32) -> i32:
    (flags / FN_PARAM_FLAG_REF_SELF) % 2

fn fn_param_is_move_self(flags: i32) -> i32:
    (flags / FN_PARAM_FLAG_MOVE_SELF) % 2

// docs/mut.md Rev 8 §12 — module-level place declarations.
// NK_LET_DECL flags layout:
//   bit 0 (mask 1):  is_mut (var vs let)
//   bit 1 (mask 2):  is_pub
//   bit 2 (mask 4):  LET_FLAG_GLOBAL     — declared via `global`
//   bit 3 (mask 8):  LET_FLAG_GLOBAL_VAR — declared via `global var`
//   bits 4+       :  (type_extra index + 1) * 16   (0 means no type)
// Plain top-level `let`/`var` (without `global`) leave bits 2/3 clear.
const LET_FLAG_GLOBAL: i32 = 4
const LET_FLAG_GLOBAL_VAR: i32 = 8

fn let_decl_is_global(flags: i32) -> i32:
    (flags / LET_FLAG_GLOBAL) % 2

fn let_decl_is_global_var(flags: i32) -> i32:
    (flags / LET_FLAG_GLOBAL_VAR) % 2

// Visibility flags
enum Visibility: i32:
    Private = 0
    Public = 1

// Binary operators
enum BinaryOp: i32:
    OP_ADD = 0
    OP_SUB = 1
    OP_MUL = 2
    OP_DIV = 3
    OP_MOD = 4
    OP_EQ = 5
    OP_NEQ = 6
    OP_LT = 7
    OP_GT = 8
    OP_LTE = 9
    OP_GTE = 10
    OP_AND = 11
    OP_OR = 12
    OP_BIT_AND = 13
    OP_BIT_OR = 14
    OP_BIT_XOR = 15
    OP_SHL = 16
    OP_SHR = 17
    OP_DEFAULT = 18
    OP_CONCAT = 19
    OP_ADD_WRAP = 20
    OP_SUB_WRAP = 21
    OP_MUL_WRAP = 22
    OP_IN = 23
    OP_NOT_IN = 24
    OP_ADD_SAT = 25
    OP_SUB_SAT = 26
    OP_MUL_SAT = 27
    OP_MATMUL = 28

// Unary operators
enum UnaryOp: i32:
    UOP_NEGATE = 0
    UOP_NOT = 1
    UOP_REF = 2
    UOP_MUT_REF = 3  // dead after P12 lockdown — parser rejects &mut
    UOP_DEREF = 4
    UOP_TRY = 5
    UOP_BIT_NOT = 6
    // docs/mut.md Rev 8 §13.2 — explicit raw-address-of forms.
    UOP_RAW_REF_CONST = 7
    UOP_RAW_REF_MUT = 8

// Literal suffix metadata (stored out-of-line in AstPool.literal_suffixes)
enum LiteralSuffix: i32:
    None = 0
    I8 = 1
    I16 = 2
    I32 = 3
    I64 = 4
    I128 = 5
    Isize = 6
    U8 = 7
    U16 = 8
    U32 = 9
    U64 = 10
    U128 = 11
    Usize = 12
    F32 = 13
    F64 = 14

// F-string segment kinds (stored in extra_data)
enum FStringSegmentKind: i32:
    LITERAL = 0  // +1 word: string token index (interned symbol)
    EXPR = 1     // +1 word: expression node, +1 word: spec node (0 if none)

// ── AST Pool ──────────────────────────────────────────────────────

// The AstPool stores all AST nodes in parallel arrays (SoA layout).
// Each node has:
// - A kind tag (NodeKind.NK_*)
// - Start/end span positions (byte offsets into source)
// - Up to 3 integer data fields (meaning depends on kind)
// - An optional extra data range for variable-length data
//
// Node 0 is reserved as a null sentinel.

type AstPoolState {
    kinds: Vec[i32],
    starts: Vec[i32],
    ends: Vec[i32],
    data0: Vec[i32],
    data1: Vec[i32],
    data2: Vec[i32],
    literal_suffixes: Vec[i32],
    int_literal_digit_idxs: Vec[i32],
    int_literal_radices: Vec[i32],
    extra: Vec[i32],
    decls: Vec[i32],
    local_decl_count: i32,
    prelude_decl_count: i32,
    strings: Vec[str],
    fn_meta: Vec[i32],
    type_meta: Vec[i32],
    pattern_qualifiers: Vec[i32],
    fn_param_patterns: Vec[i32],
    fn_param_pattern_meta: Vec[i32],
    for_meta: Vec[i32],
    block_meta: Vec[i32],
    must_use_type_nodes: Vec[i32],
    iter_of_self_fn_nodes: Vec[i32],
    sealed_trait_nodes: Vec[i32],
    comptime_decl_nodes: Vec[i32],
    move_closure_nodes: Vec[i32],
    non_escaping_closure_nodes: Vec[i32],
    where_meta: Vec[i32],
    impl_type_params: Vec[i32],
    impl_target_type_nodes: Vec[i32],
    impl_trait_type_args: Vec[i32],
    fn_meta_map: HashMap[i32, i32],
    type_meta_map: HashMap[i32, i32],
    pattern_qualifier_map: HashMap[i32, i32],
    where_meta_map: HashMap[i32, i32],
    impl_type_params_map: HashMap[i32, i32],
    impl_target_type_nodes_map: HashMap[i32, i32],
    impl_trait_type_args_map: HashMap[i32, i32],
    fn_param_pattern_meta_map: HashMap[i32, i32],
    for_meta_map: HashMap[i32, i32],
    block_meta_map: HashMap[i32, i32],
    fn_param_defaults: HashMap[i32, i32],
    must_use_type_set: HashMap[i32, i32],
    iter_of_self_fn_set: HashMap[i32, i32],
    sealed_trait_set: HashMap[i32, i32],
    comptime_decl_set: HashMap[i32, i32],
    move_closure_set: HashMap[i32, i32],
    non_escaping_closure_set: HashMap[i32, i32],
    call_named_args: HashMap[i32, i32],
    fn_stack_sizes: HashMap[i32, i32],
    fn_weak_flags: HashMap[i32, i32],
    fn_effect_pin_params: HashMap[i32, i32],   // fn_node → param_name_sym
    fn_effect_pin_bits: HashMap[i32, i32],     // fn_node → effect bitmask
    // NK_COPY_ARG nodes that require a .clone() call (type is Clone-only, not Copy)
    copy_arg_needs_clone: HashMap[i32, i32],   // node → 1
    frozen: i32,
}

type AstPool {
    state: *mut AstPoolState,
}
impl Copy for AstPool

fn AstPool.new -> AstPool:
    let ptr = with_alloc(2048) as *mut AstPoolState
    unsafe:
        *ptr = AstPoolState {
            kinds: Vec.new(),
            starts: Vec.new(),
            ends: Vec.new(),
            data0: Vec.new(),
            data1: Vec.new(),
            data2: Vec.new(),
            literal_suffixes: Vec.new(),
            int_literal_digit_idxs: Vec.new(),
            int_literal_radices: Vec.new(),
            extra: Vec.new(),
            decls: Vec.new(),
            local_decl_count: 0 - 1,
            prelude_decl_count: 0 - 1,
            strings: Vec.new(),
            fn_meta: Vec.new(),
            type_meta: Vec.new(),
            pattern_qualifiers: Vec.new(),
            fn_param_patterns: Vec.new(),
            fn_param_pattern_meta: Vec.new(),
            for_meta: Vec.new(),
            block_meta: Vec.new(),
            must_use_type_nodes: Vec.new(),
            iter_of_self_fn_nodes: Vec.new(),
            sealed_trait_nodes: Vec.new(),
            comptime_decl_nodes: Vec.new(),
            move_closure_nodes: Vec.new(),
            non_escaping_closure_nodes: Vec.new(),
            where_meta: Vec.new(),
            impl_type_params: Vec.new(),
            impl_target_type_nodes: Vec.new(),
            impl_trait_type_args: Vec.new(),
            fn_meta_map: HashMap.new(),
            type_meta_map: HashMap.new(),
            pattern_qualifier_map: HashMap.new(),
            where_meta_map: HashMap.new(),
            impl_type_params_map: HashMap.new(),
            impl_target_type_nodes_map: HashMap.new(),
            impl_trait_type_args_map: HashMap.new(),
            fn_param_pattern_meta_map: HashMap.new(),
            for_meta_map: HashMap.new(),
            block_meta_map: HashMap.new(),
            fn_param_defaults: HashMap.new(),
            must_use_type_set: HashMap.new(),
            iter_of_self_fn_set: HashMap.new(),
            sealed_trait_set: HashMap.new(),
            comptime_decl_set: HashMap.new(),
            move_closure_set: HashMap.new(),
            non_escaping_closure_set: HashMap.new(),
            call_named_args: HashMap.new(),
            fn_stack_sizes: HashMap.new(),
            fn_weak_flags: HashMap.new(),
            fn_effect_pin_params: HashMap.new(),
            fn_effect_pin_bits: HashMap.new(),
            copy_arg_needs_clone: HashMap.new(),
            frozen: 0,
        }
    let st = ptr
    st.kinds.push(0)
    st.starts.push(0)
    st.ends.push(0)
    st.data0.push(0)
    st.data1.push(0)
    st.data2.push(0)
    st.literal_suffixes.push(LiteralSuffix.None)
    st.int_literal_digit_idxs.push(0 - 1)
    st.int_literal_radices.push(0)
    AstPool { state: ptr }

// Mark the pool as immutable. Any subsequent mutation will print an error.
fn AstPool.freeze(self: AstPool):
    self.state.frozen = 1

// Add a node to the pool, returns the node index.
fn AstPool.add_node(self: AstPool, kind: i32, start: i32, end: i32, d0: i32, d1: i32, d2: i32) -> NodeId:
    if self.state.frozen != 0:
        with_eprint("BUG: AstPool.add_node called after freeze")
    let idx = self.state.kinds.len() as i32
    self.state.kinds.push(kind)
    self.state.starts.push(start)
    self.state.ends.push(end)
    self.state.data0.push(d0)
    self.state.data1.push(d1)
    self.state.data2.push(d2)
    self.state.literal_suffixes.push(LiteralSuffix.None)
    self.state.int_literal_digit_idxs.push(0 - 1)
    self.state.int_literal_radices.push(0)
    idx as NodeId

// Add extra data, returns the index in the extra array.
fn AstPool.add_extra(self: AstPool, value: i32) -> i32:
    if self.state.frozen != 0:
        with_eprint("BUG: AstPool.add_extra called after freeze")
    let idx = self.state.extra.len() as i32
    self.state.extra.push(value)
    idx

// Add a string to the string table, returns the string index.
fn AstPool.add_string(self: AstPool, s: str) -> i32:
    if self.state.frozen != 0:
        with_eprint("BUG: AstPool.add_string called after freeze")
    let idx = self.state.strings.len() as i32
    self.state.strings.push(s)
    idx

// Get node kind at index
fn AstPool.kind(self: AstPool, idx: NodeId) -> i32:
    self.state.kinds.get((idx as i32) as i64)

// Get node data fields
fn AstPool.get_data0(self: AstPool, idx: NodeId) -> i32:
    self.state.data0.get((idx as i32) as i64)

fn AstPool.get_data1(self: AstPool, idx: NodeId) -> i32:
    self.state.data1.get((idx as i32) as i64)

fn AstPool.get_data2(self: AstPool, idx: NodeId) -> i32:
    self.state.data2.get((idx as i32) as i64)

fn AstPool.literal_suffix(self: AstPool, idx: NodeId) -> i32:
    self.state.literal_suffixes.get((idx as i32) as i64)

fn AstPool.set_literal_suffix(self: AstPool, idx: NodeId, suffix: i32):
    self.state.literal_suffixes.set_i32((idx as i32) as i64, suffix)

fn AstPool.int_literal_digit_idx(self: AstPool, idx: NodeId) -> i32:
    self.state.int_literal_digit_idxs.get((idx as i32) as i64)

fn AstPool.int_literal_radix(self: AstPool, idx: NodeId) -> i32:
    self.state.int_literal_radices.get((idx as i32) as i64)

fn AstPool.set_int_literal_exact(self: AstPool, idx: NodeId, digit_idx: i32, radix: i32):
    self.state.int_literal_digit_idxs.set_i32((idx as i32) as i64, digit_idx)
    self.state.int_literal_radices.set_i32((idx as i32) as i64, radix)

fn AstPool.has_int_literal_exact(self: AstPool, idx: NodeId) -> bool:
    self.int_literal_digit_idx(idx) >= 0 and self.int_literal_radix(idx) >= 2

fn AstPool.int_literal_digits(self: AstPool, idx: NodeId) -> str:
    let digit_idx = self.int_literal_digit_idx(idx)
    if digit_idx < 0:
        return ""
    self.get_string(digit_idx)

const AST_INT_PART_BASE: i64 = 2097152
const AST_INT_PART_BASE2: i64 = 4398046511104

fn ast_int_part0(value: i64) -> i32:
    (value % AST_INT_PART_BASE) as i32

fn ast_int_part1(value: i64) -> i32:
    ((value / AST_INT_PART_BASE) % AST_INT_PART_BASE) as i32

fn ast_int_part2(value: i64) -> i32:
    (value / AST_INT_PART_BASE2) as i32

fn ast_int_from_parts(d0: i32, d1: i32, d2: i32) -> i64:
    (d0 as i64) + (d1 as i64) * AST_INT_PART_BASE + (d2 as i64) * AST_INT_PART_BASE2

fn AstPool.int_lit_value(self: AstPool, idx: NodeId) -> i64:
    ast_int_from_parts(self.get_data0(idx), self.get_data1(idx), self.get_data2(idx))

type ExactIntValue {
    ok: i32,
    overflow: i32,
    lo: i64,
    hi: i64,
}
impl Copy for ExactIntValue

type ExactIntExpr {
    ok: i32,
    overflow: i32,
    negative: i32,
    lo: i64,
    hi: i64,
}
impl Copy for ExactIntExpr

type ExactIntI64 {
    ok: i32,
    value: i64,
}
impl Copy for ExactIntI64

fn exact_int_invalid() -> ExactIntValue:
    ExactIntValue { ok: 0, overflow: 1, lo: 0, hi: 0 }

fn exact_int_overflow() -> ExactIntValue:
    ExactIntValue { ok: 1, overflow: 1, lo: 0, hi: 0 }

fn exact_int_value(lo: i64, hi: i64) -> ExactIntValue:
    ExactIntValue { ok: 1, overflow: 0, lo, hi }

fn exact_int_expr_invalid() -> ExactIntExpr:
    ExactIntExpr { ok: 0, overflow: 1, negative: 0, lo: 0, hi: 0 }

fn exact_int_expr_value(lo: i64, hi: i64, negative: i32) -> ExactIntExpr:
    ExactIntExpr { ok: 1, overflow: 0, negative, lo, hi }

fn exact_int_expr_magnitude(expr: ExactIntExpr) -> ExactIntValue:
    ExactIntValue { ok: expr.ok, overflow: expr.overflow, lo: expr.lo, hi: expr.hi }

fn exact_int_sign_bit() -> i64:
    0 - 9223372036854775807 - 1

fn exact_int_uword_lt(lhs: i64, rhs: i64) -> bool:
    let sign_bit = exact_int_sign_bit()
    (lhs ^ sign_bit) < (rhs ^ sign_bit)

fn exact_int_uword_lte(lhs: i64, rhs: i64) -> bool:
    let sign_bit = exact_int_sign_bit()
    (lhs ^ sign_bit) <= (rhs ^ sign_bit)

fn exact_int_low_mask(bits: i32) -> i64:
    if bits <= 0:
        return 0
    if bits >= 64:
        return 0 - 1
    if bits == 63:
        return 9223372036854775807
    ((1 as i64) << (bits as u32)) - 1

fn exact_int_pow2_word(bit: i32) -> i64:
    if bit < 0 or bit >= 64:
        return 0
    if bit == 63:
        return exact_int_sign_bit()
    (1 as i64) << (bit as u32)

fn exact_int_logical_shr_word(value: i64, shift: i32) -> i64:
    if shift <= 0:
        return value
    if shift >= 64:
        return 0
    (value >> (shift as u32)) & exact_int_low_mask(64 - shift)

fn exact_int_shl_word(value: i64, shift: i32) -> i64:
    if shift <= 0:
        return value
    if shift >= 64:
        return 0
    var out = value
    for i in 0..shift:
        out = out +% out
    out

fn exact_int_word_to_f64(value: i64) -> f64:
    if value >= 0:
        return value as f64
    9223372036854775808.0 + ((value ^ exact_int_sign_bit()) as f64)

fn exact_int_is_zero(value: ExactIntValue) -> bool:
    value.ok != 0 and value.overflow == 0 and value.lo == 0 and value.hi == 0

fn exact_int_cmp(lhs: ExactIntValue, rhs: ExactIntValue) -> i32:
    if exact_int_uword_lt(lhs.hi, rhs.hi):
        return 0 - 1
    if exact_int_uword_lt(rhs.hi, lhs.hi):
        return 1
    if exact_int_uword_lt(lhs.lo, rhs.lo):
        return 0 - 1
    if exact_int_uword_lt(rhs.lo, lhs.lo):
        return 1
    0

fn exact_int_add_values(lhs: ExactIntValue, rhs: ExactIntValue) -> ExactIntValue:
    if lhs.ok == 0 or rhs.ok == 0:
        return exact_int_invalid()
    if lhs.overflow != 0 or rhs.overflow != 0:
        return exact_int_overflow()
    let lo = lhs.lo +% rhs.lo
    let carry = if exact_int_uword_lt(lo, lhs.lo): 1 as i64 else: 0 as i64
    let hi = lhs.hi +% rhs.hi
    if exact_int_uword_lt(hi, lhs.hi):
        return exact_int_overflow()
    let hi2 = hi +% carry
    if exact_int_uword_lt(hi2, hi):
        return exact_int_overflow()
    exact_int_value(lo, hi2)

fn exact_int_add_small(value: ExactIntValue, digit: i64) -> ExactIntValue:
    exact_int_add_values(value, exact_int_value(digit, 0))

fn exact_int_shl_small(value: ExactIntValue, shift: i32) -> ExactIntValue:
    if value.ok == 0:
        return exact_int_invalid()
    if value.overflow != 0:
        return exact_int_overflow()
    if shift < 0 or shift >= 64:
        return exact_int_invalid()
    if shift == 0:
        return value
    if exact_int_logical_shr_word(value.hi, 64 - shift) != 0:
        return exact_int_overflow()
    let hi = exact_int_shl_word(value.hi, shift) | exact_int_logical_shr_word(value.lo, 64 - shift)
    let lo = exact_int_shl_word(value.lo, shift)
    exact_int_value(lo, hi)

fn exact_int_mul_small(value: ExactIntValue, factor: i32) -> ExactIntValue:
    if value.ok == 0:
        return exact_int_invalid()
    if value.overflow != 0:
        return exact_int_overflow()
    if factor < 0:
        return exact_int_invalid()
    var result = exact_int_value(0, 0)
    var addend = value
    var mul = factor
    while mul > 0:
        if (mul & 1) != 0:
            result = exact_int_add_values(result, addend)
            if result.overflow != 0:
                return result
        mul = mul >> 1
        if mul > 0:
            addend = exact_int_shl_small(addend, 1)
            if addend.overflow != 0:
                return addend
    result

fn exact_int_mask_bits(value: ExactIntValue, bits: i32) -> ExactIntValue:
    if value.ok == 0:
        return exact_int_invalid()
    if value.overflow != 0:
        return exact_int_overflow()
    if bits <= 0:
        return exact_int_value(0, 0)
    if bits >= 128:
        return value
    if bits < 64:
        let mask = exact_int_low_mask(bits)
        return exact_int_value(value.lo & mask, 0)
    if bits == 64:
        return exact_int_value(value.lo, 0)
    let hi_bits = bits - 64
    let hi_mask = exact_int_low_mask(hi_bits)
    exact_int_value(value.lo, value.hi & hi_mask)

fn exact_int_digit_value(ch: i32) -> i32:
    if ch >= 48 and ch <= 57:
        return ch - 48
    if ch >= 97 and ch <= 102:
        return ch - 87
    if ch >= 65 and ch <= 70:
        return ch - 55
    0 - 1

fn exact_int_parse_digits(digits: str, radix: i32) -> ExactIntValue:
    if radix < 2 or radix > 16:
        return exact_int_invalid()
    var acc = exact_int_value(0, 0)
    for i in 0..digits.len() as i32:
        let digit = exact_int_digit_value(digits.byte_at(i as i64))
        if digit < 0 or digit >= radix:
            return exact_int_invalid()
        acc = exact_int_mul_small(acc, radix)
        if acc.overflow != 0:
            return acc
        acc = exact_int_add_small(acc, digit as i64)
        if acc.overflow != 0:
            return acc
    acc

fn exact_int_fits_unsigned_bits(value: ExactIntValue, bits: i32) -> bool:
    if value.ok == 0 or value.overflow != 0:
        return false
    if bits <= 0:
        return false
    if bits >= 128:
        return true
    if bits < 64:
        if value.hi != 0:
            return false
        let max_lo = exact_int_low_mask(bits)
        return exact_int_uword_lte(value.lo, max_lo)
    if bits == 64:
        return value.hi == 0
    let hi_bits = bits - 64
    let max_hi = exact_int_low_mask(hi_bits)
    exact_int_uword_lte(value.hi, max_hi)

fn exact_int_fits_signed_magnitude_bits(value: ExactIntValue, bits: i32) -> bool:
    if value.ok == 0 or value.overflow != 0:
        return false
    if bits <= 0:
        return false
    if bits == 1:
        return exact_int_is_zero(value)
    exact_int_fits_unsigned_bits(value, bits - 1)

fn exact_int_fits_signed_negative_bits(value: ExactIntValue, bits: i32) -> bool:
    if value.ok == 0 or value.overflow != 0:
        return false
    if bits <= 0:
        return false
    let mag_bits = bits - 1
    if mag_bits < 64:
        if value.hi != 0:
            return false
        return exact_int_uword_lte(value.lo, exact_int_pow2_word(mag_bits))
    if mag_bits == 64:
        if value.hi == 0:
            return true
        return value.hi == 1 and value.lo == 0
    let limit_hi = exact_int_pow2_word(mag_bits - 64)
    if exact_int_uword_lt(value.hi, limit_hi):
        return true
    value.hi == limit_hi and value.lo == 0

fn exact_int_try_i64(value: ExactIntValue) -> ExactIntI64:
    if value.ok == 0 or value.overflow != 0:
        return ExactIntI64 { ok: 0, value: 0 }
    if value.hi != 0 or value.lo < 0:
        return ExactIntI64 { ok: 0, value: 0 }
    ExactIntI64 { ok: 1, value: value.lo }

fn exact_int_twos_complement_bits(value: ExactIntValue, bits: i32) -> ExactIntValue:
    if value.ok == 0 or value.overflow != 0:
        return exact_int_invalid()
    let lo = (~value.lo) +% 1
    let carry = if lo == 0: 1 as i64 else: 0 as i64
    let hi = (~value.hi) +% carry
    let neg = exact_int_value(lo, hi)
    if bits >= 128:
        return neg
    exact_int_mask_bits(neg, bits)

fn AstPool.int_literal_exact_value(self: AstPool, idx: NodeId) -> ExactIntValue:
    if not self.has_int_literal_exact(idx):
        return exact_int_invalid()
    exact_int_parse_digits(self.int_literal_digits(idx), self.int_literal_radix(idx))

fn AstPool.int_literal_fast_i64(self: AstPool, idx: NodeId) -> ExactIntI64:
    if self.has_int_literal_exact(idx):
        return exact_int_try_i64(self.int_literal_exact_value(idx))
    ExactIntI64 { ok: 1, value: self.int_lit_value(idx) }

fn AstPool.int_literal_expr_i64(self: AstPool, node: i32) -> ExactIntI64:
    if node == 0:
        return ExactIntI64 { ok: 0, value: 0 }
    let kind = self.kind(node)
    if kind == NodeKind.NK_INT_LIT and not self.has_int_literal_exact(node as NodeId):
        return ExactIntI64 { ok: 1, value: self.int_lit_value(node as NodeId) }
    let expr = self.int_literal_exact_expr(node)
    if expr.ok == 0 or expr.overflow != 0:
        return ExactIntI64 { ok: 0, value: 0 }
    let mag = exact_int_expr_magnitude(expr)
    if expr.negative == 0:
        return exact_int_try_i64(mag)
    if not exact_int_fits_signed_negative_bits(mag, 64):
        return ExactIntI64 { ok: 0, value: 0 }
    if mag.hi == 0 and mag.lo == exact_int_sign_bit():
        return ExactIntI64 { ok: 1, value: 0 - 9223372036854775807 - 1 }
    ExactIntI64 { ok: 1, value: 0 - mag.lo }

fn AstPool.int_literal_exact_expr(self: AstPool, node: i32) -> ExactIntExpr:
    if node == 0:
        return exact_int_expr_invalid()
    let kind = self.kind(node)
    if kind == NodeKind.NK_GROUPED or kind == NodeKind.NK_COMPTIME or kind == NodeKind.NK_CAST:
        return self.int_literal_exact_expr(self.get_data0(node))
    if kind == NodeKind.NK_UNARY and self.get_data0(node) == UnaryOp.UOP_NEGATE:
        let inner = self.int_literal_exact_expr(self.get_data1(node))
        if inner.ok == 0 or inner.overflow != 0:
            return inner
        return exact_int_expr_value(inner.lo, inner.hi, if inner.negative != 0: 0 else: 1)
    if kind != NodeKind.NK_INT_LIT:
        return exact_int_expr_invalid()
    if self.has_int_literal_exact(node):
        let parsed = self.int_literal_exact_value(node)
        return ExactIntExpr { ok: parsed.ok, overflow: parsed.overflow, negative: 0, lo: parsed.lo, hi: parsed.hi }
    let raw = self.int_lit_value(node)
    if raw < 0:
        return exact_int_expr_invalid()
    exact_int_expr_value(raw, 0, 0)

fn AstPool.int_literal_expr_bits(self: AstPool, node: i32, bits: i32, signed: i32) -> ExactIntValue:
    let expr = self.int_literal_exact_expr(node)
    if expr.ok == 0 or expr.overflow != 0:
        return exact_int_invalid()
    let mag = exact_int_expr_magnitude(expr)
    if expr.negative == 0:
        if signed != 0:
            if not exact_int_fits_signed_magnitude_bits(mag, bits):
                return exact_int_invalid()
        else:
            if not exact_int_fits_unsigned_bits(mag, bits):
                return exact_int_invalid()
        return mag
    if signed == 0 or not exact_int_fits_signed_negative_bits(mag, bits):
        return exact_int_invalid()
    exact_int_twos_complement_bits(mag, bits)

fn AstPool.has_comptime_nodes(self: AstPool) -> bool:
    for ni in 1..self.node_count():
        let nid = ni as NodeId
        if self.kind(nid) == NodeKind.NK_COMPTIME:
            return true
    false

fn AstPool.has_comptime_branch_nodes(self: AstPool) -> bool:
    for ni in 1..self.node_count():
        let nid = ni as NodeId
        if self.kind(nid) == NodeKind.NK_COMPTIME:
            let inner_i32 = self.get_data0(nid)
            if inner_i32 > 0 and inner_i32 < self.node_count():
                let inner = inner_i32 as NodeId
                let ik = self.kind(inner)
                if ik == NodeKind.NK_IF_EXPR or ik == NodeKind.NK_FOR:
                    return true
    false

fn AstPool.has_type_derives(self: AstPool) -> bool:
    var meta = 0
    while meta < self.state.type_meta.len() as i32:
        if self.type_meta_derive_count(meta) > 0:
            return true
        meta = meta + 3
    false

fn AstPool.get_extra(self: AstPool, idx: i32) -> i32:
    self.state.extra.get(idx as i64)

fn AstPool.get_string(self: AstPool, idx: i32) -> str:
    self.state.strings.get(idx as i64)

fn AstPool.get_start(self: AstPool, idx: NodeId) -> i32:
    self.state.starts.get((idx as i32) as i64)

fn AstPool.get_end(self: AstPool, idx: NodeId) -> i32:
    self.state.ends.get((idx as i32) as i64)

fn AstPool.node_count(self: AstPool) -> i32:
    self.state.kinds.len() as i32

fn AstPool.add_decl(self: AstPool, node_idx: NodeId):
    if self.state.frozen != 0:
        with_eprint("BUG: AstPool.add_decl called after freeze")
    self.state.decls.push(node_idx as i32)

fn AstPool.decl_count(self: AstPool) -> i32:
    self.state.decls.len() as i32

fn AstPool.get_decl(self: AstPool, idx: i32) -> NodeId:
    (self.state.decls.get(idx as i64)) as NodeId

fn AstPool.set_local_decl_count(self: AstPool, n: i32):
    self.state.local_decl_count = n

fn AstPool.local_decl_count(self: AstPool) -> i32:
    self.state.local_decl_count

fn AstPool.set_prelude_decl_count(self: AstPool, n: i32):
    self.state.prelude_decl_count = n

fn AstPool.prelude_decl_count(self: AstPool) -> i32:
    self.state.prelude_decl_count

fn AstPool.extra_len(self: AstPool) -> i32:
    self.state.extra.len() as i32

fn AstPool.set_data0(self: AstPool, idx: NodeId, val: i32):
    self.state.data0.set_i32((idx as i32) as i64, val)

fn AstPool.set_data1(self: AstPool, idx: NodeId, val: i32):
    self.state.data1.set_i32((idx as i32) as i64, val)

fn AstPool.set_data2(self: AstPool, idx: NodeId, val: i32):
    self.state.data2.set_i32((idx as i32) as i64, val)

fn AstPool.set_start(self: AstPool, idx: NodeId, val: i32):
    self.state.starts.set_i32((idx as i32) as i64, val)

fn AstPool.set_end(self: AstPool, idx: NodeId, val: i32):
    self.state.ends.set_i32((idx as i32) as i64, val)

// Store fn decl metadata: [node, flags, ret_type, param_start, param_count, tp_start, tp_count]
fn AstPool.add_fn_meta(self: AstPool, node: NodeId, flags: i32, ret: i32, ps: i32, pc: i32, ts: i32, tc: i32):
    let idx = self.state.fn_meta.len() as i32
    self.state.fn_meta.push(node as i32)
    self.state.fn_meta.push(flags)
    self.state.fn_meta.push(ret)
    self.state.fn_meta.push(ps)
    self.state.fn_meta.push(pc)
    self.state.fn_meta.push(ts)
    self.state.fn_meta.push(tc)
    self.state.fn_meta_map.insert(node as i32, idx)

// Get fn metadata for a given fn decl node. Returns 7-int record start or -1.
fn AstPool.find_fn_meta(self: AstPool, node: NodeId) -> i32:
    let opt = self.state.fn_meta_map.get(node as i32)
    if opt.is_some():
        return opt.unwrap()
    0 - 1

fn AstPool.fn_meta_flags(self: AstPool, meta: i32) -> i32:
    self.state.fn_meta.get((meta + 1) as i64)

fn AstPool.fn_meta_ret(self: AstPool, meta: i32) -> i32:
    self.state.fn_meta.get((meta + 2) as i64)

fn AstPool.fn_meta_param_start(self: AstPool, meta: i32) -> i32:
    self.state.fn_meta.get((meta + 3) as i64)

fn AstPool.fn_meta_param_count(self: AstPool, meta: i32) -> i32:
    self.state.fn_meta.get((meta + 4) as i64)

fn AstPool.fn_meta_tp_start(self: AstPool, meta: i32) -> i32:
    self.state.fn_meta.get((meta + 5) as i64)

fn AstPool.fn_meta_tp_count(self: AstPool, meta: i32) -> i32:
    self.state.fn_meta.get((meta + 6) as i64)

fn AstPool.fn_param_name(self: AstPool, param_start: i32, param_idx: i32) -> i32:
    self.get_extra(param_start + param_idx * FN_PARAM_STRIDE)

fn AstPool.fn_param_type(self: AstPool, param_start: i32, param_idx: i32) -> i32:
    self.get_extra(param_start + param_idx * FN_PARAM_STRIDE + 1)

fn AstPool.fn_param_flags(self: AstPool, param_start: i32, param_idx: i32) -> i32:
    self.get_extra(param_start + param_idx * FN_PARAM_STRIDE + 2)

fn AstPool.set_fn_param_default(self: AstPool, param_start: i32, param_idx: i32, default_node: i32):
    let key = param_start * 1000 + param_idx
    self.state.fn_param_defaults.insert(key, default_node)

fn AstPool.get_fn_param_default(self: AstPool, param_start: i32, param_idx: i32) -> i32:
    let key = param_start * 1000 + param_idx
    if self.state.fn_param_defaults.contains(key):
        return self.state.fn_param_defaults.get(key).unwrap()
    0

fn AstPool.set_call_named_args(self: AstPool, call_node: NodeId, names_extra_start: i32):
    self.state.call_named_args.insert(call_node as i32, names_extra_start)

fn AstPool.get_call_named_arg(self: AstPool, call_node: NodeId, arg_idx: i32) -> i32:
    if self.state.call_named_args.contains(call_node as i32):
        let start = self.state.call_named_args.get(call_node as i32).unwrap()
        return self.get_extra(start + arg_idx)
    0

fn AstPool.has_call_named_args(self: AstPool, call_node: NodeId) -> i32:
    if self.state.call_named_args.contains(call_node as i32): 1 else: 0

fn AstPool.add_type_meta(self: AstPool, node: NodeId, derive_start: i32, derive_count: i32):
    let idx = self.state.type_meta.len() as i32
    self.state.type_meta.push(node as i32)
    self.state.type_meta.push(derive_start)
    self.state.type_meta.push(derive_count)
    self.state.type_meta_map.insert(node as i32, idx)

fn AstPool.find_type_meta(self: AstPool, node: NodeId) -> i32:
    let opt = self.state.type_meta_map.get(node as i32)
    if opt.is_some():
        return opt.unwrap()
    0 - 1

fn AstPool.type_meta_derive_start(self: AstPool, meta: i32) -> i32:
    self.state.type_meta.get((meta + 1) as i64)

fn AstPool.type_meta_derive_count(self: AstPool, meta: i32) -> i32:
    self.state.type_meta.get((meta + 2) as i64)

fn AstPool.add_pattern_qualifier(self: AstPool, node: NodeId, type_sym: i32):
    let idx = self.state.pattern_qualifiers.len() as i32
    self.state.pattern_qualifiers.push(node as i32)
    self.state.pattern_qualifiers.push(type_sym)
    self.state.pattern_qualifier_map.insert(node as i32, idx)

fn AstPool.pattern_qualifier(self: AstPool, node: NodeId) -> i32:
    let opt = self.state.pattern_qualifier_map.get(node as i32)
    if opt.is_some():
        return self.state.pattern_qualifiers.get((opt.unwrap() + 1) as i64)
    0

fn AstPool.mark_must_use_type(self: AstPool, node: NodeId):
    self.state.must_use_type_nodes.push(node as i32)
    self.state.must_use_type_set.insert(node as i32, 1)

fn AstPool.is_must_use_type_node(self: AstPool, node: NodeId) -> i32:
    if self.state.must_use_type_set.contains(node as i32): return 1
    0

fn AstPool.mark_iter_of_self_fn(self: AstPool, node: NodeId):
    self.state.iter_of_self_fn_nodes.push(node as i32)
    self.state.iter_of_self_fn_set.insert(node as i32, 1)

fn AstPool.is_iter_of_self_fn_node(self: AstPool, node: NodeId) -> i32:
    if self.state.iter_of_self_fn_set.contains(node as i32): return 1
    0

fn AstPool.mark_sealed_trait(self: AstPool, node: NodeId):
    self.state.sealed_trait_nodes.push(node as i32)
    self.state.sealed_trait_set.insert(node as i32, 1)

fn AstPool.is_sealed_trait_node(self: AstPool, node: NodeId) -> i32:
    if self.state.sealed_trait_set.contains(node as i32): return 1
    0

fn AstPool.mark_comptime_decl(self: AstPool, node: NodeId):
    self.state.comptime_decl_nodes.push(node as i32)
    self.state.comptime_decl_set.insert(node as i32, 1)

fn AstPool.is_comptime_decl_node(self: AstPool, node: NodeId) -> i32:
    if self.state.comptime_decl_set.contains(node as i32): return 1
    0

fn AstPool.mark_move_closure(self: AstPool, node: NodeId):
    self.state.move_closure_nodes.push(node as i32)
    self.state.move_closure_set.insert(node as i32, 1)

fn AstPool.is_move_closure(self: AstPool, node: NodeId) -> i32:
    if self.state.move_closure_set.contains(node as i32): return 1
    0

fn AstPool.mark_non_escaping_closure(self: AstPool, node: NodeId):
    self.state.non_escaping_closure_nodes.push(node as i32)
    self.state.non_escaping_closure_set.insert(node as i32, 1)

fn AstPool.is_non_escaping_closure(self: AstPool, node: NodeId) -> i32:
    if self.state.non_escaping_closure_set.contains(node as i32): return 1
    0

fn AstPool.add_where_meta(self: AstPool, fn_node: NodeId, extra_start: i32, clause_count: i32):
    let idx = self.state.where_meta.len() as i32
    self.state.where_meta.push(fn_node as i32)
    self.state.where_meta.push(extra_start)
    self.state.where_meta.push(clause_count)
    self.state.where_meta_map.insert(fn_node as i32, idx)

fn AstPool.find_where_meta(self: AstPool, fn_node: NodeId) -> i32:
    let opt = self.state.where_meta_map.get(fn_node as i32)
    if opt.is_some():
        return opt.unwrap()
    0 - 1

fn AstPool.add_impl_type_params(self: AstPool, impl_node: NodeId, tp_start: i32, tp_count: i32):
    let idx = self.state.impl_type_params.len() as i32
    self.state.impl_type_params.push(impl_node as i32)
    self.state.impl_type_params.push(tp_start)
    self.state.impl_type_params.push(tp_count)
    self.state.impl_type_params_map.insert(impl_node as i32, idx)

fn AstPool.find_impl_type_params(self: AstPool, impl_node: NodeId) -> i32:
    let opt = self.state.impl_type_params_map.get(impl_node as i32)
    if opt.is_some():
        return opt.unwrap()
    0 - 1

fn AstPool.add_impl_target_type_node(self: AstPool, impl_node: NodeId, type_node: NodeId):
    self.state.impl_target_type_nodes.push(impl_node as i32)
    self.state.impl_target_type_nodes.push(type_node as i32)
    self.state.impl_target_type_nodes_map.insert(impl_node as i32, type_node as i32)

fn AstPool.find_impl_target_type_node(self: AstPool, impl_node: NodeId) -> NodeId:
    let opt = self.state.impl_target_type_nodes_map.get(impl_node as i32)
    if opt.is_some():
        return (opt.unwrap()) as NodeId
    var i = 0
    while i < self.state.impl_target_type_nodes.len() as i32:
        if self.state.impl_target_type_nodes.get(i as i64) == (impl_node as i32):
            return (self.state.impl_target_type_nodes.get((i + 1) as i64)) as NodeId
        i = i + 2
    0 as NodeId

fn AstPool.add_impl_trait_type_args(self: AstPool, impl_node: NodeId, args_start: i32, args_count: i32):
    let idx = self.state.impl_trait_type_args.len() as i32
    self.state.impl_trait_type_args.push(impl_node as i32)
    self.state.impl_trait_type_args.push(args_start)
    self.state.impl_trait_type_args.push(args_count)
    self.state.impl_trait_type_args_map.insert(impl_node as i32, idx)

fn AstPool.find_impl_trait_type_args(self: AstPool, impl_node: NodeId) -> i32:
    let opt = self.state.impl_trait_type_args_map.get(impl_node as i32)
    if opt.is_some():
        return opt.unwrap()
    0 - 1

fn AstPool.fn_param_patterns_len(self: AstPool) -> i32:
    self.state.fn_param_patterns.len() as i32

fn AstPool.add_fn_param_pattern_value(self: AstPool, node: NodeId):
    self.state.fn_param_patterns.push(node as i32)

fn AstPool.fn_param_pattern_value(self: AstPool, idx: i32) -> NodeId:
    (self.state.fn_param_patterns.get(idx as i64)) as NodeId

fn AstPool.add_fn_param_pattern_meta(self: AstPool, node: NodeId, start: i32, count: i32):
    let idx = self.state.fn_param_pattern_meta.len() as i32
    self.state.fn_param_pattern_meta.push(node as i32)
    self.state.fn_param_pattern_meta.push(start)
    self.state.fn_param_pattern_meta.push(count)
    self.state.fn_param_pattern_meta_map.insert(node as i32, idx)

fn AstPool.find_fn_param_pattern_meta(self: AstPool, node: NodeId) -> i32:
    let opt = self.state.fn_param_pattern_meta_map.get(node as i32)
    if opt.is_some():
        return opt.unwrap()
    0 - 1

fn AstPool.fn_param_pattern_meta_start(self: AstPool, meta: i32) -> i32:
    self.state.fn_param_pattern_meta.get((meta + 1) as i64)

fn AstPool.fn_param_pattern_meta_count(self: AstPool, meta: i32) -> i32:
    self.state.fn_param_pattern_meta.get((meta + 2) as i64)

fn AstPool.add_for_meta(self: AstPool, node: NodeId, index_binding: i32, label: i32):
    let idx = self.state.for_meta.len() as i32
    self.state.for_meta.push(node as i32)
    self.state.for_meta.push(index_binding)
    self.state.for_meta.push(label)
    self.state.for_meta_map.insert(node as i32, idx)

fn AstPool.find_for_meta(self: AstPool, node: NodeId) -> i32:
    let opt = self.state.for_meta_map.get(node as i32)
    if opt.is_some():
        return opt.unwrap()
    0 - 1

fn AstPool.for_meta_index_binding(self: AstPool, meta: i32) -> i32:
    self.state.for_meta.get((meta + 1) as i64)

fn AstPool.for_meta_label(self: AstPool, meta: i32) -> i32:
    self.state.for_meta.get((meta + 2) as i64)

fn AstPool.add_block_meta(self: AstPool, node: NodeId, label: i32):
    let idx = self.state.block_meta.len() as i32
    self.state.block_meta.push(node as i32)
    self.state.block_meta.push(label)
    self.state.block_meta_map.insert(node as i32, idx)

fn AstPool.find_block_meta(self: AstPool, node: NodeId) -> i32:
    let opt = self.state.block_meta_map.get(node as i32)
    if opt.is_some():
        return opt.unwrap()
    0 - 1

fn AstPool.block_meta_label(self: AstPool, meta: i32) -> i32:
    self.state.block_meta.get((meta + 1) as i64)

fn ast_is_pattern_kind(kind: i32) -> bool:
    kind == NodeKind.NK_PAT_WILDCARD or
    kind == NodeKind.NK_PAT_IDENT or
    kind == NodeKind.NK_PAT_INT or
    kind == NodeKind.NK_PAT_BOOL or
    kind == NodeKind.NK_PAT_STRING or
    kind == NodeKind.NK_PAT_VARIANT or
    kind == NodeKind.NK_PAT_TUPLE or
    kind == NodeKind.NK_PAT_STRUCT or
    kind == NodeKind.NK_PAT_RANGE or
    kind == NodeKind.NK_PAT_OR or
    kind == NodeKind.NK_PAT_ENUM_SHORTHAND or
    kind == NodeKind.NK_PAT_AT_BINDING or
    kind == NodeKind.NK_PAT_SLICE or
    kind == NodeKind.NK_PAT_TYPED_BIND or
    kind == NodeKind.NK_PAT_REGEX

fn AstPool.is_pattern_node(self: AstPool, node: i32) -> bool:
    if node <= 0 or node >= self.node_count():
        return false
    ast_is_pattern_kind(self.kind(node as NodeId))

fn AstPool.for_binding_is_pattern(self: AstPool, node: NodeId) -> bool:
    if node <= 0 or node >= self.node_count():
        return false
    if self.kind(node) != NodeKind.NK_FOR:
        return false
    let binding = self.get_data0(node)
    if not self.is_pattern_node(binding):
        return false
    let bind_node = binding as NodeId
    let for_start = self.get_start(node)
    let for_end = self.get_end(node)
    self.get_start(bind_node) >= for_start and self.get_end(bind_node) <= for_end

// ── Node Data Layout Reference ───────────────────────────────────
//
// NodeKind.NK_FN_DECL:       d0=name(sym), d1=body(node), d2=flags
//                   extra: [return_type(node), param_count, [param_name, param_type, param_flags]*, type_param_count, [type_param_name, bound_count, bounds...]*]
//
// NodeKind.NK_TYPE_DECL:     d0=name(sym), d1=extra_start, d2=packed_kind (TypeDeclKind.* + flags)
//                   For struct: extra=[field_count, [field_name, field_type, field_default]*, vis, tp_start, tp_count]
//                   For enum: extra=[variant_count, [var_name, payload_count, payload_type...]*, vis, tp_start, tp_count]
//                   For alias/distinct: extra=[aliased_or_inner_type, vis, tp_start, tp_count]
//
// NodeKind.NK_USE_DECL:      d0=extra_start, d1=path_count, d2=0
//                   extra: [sym, sym, ...]
//
// NodeKind.NK_LET_DECL:      d0=name(sym), d1=value(node), d2=flags (bit0=mut, bit1=pub)
//                   extra: [type_expr(node)] if type annotation present
//
// NodeKind.NK_EXTERN_FN:     d0=name(sym), d1=extra_start, d2=flags (bit0=variadic)
//                   extra: [return_type(node), param_count, [param_name, param_type, param_flags]*]
//
// NodeKind.NK_C_IMPORT:      d0=header_str_idx, d1=extra_start, d2=link_lib_count
//
// NodeKind.NK_TRAIT_DECL:    d0=name(sym), d1=extra_start, d2=vis
//
// NodeKind.NK_IMPL_DECL:     d0=type_name(sym), d1=extra_start, d2=trait_name(sym, 0=none)
//
// NodeKind.NK_INT_LIT:       d0=value_low, d1=value_high, d2=0
// NodeKind.NK_FLOAT_LIT:     d0=string_idx, d1=0, d2=0
// NodeKind.NK_STRING_LIT:    d0=sym, d1=0, d2=0
// NodeKind.NK_C_STRING_LIT:  d0=sym, d1=0, d2=0
// NodeKind.NK_BOOL_LIT:      d0=value(0/1), d1=0, d2=0
// NodeKind.NK_IDENT:         d0=sym, d1=0, d2=0
// NodeKind.NK_BINARY:        d0=op(OP_*), d1=lhs(node), d2=rhs(node)
// NodeKind.NK_UNARY:         d0=op(UOP_*), d1=operand(node), d2=0
// NodeKind.NK_CALL:          d0=callee(node), d1=extra_start, d2=arg_count
// NodeKind.NK_FIELD_ACCESS:  d0=expr(node), d1=field(sym), d2=0
// NodeKind.NK_COMPUTED_FIELD_ACCESS: d0=expr(node), d1=field_expr(node), d2=0
// NodeKind.NK_INDEX:         d0=expr(node), d1=index(node), d2=0
// NodeKind.NK_SLICE:         d0=expr(node), d1=start(node,0=none), d2=end(node,0=none)
// NodeKind.NK_BLOCK:         d0=extra_start, d1=stmt_count, d2=tail(node,0=none)
// NodeKind.NK_IF_EXPR:       d0=cond(node), d1=then(node), d2=else(node,0=none)
// NodeKind.NK_RETURN:        d0=value(node,0=none), d1=0, d2=0
// NodeKind.NK_LET_BINDING:   d0=name(sym), d1=value(node), d2=flags (bit0=mut)
//                   If has type: extra=[type_node]
// NodeKind.NK_LET_ELSE:      d0=pattern(node), d1=value(node), d2=else_body(node)
// NodeKind.NK_TUPLE_DESTRUCTURE: d0=extra_start, d1=name_count, d2=value(node)
// NodeKind.NK_ASSIGN:        d0=target(node), d1=value(node), d2=0
// NodeKind.NK_WHILE:         d0=cond(node), d1=body(node), d2=label(sym,0=none)
// NodeKind.NK_DO_WHILE:      d0=body(node), d1=cond(node), d2=label(sym,0=none)
// NodeKind.NK_LOOP:          d0=body(node), d1=label(sym,0=none), d2=0
// NodeKind.NK_FOR:           d0=binding(sym) or pattern(node), d1=iterable(node), d2=body(node)
//                   extra: [index_binding(sym,0=none), label(sym,0=none)]
// NodeKind.NK_BREAK:         d0=value(node,0=none), d1=label(sym,0=none), d2=0
// NodeKind.NK_CONTINUE:      d0=label(sym,0=none), d1=0, d2=0
// NodeKind.NK_LABEL:         d0=label_sym, d1=statement(node), d2=0
// NodeKind.NK_GOTO:          d0=label_sym, d1=0, d2=0
// NodeKind.NK_MATCH:         d0=subject(node), d1=extra_start, d2=arm_count
// NodeKind.NK_MATCH_ARM:     d0=pattern(node), d1=body(node), d2=guard(node,0=none)
// NodeKind.NK_TUPLE:         d0=extra_start, d1=elem_count, d2=0
// NodeKind.NK_ARRAY_LIT:     d0=extra_start, d1=elem_count, d2=0
// NodeKind.NK_ARRAY_COMPREHENSION: d0=expr(node), d1=binding(sym), d2=iterable(node)
//                   extra: [filter(node,0=none)]
// NodeKind.NK_STRUCT_LIT:    d0=name(sym), d1=extra_start, d2=field_count
// NodeKind.NK_CLOSURE:       d0=body(node), d1=extra_start, d2=param_count
// NodeKind.NK_CAST:          d0=expr(node), d1=target_type(node), d2=0
// NodeKind.NK_DEFER:         d0=body(node), d1=0, d2=0
// NodeKind.NK_ERRDEFER:      d0=body(node), d1=0, d2=0
// NodeKind.NK_PIPELINE:      d0=lhs(node), d1=rhs(node), d2=0
// NodeKind.NK_RANGE:         d0=start(node,0=none), d1=end(node,0=none), d2=inclusive(0/1)
// NodeKind.NK_GROUPED:       d0=inner(node), d1=0, d2=0
// NodeKind.NK_VARIANT_SHORTHAND: d0=name(sym), d1=extra_start, d2=arg_count
// NodeKind.NK_WITH_EXPR:     d0=source(node), d1=body(node), d2=encoded_binding(sym+mut)
// NodeKind.NK_RECORD_UPDATE: d0=source(node), d1=extra_start, d2=field_count
// NodeKind.NK_ENUM_VARIANT:  d0=type_name(sym), d1=variant_name(sym), d2=extra_start
//                   extra: [arg_count, args...]
// NodeKind.NK_OPTIONAL_CHAIN: d0=expr(node), d1=member(sym), d2=extra_start
//                    extra: [has_args(0/1), arg_count, args...]
// NodeKind.NK_AWAIT:         d0=expr(node), d1=0, d2=0
// NodeKind.NK_ASYNC_BLOCK:   d0=body(node), d1=0, d2=0
// NodeKind.NK_SPAWN:         d0=expr(node), d1=0, d2=0
// NodeKind.NK_YIELD:         d0=expr(node), d1=0, d2=0
// NodeKind.NK_COMPTIME:      d0=expr(node), d1=0, d2=0
// NodeKind.NK_ASYNC_SCOPE:   d0=name(sym), d1=body(node), d2=0
// NodeKind.NK_SELECT_AWAIT:  d0=extra_start, d1=arm_count, d2=0
//
// Type expression nodes:
// NodeKind.NK_TYPE_NAMED:    d0=sym, d1=0, d2=0
// NodeKind.NK_TYPE_GENERIC:  d0=name(sym), d1=extra_start, d2=arg_count
// NodeKind.NK_TYPE_REF:      d0=pointee(node), d1=is_mut(0/1), d2=0
// NodeKind.NK_TYPE_PTR:      d0=pointee(node), d1=is_mut(0/1), d2=0
// NodeKind.NK_TYPE_FN:       d0=extra_start, d1=param_count, d2=return_type(node)
// NodeKind.NK_TYPE_TUPLE:    d0=extra_start, d1=elem_count, d2=0
// NodeKind.NK_TYPE_OPTIONAL: d0=inner(node), d1=0, d2=0
// NodeKind.NK_TYPE_ARRAY:    d0=element(node), d1=size_low, d2=size_high
// NodeKind.NK_TYPE_SLICE:    d0=element(node), d1=0, d2=0
// NodeKind.NK_TYPE_TRAIT_OBJ: d0=sym, d1=0, d2=0
// NodeKind.NK_TYPE_INFERRED: d0=0, d1=0, d2=0
//
// Pattern nodes:
// NodeKind.NK_PAT_WILDCARD:  d0=0, d1=0, d2=0
// NodeKind.NK_PAT_IDENT:     d0=sym, d1=0, d2=0
// NodeKind.NK_PAT_INT:       d0/d1/d2 = i64 value, encoded with ast_int_part0/1/2 (same as NK_INT_LIT)
// NodeKind.NK_PAT_BOOL:      d0=value(0/1), d1=0, d2=0
// NodeKind.NK_PAT_STRING:    d0=sym, d1=0, d2=0
// NodeKind.NK_PAT_VARIANT:   d0=name(sym), d1=extra_start, d2=binding_count
// NodeKind.NK_PAT_TUPLE:     d0=extra_start, d1=elem_count, d2=0
// NodeKind.NK_PAT_STRUCT:    d0=type_name(sym,0=none), d1=extra_start, d2=field_count
//                   extra: [has_rest(0/1), [field_name, field_pattern(node,0=shorthand)]...]
// NodeKind.NK_PAT_RANGE:     d0=start_low, d1=end_low, d2=inclusive(0/1)
// NodeKind.NK_PAT_OR:        d0=extra_start, d1=pattern_count, d2=0
// NodeKind.NK_PAT_AT_BINDING: d0=name(sym), d1=pattern(node), d2=0
// NodeKind.NK_PAT_SLICE:     d0=extra_start, d1=head_count, d2=rest(sym,0=none)
//                   extra: [has_rest(0/1), head_syms..., tail_count, tail_syms...]
// NodeKind.NK_PAT_TYPED_BIND:  d0=binding(sym), d1=type(sym), d2=0
// NodeKind.NK_PAT_REGEX:    d0=pattern_sym, d1=flags_sym, d2=0
// NodeKind.NK_PAT_ENUM_SHORTHAND: d0=name(sym), d1=extra_start, d2=binding_count
