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
fn NK_FN_DECL -> i32: 1
fn NK_TYPE_DECL -> i32: 2
fn NK_USE_DECL -> i32: 3
fn NK_LET_DECL -> i32: 4
fn NK_EXTERN_FN -> i32: 5
fn NK_C_IMPORT -> i32: 6
fn NK_TRAIT_DECL -> i32: 7
fn NK_IMPL_DECL -> i32: 8
fn NK_POISONED_DECL -> i32: 9

// Expressions
fn NK_INT_LIT -> i32: 20
fn NK_FLOAT_LIT -> i32: 21
fn NK_STRING_LIT -> i32: 22
fn NK_BOOL_LIT -> i32: 23
fn NK_IDENT -> i32: 24
fn NK_BINARY -> i32: 25
fn NK_UNARY -> i32: 26
fn NK_CALL -> i32: 27
fn NK_FIELD_ACCESS -> i32: 28
fn NK_INDEX -> i32: 29
fn NK_BLOCK -> i32: 30
fn NK_IF_EXPR -> i32: 31
fn NK_RETURN -> i32: 32
fn NK_LET_BINDING -> i32: 33
fn NK_ASSIGN -> i32: 34
fn NK_WHILE -> i32: 35
fn NK_LOOP -> i32: 36
fn NK_FOR -> i32: 37
fn NK_BREAK -> i32: 38
fn NK_CONTINUE -> i32: 39
fn NK_MATCH -> i32: 40
fn NK_TUPLE -> i32: 41
fn NK_ARRAY_LIT -> i32: 42
fn NK_STRUCT_LIT -> i32: 43
fn NK_CLOSURE -> i32: 44
fn NK_CAST -> i32: 45
fn NK_DEFER -> i32: 46
fn NK_PIPELINE -> i32: 47
fn NK_RANGE -> i32: 48
fn NK_GROUPED -> i32: 49
fn NK_C_STRING_LIT -> i32: 50
fn NK_VARIANT_SHORTHAND -> i32: 51
fn NK_WITH_EXPR -> i32: 52
fn NK_RECORD_UPDATE -> i32: 53
fn NK_ENUM_VARIANT -> i32: 54
fn NK_SLICE -> i32: 55
fn NK_OPTIONAL_CHAIN -> i32: 56
fn NK_AWAIT -> i32: 57
fn NK_ASYNC_BLOCK -> i32: 58
fn NK_SPAWN -> i32: 59
fn NK_YIELD -> i32: 60
fn NK_COMPTIME -> i32: 61
fn NK_LET_ELSE -> i32: 62
fn NK_TUPLE_DESTRUCTURE -> i32: 63
fn NK_ARRAY_COMPREHENSION -> i32: 64
fn NK_ASYNC_SCOPE -> i32: 65
fn NK_SELECT_AWAIT -> i32: 66
fn NK_POISONED_EXPR -> i32: 69

// Type expressions
fn NK_TYPE_NAMED -> i32: 80
fn NK_TYPE_GENERIC -> i32: 81
fn NK_TYPE_REF -> i32: 82
fn NK_TYPE_PTR -> i32: 83
fn NK_TYPE_FN -> i32: 84
fn NK_TYPE_TUPLE -> i32: 85
fn NK_TYPE_OPTIONAL -> i32: 86
fn NK_TYPE_ARRAY -> i32: 87
fn NK_TYPE_SLICE -> i32: 88
fn NK_TYPE_TRAIT_OBJ -> i32: 89
fn NK_TYPE_INFERRED -> i32: 90

// Patterns (for match arms)
fn NK_PAT_WILDCARD -> i32: 100
fn NK_PAT_IDENT -> i32: 101
fn NK_PAT_INT -> i32: 102
fn NK_PAT_BOOL -> i32: 103
fn NK_PAT_STRING -> i32: 104
fn NK_PAT_VARIANT -> i32: 105
fn NK_PAT_TUPLE -> i32: 106
fn NK_PAT_STRUCT -> i32: 107
fn NK_PAT_RANGE -> i32: 108
fn NK_PAT_OR -> i32: 109
fn NK_PAT_ENUM_SHORTHAND -> i32: 111
fn NK_PAT_AT_BINDING -> i32: 112
fn NK_PAT_SLICE -> i32: 113

// Match arm
fn NK_MATCH_ARM -> i32: 110

// Type decl sub-kinds (stored in data2 field)
fn TDK_ALIAS -> i32: 0
fn TDK_STRUCT -> i32: 1
fn TDK_ENUM -> i32: 2
fn TDK_DISTINCT -> i32: 3

// Fn decl flag bits (stored in data2 field)
fn FN_FLAG_PUB -> i32: 1
fn FN_FLAG_ASYNC -> i32: 2
fn FN_FLAG_GEN -> i32: 4
fn FN_FLAG_COMPTIME -> i32: 8
fn FN_FLAG_TAILREC -> i32: 16
fn FN_FLAG_MUST_USE -> i32: 32
fn FN_FLAG_VARIADIC -> i32: 64
fn FN_FLAG_INLINE -> i32: 128
fn FN_FLAG_NOINLINE -> i32: 256
fn FN_FLAG_PANIC_HANDLER -> i32: 512
fn FN_FLAG_ENTRY -> i32: 1024
fn FN_FLAG_NO_MAIN -> i32: 2048
fn FN_FLAG_TEST -> i32: 4096
fn FN_FLAG_BEFORE -> i32: 8192
fn FN_FLAG_AFTER -> i32: 16384

// Visibility flags
fn VIS_PRIVATE -> i32: 0
fn VIS_PUBLIC -> i32: 1

// Binary operators
fn OP_ADD -> i32: 0
fn OP_SUB -> i32: 1
fn OP_MUL -> i32: 2
fn OP_DIV -> i32: 3
fn OP_MOD -> i32: 4
fn OP_EQ -> i32: 5
fn OP_NEQ -> i32: 6
fn OP_LT -> i32: 7
fn OP_GT -> i32: 8
fn OP_LTE -> i32: 9
fn OP_GTE -> i32: 10
fn OP_AND -> i32: 11
fn OP_OR -> i32: 12
fn OP_BIT_AND -> i32: 13
fn OP_BIT_OR -> i32: 14
fn OP_BIT_XOR -> i32: 15
fn OP_SHL -> i32: 16
fn OP_SHR -> i32: 17
fn OP_DEFAULT -> i32: 18
fn OP_CONCAT -> i32: 19
fn OP_ADD_WRAP -> i32: 20
fn OP_SUB_WRAP -> i32: 21
fn OP_MUL_WRAP -> i32: 22
fn OP_IN -> i32: 23
fn OP_NOT_IN -> i32: 24

// Unary operators
fn UOP_NEGATE -> i32: 0
fn UOP_NOT -> i32: 1
fn UOP_REF -> i32: 2
fn UOP_MUT_REF -> i32: 3
fn UOP_DEREF -> i32: 4
fn UOP_TRY -> i32: 5

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

    // String table for source text slices
    strings: Vec[str],

    // Auxiliary fn decl metadata: [node, flags, ret_type, param_start, param_count, tp_start, tp_count]*
    // Each fn decl stores 7 ints. Used by Sema to access param info.
    fn_meta: Vec[i32],
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
        strings: Vec.new(),
        fn_meta: Vec.new(),
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
fn AstPool.add_node(self: AstPool, kind: i32, start: i32, end: i32, d0: i32, d1: i32, d2: i32) -> i32:
    let idx = self.kinds.len() as i32
    self.kinds.push(kind)
    self.starts.push(start)
    self.ends.push(end)
    self.data0.push(d0)
    self.data1.push(d1)
    self.data2.push(d2)
    idx

// Add extra data, returns the index in the extra array.
fn AstPool.add_extra(self: AstPool, value: i32) -> i32:
    let idx = self.extra.len() as i32
    self.extra.push(value)
    idx

// Add a string to the string table, returns the string index.
fn AstPool.add_string(self: AstPool, s: str) -> i32:
    let idx = self.strings.len() as i32
    self.strings.push(s)
    idx

// Get node kind at index
fn AstPool.kind(self: AstPool, idx: i32) -> i32:
    self.kinds.get(idx as i64)

// Get node data fields
fn AstPool.get_data0(self: AstPool, idx: i32) -> i32:
    self.data0.get(idx as i64)

fn AstPool.get_data1(self: AstPool, idx: i32) -> i32:
    self.data1.get(idx as i64)

fn AstPool.get_data2(self: AstPool, idx: i32) -> i32:
    self.data2.get(idx as i64)

fn AstPool.get_extra(self: AstPool, idx: i32) -> i32:
    self.extra.get(idx as i64)

fn AstPool.get_string(self: AstPool, idx: i32) -> str:
    self.strings.get(idx as i64)

fn AstPool.get_start(self: AstPool, idx: i32) -> i32:
    self.starts.get(idx as i64)

fn AstPool.get_end(self: AstPool, idx: i32) -> i32:
    self.ends.get(idx as i64)

fn AstPool.node_count(self: AstPool) -> i32:
    self.kinds.len() as i32

fn AstPool.add_decl(self: AstPool, node_idx: i32):
    self.decls.push(node_idx)

fn AstPool.decl_count(self: AstPool) -> i32:
    self.decls.len() as i32

fn AstPool.get_decl(self: AstPool, idx: i32) -> i32:
    self.decls.get(idx as i64)

fn AstPool.extra_len(self: AstPool) -> i32:
    self.extra.len() as i32

fn AstPool.set_data0(self: AstPool, idx: i32, val: i32):
    self.data0.set_i32(idx as i64, val)

fn AstPool.set_data1(self: AstPool, idx: i32, val: i32):
    self.data1.set_i32(idx as i64, val)

fn AstPool.set_data2(self: AstPool, idx: i32, val: i32):
    self.data2.set_i32(idx as i64, val)

// Store fn decl metadata: [node, flags, ret_type, param_start, param_count, tp_start, tp_count]
fn AstPool.add_fn_meta(self: AstPool, node: i32, flags: i32, ret: i32, ps: i32, pc: i32, ts: i32, tc: i32):
    self.fn_meta.push(node)
    self.fn_meta.push(flags)
    self.fn_meta.push(ret)
    self.fn_meta.push(ps)
    self.fn_meta.push(pc)
    self.fn_meta.push(ts)
    self.fn_meta.push(tc)

// Get fn metadata for a given fn decl node. Returns 7-int record start or -1.
fn AstPool.find_fn_meta(self: AstPool, node: i32) -> i32:
    var i = 0
    let len = self.fn_meta.len() as i32
    while i < len:
        if self.fn_meta.get(i as i64) == node:
            return i
        i = i + 7
    0 - 1

fn AstPool.fn_meta_flags(self: AstPool, meta: i32) -> i32:
    self.fn_meta.get((meta + 1) as i64)

fn AstPool.fn_meta_ret(self: AstPool, meta: i32) -> i32:
    self.fn_meta.get((meta + 2) as i64)

fn AstPool.fn_meta_param_start(self: AstPool, meta: i32) -> i32:
    self.fn_meta.get((meta + 3) as i64)

fn AstPool.fn_meta_param_count(self: AstPool, meta: i32) -> i32:
    self.fn_meta.get((meta + 4) as i64)

fn AstPool.fn_meta_tp_start(self: AstPool, meta: i32) -> i32:
    self.fn_meta.get((meta + 5) as i64)

fn AstPool.fn_meta_tp_count(self: AstPool, meta: i32) -> i32:
    self.fn_meta.get((meta + 6) as i64)

// ── Node Data Layout Reference ───────────────────────────────────
//
// NK_FN_DECL:       d0=name(sym), d1=body(node), d2=flags
//                   extra: [return_type(node), param_count, [param_name, param_type]*, type_param_count, [type_param_name, bound_count, bounds...]*]
//
// NK_TYPE_DECL:     d0=name(sym), d1=extra_start, d2=sub_kind(TDK_*)
//                   For struct: extra=[field_count, [field_name, field_type, field_default]*, vis, type_param_count...]
//                   For enum: extra=[variant_count, [var_name, payload_count, payload_type...]*, vis]
//                   For alias: extra=[aliased_type, vis]
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
// NK_PIPELINE:      d0=lhs(node), d1=rhs(node), d2=0
// NK_RANGE:         d0=start(node,0=none), d1=end(node,0=none), d2=inclusive(0/1)
// NK_GROUPED:       d0=inner(node), d1=0, d2=0
// NK_VARIANT_SHORTHAND: d0=name(sym), d1=extra_start, d2=arg_count
// NK_WITH_EXPR:     d0=source(node), d1=body(node), d2=name(sym)
//                   extra: [is_mut(0/1)]
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
// NK_PAT_ENUM_SHORTHAND: d0=name(sym), d1=extra_start, d2=binding_count
