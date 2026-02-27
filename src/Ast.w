// Ast — AST node types for the With language.
//
// The AST is produced by the parser and consumed by later passes
// (sema, mir lowering, codegen). Nodes are stored in an AstPool
// using index-based references (i32 handles) instead of pointers.
// This follows the Zig reference compiler's SoA approach.

use Span
use Token

// ── Node kinds (integer constants) ────────────────────────────────

// Declarations
fn NK_FN_DECL() -> i32: 1
fn NK_TYPE_DECL() -> i32: 2
fn NK_USE_DECL() -> i32: 3
fn NK_LET_DECL() -> i32: 4
fn NK_EXTERN_FN() -> i32: 5
fn NK_C_IMPORT() -> i32: 6
fn NK_TRAIT_DECL() -> i32: 7
fn NK_IMPL_DECL() -> i32: 8
fn NK_POISONED_DECL() -> i32: 9

// Expressions
fn NK_INT_LIT() -> i32: 20
fn NK_FLOAT_LIT() -> i32: 21
fn NK_STRING_LIT() -> i32: 22
fn NK_BOOL_LIT() -> i32: 23
fn NK_IDENT() -> i32: 24
fn NK_BINARY() -> i32: 25
fn NK_UNARY() -> i32: 26
fn NK_CALL() -> i32: 27
fn NK_FIELD_ACCESS() -> i32: 28
fn NK_INDEX() -> i32: 29
fn NK_BLOCK() -> i32: 30
fn NK_IF_EXPR() -> i32: 31
fn NK_RETURN() -> i32: 32
fn NK_LET_BINDING() -> i32: 33
fn NK_ASSIGN() -> i32: 34
fn NK_WHILE() -> i32: 35
fn NK_LOOP() -> i32: 36
fn NK_FOR() -> i32: 37
fn NK_BREAK() -> i32: 38
fn NK_CONTINUE() -> i32: 39
fn NK_MATCH() -> i32: 40
fn NK_TUPLE() -> i32: 41
fn NK_ARRAY_LIT() -> i32: 42
fn NK_STRUCT_LIT() -> i32: 43
fn NK_CLOSURE() -> i32: 44
fn NK_CAST() -> i32: 45
fn NK_DEFER() -> i32: 46
fn NK_PIPELINE() -> i32: 47
fn NK_RANGE() -> i32: 48
fn NK_GROUPED() -> i32: 49
fn NK_C_STRING_LIT() -> i32: 50
fn NK_VARIANT_SHORTHAND() -> i32: 51
fn NK_WITH_EXPR() -> i32: 52
fn NK_RECORD_UPDATE() -> i32: 53
fn NK_ENUM_VARIANT() -> i32: 54
fn NK_SLICE() -> i32: 55
fn NK_OPTIONAL_CHAIN() -> i32: 56
fn NK_AWAIT() -> i32: 57
fn NK_ASYNC_BLOCK() -> i32: 58
fn NK_SPAWN() -> i32: 59
fn NK_YIELD() -> i32: 60
fn NK_COMPTIME() -> i32: 61
fn NK_LET_ELSE() -> i32: 62
fn NK_TUPLE_DESTRUCTURE() -> i32: 63
fn NK_POISONED_EXPR() -> i32: 69

// Type expressions
fn NK_TYPE_NAMED() -> i32: 80
fn NK_TYPE_GENERIC() -> i32: 81
fn NK_TYPE_REF() -> i32: 82
fn NK_TYPE_PTR() -> i32: 83
fn NK_TYPE_FN() -> i32: 84
fn NK_TYPE_TUPLE() -> i32: 85
fn NK_TYPE_OPTIONAL() -> i32: 86
fn NK_TYPE_ARRAY() -> i32: 87
fn NK_TYPE_SLICE() -> i32: 88
fn NK_TYPE_TRAIT_OBJ() -> i32: 89
fn NK_TYPE_INFERRED() -> i32: 90

// Patterns (for match arms)
fn NK_PAT_WILDCARD() -> i32: 100
fn NK_PAT_IDENT() -> i32: 101
fn NK_PAT_INT() -> i32: 102
fn NK_PAT_BOOL() -> i32: 103
fn NK_PAT_STRING() -> i32: 104
fn NK_PAT_VARIANT() -> i32: 105
fn NK_PAT_TUPLE() -> i32: 106
fn NK_PAT_STRUCT() -> i32: 107
fn NK_PAT_RANGE() -> i32: 108
fn NK_PAT_OR() -> i32: 109
fn NK_PAT_ENUM_SHORTHAND() -> i32: 111

// Match arm
fn NK_MATCH_ARM() -> i32: 110

// Type decl sub-kinds (stored in flags field bits 1-2)
fn TDK_ALIAS() -> i32: 0
fn TDK_STRUCT() -> i32: 1
fn TDK_ENUM() -> i32: 2
fn TDK_DISTINCT() -> i32: 3

// Fn decl flag bits
fn FN_FLAG_PUB() -> i32: 1
fn FN_FLAG_ASYNC() -> i32: 2
fn FN_FLAG_GEN() -> i32: 4
fn FN_FLAG_COMPTIME() -> i32: 8
fn FN_FLAG_TAILREC() -> i32: 16
fn FN_FLAG_MUST_USE() -> i32: 32
fn FN_FLAG_VARIADIC() -> i32: 64

// Binary operators
fn OP_ADD() -> i32: 0
fn OP_SUB() -> i32: 1
fn OP_MUL() -> i32: 2
fn OP_DIV() -> i32: 3
fn OP_MOD() -> i32: 4
fn OP_EQ() -> i32: 5
fn OP_NEQ() -> i32: 6
fn OP_LT() -> i32: 7
fn OP_GT() -> i32: 8
fn OP_LTE() -> i32: 9
fn OP_GTE() -> i32: 10
fn OP_AND() -> i32: 11
fn OP_OR() -> i32: 12
fn OP_BIT_AND() -> i32: 13
fn OP_BIT_OR() -> i32: 14
fn OP_BIT_XOR() -> i32: 15
fn OP_SHL() -> i32: 16
fn OP_SHR() -> i32: 17
fn OP_DEFAULT() -> i32: 18
fn OP_CONCAT() -> i32: 19

// Unary operators
fn UOP_NEGATE() -> i32: 0
fn UOP_NOT() -> i32: 1
fn UOP_REF() -> i32: 2
fn UOP_MUT_REF() -> i32: 3
fn UOP_DEREF() -> i32: 4
fn UOP_TRY() -> i32: 5

// ── AST Pool ──────────────────────────────────────────────────────

// The AstPool stores all AST nodes. Each node has:
// - A kind tag (NK_*)
// - Start/end span positions
// - Up to 3 integer data fields (meaning depends on kind)
// - An optional extra data index for variable-length data

type AstPool = {
    // Core node data (parallel arrays, one entry per node)
    kinds: Vec[i32],
    starts: Vec[i32],
    ends: Vec[i32],
    data0: Vec[i32],   // primary data (e.g. symbol id, operator, lhs index)
    data1: Vec[i32],   // secondary data (e.g. rhs index, type index)
    data2: Vec[i32],   // tertiary data (e.g. body index, flags)

    // Extra data for variable-length lists (params, fields, arms, etc.)
    extra: Vec[i32],

    // Top-level declaration indices
    decls: Vec[i32],

    // String table for source text slices
    strings: Vec[str],
}

fn AstPool.new() -> AstPool:
    AstPool {
        kinds: Vec.new(),
        starts: Vec.new(),
        ends: Vec.new(),
        data0: Vec.new(),
        data1: Vec.new(),
        data2: Vec.new(),
        extra: Vec.new(),
        decls: Vec.new(),
        strings: Vec.new(),
    }

// Add a node to the pool, returns the node index.
fn AstPool.add_node(self: *mut AstPool, kind: i32, start: i32, end: i32, d0: i32, d1: i32, d2: i32) -> i32:
    let idx = self.kinds.len() as i32
    self.kinds.push(kind)
    self.starts.push(start)
    self.ends.push(end)
    self.data0.push(d0)
    self.data1.push(d1)
    self.data2.push(d2)
    idx

// Add extra data, returns the start index in the extra array.
fn AstPool.add_extra(self: *mut AstPool, value: i32) -> i32:
    let idx = self.extra.len() as i32
    self.extra.push(value)
    idx

// Add a string to the string table, returns the string index.
fn AstPool.add_string(self: *mut AstPool, s: str) -> i32:
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

fn AstPool.add_decl(self: *mut AstPool, node_idx: i32) -> void:
    self.decls.push(node_idx)

fn AstPool.decl_count(self: AstPool) -> i32:
    self.decls.len() as i32

fn AstPool.get_decl(self: AstPool, idx: i32) -> i32:
    self.decls.get(idx as i64)

fn AstPool.extra_len(self: AstPool) -> i32:
    self.extra.len() as i32
