// Ast — AST node types for the With language.
//
// The AST is produced by the parser and consumed by later passes
// (type checking, lowering, codegen). Nodes are stored in an AstPool
// using index-based references (i32 handles) instead of pointers.
// This follows a SoA (Struct of Arrays) approach for cache-friendly
// access and avoids the need for heap-allocated pointer trees.

use Span
use Token

extern fn with_eprintln(s: str) -> void

// ── Node kinds ───────────────────────────────────────────────────

type NodeId = distinct i32

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
// Metadata packing unit used to encode required-parameter count into
// fn_meta flags without affecting existing FnFlags.* parity checks.
const FN_META_REQUIRED_UNIT: i32 = 32768
const FN_PARAM_STRIDE: i32 = 3
const FN_PARAM_FLAG_NOALIAS: i32 = 1

fn fn_param_is_noalias(flags: i32) -> i32:
    (flags / FN_PARAM_FLAG_NOALIAS) % 2

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

// Unary operators
enum UnaryOp: i32:
    UOP_NEGATE = 0
    UOP_NOT = 1
    UOP_REF = 2
    UOP_MUT_REF = 3
    UOP_DEREF = 4
    UOP_TRY = 5
    UOP_BIT_NOT = 6

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

type AstPool {
    // Core node data (parallel arrays, one entry per node)
    kinds: Vec[i32],
    starts: Vec[i32],
    ends: Vec[i32],
    data0: Vec[i32],
    data1: Vec[i32],
    data2: Vec[i32],
    literal_suffixes: Vec[i32],

    // Extra data for variable-length lists (params, fields, arms, etc.)
    extra: Vec[i32],

    // Top-level declaration indices
    decls: Vec[i32],
    // Number of declarations that originate from the root module after
    // import-merging/strip. -1 means "unknown", and consumers should
    // conservatively treat all declarations as local.
    local_decl_count: i32,
    // Number of declarations that belong to the root module plus the
    // implicitly injected prelude after import-merging/strip.
    // -1 means "unknown".
    prelude_decl_count: i32,

    // String table for source text slices
    strings: Vec[str],

    // Auxiliary fn decl metadata: [node, flags, ret_type, param_start, param_count, tp_start, tp_count]*
    // Each fn decl stores 7 ints. Used by Sema to access param info.
    fn_meta: Vec[i32],

    // Auxiliary type decl metadata: [node, derive_start, derive_count]*
    // derive_start/derive_count reference AstPool.extra symbols.
    type_meta: Vec[i32],

    // Qualified enum pattern metadata: [node, type_sym]*
    pattern_qualifiers: Vec[i32],

    // Auxiliary fn parameter-pattern metadata:
    // - fn_param_patterns stores flat pattern nodes (0 for plain identifier param)
    // - fn_param_pattern_meta stores [node, start, count] records
    fn_param_patterns: Vec[i32],
    fn_param_pattern_meta: Vec[i32],

    // Auxiliary for-loop metadata: [node, index_binding(sym,0=none), label(sym,0=none)]*
    for_meta: Vec[i32],

    // Must-use type declaration nodes
    must_use_type_nodes: Vec[i32],

    // Sealed trait declaration nodes
    sealed_trait_nodes: Vec[i32],

    // Move closure nodes
    move_closure_nodes: Vec[i32],

    // Non-escaping closure nodes (passed as direct call argument)
    non_escaping_closure_nodes: Vec[i32],

    // Where clause metadata: [fn_node, extra_start, clause_count]*
    where_meta: Vec[i32],

    // Impl type params metadata: [impl_node, tp_start, tp_count]*
    impl_type_params: Vec[i32],

    // Impl target type node: [impl_node, type_node]* for generic impl targets
    impl_target_type_nodes: Vec[i32],

    // Impl trait type args: [impl_node, args_start, args_count]* for impl Trait[T1, T2] for Type
    impl_trait_type_args: Vec[i32],

    // O(1) lookup maps for metadata (populated on add, queried on find)
    fn_meta_map: HashMap[i32, i32],
    type_meta_map: HashMap[i32, i32],
    pattern_qualifier_map: HashMap[i32, i32],
    where_meta_map: HashMap[i32, i32],
    impl_type_params_map: HashMap[i32, i32],
    impl_target_type_nodes_map: HashMap[i32, i32],
    impl_trait_type_args_map: HashMap[i32, i32],
    fn_param_pattern_meta_map: HashMap[i32, i32],
    for_meta_map: HashMap[i32, i32],
    must_use_type_set: HashMap[i32, i32],
    sealed_trait_set: HashMap[i32, i32],
    move_closure_set: HashMap[i32, i32],
    non_escaping_closure_set: HashMap[i32, i32],

    // Frozen flag: set to 1 after construction completes.
    // When frozen, mutation methods (add_node, add_extra, etc.) will error.
    frozen: i32,
}

fn AstPool.new -> AstPool:
    var pool = AstPool {
        kinds: Vec.new(),
        starts: Vec.new(),
        ends: Vec.new(),
        data0: Vec.new(),
        data1: Vec.new(),
        data2: Vec.new(),
        literal_suffixes: Vec.new(),
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
        must_use_type_nodes: Vec.new(),
        sealed_trait_nodes: Vec.new(),
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
        must_use_type_set: HashMap.new(),
        sealed_trait_set: HashMap.new(),
        move_closure_set: HashMap.new(),
        non_escaping_closure_set: HashMap.new(),
        frozen: 0,
    }
    // Reserve node 0 as null sentinel
    pool.kinds.push(0)
    pool.starts.push(0)
    pool.ends.push(0)
    pool.data0.push(0)
    pool.data1.push(0)
    pool.data2.push(0)
    pool.literal_suffixes.push(LiteralSuffix.None)
    pool

// Mark the pool as immutable. Any subsequent mutation will print an error.
fn AstPool.freeze(self: &mut AstPool):
    self.frozen = 1

// Add a node to the pool, returns the node index.
fn AstPool.add_node(self: &mut AstPool, kind: i32, start: i32, end: i32, d0: i32, d1: i32, d2: i32) -> NodeId:
    if self.frozen != 0:
        with_eprintln("BUG: AstPool.add_node called after freeze")
    let idx = self.kinds.len() as i32
    self.kinds.push(kind)
    self.starts.push(start)
    self.ends.push(end)
    self.data0.push(d0)
    self.data1.push(d1)
    self.data2.push(d2)
    self.literal_suffixes.push(LiteralSuffix.None)
    (idx) as NodeId

// Add extra data, returns the index in the extra array.
fn AstPool.add_extra(self: &mut AstPool, value: i32) -> i32:
    if self.frozen != 0:
        with_eprintln("BUG: AstPool.add_extra called after freeze")
    let idx = self.extra.len() as i32
    self.extra.push(value)
    idx

// Add a string to the string table, returns the string index.
fn AstPool.add_string(self: &mut AstPool, s: str) -> i32:
    if self.frozen != 0:
        with_eprintln("BUG: AstPool.add_string called after freeze")
    let idx = self.strings.len() as i32
    self.strings.push(s)
    idx

// Get node kind at index
fn AstPool.kind(self: &AstPool, idx: NodeId) -> i32:
    self.kinds.get((idx as i32) as i64)

// Get node data fields
fn AstPool.get_data0(self: &AstPool, idx: NodeId) -> i32:
    self.data0.get((idx as i32) as i64)

fn AstPool.get_data1(self: &AstPool, idx: NodeId) -> i32:
    self.data1.get((idx as i32) as i64)

fn AstPool.get_data2(self: &AstPool, idx: NodeId) -> i32:
    self.data2.get((idx as i32) as i64)

fn AstPool.literal_suffix(self: &AstPool, idx: NodeId) -> i32:
    self.literal_suffixes.get((idx as i32) as i64)

fn AstPool.set_literal_suffix(self: &mut AstPool, idx: NodeId, suffix: i32):
    self.literal_suffixes.set_i32((idx as i32) as i64, suffix)

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

fn AstPool.int_lit_value(self: &AstPool, idx: NodeId) -> i64:
    ast_int_from_parts(self.get_data0(idx), self.get_data1(idx), self.get_data2(idx))

fn AstPool.get_extra(self: &AstPool, idx: i32) -> i32:
    self.extra.get(idx as i64)

fn AstPool.get_string(self: &AstPool, idx: i32) -> str:
    self.strings.get(idx as i64)

fn AstPool.get_start(self: &AstPool, idx: NodeId) -> i32:
    self.starts.get((idx as i32) as i64)

fn AstPool.get_end(self: &AstPool, idx: NodeId) -> i32:
    self.ends.get((idx as i32) as i64)

fn AstPool.node_count(self: &AstPool) -> i32:
    self.kinds.len() as i32

fn AstPool.add_decl(self: &mut AstPool, node_idx: NodeId):
    if self.frozen != 0:
        with_eprintln("BUG: AstPool.add_decl called after freeze")
    self.decls.push(node_idx as i32)

fn AstPool.decl_count(self: &AstPool) -> i32:
    self.decls.len() as i32

fn AstPool.get_decl(self: &AstPool, idx: i32) -> NodeId:
    (self.decls.get(idx as i64)) as NodeId

fn AstPool.set_local_decl_count(self: &mut AstPool, n: i32):
    self.local_decl_count = n

fn AstPool.local_decl_count(self: &AstPool) -> i32:
    self.local_decl_count

fn AstPool.set_prelude_decl_count(self: &mut AstPool, n: i32):
    self.prelude_decl_count = n

fn AstPool.prelude_decl_count(self: &AstPool) -> i32:
    self.prelude_decl_count

fn AstPool.extra_len(self: &AstPool) -> i32:
    self.extra.len() as i32

fn AstPool.set_data0(self: &mut AstPool, idx: NodeId, val: i32):
    self.data0.set_i32((idx as i32) as i64, val)

fn AstPool.set_data1(self: &mut AstPool, idx: NodeId, val: i32):
    self.data1.set_i32((idx as i32) as i64, val)

fn AstPool.set_data2(self: &mut AstPool, idx: NodeId, val: i32):
    self.data2.set_i32((idx as i32) as i64, val)

fn AstPool.set_start(self: &mut AstPool, idx: NodeId, val: i32):
    self.starts.set_i32((idx as i32) as i64, val)

fn AstPool.set_end(self: &mut AstPool, idx: NodeId, val: i32):
    self.ends.set_i32((idx as i32) as i64, val)

// Store fn decl metadata: [node, flags, ret_type, param_start, param_count, tp_start, tp_count]
fn AstPool.add_fn_meta(self: &mut AstPool, node: NodeId, flags: i32, ret: i32, ps: i32, pc: i32, ts: i32, tc: i32):
    let idx = self.fn_meta.len() as i32
    self.fn_meta.push(node as i32)
    self.fn_meta.push(flags)
    self.fn_meta.push(ret)
    self.fn_meta.push(ps)
    self.fn_meta.push(pc)
    self.fn_meta.push(ts)
    self.fn_meta.push(tc)
    self.fn_meta_map.insert(node as i32, idx)

// Get fn metadata for a given fn decl node. Returns 7-int record start or -1.
fn AstPool.find_fn_meta(self: &AstPool, node: NodeId) -> i32:
    let opt = self.fn_meta_map.get(node as i32)
    if opt.is_some():
        return opt.unwrap()
    0 - 1

fn AstPool.fn_meta_flags(self: &AstPool, meta: i32) -> i32:
    self.fn_meta.get((meta + 1) as i64)

fn AstPool.fn_meta_ret(self: &AstPool, meta: i32) -> i32:
    self.fn_meta.get((meta + 2) as i64)

fn AstPool.fn_meta_param_start(self: &AstPool, meta: i32) -> i32:
    self.fn_meta.get((meta + 3) as i64)

fn AstPool.fn_meta_param_count(self: &AstPool, meta: i32) -> i32:
    self.fn_meta.get((meta + 4) as i64)

fn AstPool.fn_meta_tp_start(self: &AstPool, meta: i32) -> i32:
    self.fn_meta.get((meta + 5) as i64)

fn AstPool.fn_meta_tp_count(self: &AstPool, meta: i32) -> i32:
    self.fn_meta.get((meta + 6) as i64)

fn AstPool.fn_param_name(self: &AstPool, param_start: i32, param_idx: i32) -> i32:
    self.get_extra(param_start + param_idx * FN_PARAM_STRIDE)

fn AstPool.fn_param_type(self: &AstPool, param_start: i32, param_idx: i32) -> i32:
    self.get_extra(param_start + param_idx * FN_PARAM_STRIDE + 1)

fn AstPool.fn_param_flags(self: &AstPool, param_start: i32, param_idx: i32) -> i32:
    self.get_extra(param_start + param_idx * FN_PARAM_STRIDE + 2)

fn AstPool.add_type_meta(self: &mut AstPool, node: NodeId, derive_start: i32, derive_count: i32):
    let idx = self.type_meta.len() as i32
    self.type_meta.push(node as i32)
    self.type_meta.push(derive_start)
    self.type_meta.push(derive_count)
    self.type_meta_map.insert(node as i32, idx)

fn AstPool.find_type_meta(self: &AstPool, node: NodeId) -> i32:
    let opt = self.type_meta_map.get(node as i32)
    if opt.is_some():
        return opt.unwrap()
    0 - 1

fn AstPool.type_meta_derive_start(self: &AstPool, meta: i32) -> i32:
    self.type_meta.get((meta + 1) as i64)

fn AstPool.type_meta_derive_count(self: &AstPool, meta: i32) -> i32:
    self.type_meta.get((meta + 2) as i64)

fn AstPool.add_pattern_qualifier(self: &mut AstPool, node: NodeId, type_sym: i32):
    let idx = self.pattern_qualifiers.len() as i32
    self.pattern_qualifiers.push(node as i32)
    self.pattern_qualifiers.push(type_sym)
    self.pattern_qualifier_map.insert(node as i32, idx)

fn AstPool.pattern_qualifier(self: &AstPool, node: NodeId) -> i32:
    let opt = self.pattern_qualifier_map.get(node as i32)
    if opt.is_some():
        return self.pattern_qualifiers.get((opt.unwrap() + 1) as i64)
    0

fn AstPool.mark_must_use_type(self: &mut AstPool, node: NodeId):
    self.must_use_type_nodes.push(node as i32)
    self.must_use_type_set.insert(node as i32, 1)

fn AstPool.is_must_use_type_node(self: &AstPool, node: NodeId) -> i32:
    if self.must_use_type_set.contains(node as i32): return 1
    0

fn AstPool.mark_sealed_trait(self: &mut AstPool, node: NodeId):
    self.sealed_trait_nodes.push(node as i32)
    self.sealed_trait_set.insert(node as i32, 1)

fn AstPool.is_sealed_trait_node(self: &AstPool, node: NodeId) -> i32:
    if self.sealed_trait_set.contains(node as i32): return 1
    0

fn AstPool.mark_move_closure(self: &mut AstPool, node: NodeId):
    self.move_closure_nodes.push(node as i32)
    self.move_closure_set.insert(node as i32, 1)

fn AstPool.is_move_closure(self: &AstPool, node: NodeId) -> i32:
    if self.move_closure_set.contains(node as i32): return 1
    0

fn AstPool.mark_non_escaping_closure(self: &mut AstPool, node: NodeId):
    self.non_escaping_closure_nodes.push(node as i32)
    self.non_escaping_closure_set.insert(node as i32, 1)

fn AstPool.is_non_escaping_closure(self: &AstPool, node: NodeId) -> i32:
    if self.non_escaping_closure_set.contains(node as i32): return 1
    0

fn AstPool.add_where_meta(self: &mut AstPool, fn_node: NodeId, extra_start: i32, clause_count: i32):
    let idx = self.where_meta.len() as i32
    self.where_meta.push(fn_node as i32)
    self.where_meta.push(extra_start)
    self.where_meta.push(clause_count)
    self.where_meta_map.insert(fn_node as i32, idx)

fn AstPool.find_where_meta(self: &AstPool, fn_node: NodeId) -> i32:
    let opt = self.where_meta_map.get(fn_node as i32)
    if opt.is_some():
        return opt.unwrap()
    0 - 1

fn AstPool.add_impl_type_params(self: &mut AstPool, impl_node: NodeId, tp_start: i32, tp_count: i32):
    let idx = self.impl_type_params.len() as i32
    self.impl_type_params.push(impl_node as i32)
    self.impl_type_params.push(tp_start)
    self.impl_type_params.push(tp_count)
    self.impl_type_params_map.insert(impl_node as i32, idx)

fn AstPool.find_impl_type_params(self: &AstPool, impl_node: NodeId) -> i32:
    let opt = self.impl_type_params_map.get(impl_node as i32)
    if opt.is_some():
        return opt.unwrap()
    0 - 1

fn AstPool.add_impl_target_type_node(self: &mut AstPool, impl_node: NodeId, type_node: NodeId):
    self.impl_target_type_nodes.push(impl_node as i32)
    self.impl_target_type_nodes.push(type_node as i32)
    self.impl_target_type_nodes_map.insert(impl_node as i32, type_node as i32)

fn AstPool.find_impl_target_type_node(self: &AstPool, impl_node: NodeId) -> NodeId:
    let opt = self.impl_target_type_nodes_map.get(impl_node as i32)
    if opt.is_some():
        return (opt.unwrap()) as NodeId
    var i = 0
    while i < self.impl_target_type_nodes.len() as i32:
        if self.impl_target_type_nodes.get(i as i64) == (impl_node as i32):
            return (self.impl_target_type_nodes.get((i + 1) as i64)) as NodeId
        i = i + 2
    (0) as NodeId

fn AstPool.add_impl_trait_type_args(self: &mut AstPool, impl_node: NodeId, args_start: i32, args_count: i32):
    let idx = self.impl_trait_type_args.len() as i32
    self.impl_trait_type_args.push(impl_node as i32)
    self.impl_trait_type_args.push(args_start)
    self.impl_trait_type_args.push(args_count)
    self.impl_trait_type_args_map.insert(impl_node as i32, idx)

fn AstPool.find_impl_trait_type_args(self: &AstPool, impl_node: NodeId) -> i32:
    let opt = self.impl_trait_type_args_map.get(impl_node as i32)
    if opt.is_some():
        return opt.unwrap()
    0 - 1

fn AstPool.fn_param_patterns_len(self: &AstPool) -> i32:
    self.fn_param_patterns.len() as i32

fn AstPool.add_fn_param_pattern_value(self: &mut AstPool, node: NodeId):
    self.fn_param_patterns.push(node as i32)

fn AstPool.fn_param_pattern_value(self: &AstPool, idx: i32) -> NodeId:
    (self.fn_param_patterns.get(idx as i64)) as NodeId

fn AstPool.add_fn_param_pattern_meta(self: &mut AstPool, node: NodeId, start: i32, count: i32):
    let idx = self.fn_param_pattern_meta.len() as i32
    self.fn_param_pattern_meta.push(node as i32)
    self.fn_param_pattern_meta.push(start)
    self.fn_param_pattern_meta.push(count)
    self.fn_param_pattern_meta_map.insert(node as i32, idx)

fn AstPool.find_fn_param_pattern_meta(self: &AstPool, node: NodeId) -> i32:
    let opt = self.fn_param_pattern_meta_map.get(node as i32)
    if opt.is_some():
        return opt.unwrap()
    0 - 1

fn AstPool.fn_param_pattern_meta_start(self: &AstPool, meta: i32) -> i32:
    self.fn_param_pattern_meta.get((meta + 1) as i64)

fn AstPool.fn_param_pattern_meta_count(self: &AstPool, meta: i32) -> i32:
    self.fn_param_pattern_meta.get((meta + 2) as i64)

fn AstPool.add_for_meta(self: &mut AstPool, node: NodeId, index_binding: i32, label: i32):
    let idx = self.for_meta.len() as i32
    self.for_meta.push(node as i32)
    self.for_meta.push(index_binding)
    self.for_meta.push(label)
    self.for_meta_map.insert(node as i32, idx)

fn AstPool.find_for_meta(self: &AstPool, node: NodeId) -> i32:
    let opt = self.for_meta_map.get(node as i32)
    if opt.is_some():
        return opt.unwrap()
    0 - 1

fn AstPool.for_meta_index_binding(self: &AstPool, meta: i32) -> i32:
    self.for_meta.get((meta + 1) as i64)

fn AstPool.for_meta_label(self: &AstPool, meta: i32) -> i32:
    self.for_meta.get((meta + 2) as i64)

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
// NodeKind.NK_LOOP:          d0=body(node), d1=label(sym,0=none), d2=0
// NodeKind.NK_FOR:           d0=binding(sym), d1=iterable(node), d2=body(node)
//                   extra: [index_binding(sym,0=none), label(sym,0=none)]
// NodeKind.NK_BREAK:         d0=value(node,0=none), d1=label(sym,0=none), d2=0
// NodeKind.NK_CONTINUE:      d0=label(sym,0=none), d1=0, d2=0
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
// NodeKind.NK_PAT_INT:       d0=value_low, d1=value_high, d2=0
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
// NodeKind.NK_PAT_ENUM_SHORTHAND: d0=name(sym), d1=extra_start, d2=binding_count
