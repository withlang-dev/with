// Ast — AST node types for the With language.
//
// The AST is produced by the parser and consumed by later passes
// (type checking, lowering, codegen). Nodes are stored in an AstPool
// using index-based references (i32 handles) instead of pointers.
// This follows a SoA (Struct of Arrays) approach for cache-friendly
// access and avoids the need for heap-allocated pointer trees.

use Span
use Token

// ── Node kinds (integer constants) ────────────────────────────────

// Declarations
const NK_FN_DECL: i32 = 1
const NK_TYPE_DECL: i32 = 2
const NK_USE_DECL: i32 = 3
const NK_LET_DECL: i32 = 4
const NK_EXTERN_FN: i32 = 5
const NK_C_IMPORT: i32 = 6
const NK_TRAIT_DECL: i32 = 7
const NK_IMPL_DECL: i32 = 8
const NK_POISONED_DECL: i32 = 9

// Expressions
const NK_INT_LIT: i32 = 20
const NK_FLOAT_LIT: i32 = 21
const NK_STRING_LIT: i32 = 22
const NK_BOOL_LIT: i32 = 23
const NK_IDENT: i32 = 24
const NK_BINARY: i32 = 25
const NK_UNARY: i32 = 26
const NK_CALL: i32 = 27
const NK_FIELD_ACCESS: i32 = 28
const NK_INDEX: i32 = 29
const NK_BLOCK: i32 = 30
const NK_IF_EXPR: i32 = 31
const NK_RETURN: i32 = 32
const NK_LET_BINDING: i32 = 33
const NK_ASSIGN: i32 = 34
const NK_WHILE: i32 = 35
const NK_LOOP: i32 = 36
const NK_FOR: i32 = 37
const NK_BREAK: i32 = 38
const NK_CONTINUE: i32 = 39
const NK_MATCH: i32 = 40
const NK_TUPLE: i32 = 41
const NK_ARRAY_LIT: i32 = 42
const NK_STRUCT_LIT: i32 = 43
const NK_CLOSURE: i32 = 44
const NK_CAST: i32 = 45
const NK_DEFER: i32 = 46
const NK_PIPELINE: i32 = 47
const NK_RANGE: i32 = 48
const NK_GROUPED: i32 = 49
const NK_C_STRING_LIT: i32 = 50
const NK_VARIANT_SHORTHAND: i32 = 51
const NK_WITH_EXPR: i32 = 52
const NK_RECORD_UPDATE: i32 = 53
const NK_ENUM_VARIANT: i32 = 54
const NK_SLICE: i32 = 55
const NK_OPTIONAL_CHAIN: i32 = 56
const NK_AWAIT: i32 = 57
const NK_ASYNC_BLOCK: i32 = 58
const NK_SPAWN: i32 = 59
const NK_YIELD: i32 = 60
const NK_COMPTIME: i32 = 61
const NK_LET_ELSE: i32 = 62
const NK_TUPLE_DESTRUCTURE: i32 = 63
const NK_ARRAY_COMPREHENSION: i32 = 64
const NK_ASYNC_SCOPE: i32 = 65
const NK_SELECT_AWAIT: i32 = 66
const NK_ERRDEFER: i32 = 67
const NK_POISONED_EXPR: i32 = 69

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

// Type expressions
const NK_TYPE_NAMED: i32 = 80
const NK_TYPE_GENERIC: i32 = 81
const NK_TYPE_REF: i32 = 82
const NK_TYPE_PTR: i32 = 83
const NK_TYPE_FN: i32 = 84
const NK_TYPE_TUPLE: i32 = 85
const NK_TYPE_OPTIONAL: i32 = 86
const NK_TYPE_ARRAY: i32 = 87
const NK_TYPE_SLICE: i32 = 88
const NK_TYPE_TRAIT_OBJ: i32 = 89
const NK_TYPE_INFERRED: i32 = 90
const NK_TYPE_ASSOC: i32 = 91  // d0=base_sym (e.g. Self), d1=assoc_sym (e.g. Output), d2=0

// Patterns (for match arms)
const NK_PAT_WILDCARD: i32 = 100
const NK_PAT_IDENT: i32 = 101
const NK_PAT_INT: i32 = 102
const NK_PAT_BOOL: i32 = 103
const NK_PAT_STRING: i32 = 104
const NK_PAT_VARIANT: i32 = 105
const NK_PAT_TUPLE: i32 = 106
const NK_PAT_STRUCT: i32 = 107
const NK_PAT_RANGE: i32 = 108
const NK_PAT_OR: i32 = 109
const NK_PAT_ENUM_SHORTHAND: i32 = 111
const NK_PAT_AT_BINDING: i32 = 112
const NK_PAT_SLICE: i32 = 113
const NK_PAT_TYPED_BIND: i32 = 114

// Match arm
const NK_MATCH_ARM: i32 = 110

// Type decl sub-kinds (stored in data2 field)
const TDK_ALIAS: i32 = 0
const TDK_STRUCT: i32 = 1
const TDK_ENUM: i32 = 2
const TDK_DISTINCT: i32 = 3
const TDK_DISC_ENUM: i32 = 4
const TDK_FLAG_EPHEMERAL: i32 = 8

fn pack_type_decl_kind(sub_kind: i32, is_ephemeral: i32) -> i32:
    if is_ephemeral != 0:
        return sub_kind + TDK_FLAG_EPHEMERAL
    sub_kind

fn type_decl_sub_kind(packed: i32) -> i32:
    packed % TDK_FLAG_EPHEMERAL

fn type_decl_is_ephemeral(packed: i32) -> i32:
    (packed / TDK_FLAG_EPHEMERAL) % 2

// Fn decl flag bits (stored in data2 field)
const FN_FLAG_PUB: i32 = 1
const FN_FLAG_ASYNC: i32 = 2
const FN_FLAG_GEN: i32 = 4
const FN_FLAG_COMPTIME: i32 = 8
const FN_FLAG_TAILREC: i32 = 16
const FN_FLAG_MUST_USE: i32 = 32
const FN_FLAG_VARIADIC: i32 = 64
const FN_FLAG_INLINE: i32 = 128
const FN_FLAG_NOINLINE: i32 = 256
const FN_FLAG_PANIC_HANDLER: i32 = 512
const FN_FLAG_ENTRY: i32 = 1024
const FN_FLAG_NO_MAIN: i32 = 2048
const FN_FLAG_TEST: i32 = 4096
const FN_FLAG_BEFORE: i32 = 8192
const FN_FLAG_AFTER: i32 = 16384
// Metadata packing unit used to encode required-parameter count into
// fn_meta flags without affecting existing FN_FLAG_* parity checks.
const FN_META_REQUIRED_UNIT: i32 = 32768

// Visibility flags
const VIS_PRIVATE: i32 = 0
const VIS_PUBLIC: i32 = 1

// Binary operators
const OP_ADD: i32 = 0
const OP_SUB: i32 = 1
const OP_MUL: i32 = 2
const OP_DIV: i32 = 3
const OP_MOD: i32 = 4
const OP_EQ: i32 = 5
const OP_NEQ: i32 = 6
const OP_LT: i32 = 7
const OP_GT: i32 = 8
const OP_LTE: i32 = 9
const OP_GTE: i32 = 10
const OP_AND: i32 = 11
const OP_OR: i32 = 12
const OP_BIT_AND: i32 = 13
const OP_BIT_OR: i32 = 14
const OP_BIT_XOR: i32 = 15
const OP_SHL: i32 = 16
const OP_SHR: i32 = 17
const OP_DEFAULT: i32 = 18
const OP_CONCAT: i32 = 19
const OP_ADD_WRAP: i32 = 20
const OP_SUB_WRAP: i32 = 21
const OP_MUL_WRAP: i32 = 22
const OP_IN: i32 = 23
const OP_NOT_IN: i32 = 24

// Unary operators
const UOP_NEGATE: i32 = 0
const UOP_NOT: i32 = 1
const UOP_REF: i32 = 2
const UOP_MUT_REF: i32 = 3
const UOP_DEREF: i32 = 4
const UOP_TRY: i32 = 5

// ── AST Pool ──────────────────────────────────────────────────────

// The AstPool stores all AST nodes in parallel arrays (SoA layout).
// Each node has:
// - A kind tag (NK_*)
// - Start/end span positions (byte offsets into source)
// - Up to 3 integer data fields (meaning depends on kind)
// - An optional extra data range for variable-length data
//
// Node 0 is reserved as a null sentinel.

type AstPool = {
    // Core node data (parallel arrays, one entry per node)
    kinds: Vec[i32],
    starts: Vec[i32],
    ends: Vec[i32],
    data0: Vec[i32],
    data1: Vec[i32],
    data2: Vec[i32],

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

}

fn AstPool.new -> AstPool:
    var pool = AstPool {
        kinds: Vec.new(),
        starts: Vec.new(),
        ends: Vec.new(),
        data0: Vec.new(),
        data1: Vec.new(),
        data2: Vec.new(),
        extra: Vec.new(),
        decls: Vec.new(),
        local_decl_count: 0 - 1,
        prelude_decl_count: 0 - 1,
        strings: Vec.new(),
        fn_meta: Vec.new(),
        type_meta: Vec.new(),
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
    }
    // Reserve node 0 as null sentinel
    pool.kinds.push(0)
    pool.starts.push(0)
    pool.ends.push(0)
    pool.data0.push(0)
    pool.data1.push(0)
    pool.data2.push(0)
    pool

// Add a node to the pool, returns the node index.
fn AstPool.add_node(self: &mut AstPool, kind: i32, start: i32, end: i32, d0: i32, d1: i32, d2: i32) -> i32:
    let idx = self.kinds.len() as i32
    self.kinds.push(kind)
    self.starts.push(start)
    self.ends.push(end)
    self.data0.push(d0)
    self.data1.push(d1)
    self.data2.push(d2)
    idx

// Add extra data, returns the index in the extra array.
fn AstPool.add_extra(self: &mut AstPool, value: i32) -> i32:
    let idx = self.extra.len() as i32
    self.extra.push(value)
    idx

// Add a string to the string table, returns the string index.
fn AstPool.add_string(self: &mut AstPool, s: str) -> i32:
    let idx = self.strings.len() as i32
    self.strings.push(s)
    idx

// Get node kind at index
fn AstPool.kind(self: &AstPool, idx: i32) -> i32:
    self.kinds.get(idx as i64)

// Get node data fields
fn AstPool.get_data0(self: &AstPool, idx: i32) -> i32:
    self.data0.get(idx as i64)

fn AstPool.get_data1(self: &AstPool, idx: i32) -> i32:
    self.data1.get(idx as i64)

fn AstPool.get_data2(self: &AstPool, idx: i32) -> i32:
    self.data2.get(idx as i64)

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

fn AstPool.int_lit_value(self: &AstPool, idx: i32) -> i64:
    ast_int_from_parts(self.get_data0(idx), self.get_data1(idx), self.get_data2(idx))

fn AstPool.get_extra(self: &AstPool, idx: i32) -> i32:
    self.extra.get(idx as i64)

fn AstPool.get_string(self: &AstPool, idx: i32) -> str:
    self.strings.get(idx as i64)

fn AstPool.get_start(self: &AstPool, idx: i32) -> i32:
    self.starts.get(idx as i64)

fn AstPool.get_end(self: &AstPool, idx: i32) -> i32:
    self.ends.get(idx as i64)

fn AstPool.node_count(self: &AstPool) -> i32:
    self.kinds.len() as i32

fn AstPool.add_decl(self: &mut AstPool, node_idx: i32):
    self.decls.push(node_idx)

fn AstPool.decl_count(self: &AstPool) -> i32:
    self.decls.len() as i32

fn AstPool.get_decl(self: &AstPool, idx: i32) -> i32:
    self.decls.get(idx as i64)

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

fn AstPool.set_data0(self: &mut AstPool, idx: i32, val: i32):
    self.data0.set_i32(idx as i64, val)

fn AstPool.set_data1(self: &mut AstPool, idx: i32, val: i32):
    self.data1.set_i32(idx as i64, val)

fn AstPool.set_data2(self: &mut AstPool, idx: i32, val: i32):
    self.data2.set_i32(idx as i64, val)

fn AstPool.set_start(self: &mut AstPool, idx: i32, val: i32):
    self.starts.set_i32(idx as i64, val)

fn AstPool.set_end(self: &mut AstPool, idx: i32, val: i32):
    self.ends.set_i32(idx as i64, val)

// Store fn decl metadata: [node, flags, ret_type, param_start, param_count, tp_start, tp_count]
fn AstPool.add_fn_meta(self: &mut AstPool, node: i32, flags: i32, ret: i32, ps: i32, pc: i32, ts: i32, tc: i32):
    self.fn_meta.push(node)
    self.fn_meta.push(flags)
    self.fn_meta.push(ret)
    self.fn_meta.push(ps)
    self.fn_meta.push(pc)
    self.fn_meta.push(ts)
    self.fn_meta.push(tc)

// Get fn metadata for a given fn decl node. Returns 7-int record start or -1.
fn AstPool.find_fn_meta(self: &AstPool, node: i32) -> i32:
    var i = 0
    while i < self.fn_meta.len() as i32:
        if self.fn_meta.get(i as i64) == node:
            return i
        i = i + 7
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

fn AstPool.add_type_meta(self: &mut AstPool, node: i32, derive_start: i32, derive_count: i32):
    self.type_meta.push(node)
    self.type_meta.push(derive_start)
    self.type_meta.push(derive_count)

fn AstPool.find_type_meta(self: &AstPool, node: i32) -> i32:
    var i = 0
    while i < self.type_meta.len() as i32:
        if self.type_meta.get(i as i64) == node:
            return i
        i = i + 3
    0 - 1

fn AstPool.type_meta_derive_start(self: &AstPool, meta: i32) -> i32:
    self.type_meta.get((meta + 1) as i64)

fn AstPool.type_meta_derive_count(self: &AstPool, meta: i32) -> i32:
    self.type_meta.get((meta + 2) as i64)

fn AstPool.mark_must_use_type(self: &mut AstPool, node: i32):
    self.must_use_type_nodes.push(node)

fn AstPool.is_must_use_type_node(self: &AstPool, node: i32) -> i32:
    var i = 0
    while i < self.must_use_type_nodes.len() as i32:
        if self.must_use_type_nodes.get(i as i64) == node:
            return 1
        i = i + 1
    0

fn AstPool.mark_sealed_trait(self: &mut AstPool, node: i32):
    self.sealed_trait_nodes.push(node)

fn AstPool.is_sealed_trait_node(self: &AstPool, node: i32) -> i32:
    var i = 0
    while i < self.sealed_trait_nodes.len() as i32:
        if self.sealed_trait_nodes.get(i as i64) == node:
            return 1
        i = i + 1
    0

fn AstPool.mark_move_closure(self: &mut AstPool, node: i32):
    self.move_closure_nodes.push(node)

fn AstPool.is_move_closure(self: &AstPool, node: i32) -> i32:
    var i = 0
    while i < self.move_closure_nodes.len() as i32:
        if self.move_closure_nodes.get(i as i64) == node:
            return 1
        i = i + 1
    0

fn AstPool.mark_non_escaping_closure(self: &mut AstPool, node: i32):
    self.non_escaping_closure_nodes.push(node)

fn AstPool.is_non_escaping_closure(self: &AstPool, node: i32) -> i32:
    var i = 0
    while i < self.non_escaping_closure_nodes.len() as i32:
        if self.non_escaping_closure_nodes.get(i as i64) == node:
            return 1
        i = i + 1
    0

fn AstPool.add_where_meta(self: &mut AstPool, fn_node: i32, extra_start: i32, clause_count: i32):
    self.where_meta.push(fn_node)
    self.where_meta.push(extra_start)
    self.where_meta.push(clause_count)

fn AstPool.find_where_meta(self: &AstPool, fn_node: i32) -> i32:
    var i = 0
    while i < self.where_meta.len() as i32:
        if self.where_meta.get(i as i64) == fn_node:
            return i
        i = i + 3
    0 - 1

fn AstPool.add_impl_type_params(self: &mut AstPool, impl_node: i32, tp_start: i32, tp_count: i32):
    self.impl_type_params.push(impl_node)
    self.impl_type_params.push(tp_start)
    self.impl_type_params.push(tp_count)

fn AstPool.find_impl_type_params(self: &AstPool, impl_node: i32) -> i32:
    var i = 0
    while i < self.impl_type_params.len() as i32:
        if self.impl_type_params.get(i as i64) == impl_node:
            return i
        i = i + 3
    0 - 1

fn AstPool.add_impl_target_type_node(self: &mut AstPool, impl_node: i32, type_node: i32):
    self.impl_target_type_nodes.push(impl_node)
    self.impl_target_type_nodes.push(type_node)

fn AstPool.find_impl_target_type_node(self: &AstPool, impl_node: i32) -> i32:
    var i = 0
    while i < self.impl_target_type_nodes.len() as i32:
        if self.impl_target_type_nodes.get(i as i64) == impl_node:
            return self.impl_target_type_nodes.get((i + 1) as i64)
        i = i + 2
    0

fn AstPool.add_impl_trait_type_args(self: &mut AstPool, impl_node: i32, args_start: i32, args_count: i32):
    self.impl_trait_type_args.push(impl_node)
    self.impl_trait_type_args.push(args_start)
    self.impl_trait_type_args.push(args_count)

fn AstPool.find_impl_trait_type_args(self: &AstPool, impl_node: i32) -> i32:
    var i = 0
    while i < self.impl_trait_type_args.len() as i32:
        if self.impl_trait_type_args.get(i as i64) == impl_node:
            return i
        i = i + 3
    0 - 1

fn AstPool.fn_param_patterns_len(self: &AstPool) -> i32:
    self.fn_param_patterns.len() as i32

fn AstPool.add_fn_param_pattern_value(self: &mut AstPool, node: i32):
    self.fn_param_patterns.push(node)

fn AstPool.fn_param_pattern_value(self: &AstPool, idx: i32) -> i32:
    self.fn_param_patterns.get(idx as i64)

fn AstPool.add_fn_param_pattern_meta(self: &mut AstPool, node: i32, start: i32, count: i32):
    self.fn_param_pattern_meta.push(node)
    self.fn_param_pattern_meta.push(start)
    self.fn_param_pattern_meta.push(count)

fn AstPool.find_fn_param_pattern_meta(self: &AstPool, node: i32) -> i32:
    var i = 0
    while i < self.fn_param_pattern_meta.len() as i32:
        if self.fn_param_pattern_meta.get(i as i64) == node:
            return i
        i = i + 3
    0 - 1

fn AstPool.fn_param_pattern_meta_start(self: &AstPool, meta: i32) -> i32:
    self.fn_param_pattern_meta.get((meta + 1) as i64)

fn AstPool.fn_param_pattern_meta_count(self: &AstPool, meta: i32) -> i32:
    self.fn_param_pattern_meta.get((meta + 2) as i64)

fn AstPool.add_for_meta(self: &mut AstPool, node: i32, index_binding: i32, label: i32):
    self.for_meta.push(node)
    self.for_meta.push(index_binding)
    self.for_meta.push(label)

fn AstPool.find_for_meta(self: &AstPool, node: i32) -> i32:
    var i = 0
    while i < self.for_meta.len() as i32:
        if self.for_meta.get(i as i64) == node:
            return i
        i = i + 3
    0 - 1

fn AstPool.for_meta_index_binding(self: &AstPool, meta: i32) -> i32:
    self.for_meta.get((meta + 1) as i64)

fn AstPool.for_meta_label(self: &AstPool, meta: i32) -> i32:
    self.for_meta.get((meta + 2) as i64)

// ── Node Data Layout Reference ───────────────────────────────────
//
// NK_FN_DECL:       d0=name(sym), d1=body(node), d2=flags
//                   extra: [return_type(node), param_count, [param_name, param_type]*, type_param_count, [type_param_name, bound_count, bounds...]*]
//
// NK_TYPE_DECL:     d0=name(sym), d1=extra_start, d2=packed_kind (TDK_* + flags)
//                   For struct: extra=[field_count, [field_name, field_type, field_default]*, vis, tp_start, tp_count]
//                   For enum: extra=[variant_count, [var_name, payload_count, payload_type...]*, vis, tp_start, tp_count]
//                   For alias/distinct: extra=[aliased_or_inner_type, vis, tp_start, tp_count]
//
// NK_USE_DECL:      d0=extra_start, d1=path_count, d2=0
//                   extra: [sym, sym, ...]
//
// NK_LET_DECL:      d0=name(sym), d1=value(node), d2=flags (bit0=mut, bit1=pub)
//                   extra: [type_expr(node)] if type annotation present
//
// NK_EXTERN_FN:     d0=name(sym), d1=extra_start, d2=flags (bit0=variadic)
//                   extra: [return_type(node), param_count, [param_name, param_type]*]
//
// NK_C_IMPORT:      d0=header_str_idx, d1=extra_start, d2=link_lib_count
//
// NK_TRAIT_DECL:    d0=name(sym), d1=extra_start, d2=vis
//
// NK_IMPL_DECL:     d0=type_name(sym), d1=extra_start, d2=trait_name(sym, 0=none)
//
// NK_INT_LIT:       d0=value_low, d1=value_high, d2=0
// NK_FLOAT_LIT:     d0=string_idx, d1=0, d2=0
// NK_STRING_LIT:    d0=sym, d1=0, d2=0
// NK_C_STRING_LIT:  d0=sym, d1=0, d2=0
// NK_BOOL_LIT:      d0=value(0/1), d1=0, d2=0
// NK_IDENT:         d0=sym, d1=0, d2=0
// NK_BINARY:        d0=op(OP_*), d1=lhs(node), d2=rhs(node)
// NK_UNARY:         d0=op(UOP_*), d1=operand(node), d2=0
// NK_CALL:          d0=callee(node), d1=extra_start, d2=arg_count
// NK_FIELD_ACCESS:  d0=expr(node), d1=field(sym), d2=0
// NK_INDEX:         d0=expr(node), d1=index(node), d2=0
// NK_SLICE:         d0=expr(node), d1=start(node,0=none), d2=end(node,0=none)
// NK_BLOCK:         d0=extra_start, d1=stmt_count, d2=tail(node,0=none)
// NK_IF_EXPR:       d0=cond(node), d1=then(node), d2=else(node,0=none)
// NK_RETURN:        d0=value(node,0=none), d1=0, d2=0
// NK_LET_BINDING:   d0=name(sym), d1=value(node), d2=flags (bit0=mut)
//                   If has type: extra=[type_node]
// NK_LET_ELSE:      d0=pattern(node), d1=value(node), d2=else_body(node)
// NK_TUPLE_DESTRUCTURE: d0=extra_start, d1=name_count, d2=value(node)
// NK_ASSIGN:        d0=target(node), d1=value(node), d2=0
// NK_WHILE:         d0=cond(node), d1=body(node), d2=label(sym,0=none)
// NK_LOOP:          d0=body(node), d1=label(sym,0=none), d2=0
// NK_FOR:           d0=binding(sym), d1=iterable(node), d2=body(node)
//                   extra: [index_binding(sym,0=none), label(sym,0=none)]
// NK_BREAK:         d0=value(node,0=none), d1=label(sym,0=none), d2=0
// NK_CONTINUE:      d0=label(sym,0=none), d1=0, d2=0
// NK_MATCH:         d0=subject(node), d1=extra_start, d2=arm_count
// NK_MATCH_ARM:     d0=pattern(node), d1=body(node), d2=guard(node,0=none)
// NK_TUPLE:         d0=extra_start, d1=elem_count, d2=0
// NK_ARRAY_LIT:     d0=extra_start, d1=elem_count, d2=0
// NK_ARRAY_COMPREHENSION: d0=expr(node), d1=binding(sym), d2=iterable(node)
//                   extra: [filter(node,0=none)]
// NK_STRUCT_LIT:    d0=name(sym), d1=extra_start, d2=field_count
// NK_CLOSURE:       d0=body(node), d1=extra_start, d2=param_count
// NK_CAST:          d0=expr(node), d1=target_type(node), d2=0
// NK_DEFER:         d0=body(node), d1=0, d2=0
// NK_ERRDEFER:      d0=body(node), d1=0, d2=0
// NK_PIPELINE:      d0=lhs(node), d1=rhs(node), d2=0
// NK_RANGE:         d0=start(node,0=none), d1=end(node,0=none), d2=inclusive(0/1)
// NK_GROUPED:       d0=inner(node), d1=0, d2=0
// NK_VARIANT_SHORTHAND: d0=name(sym), d1=extra_start, d2=arg_count
// NK_WITH_EXPR:     d0=source(node), d1=body(node), d2=encoded_binding(sym+mut)
// NK_RECORD_UPDATE: d0=source(node), d1=extra_start, d2=field_count
// NK_ENUM_VARIANT:  d0=type_name(sym), d1=variant_name(sym), d2=extra_start
//                   extra: [arg_count, args...]
// NK_OPTIONAL_CHAIN: d0=expr(node), d1=member(sym), d2=extra_start
//                    extra: [has_args(0/1), arg_count, args...]
// NK_AWAIT:         d0=expr(node), d1=0, d2=0
// NK_ASYNC_BLOCK:   d0=body(node), d1=0, d2=0
// NK_SPAWN:         d0=expr(node), d1=0, d2=0
// NK_YIELD:         d0=expr(node), d1=0, d2=0
// NK_COMPTIME:      d0=expr(node), d1=0, d2=0
// NK_ASYNC_SCOPE:   d0=name(sym), d1=body(node), d2=0
// NK_SELECT_AWAIT:  d0=extra_start, d1=arm_count, d2=0
//
// Type expression nodes:
// NK_TYPE_NAMED:    d0=sym, d1=0, d2=0
// NK_TYPE_GENERIC:  d0=name(sym), d1=extra_start, d2=arg_count
// NK_TYPE_REF:      d0=pointee(node), d1=is_mut(0/1), d2=0
// NK_TYPE_PTR:      d0=pointee(node), d1=is_mut(0/1), d2=0
// NK_TYPE_FN:       d0=extra_start, d1=param_count, d2=return_type(node)
// NK_TYPE_TUPLE:    d0=extra_start, d1=elem_count, d2=0
// NK_TYPE_OPTIONAL: d0=inner(node), d1=0, d2=0
// NK_TYPE_ARRAY:    d0=element(node), d1=size_low, d2=size_high
// NK_TYPE_SLICE:    d0=element(node), d1=0, d2=0
// NK_TYPE_TRAIT_OBJ: d0=sym, d1=0, d2=0
// NK_TYPE_INFERRED: d0=0, d1=0, d2=0
//
// Pattern nodes:
// NK_PAT_WILDCARD:  d0=0, d1=0, d2=0
// NK_PAT_IDENT:     d0=sym, d1=0, d2=0
// NK_PAT_INT:       d0=value_low, d1=value_high, d2=0
// NK_PAT_BOOL:      d0=value(0/1), d1=0, d2=0
// NK_PAT_STRING:    d0=sym, d1=0, d2=0
// NK_PAT_VARIANT:   d0=name(sym), d1=extra_start, d2=binding_count
// NK_PAT_TUPLE:     d0=extra_start, d1=elem_count, d2=0
// NK_PAT_STRUCT:    d0=type_name(sym,0=none), d1=extra_start, d2=field_count
//                   extra: [has_rest(0/1), [field_name, field_pattern(node,0=shorthand)]...]
// NK_PAT_RANGE:     d0=start_low, d1=end_low, d2=inclusive(0/1)
// NK_PAT_OR:        d0=extra_start, d1=pattern_count, d2=0
// NK_PAT_AT_BINDING: d0=name(sym), d1=pattern(node), d2=0
// NK_PAT_SLICE:     d0=extra_start, d1=head_count, d2=rest(sym,0=none)
//                   extra: [has_rest(0/1), head_syms..., tail_count, tail_syms...]
// NK_PAT_TYPED_BIND:  d0=binding(sym), d1=type(sym), d2=0
// NK_PAT_ENUM_SHORTHAND: d0=name(sym), d1=extra_start, d2=binding_count
