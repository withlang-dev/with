// CCodegen — conservative MIR → C11 emitter used by `with build --emit-c`.
//
// This backend intentionally supports the same conservative MIR subset that
// LLVM MIR codegen currently accepts directly. When MIR contains unsupported
// constructs, emission fails with a clear error.

use Mir
use Ast
use InternPool
use Sema
use render
use compiler.EmbeddedStdlib
use Overflow
use CImport
use std.collections.HashMap
use std.string.StringBuilder
use MathBuiltins
use MirCore
use MirLower
use SemaTypes
use rt.rt_core
use rt.compat_runtime


type COut {
    buf: *mut u8,
}
impl Copy for COut

fn COut.new -> COut:
    COut { buf: with_fmt_buf_new() }

impl COut:
    fn write(text: &str):
        with_fmt_buf_write_str_ref(self.buf, text)

    fn finish() -> str:
        with_fmt_buf_finish(self.buf)

fn cc_intern_resolve(intern: &InternPool, sym: i32) -> str:
    with_str_clone_ref(intern.resolve_symbol(sym))


fn cc_lbrace -> str:
    str_from_byte(123)

fn cc_rbrace -> str:
    str_from_byte(125)

const CC_PSEUDO_TID_LIST = 1900001
const CC_PSEUDO_TID_FMT_BUF = 1900002

enum CcPlaceKind: i32:
    UNKNOWN
    LIST
    HASHMAP
    OPTION

// Copy: these C-backend tag enums are lightweight values passed by value,
// cached in HashMaps, and compared throughout codegen.
impl Copy for CcPlaceKind

enum CcBuiltin: i32:
    NONE
    LIST_NEW
    LIST_PUSH
    LIST_GET
    LIST_LEN
    LIST_IS_EMPTY

    LIST_REMOVE
    LIST_CLEAR
    LIST_MAKE_UNIQUE
    MAP_MAKE_UNIQUE
    MAP_NEW
    MAP_INSERT
    MAP_GET
    MAP_CONTAINS
    MAP_LEN
    MAP_REMOVE
    OPT_IS_SOME
    OPT_UNWRAP
    OPT_EXPECT
    LIST_POP
    LIST_CONCAT
    LIST_EXTEND
    LIST_TAKE_FRONT
    LIST_RESTORE_FRONT
    STR_LEN
    STR_BYTE_AT
    STR_SLICE
    STR_CONTAINS
    STR_CONTAINS_CHAR
    STR_STARTS_WITH
    STR_ENDS_WITH
    STR_FIND
    MAP_CLEAR
    OPT_IS_NONE
    STR_SPLIT
    STR_TO_UPPER
    STR_TO_LOWER
    STR_REPLACE
    STR_INDEX_OF
    MAP_INCREMENT
    MAP_DECREMENT
    MAP_UPDATE
    MAP_SLOT_WALK
    LIST_CONTAINS
    STR_REPEAT
    ARR_LEN
    GENERIC_CALL
    LIST_JOIN
    DYN_VTABLE_CMP
    DYN_DOWNCAST
    OPT_FILTER
    ROTATE_LEFT
    ROTATE_RIGHT
    LIST_WITH_CAPACITY
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
    LIST_SLOT
    VECSLOT_GET
    VECSLOT_SET
    FMT_BUF_NEW
    FMT_BUF_WRITE_STR
    FMT_BUF_WRITE_FMT
    FMT_BUF_FINISH
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
    LIST_GET_DISJOINT
    DYN_CALL
    SLOTMAP
    MULTI_INDEX
    LIST_LEN32
    LIST_LEN64
    LIST_ULEN32
    MAP_LEN32
    MAP_LEN64
    MAP_ULEN32
    STR_LEN32
    STR_LEN64
    STR_ULEN32
    ARR_LEN32
    ARR_LEN64
    ARR_ULEN32
    VECRANGE
    FMT_BUF_WRITE_STR_REF
    STR_CLONE_REF
    CLOSURE_CLONE
    MATH_FN
    VA_START
    VA_ARG
    VA_END
    FIBER_IS_CANCELLED
    FIBER_WAIT_CANCELLED
    FIBER_SET_CANCELLED_RETURN
    FIBER_WAS_CANCELLED_RETURN

impl Copy for CcBuiltin

fn cc_builtin_uses_list_receiver(kind: CcBuiltin) -> bool:
    if kind == CcBuiltin.LIST_PUSH: return true
    if kind == CcBuiltin.LIST_GET: return true
    if kind == CcBuiltin.LIST_LEN: return true
    if kind == CcBuiltin.LIST_IS_EMPTY: return true
    if kind == CcBuiltin.LIST_LEN32: return true
    if kind == CcBuiltin.LIST_LEN64: return true
    if kind == CcBuiltin.LIST_ULEN32: return true
    if kind == CcBuiltin.LIST_REMOVE: return true
    if kind == CcBuiltin.LIST_CLEAR: return true
    if kind == CcBuiltin.LIST_MAKE_UNIQUE: return true
    if kind == CcBuiltin.MAP_MAKE_UNIQUE: return true
    if kind == CcBuiltin.LIST_POP: return true
    if kind == CcBuiltin.LIST_EXTEND: return true
    if kind == CcBuiltin.LIST_TAKE_FRONT: return true
    if kind == CcBuiltin.LIST_RESTORE_FRONT: return true
    if kind == CcBuiltin.LIST_CONTAINS: return true
    if kind == CcBuiltin.LIST_JOIN: return true
    if kind == CcBuiltin.LIST_SLOT: return true
    if kind == CcBuiltin.LIST_GET_DISJOINT: return true
    false

fn cc_builtin_uses_option_receiver(kind: CcBuiltin) -> bool:
    if kind == CcBuiltin.OPT_IS_SOME: return true
    if kind == CcBuiltin.OPT_IS_NONE: return true
    if kind == CcBuiltin.OPT_UNWRAP: return true
    if kind == CcBuiltin.OPT_EXPECT: return true
    if kind == CcBuiltin.OPT_FILTER: return true
    false

enum CcCalleeHint: i32:
    NONE
    LIST_RECV
    MAP_RECV
    OPT_RECV
    LIST_NEW
    MAP_NEW
    OPT_NEW

impl Copy for CcCalleeHint

enum CcLenMode: i32:
    USIZE
    I32
    I64
    U32

impl Copy for CcLenMode

fn cc_is_len_method(method: &str) -> bool:
    method == "len" or method == "len32" or method == "len64" or method == "ulen32"

fn cc_len_method_builtin(base: CcBuiltin, method: &str) -> CcBuiltin:
    if method == "len":
        return base
    if method == "len32":
        if base == CcBuiltin.LIST_LEN: return CcBuiltin.LIST_LEN32
        if base == CcBuiltin.MAP_LEN: return CcBuiltin.MAP_LEN32
        if base == CcBuiltin.STR_LEN: return CcBuiltin.STR_LEN32
        if base == CcBuiltin.ARR_LEN: return CcBuiltin.ARR_LEN32
    if method == "len64":
        if base == CcBuiltin.LIST_LEN: return CcBuiltin.LIST_LEN64
        if base == CcBuiltin.MAP_LEN: return CcBuiltin.MAP_LEN64
        if base == CcBuiltin.STR_LEN: return CcBuiltin.STR_LEN64
        if base == CcBuiltin.ARR_LEN: return CcBuiltin.ARR_LEN64
    if method == "ulen32":
        if base == CcBuiltin.LIST_LEN: return CcBuiltin.LIST_ULEN32
        if base == CcBuiltin.MAP_LEN: return CcBuiltin.MAP_ULEN32
        if base == CcBuiltin.STR_LEN: return CcBuiltin.STR_ULEN32
        if base == CcBuiltin.ARR_LEN: return CcBuiltin.ARR_ULEN32
    CcBuiltin.NONE

fn cc_builtin_len_mode(kind: CcBuiltin) -> CcLenMode:
    if kind == CcBuiltin.LIST_LEN32 or kind == CcBuiltin.MAP_LEN32 or kind == CcBuiltin.STR_LEN32 or kind == CcBuiltin.ARR_LEN32:
        return CcLenMode.I32
    if kind == CcBuiltin.LIST_LEN64 or kind == CcBuiltin.MAP_LEN64 or kind == CcBuiltin.STR_LEN64 or kind == CcBuiltin.ARR_LEN64:
        return CcLenMode.I64
    if kind == CcBuiltin.LIST_ULEN32 or kind == CcBuiltin.MAP_ULEN32 or kind == CcBuiltin.STR_ULEN32 or kind == CcBuiltin.ARR_ULEN32:
        return CcLenMode.U32
    CcLenMode.USIZE

fn cc_len_result_c_type(mode: CcLenMode) -> str:
    if mode == CcLenMode.I32:
        return "int32_t"
    if mode == CcLenMode.I64:
        return "int64_t"
    if mode == CcLenMode.U32:
        return "uint32_t"
    "uint64_t"

fn cc_builtin_is_map_len(kind: CcBuiltin) -> bool:
    kind == CcBuiltin.MAP_LEN or kind == CcBuiltin.MAP_LEN32 or kind == CcBuiltin.MAP_LEN64 or kind == CcBuiltin.MAP_ULEN32

fn cc_builtin_is_list_len(kind: CcBuiltin) -> bool:
    kind == CcBuiltin.LIST_LEN or kind == CcBuiltin.LIST_LEN32 or kind == CcBuiltin.LIST_LEN64 or kind == CcBuiltin.LIST_ULEN32

fn cc_builtin_is_str_len(kind: CcBuiltin) -> bool:
    kind == CcBuiltin.STR_LEN or kind == CcBuiltin.STR_LEN32 or kind == CcBuiltin.STR_LEN64 or kind == CcBuiltin.STR_ULEN32

fn cc_builtin_is_arr_len(kind: CcBuiltin) -> bool:
    kind == CcBuiltin.ARR_LEN or kind == CcBuiltin.ARR_LEN32 or kind == CcBuiltin.ARR_LEN64 or kind == CcBuiltin.ARR_ULEN32

type CEmitResult {
    ok: i32,
    source: str,
    err_msg: str,
}

type CCodegen {
    mir_mod: MirModule,
    ast: AstPool,
    intern: InternPool,
    sema: Sema,
    overflow_mode: i32,
    had_error: i32,
    err_msg: str,
    source_path: str,
    source_text: str,
    // The file the current body's declaration was parsed from (AstPool.file):
    // its statement spans are byte offsets into that file, not the root.
    // -1 when the body has no declaration node — no #line is emitted then.
    line_file_id: i32,
    line_file_path: str,
    last_line_directive: i32,
    body_fn_map: HashMap[i32, i32],
    body_fn_name_map: HashMap[str, i32],
    canonical_body_cache: HashMap[i32, i32],
    // Receiver ABI decisions happen at every call, declaration, and place
    // reference. Keep parameter-shape lookups cached; the uncached path
    // resolves through Sema signatures at every generated call site.
    fn_pointer_param_cache: HashMap[i64, i32],
    sig_idx_cache: HashMap[i32, i32],
    infer_local_depth: i32,
    active_local_body_fns: List[i32],
    active_local_ids: List[i32],
    active_method_syms: List[i32],
    active_method_args: List[i32],
    active_method_dests: List[i32],
    active_direct_args: List[i32],
    active_direct_dests: List[i32],
    call_infer_cache: HashMap[str, i32],
    field_cache_struct_tids: List[i32],
    field_cache_syms: List[i32],
    field_cache_tids: List[i32],
    field_cache_ready: i32,
    in_field_cache_build: i32,
    local_infer_cache: HashMap[i64, i32],
    local_usage_hint_cache: HashMap[i64, i32],
    local_call_ret_cache: HashMap[i64, i32],
    local_copied_payload_cache: HashMap[i64, i32],
    local_downcast_option_cache: HashMap[i64, i32],
    local_effective_cache: HashMap[i64, i32],
    local_ref_target_cache: HashMap[i64, i32],
    // Write every function and global, reached or not (--emit-all).
    emit_all: bool,
    // Each local's direct assignments, in block and statement order: CSR
    // over the body `assign_index_sym` (ensure_assign_index).
    assign_index_sym: i32,
    assign_index_len: isize,
    assign_starts: List[i32],
    assign_stmts: List[i32],
    local_value_use_cache: HashMap[i64, i32],
    place_kind_cache: HashMap[i64, i32],
    callee_hint_cache: HashMap[i32, i32],
    // With fn values are fat pairs {fn_ptr(ctx, ...), ctx} matching native
    // codegen's closure convention. Materializing a named function into a fn
    // value registers a static C thunk here; definitions are emitted between
    // the prototypes and the function bodies, in first-use order so emission
    // stays deterministic.
    fat_thunk_syms: List[i32],
    fat_thunk_tids: List[i32],
    fat_thunk_keys: HashMap[i64, i32],
    // Set by resolve_call_named_callee when the callee resolved to an
    // observing `_ref` str-builtin runtime fn (unqualified_builtin_method_name):
    // emit_term then passes each str-ish operand as the `&str` view the
    // runtime takes, the str's own {ptr, len} (#1810).
    callee_is_str_builtin_ref: i32,
    // #1484: globals initialized before `main` (prepare_global_init_bodies):
    // each global's symbol, its declaration index (the order they run in,
    // §9.1c) and its synthesized initializer body's function symbol.
    global_init_syms: List[i32],
    global_init_decl_indices: List[i32],
    global_init_fn_syms: List[i32],
    // §16.3c, D47: the C strings a call lends its `const char *` parameters
    // (call_args_text): each a `with_cstr_lend` of a str or `&str` view,
    // held in a temp for the call and released after it (emit_term).
    call_lends: List[str],
    // #1766: every closure of the module (a CK_CLOSURE constant: an
    // NK_CLOSURE, or the NK_FOR whose body is a Gen[T]'s `each` closure,
    // D69), registered up front in body order so names are deterministic.
    // Closure N is the static C function __with_closure_N(void* ctx, ...)
    // over its retained MIR body (closure_syms[N]); its captures are the
    // body's locals 1..anonymous_capture_count, taken from the creating
    // body (closure_parents[N]) by the mode Sema decided on the node
    // (closure_env_kind): the pair {fn, ctx} is the LLVM backend's, tag
    // bits included (CodegenDispatch.gen_closure, D63).
    closure_syms: List[i32],
    closure_parents: List[i32],
    closure_nodes: List[i32],
    closure_in_loop: List[i32],
    closure_env_kinds: List[i32],
    closure_index_by_sym: HashMap[i32, i32],
    // #983: the per-type drop and copy glue (ensure_glue), prototypes and
    // definitions in creation order, and the bodies of the types' Drop impls.
    glue_done: HashMap[str, i32],
    glue_protos: List[str],
    glue_defs: List[str],
    drop_body_by_owner: HashMap[i32, i32],
    drop_receivers_ready: bool,
    // D111: the holds of the statement being emitted (held_operand_text).
    hold_active: bool,
    hold_pre: str,
    hold_texts: HashMap[i32, str],
    hold_counter: i32,
    // @[link_name("sym")] of each extern fn, by its symbol (extern_link_name).
    extern_link_names: HashMap[i32, str],
}

// #1766: how a closure holds its environment (CodegenDispatch D63 tags).
const CC_CLOSURE_ENV_NONE: i32 = 0      // no captures: ctx is null
const CC_CLOSURE_ENV_BY_PLACE: i32 = 1  // pointers to the creating frame's slots, tag 00
const CC_CLOSURE_ENV_INLINE: i32 = 2    // `move`, every capture Copy, in the word's upper 62 bits, tag 01
const CC_CLOSURE_ENV_CELL: i32 = 3      // `move`, an owned heap cell {drop_fn, clone_fn, env}, tag 10

impl CCodegen:
    fn intern_intern(s: &str) -> i32:
        self.intern.intern(s)

fn c_emit_module(mir_mod: MirModule, ast: &AstPool, intern: &InternPool, sema: Sema, source_path: &str, source_text: &str, overflow_mode: i32, emit_all: bool) -> CEmitResult:
    var cg = CCodegen {
        emit_all,
        mir_mod,
        ast: ast.clone(),
        intern: intern.clone(),
        sema,
        overflow_mode,
        had_error: 0,
        err_msg: "",
        source_path: with_str_clone_ref(source_path),
        source_text: with_str_clone_ref(source_text),
        line_file_id: -1,
        line_file_path: "",
        last_line_directive: 0,
        body_fn_map: HashMap.new(),
        body_fn_name_map: HashMap.new(),
        canonical_body_cache: HashMap.new(),
        fn_pointer_param_cache: HashMap.new(),
        sig_idx_cache: HashMap.new(),
        infer_local_depth: 0,
        active_local_body_fns: List.new(),
        active_local_ids: List.new(),
        active_method_syms: List.new(),
        active_method_args: List.new(),
        active_method_dests: List.new(),
        active_direct_args: List.new(),
        active_direct_dests: List.new(),
        call_infer_cache: HashMap.new(),
        field_cache_struct_tids: List.new(),
        field_cache_syms: List.new(),
        field_cache_tids: List.new(),
        field_cache_ready: 0,
        in_field_cache_build: 0,
        local_infer_cache: HashMap.new(),
        local_usage_hint_cache: HashMap.new(),
        local_call_ret_cache: HashMap.new(),
        local_copied_payload_cache: HashMap.new(),
        local_downcast_option_cache: HashMap.new(),
        local_effective_cache: HashMap.new(),
        local_ref_target_cache: HashMap.new(),
        assign_index_sym: -1,
        assign_index_len: -1,
        assign_starts: List.new(),
        assign_stmts: List.new(),
        local_value_use_cache: HashMap.new(),
        place_kind_cache: HashMap.new(),
        callee_hint_cache: HashMap.new(),
        fat_thunk_syms: List.new(),
        fat_thunk_tids: List.new(),
        fat_thunk_keys: HashMap.new(),
        callee_is_str_builtin_ref: 0,
        global_init_syms: List.new(),
        global_init_decl_indices: List.new(),
        global_init_fn_syms: List.new(),
        call_lends: List.new(),
        closure_syms: List.new(),
        closure_parents: List.new(),
        closure_nodes: List.new(),
        closure_in_loop: List.new(),
        closure_env_kinds: List.new(),
        closure_index_by_sym: HashMap.new(),
        glue_done: HashMap.new(),
        glue_protos: List.new(),
        glue_defs: List.new(),
        drop_body_by_owner: HashMap.new(),
        drop_receivers_ready: false,
        hold_active: false,
        hold_pre: "",
        hold_texts: HashMap.new(),
        hold_counter: 0,
        extern_link_names: HashMap.new(),
    }
    for i in 0..cg.mir_mod.body_fn_syms.len():
        let sym: i32 = cg.mir_mod.body_fn_syms[i]
        cg.body_fn_map.insert(sym, 1)
    let src = cg.emit_module()
    if cg.had_error != 0:
        return CEmitResult { ok: 0, source: "", err_msg: move cg.err_msg }
    CEmitResult { ok: 1, source: src, err_msg: "" }

impl CCodegen:
    mut fn fail(msg: &str):
        if self.had_error != 0:
            return
        self.had_error = 1
        self.err_msg = with_str_clone_ref(msg)

    mut fn check_interrupted() -> i32:
        if with_interrupt_requested() == 0:
            return 0
        self.fail("interrupted by signal")
        1

    // C emission observes bodies owned by the frozen MirModule while
    // mutating unrelated self state (field cache, interrupt flag, emission
    // buffers). A checked `&self.mir_mod.bodies[i]` view pins all of
    // `self`; nothing mutates `mir_mod` during emission, so a raw element
    // handle is sound (same shape as Codegen.mir_body_at). The raw pointer
    // must be copied into a local first: deriving the reference straight
    // from the bodies' buffer still reads a self-rooted place and
    // the view checker pins `self` through it.
    fn mir_body_at(i: i64) -> &MirBody:
        assert(i >= 0 and i < self.mir_mod.bodies.len())
        unsafe { with_vec_get_ptr_es(&raw const self.mir_mod.bodies as *mut u8, i, sizeof[MirBody]()) as &MirBody }

fn cc_is_ident_start(ch: i32) -> i32:
    if ch == 95:
        return 1
    if ch >= 65 and ch <= 90:
        return 1
    if ch >= 97 and ch <= 122:
        return 1
    0

fn cc_is_ident_char(ch: i32) -> i32:
    if ch >= 48 and ch <= 57:
        return 1
    cc_is_ident_start(ch)

fn cc_hex_digit(v: i32) -> str:
    if v >= 0 and v <= 9:
        return f"{v}"
    if v == 10: return "A"
    if v == 11: return "B"
    if v == 12: return "C"
    if v == 13: return "D"
    if v == 14: return "E"
    "F"

fn cc_escape_c_string(text: &str) -> str:
    var out = StringBuilder.with_capacity(text.len())
    for i in 0..text.len():
        let b = text[i]
        if b == 92: // '\'
            out.push_str("\\\\")
            continue
        if b == 34: // '"'
            out.push_str("\\\"")
            continue
        if b == 10:
            out.push_str("\\n")
            continue
        if b == 13:
            out.push_str("\\r")
            continue
        if b == 9:
            out.push_str("\\t")
            continue
        if b >= 32 and b <= 126:
            out.push_str(text.slice(i as i64, (i + 1) as i64))
            continue
        // Octal escapes for non-ASCII bytes: no hex continuation ambiguity.
        // (`b` is the u8 byte; the old byte_at returned bytes > 127 as a
        // negative i32 and needed a +256 fixup here.)
        let ub = b as i32
        let d2 = ub / 64
        let d1 = (ub % 64) / 8
        let d0 = ub % 8
        out.push_byte(92 as u8)
        out.push_byte((48 + d2) as u8)
        out.push_byte((48 + d1) as u8)
        out.push_byte((48 + d0) as u8)
    out.to_str()

fn cc_hex_digit_value(ch: i32) -> i32:
    if ch >= 48 and ch <= 57:
        return ch - 48
    if ch >= 97 and ch <= 102:
        return ch - 87
    if ch >= 65 and ch <= 70:
        return ch - 55
    -1

fn cc_decode_with_string_escapes(text: &str) -> str:
    var out = StringBuilder.with_capacity(text.len())
    var i = 0
    while i < text.len():
        let ch = text[i]
        if ch == 92 and i + 1 < text.len():
            i = i + 1
            let esc = text[i]
            if esc == 120 and i + 2 < text.len():
                let hi = cc_hex_digit_value(text[(i + 1)])
                let lo = cc_hex_digit_value(text[(i + 2)])
                if hi >= 0 and lo >= 0:
                    out.push_byte((hi * 16 + lo) as u8)
                    i = i + 2
                else:
                    out.push_str(text.slice(i as i64, (i + 1) as i64))
            else if esc == 110:
                out.push_byte(10 as u8)
            else if esc == 116:
                out.push_byte(9 as u8)
            else if esc == 114:
                out.push_byte(13 as u8)
            else if esc == 48:
                out.push_byte(0 as u8)
            else if esc == 92:
                out.push_byte(92 as u8)
            else if esc == 34:
                out.push_byte(34 as u8)
            else:
                out.push_str(text.slice(i as i64, (i + 1) as i64))
        else:
            out.push_str(text.slice(i as i64, (i + 1) as i64))
        i = i + 1
    out.to_str()

fn cc_string_literal_payload(raw: &str) -> str:
    if raw.len() >= 5 and raw[0] == 1 and raw[1] == 114 and raw[2] == 97 and raw[3] == 119 and raw[4] == 1:
        return raw.slice(5, raw.len())
    cc_decode_with_string_escapes(raw)

fn cc_hash_name_component(value: i64) -> str:
    if value < 0:
        return "n" ++ f"{0 - value}"
    f"{value}"

fn cc_is_raw_string_token_text(text: &str) -> i32:
    if text.len() < 3:
        return 0
    if text[0] != 114:  // r
        return 0
    var i = 1
    while i < text.len() and text[i] == 35:  // #
        i = i + 1
    let hash_count = i - 1
    if i >= text.len() or text[i] != 34:
        return 0
    let len = text.len()
    if len < i + 2 + hash_count:
        return 0
    let close_quote = len - hash_count - 1
    if close_quote <= i or text[close_quote] != 34:
        return 0
    var hi = 0
    while hi < hash_count:
        if text[(close_quote + 1 + hi)] != 35:
            return 0
        hi = hi + 1
    1

fn cc_is_quoted_string_token_text(text: &str, prefix_len: i32) -> i32:
    let len = text.len()
    if len < prefix_len + 2:
        return 0
    if text[prefix_len] != 34:
        return 0
    if text[(len - 1)] != 34:
        return 0
    var i = prefix_len + 1
    while i < len - 1:
        let ch = text[i]
        if ch == 10 or ch == 13:
            return 0
        if ch == 34:
            var slash_count = 0
            var j = i - 1
            while j >= prefix_len + 1 and text[j] == 92:
                slash_count = slash_count + 1
                j = j - 1
            if slash_count % 2 == 0:
                return 0
        i = i + 1
    1

fn cc_string_token_payload(text: &str) -> str:
    if cc_is_raw_string_token_text(text) != 0:
        var i = 1
        while i < text.len() and text[i] == 35:
            i = i + 1
        if i < text.len() and text[i] == 34:
            let content_start = i + 1
            var end_q = text.len() - 1
            while end_q >= content_start and text[end_q] == 35:
                end_q = end_q - 1
            if end_q >= content_start and text[end_q] == 34:
                return text.slice(content_start as i64, end_q as i64)
    if cc_is_quoted_string_token_text(text, 0) != 0:
        return cc_decode_with_string_escapes(text.slice(1, text.len() as i64 - 1))
    if text.len() >= 3 and text[0] == 102 and cc_is_quoted_string_token_text(text, 1) != 0:
        return cc_decode_with_string_escapes(text.slice(2, text.len() as i64 - 1))
    ""

fn cc_is_string_token_text(text: &str) -> i32:
    if cc_is_raw_string_token_text(text) != 0:
        return 1
    if cc_is_quoted_string_token_text(text, 0) != 0:
        return 1
    if text.len() >= 3 and text[0] == 102 and cc_is_quoted_string_token_text(text, 1) != 0:
        return 1
    0

fn cc_is_c_string_token_text(text: &str) -> i32:
    if text.len() >= 3 and text[0] == 99 and cc_is_quoted_string_token_text(text, 1) != 0:
        return 1
    0

fn cc_c_string_token_payload(text: &str) -> str:
    if cc_is_c_string_token_text(text) != 0:
        return cc_decode_with_string_escapes(text.slice(2, text.len() as i64 - 1))
    ""

impl CCodegen:
    fn string_literal_node_payload(node: i32) -> str:
        self.string_literal_node_payload_from_source(node, self.source_text)

    fn string_literal_node_payload_from_source(node: i32, src_text: &str) -> str:
        let start = self.ast.get_start(node)
        let end = self.ast.get_end(node)
        if start >= 0 and end > start and end <= src_text.len():
            let text = src_text.slice(start as i64, end as i64)
            if cc_is_string_token_text(text) != 0:
                return cc_string_token_payload(text)
        cc_string_literal_payload(cc_intern_resolve(self.intern, self.ast.get_data0(node)))

    fn c_string_literal_node_payload_from_source(node: i32, src_text: &str) -> str:
        var expr = node
        while expr != 0:
            let k = self.ast.kind(expr)
            if k != NodeKind.NK_COMPTIME and k != NodeKind.NK_GROUPED:
                break
            expr = self.ast.get_data0(expr)
        if expr == 0 or self.ast.kind(expr) != NodeKind.NK_C_STRING_LIT:
            return ""
        let start = self.ast.get_start(expr)
        let end = self.ast.get_end(expr)
        if start >= 0 and end > start and end <= src_text.len():
            let text = src_text.slice(start as i64, end as i64)
            if cc_is_c_string_token_text(text) != 0:
                return cc_c_string_token_payload(text)
        cc_string_literal_payload(cc_intern_resolve(self.intern, self.ast.get_data0(expr)))

fn cc_cstr_literal_data_name(text: &str) -> str:
    f"__with_cstr_{cc_hash_name_component(with_str_hash(text) as i64)}_{text.len()}"

fn cc_cstr_literal_view_name(text: &str) -> str:
    f"__with_cstr_view_{cc_hash_name_component(with_str_hash(text) as i64)}_{text.len()}"

fn cc_cstr_literal_bytes_initializer(text: &str) -> str:
    var out = cc_lbrace()
    for i in 0..text.len():
        if i > 0:
            out = out ++ ", "
        let byte = text[i] as i32
        out = out ++ f"{byte}"
    if text.len() > 0:
        out = out ++ ", "
    out ++ "0" ++ cc_rbrace()

fn cc_str_list_contains(values: &List[str], needle: &str) -> bool:
    for i in 0..values.len():
        if values[i] == needle:
            return true
    false

fn cc_push_unique_str(values: List[str], value: &str) -> List[str]:
    if cc_str_list_contains(&values, value):
        return values
    values.push(with_str_clone_ref(value))
    values

fn cc_sanitize_ident(raw: &str) -> str:
    if raw.len() == 0:
        return "sym"
    var out = ""
    for i in 0..raw.len():
        if with_interrupt_requested() != 0:
            return "__with_interrupted"
        let b = raw[i]
        if cc_is_ident_char(b) != 0:
            out = out ++ raw.slice(i as i64, (i + 1) as i64)
        else:
            out = out ++ "_"
    if out.len() == 0:
        return "sym"
    let first = out[0]
    if cc_is_ident_start(first) == 0:
        return "_" ++ out
    out

fn cc_str_ends_with(text: &str, suffix: &str) -> i32:
    if suffix.len() == 0:
        return 1
    if text.len() < suffix.len():
        return 0
    let start = text.len() - suffix.len()
    if text.slice(start as i64, text.len() as i64) == suffix:
        return 1
    0

fn cc_str_starts_with(text: &str, prefix: &str) -> i32:
    if prefix.len() == 0:
        return 1
    if text.len() < prefix.len():
        return 0
    if text.slice(0, prefix.len() as i64) == prefix:
        return 1
    0

fn cc_str_find_last_char(text: &str, ch: i32) -> i32:
    var i = text.len() as i32 - 1
    while i >= 0:
        if text[i] == ch:
            return i
        i = i - 1
    -1

fn cc_owner_prefix(sym_text: &str) -> str:
    let dot = cc_str_find_last_char(sym_text, 46)
    if dot <= 0:
        return ""
    sym_text.slice(0, dot as i64)

fn cc_str_contains_dot(text: &str) -> i32:
    for i in 0..text.len():
        if text[i] == 46:
            return 1
    0

fn cc_str_contains(text: &str, needle: &str) -> i32:
    if needle.len() == 0:
        return 1
    if text.len() < needle.len():
        return 0
    let end = text.len() - needle.len()
    for i in 0..(end + 1):
        if text.slice(i as i64, (i + needle.len()) as i64) == needle:
            return 1
    0

fn cc_rval_looks_address(text: &str) -> i32:
    if text.len() >= 2 and text[0] == 40 and text[1] == 38:
        return 1
    if cc_str_contains(text, "*)") != 0 or cc_str_contains(text, "* const") != 0:
        return 1
    0

fn cc_name_matches(raw: &str, wanted: &str) -> i32:
    if raw == wanted:
        return 1
    cc_str_ends_with(raw, "." ++ wanted)

fn cc_emit_checked_signed_helpers(c_type: &str, suffix: &str, min_expr: &str) -> str:
    var out = ""
    out = out ++ "static inline " ++ c_type ++ " __with_checked_add_" ++ suffix ++ "(" ++ c_type ++ " a, " ++ c_type ++ " b) {\n"
    out = out ++ "    " ++ c_type ++ " r;\n"
    out = out ++ "    if (__builtin_add_overflow(a, b, &r)) __with_arith_overflow_panic();\n"
    out = out ++ "    return r;\n"
    out = out ++ "}\n"
    out = out ++ "static inline " ++ c_type ++ " __with_checked_sub_" ++ suffix ++ "(" ++ c_type ++ " a, " ++ c_type ++ " b) {\n"
    out = out ++ "    " ++ c_type ++ " r;\n"
    out = out ++ "    if (__builtin_sub_overflow(a, b, &r)) __with_arith_overflow_panic();\n"
    out = out ++ "    return r;\n"
    out = out ++ "}\n"
    out = out ++ "static inline " ++ c_type ++ " __with_checked_mul_" ++ suffix ++ "(" ++ c_type ++ " a, " ++ c_type ++ " b) {\n"
    out = out ++ "    " ++ c_type ++ " r;\n"
    out = out ++ "    if (__builtin_mul_overflow(a, b, &r)) __with_arith_overflow_panic();\n"
    out = out ++ "    return r;\n"
    out = out ++ "}\n"
    out = out ++ "static inline " ++ c_type ++ " __with_checked_div_" ++ suffix ++ "(" ++ c_type ++ " a, " ++ c_type ++ " b) {\n"
    out = out ++ "    if (b == (" ++ c_type ++ ")0) __with_div_zero_panic();\n"
    out = out ++ "    if (a == (" ++ c_type ++ ")(" ++ min_expr ++ ") && b == (" ++ c_type ++ ")-1) __with_arith_overflow_panic();\n"
    out = out ++ "    return (" ++ c_type ++ ")(a / b);\n"
    out = out ++ "}\n"
    out = out ++ "static inline " ++ c_type ++ " __with_checked_mod_" ++ suffix ++ "(" ++ c_type ++ " a, " ++ c_type ++ " b) {\n"
    out = out ++ "    if (b == (" ++ c_type ++ ")0) __with_div_zero_panic();\n"
    out = out ++ "    if (a == (" ++ c_type ++ ")(" ++ min_expr ++ ") && b == (" ++ c_type ++ ")-1) __with_arith_overflow_panic();\n"
    out = out ++ "    return (" ++ c_type ++ ")(a % b);\n"
    out = out ++ "}\n"
    out = out ++ "static inline " ++ c_type ++ " __with_checked_neg_" ++ suffix ++ "(" ++ c_type ++ " a) {\n"
    out = out ++ "    " ++ c_type ++ " r;\n"
    out = out ++ "    if (__builtin_sub_overflow((" ++ c_type ++ ")0, a, &r)) __with_arith_overflow_panic();\n"
    out = out ++ "    return r;\n"
    out = out ++ "}\n"
    out

fn cc_emit_checked_unsigned_helpers(c_type: &str, suffix: &str) -> str:
    var out = ""
    out = out ++ "static inline " ++ c_type ++ " __with_checked_add_" ++ suffix ++ "(" ++ c_type ++ " a, " ++ c_type ++ " b) {\n"
    out = out ++ "    " ++ c_type ++ " r;\n"
    out = out ++ "    if (__builtin_add_overflow(a, b, &r)) __with_arith_overflow_panic();\n"
    out = out ++ "    return r;\n"
    out = out ++ "}\n"
    out = out ++ "static inline " ++ c_type ++ " __with_checked_sub_" ++ suffix ++ "(" ++ c_type ++ " a, " ++ c_type ++ " b) {\n"
    out = out ++ "    " ++ c_type ++ " r;\n"
    out = out ++ "    if (__builtin_sub_overflow(a, b, &r)) __with_arith_overflow_panic();\n"
    out = out ++ "    return r;\n"
    out = out ++ "}\n"
    out = out ++ "static inline " ++ c_type ++ " __with_checked_mul_" ++ suffix ++ "(" ++ c_type ++ " a, " ++ c_type ++ " b) {\n"
    out = out ++ "    " ++ c_type ++ " r;\n"
    out = out ++ "    if (__builtin_mul_overflow(a, b, &r)) __with_arith_overflow_panic();\n"
    out = out ++ "    return r;\n"
    out = out ++ "}\n"
    out = out ++ "static inline " ++ c_type ++ " __with_checked_div_" ++ suffix ++ "(" ++ c_type ++ " a, " ++ c_type ++ " b) {\n"
    out = out ++ "    if (b == (" ++ c_type ++ ")0) __with_div_zero_panic();\n"
    out = out ++ "    return (" ++ c_type ++ ")(a / b);\n"
    out = out ++ "}\n"
    out = out ++ "static inline " ++ c_type ++ " __with_checked_mod_" ++ suffix ++ "(" ++ c_type ++ " a, " ++ c_type ++ " b) {\n"
    out = out ++ "    if (b == (" ++ c_type ++ ")0) __with_div_zero_panic();\n"
    out = out ++ "    return (" ++ c_type ++ ")(a % b);\n"
    out = out ++ "}\n"
    out

// D71 (§4.8a): a str range `s[a..b]` is a `&str` view of its bytes —
// `{ptr, len}` by value (#1810) — checked in every build as the LLVM
// backend checks it (CodegenDispatch mir_emit_str_slice_checks): an offset
// past the end panics, and so does one inside a UTF-8 character (a
// `10xxxxxx` byte at the offset).
fn cc_emit_str_range_view_helper -> str:
    var out = "static inline with_str __with_str_range_view(with_str s, int64_t a, int64_t b) {\n"
    out = out ++ "    if (a < 0 || a > b || b > s.len) with_panic(WITH_STR_LIT(\"string slice out of range\"), WITH_STR_LIT(\"\"), 0);\n"
    out = out ++ "    if ((a < s.len && (((uint8_t)s.ptr[a]) & 0xC0) == 0x80) || (b < s.len && (((uint8_t)s.ptr[b]) & 0xC0) == 0x80))\n"
    out = out ++ "        with_panic(WITH_STR_LIT(\"string slice inside a UTF-8 character\"), WITH_STR_LIT(\"\"), 0);\n"
    out = out ++ "    return (with_str){ s.ptr + a, b - a };\n"
    out = out ++ "}\n"
    out

fn cc_emit_checked_arith_helpers -> str:
    var out = ""
    out = out ++ "static inline void __with_arith_overflow_panic(void) {\n"
    out = out ++ "    with_panic(WITH_STR_LIT(\"integer overflow\"), WITH_STR_LIT(\"\"), 0);\n"
    out = out ++ "}\n"
    out = out ++ "static inline void __with_div_zero_panic(void) {\n"
    out = out ++ "    with_panic(WITH_STR_LIT(\"division by zero\"), WITH_STR_LIT(\"\"), 0);\n"
    out = out ++ "}\n"
    out = out ++ "static inline __int128 __with_i128_min_value(void) {\n"
    out = out ++ "    return -(((__int128)1) << 126) - (((__int128)1) << 126);\n"
    out = out ++ "}\n"
    out = out ++ cc_emit_checked_signed_helpers("int8_t", "i8", "INT8_MIN")
    out = out ++ cc_emit_checked_unsigned_helpers("uint8_t", "u8")
    out = out ++ cc_emit_checked_signed_helpers("int16_t", "i16", "INT16_MIN")
    out = out ++ cc_emit_checked_unsigned_helpers("uint16_t", "u16")
    out = out ++ cc_emit_checked_signed_helpers("int32_t", "i32", "INT32_MIN")
    out = out ++ cc_emit_checked_unsigned_helpers("uint32_t", "u32")
    out = out ++ cc_emit_checked_signed_helpers("int64_t", "i64", "INT64_MIN")
    out = out ++ cc_emit_checked_unsigned_helpers("uint64_t", "u64")
    out = out ++ cc_emit_checked_signed_helpers("__int128", "i128", "__with_i128_min_value()")
    out = out ++ cc_emit_checked_unsigned_helpers("unsigned __int128", "u128")
    out ++ "\n"

fn cc_base_name(raw: &str) -> str:
    let dot = cc_str_find_last_char(raw, 46)
    if dot < 0:
        return with_str_clone_ref(raw)
    raw.slice((dot + 1) as i64, raw.len() as i64)

fn cc_is_list_method_name(name: &str) -> i32:
    if name == "new":
        return 1
    if name == "push" or name == "get" or name == "len":
        return 1
    if name == "slot" or name == "remove" or name == "clear" or name == "pop":
        return 1
    0

fn cc_is_hashmap_method_name(name: &str) -> i32:
    if name == "insert" or name == "contains" or name == "remove":
        return 1
    if name == "get" or name == "len" or name == "new":
        return 1
    0

fn cc_is_option_method_name(name: &str) -> i32:
    if name == "is_some" or name == "unwrap" or name == "expect":
        return 1
    0

fn cc_is_public_abi_name(name: &str) -> i32:
    if name.starts_with("with_") or name.starts_with("rt_") or name.starts_with("wl_"):
        return 1
    if name.starts_with("migrate_") or name.starts_with("ci_"):
        return 1
    if name == "pthread_self":
        return 1
    if name == "i32_to_str" or name == "i64_to_string" or name == "str_from_byte":
        return 1
    0

impl CCodegen:
    fn fn_c_name(fn_sym: i32) -> str:
        if fn_sym == 0:
            return "sym0"
        let export_name = self.fn_c_export_name(fn_sym)
        if export_name.len() > 0:
            return cc_sanitize_ident(export_name)
        let raw = cc_intern_resolve(self.intern, fn_sym)
        let id = cc_sanitize_ident(raw)
        if self.fn_decl_is_public(fn_sym) != 0 and cc_is_public_abi_name(id) != 0:
            return id
        if id == "main":
            return f"__with_main__{fn_sym}"
        f"{id}__{fn_sym}"

    // Whether fn_c_name gives `fn_sym` its mangled, program-internal name.
    fn fn_c_name_is_internal(fn_sym: i32) -> bool:
        if fn_sym == 0 or self.fn_c_export_name(fn_sym).len() > 0:
            return false
        let id = cc_sanitize_ident(cc_intern_resolve(self.intern, fn_sym))
        not (self.fn_decl_is_public(fn_sym) != 0 and cc_is_public_abi_name(id) != 0)

    fn global_c_name(sym: i32) -> str:
        if sym == 0:
            return "__with_global_0"
        let decl = self.global_decl_node(sym)
        if decl != 0 as NodeId and self.ast.kind(decl) == NodeKind.NK_EXTERN_VAR:
            let link_sym = self.ast.state.extern_var_link_names.get(decl as i32) ?? 0
            if link_sym != 0: return cc_intern_resolve(self.intern, link_sym)
            return cc_sanitize_ident(cc_intern_resolve(self.intern, sym))
        "__with_global_" ++ cc_sanitize_ident(cc_intern_resolve(self.intern, sym)) ++ f"__{sym}"

    fn extern_sym_c_name(fn_sym: i32) -> str:
        if fn_sym == 0:
            return "sym0"
        let linked = self.extern_link_name(fn_sym)
        if linked.len() > 0:
            return linked
        let raw = cc_intern_resolve(self.intern, fn_sym)
        if raw.len() == 0:
            return "sym0"
        cc_sanitize_ident(self.canonical_extern_name(raw))

    // The C symbol an extern fn's `@[link_name("sym")]` names (the parser
    // keeps it in the fn's calling-convention slot as `link_name:sym`), or
    // "". The emitted C called `ci_unlink` where the program links unlink.
    fn extern_link_name(fn_sym: i32) -> str:
        self.extern_link_names.get(fn_sym) ?? ""

    mut fn prepare_extern_link_names():
        for di in 0..self.ast.decl_count():
            let decl = self.ast.get_decl(di)
            if self.ast.kind(decl) != NodeKind.NK_EXTERN_FN:
                continue
            let cc = self.fn_callconv_name(self.ast.find_fn_meta(decl))
            if cc.starts_with("link_name:"):
                self.extern_link_names.insert(self.ast.get_data0(decl), cc.slice(10, cc.len()))

    fn canonical_extern_name(name: &str) -> str:
        // c_import can suffix C symbols as "name.<n>" to avoid With-side name
        // collisions. The emitted C must still call the original C symbol.
        var dot_pos = -1
        for i in 0..name.len():
            if name[i] == 46:
                dot_pos = i as i32
        if dot_pos > 0 and dot_pos + 1 < name.len():
            var all_digits = true
            var j = dot_pos + 1
            while j < name.len():
                let ch = name[j]
                if ch < 48 or ch > 57:
                    all_digits = false
                    break
                j = j + 1
            if all_digits:
                return name.slice(0, dot_pos as i64)
        with_str_clone_ref(name)

    fn global_decl_node(sym: i32) -> NodeId:
        for di in 0..self.ast.decl_count():
            let decl = self.ast.get_decl(di)
            let dk = self.ast.kind(decl)
            if dk != NodeKind.NK_LET_DECL and dk != NodeKind.NK_EXTERN_VAR:
                continue
            if self.ast.get_data0(decl) == sym:
                return decl
        0 as NodeId

    fn decl_index_for_node(node: NodeId) -> i32:
        for di in 0..self.ast.decl_count():
            if self.ast.get_decl(di) == node:
                return di
        -1

    fn decl_source_path(decl: NodeId) -> str:
        let di = self.decl_index_for_node(decl)
        if di >= 0 and di < self.sema.decl_source_paths.len():
            let path = self.sema.decl_source_paths[di]
            if path.len() > 0:
                return with_str_clone_ref(path)
        self.source_path.clone()

    fn source_text_for_path(path: &str) -> str:
        if path.len() == 0 or path == self.source_path:
            return self.source_text.clone()
        let embedded_rel = embedded_std_rel_path(path)
        if embedded_rel.len() > 0:
            return embedded_std_source(embedded_rel)
        let text = with_fs_read_file(path)
        if text.len() > 0:
            return text
        self.source_text.clone()

    fn decl_source_text(decl: NodeId) -> str:
        self.source_text_for_path(self.decl_source_path(decl))

fn cc_path_with_slashes(path: &str) -> str:
    var out = StringBuilder.with_capacity(path.len())
    for i in 0..path.len():
        let ch = path[i]
        if ch == 92:
            out.push_byte(47 as u8)
        else:
            out.push_byte(ch as u8)
    out.to_str()

fn cc_path_find(text: &str, needle: &str) -> isize:
    if needle.len() == 0 or text.len() < needle.len():
        return -1
    var i = 0
    while i <= text.len() - needle.len():
        var j = 0
        var ok = true
        while j < needle.len():
            if text[(i + j)] != needle[j]:
                ok = false
                break
            j = j + 1
        if ok:
            return i
        i = i + 1
    -1

fn cc_line_directive_path(path: &str) -> str:
    let p = cc_path_with_slashes(path)
    let anchors: List[str] = List.new()
    anchors.push("/out/gen/")
    anchors.push("/src/")
    anchors.push("/lib/")
    anchors.push("/rt/")
    anchors.push("/build/")
    anchors.push("/test/")
    anchors.push("/tests/")
    anchors.push("/runtime/")
    for i in 0..anchors.len():
        let anchor = anchors[i]
        let at = cc_path_find(p, anchor)
        if at >= 0:
            return p.slice((at + 1) as i64, p.len())
    p

impl CCodegen:
    fn fn_decl_node(sym: i32) -> NodeId:
        for di in 0..self.ast.decl_count():
            let decl = self.ast.get_decl(di)
            if self.ast.kind(decl) != NodeKind.NK_FN_DECL:
                continue
            if self.ast.get_data0(decl) == sym:
                return decl
        0 as NodeId

    fn fn_decl_is_public(sym: i32) -> i32:
        let decl = self.fn_decl_node(sym)
        if decl == 0 as NodeId:
            return 0
        let flags = self.ast.get_data2(decl)
        if (flags / FnFlags.PUB) % 2 == 1:
            return 1
        0

    fn fn_callconv_name(meta: i32) -> str:
        if meta < 0:
            return ""
        let cc_sym = self.ast.fn_meta_tp_start(meta)
        if cc_sym == 0:
            return ""
        let cc_name = cc_intern_resolve(self.intern, cc_sym)
        if cc_name.len() >= 2 and cc_name[0] == 34 and cc_name[cc_name.len() - 1] == 34:
            return cc_name.slice(1, cc_name.len() - 1)
        cc_name

    fn fn_c_export_name(fn_sym: i32) -> str:
        let decl = self.fn_decl_node(fn_sym)
        if decl == 0 as NodeId:
            return ""
        let meta = self.ast.find_fn_meta(decl)
        let cc_name = self.fn_callconv_name(meta)
        if cc_name.len() <= 9:
            return ""
        if cc_name.slice(0, 9) != "c_export:":
            return ""
        cc_name.slice(9, cc_name.len())

    // Does this unit DEFINE the C function `name`? A declaration with an
    // interface body (the runtime's interface, D30 step 3) defines nothing:
    // its prototype still comes from the fixed block below or the extern
    // walk, and the C runtime defines it.
    fn module_exports_c_name(name: &str) -> i32:
        for di in 0..self.ast.decl_count():
            let decl = self.ast.get_decl(di)
            if self.ast.kind(decl) != NodeKind.NK_FN_DECL or self.ast.fn_decl_body_is_interface(decl):
                continue
            let sym = self.ast.get_data0(decl)
            if self.fn_c_name(sym) == name:
                return 1
        0

    // A declaration's own type node resolves where it is declared: frozen
    // resolution judges visibility from sema.current_module_path, and the
    // globals of an engine corpus compiled in-unit (std.engines.pcre2's
    // `extern var _pcre2_utf8_table1: *c_int`) name types user code cannot
    // see (#705, #1362).
    mut fn resolve_decl_type_frozen(decl: NodeId, type_node: i32) -> i32:
        let saved = with_str_clone_ref(self.sema.current_module_path)
        self.sema.current_module_path = self.decl_source_path(decl)
        let tid = self.sema.resolve_type_expr_frozen(type_node) as i32
        self.sema.current_module_path = saved
        tid

    // The type a global is emitted with, or 0 after a loud failure. A global
    // whose type cannot be recovered is never declared `int`: an extern var
    // of another C type would read the wrong bytes, and a `let` would store
    // its value truncated (#1429).
    mut fn global_decl_tid(decl: NodeId) -> i32:
        let dk = self.ast.kind(decl)
        if dk != NodeKind.NK_EXTERN_VAR and dk != NodeKind.NK_LET_DECL:
            return 0
        let name = cc_intern_resolve(self.intern, self.ast.get_data0(decl))
        let what = if dk == NodeKind.NK_EXTERN_VAR: "extern var" else: "global"
        var type_node: i32 = 0
        if dk == NodeKind.NK_EXTERN_VAR:
            type_node = self.ast.get_data1(decl)
        else:
            let type_extra_packed = self.ast.get_data2(decl) / 16
            if type_extra_packed > 0:
                type_node = self.ast.get_extra(type_extra_packed - 1)
        if type_node != 0:
            let tid = self.resolve_decl_type_frozen(decl, type_node)
            if tid == 0:
                let spelling = self.type_arg_text(type_node)
                let declaring = self.decl_source_path(decl)
                self.fail(f"emit-c could not resolve the type '{spelling}' of {what} '{name}' (resolved from module '{declaring}')")
            return tid
        let value = self.ast.get_data1(decl)
        if self.sema.typed_expr_types.contains(value):
            return self.sema.typed_expr_types.get(value).unwrap()
        self.fail(f"emit-c has no type for {what} '{name}': it has no annotation and Sema recorded no type for its initializer")
        0

    fn local_global_sym(body: &MirBody, local_id: i32) -> i32:
        if local_id <= 0 or local_id >= body.local_names.len():
            return 0
        let sym = body.local_names[local_id]
        if sym == 0 or body.local_is_global[local_id] == 0:
            return 0
        let decl = self.global_decl_node(sym)
        if decl == 0 as NodeId:
            return 0
        sym

    fn canonical_body_sym(fn_sym: i32) -> i32:
        if fn_sym == 0:
            return 0
        if self.canonical_body_cache.contains(fn_sym):
            return self.canonical_body_cache.get(fn_sym).unwrap()
        var out: i32 = 0
        if self.body_fn_map.contains(fn_sym):
            out = fn_sym
        if out != 0:
            self.canonical_body_cache.insert(fn_sym, out)
            return out
        let raw = cc_intern_resolve(self.intern, fn_sym)
        if raw.len() == 0:
            self.canonical_body_cache.insert(fn_sym, 0)
            return 0
        let by_name = self.lookup_body_sym_by_name(raw)
        if by_name != 0:
            out = by_name
            self.canonical_body_cache.insert(fn_sym, out)
            return out
        self.canonical_body_cache.insert(fn_sym, out)
        out

    fn lookup_body_sym_by_name(name: &str) -> i32:
        if name.len() == 0:
            return 0
        let cached = self.body_fn_name_map.get(name)
        if cached.is_some():
            return cached.unwrap()
        var out: i32 = 0
        for i in 0..self.mir_mod.body_fn_syms.len():
            let sym = self.mir_mod.body_fn_syms[i]
            if cc_intern_resolve(self.intern, sym) == name:
                out = sym
                break
        self.body_fn_name_map.insert(with_str_clone_ref(name), out)
        out

    fn has_body_for_sym(fn_sym: i32) -> i32:
        if self.canonical_body_sym(fn_sym) != 0:
            return 1
        0

    fn body_sig_index(fn_sym: i32) -> i32:
        let direct = self.sema.get_sig(fn_sym)
        if direct >= 0:
            return direct
        self.sig_index_for_sym(fn_sym)

    fn fn_param_is_c_pointer(fn_sym: i32, param_idx: i32) -> i32:
        let cache_key = cc_body_local_cache_key(fn_sym, param_idx)
        let cached = self.fn_pointer_param_cache.get(cache_key)
        if cached.is_some():
            return cached.unwrap()
        let sig_idx = self.sig_index_for_sym(fn_sym)
        var out = if sig_idx >= 0: self.sema.sig_param_uses_value_ref_abi(sig_idx, param_idx) else: 0
        if out == 0 and self.param_is_drop_receiver(fn_sym, param_idx):
            out = 1
        self.fn_pointer_param_cache.insert(cache_key, out)
        out

    fn local_is_c_pointer_param(body: &MirBody, local_id: i32) -> i32:
        if local_id <= 0:
            return 0
        let sig_idx = self.body_sig_index(body.fn_sym)
        let param_count = if sig_idx >= 0: self.sema.sig_get_param_count(sig_idx) else: body.n_params
        if local_id > param_count:
            return 0
        self.fn_param_is_c_pointer(body.fn_sym, local_id - 1)

    fn call_param_expects_c_pointer(body: &MirBody, args_id: i32, callee_operand: i32, param_idx: i32) -> i32:
        if body.call_requires_contract(args_id):
            let sig_idx = body.call_sig_index(args_id)
            if sig_idx >= 0:
                return self.sema.sig_param_uses_value_ref_abi(sig_idx, param_idx)
        let fn_sym = self.call_callee_fn_sym(body, callee_operand)
        self.fn_param_is_c_pointer(fn_sym, param_idx)

    fn is_void_tid(tid: i32) -> i32:
        if tid == 0:
            return 1
        let resolved = self.sema.resolve_alias(tid)
        if resolved == 0:
            return 0
        let kind = self.sema.get_type_kind(resolved)
        if kind == TypeKind.TY_VOID or kind == TypeKind.TY_NEVER:
            return 1
        0

    mut fn struct_c_name(tid: i32) -> str:
        if self.check_interrupted() != 0:
            return "with_interrupted"
        let resolved = self.sema.resolve_alias(tid)
        if self.sema.get_type_kind(resolved) == TypeKind.TY_SLICE:
            let elem_tid = self.sema.resolve_alias(self.sema.get_type_d0(resolved) as TypeId)
            return f"with_slice_{elem_tid as i32}"
        if self.sema.get_type_kind(resolved) == TypeKind.TY_TUPLE:
            return f"with_tuple_{resolved as i32}"
        if self.sema.get_type_kind(resolved) == TypeKind.TY_GENERIC_INST:
            return cc_sanitize_ident(self.sema.type_name(resolved as i32))
        let name_sym = self.sema.get_type_d0(resolved)
        let raw = cc_intern_resolve(self.intern, name_sym)
        if raw.len() == 0:
            return f"with_struct_{resolved as i32}"
        let out = cc_sanitize_ident(raw)
        if self.check_interrupted() != 0:
            return "with_interrupted"
        // A With record std.libc models under a libc name (`rlimit`) is a
        // With type: the included C headers declare their own `struct
        // rlimit`, so the With one is spelled apart from it, as With
        // functions with libc names are.
        if ci_libc_symbol_allowed_as(raw, CI_LIBC_KIND_TYPE):
            return out ++ "__with"
        out

    fn type_is_payload_enum(tid: i32) -> i32:
        let base_tid = self.sema.type_reflection_variant_base(tid)
        if base_tid == 0:
            return 0
        let count = self.sema.type_reflection_variant_count(tid)
        for vi in 0..count:
            if self.sema.type_reflection_variant_payload_count(tid, vi) > 0:
                return 1
        0

    fn type_is_distinct(tid: i32) -> i32:
        let resolved = self.sema.resolve_alias(tid)
        if self.sema.get_type_kind(resolved) != TypeKind.TY_STRUCT:
            return 0
        let name_sym = self.sema.get_type_d0(resolved)
        if name_sym == 0:
            return 0
        if self.sema.distinct_type_names.contains(name_sym):
            return 1
        0

    fn type_is_c_void(tid: i32) -> i32:
        let resolved = self.sema.resolve_alias(tid)
        if resolved == 0:
            return 0
        if self.sema.get_type_kind(resolved) != TypeKind.TY_STRUCT:
            return 0
        let name_sym = self.sema.get_type_d0(resolved)
        if name_sym == 0:
            return 0
        if cc_intern_resolve(self.intern, name_sym) == "c_void":
            return 1
        0

    fn payload_enum_variant_field(variant_index: i32) -> str:
        let _ = self
        f"payload{variant_index}"

    // The member path from an enum value to payload field `field_idx` of
    // `variant_index`: the variant's member itself when it has one field,
    // else that field of the variant's payload struct (#2017).
    fn payload_enum_field_path(enum_tid: i32, variant_index: i32, field_idx: i32) -> str:
        let member = self.enum_payload_member(enum_tid, variant_index)
        if self.sema.type_reflection_variant_payload_count(enum_tid, variant_index) == 1: member else: member ++ "." ++ cc_payload_struct_field(field_idx)

    // with-abi.md §3 (#2036): an Option whose payload is one non-null
    // address (`&T`, `*T`, an extern fn, a std Box) is that nullable
    // pointer: null is None, a live address is Some. TypeLayout owns the
    // fact; this backend only spells it.
    fn option_is_nullable_pointer(tid: i32) -> bool:
        self.sema.type_layout_option_is_nullable(self.sema.resolve_alias(tid as TypeId) as i32)

    // The member naming variant `variant_index`'s payload: none for a
    // nullable-pointer Option, whose value is its payload.
    fn enum_payload_member(enum_tid: i32, variant_index: i32) -> str:
        if self.option_is_nullable_pointer(enum_tid): "" else: "." ++ self.payload_enum_variant_field(variant_index)

    // The discriminant of the enum value `expr`.
    fn enum_tag_text(enum_tid: i32, expr: &str) -> str:
        // An enum with no payloads is its discriminant (an int32_t).
        if self.type_is_payload_enum(enum_tid) == 0:
            return "(" ++ expr ++ ")"
        if not self.option_is_nullable_pointer(enum_tid):
            return "(" ++ expr ++ ").tag"
        let some_disc = self.sema.type_reflection_variant_discriminant(enum_tid, self.payload_enum_named_variant(enum_tid, self.sema.syms.some))
        let none_disc = self.sema.type_reflection_variant_discriminant(enum_tid, self.payload_enum_named_variant(enum_tid, self.sema.syms.none))
        f"((" ++ expr ++ f") != 0 ? {some_disc} : {none_disc})"

    fn payload_enum_named_variant(enum_tid: i32, variant_sym: i32) -> i32:
        if self.type_is_payload_enum(enum_tid) == 0 or variant_sym == 0:
            return -1
        let variant_count = self.sema.type_reflection_variant_count(enum_tid)
        let target = self.sema.pool_resolve(variant_sym)
        for vi in 0..variant_count:
            let name_sym = self.sema.type_reflection_variant_name(enum_tid, vi)
            if name_sym == variant_sym:
                return vi
            if target.len() > 0 and self.sema.pool_resolve(name_sym) == target:
                return vi
        -1

    mut fn payload_enum_variant_for_payload_tid(enum_tid: i32, payload_tid: i32) -> i32:
        if self.type_is_payload_enum(enum_tid) == 0 or payload_tid == 0:
            return -1
        let variant_count = self.sema.type_reflection_variant_count(enum_tid)
        var found: i32 = -1
        for vi in 0..variant_count:
            if self.sema.type_reflection_variant_payload_count(enum_tid, vi) != 1:
                continue
            let candidate = self.sema.type_reflection_variant_payload_type_frozen(enum_tid, vi, 0)
            if candidate == 0:
                continue
            if self.strict_type_match(candidate, payload_tid) != 0:
                if found >= 0:
                    return -1
                found = vi
        found

    fn payload_enum_single_payload_variant(enum_tid: i32) -> i32:
        if self.type_is_payload_enum(enum_tid) == 0:
            return -1
        let variant_count = self.sema.type_reflection_variant_count(enum_tid)
        var found: i32 = -1
        for vi in 0..variant_count:
            if self.sema.type_reflection_variant_payload_count(enum_tid, vi) <= 0:
                continue
            if found >= 0:
                return -1
            found = vi
        found

    fn payload_enum_single_unit_variant(enum_tid: i32) -> i32:
        if self.type_is_payload_enum(enum_tid) == 0:
            return -1
        let variant_count = self.sema.type_reflection_variant_count(enum_tid)
        var found: i32 = -1
        for vi in 0..variant_count:
            if self.sema.type_reflection_variant_payload_count(enum_tid, vi) != 0:
                continue
            if found >= 0:
                return -1
            found = vi
        found

    mut fn payload_enum_literal(enum_tid: i32, variant_index: i32, payload_text: &str) -> str:
        let enum_c = self.c_type(enum_tid, 0)
        if self.option_is_nullable_pointer(enum_tid):
            if payload_text.len() == 0 or self.sema.type_reflection_variant_payload_count(enum_tid, variant_index) == 0:
                return "((" ++ enum_c ++ ")0)"
            return "((" ++ enum_c ++ ")(" ++ payload_text ++ "))"
        let tag = self.sema.type_reflection_variant_discriminant(enum_tid, variant_index)
        var out = "(" ++ enum_c ++ ")" ++ cc_lbrace() ++ ".tag = " ++ f"{tag}"
        if payload_text.len() > 0:
            out = out ++ ", ." ++ self.payload_enum_variant_field(variant_index) ++ " = " ++ payload_text
        out ++ cc_rbrace()

// A With field's C member name: a field spelled as a C keyword or a name
// the runtime header defines (`signed`, `bool`) takes a trailing `_`.
// Every site that writes a member (struct definitions, places, literals,
// layout asserts, the glue) spells it through here.
fn cc_member(name: str) -> str:
    match name:
        "auto" | "break" | "case" | "char" | "const" | "continue" | "default" | "do" | "double" | "else" | "enum" | "extern" | "float" | "for" | "goto" | "if" | "inline" | "int" | "long" | "register" | "restrict" | "return" | "short" | "signed" | "sizeof" | "static" | "struct" | "switch" | "typedef" | "union" | "unsigned" | "void" | "volatile" | "while" | "bool" | "true" | "false" | "NULL" => name ++ "_"
        _ => name

// A field of a multi-field variant's payload struct (#2017).
fn cc_payload_struct_field(field_idx: i32): f"field{field_idx}"

fn cc_str_concat_expr(left: &str, right: &str) -> str:
    "with_str_concat_ref(" ++ left ++ ", " ++ right ++ ")"

impl CCodegen:
    // The kind a formatter dispatches on: a `&str` view formats as the str
    // it is (#1810, a `{ptr, len}` value); every other type as its own kind.
    fn fmt_value_kind(resolved: i32) -> i32:
        if self.sema.type_layout_is_str_view(resolved): TypeKind.TY_STR else: self.sema.get_type_kind(resolved as TypeId)

    mut fn display_format_expr(tid: i32, expr: &str, context: &str) -> str:
        let resolved = self.sema.resolve_alias(tid as TypeId)
        let tk = self.sema.get_type_kind(resolved)
        if tk == TypeKind.TY_STR:
            return "with_fmt_str_ref(" ++ expr ++ ")"
        if tk == TypeKind.TY_BOOL:
            return "with_fmt_bool((int32_t)(" ++ expr ++ "))"
        if tk == TypeKind.TY_FLOAT:
            return "with_fmt_f64((double)(" ++ expr ++ "))"
        // A `&str` view formats as the str it is (#1810).
        if self.sema.type_layout_is_str_view(resolved as i32):
            return "with_fmt_str_ref(" ++ expr ++ ")"
        if tk == TypeKind.TY_PTR or tk == TypeKind.TY_REF:
            return "with_fmt_i64((int64_t)(intptr_t)(" ++ expr ++ "))"
        if tk == TypeKind.TY_INT:
            return self.debug_int_format_expr(resolved as i32, expr)
        if (tk == TypeKind.TY_ENUM or tk == TypeKind.TY_GENERIC_INST) and self.type_is_payload_enum(resolved as i32) != 0:
            return self.payload_enum_format_expr(resolved as i32, expr, context)
        // A payload with no default display shows its Debug form (D61).
        self.debug_formatter_call_expr(resolved as i32, expr, context)

    // D61 (§15.4.7): call the `:?` formatter Sema registered for `tid` on the
    // lvalue `expr` — the formatter borrows it.
    mut fn debug_formatter_call_expr(tid: i32, expr: &str, context: &str) -> str:
        let entry_opt = self.sema.debug_fmt_index.get(tid)
        if entry_opt.is_none():
            self.fail("no `:?` formatter is registered for the " ++ context ++ " type " ++ self.sema.type_name(tid) ++ " (D61)")
            return ""
        let mono = self.sema.debug_fmt_monos[entry_opt.unwrap()]
        let body_sym = self.canonical_body_sym(mono)
        if body_sym == 0:
            self.fail("the `:?` formatter for " ++ self.sema.type_name(tid) ++ " has no lowered body (D61)")
            return ""
        self.fn_c_name(body_sym) ++ "(&(" ++ expr ++ "))"

    mut fn payload_enum_variant_format_expr(enum_tid: i32, expr: &str, variant_index: i32, context: &str) -> str:
        let name_sym = self.sema.type_reflection_variant_name(enum_tid, variant_index)
        let variant_name: str = with_str_clone_ref(self.sema.pool_resolve(name_sym))
        var out = "WITH_STR_LIT(\"" ++ cc_escape_c_string(variant_name) ++ "\")"
        let payload_count = self.sema.type_reflection_variant_payload_count(enum_tid, variant_index)
        if payload_count <= 0:
            return out
        // `Name(a, b)`, the LLVM backend's display of a payload variant.
        out = cc_str_concat_expr(out, "WITH_STR_LIT(\"(\")")
        for pi in 0..payload_count:
            if pi > 0:
                out = cc_str_concat_expr(out, "WITH_STR_LIT(\", \")")
            let payload_tid = self.sema.type_reflection_variant_payload_type_frozen(enum_tid, variant_index, pi)
            let payload_expr = expr ++ self.payload_enum_field_path(enum_tid, variant_index, pi)
            out = cc_str_concat_expr(out, self.display_format_expr(payload_tid, payload_expr, context))
        cc_str_concat_expr(out, "WITH_STR_LIT(\")\")")

    mut fn payload_enum_format_expr(enum_tid: i32, expr: &str, context: &str) -> str:
        let variant_count = self.sema.type_reflection_variant_count(enum_tid)
        if variant_count <= 0:
            return "WITH_STR_LIT(\"<invalid enum>\")"
        var out = "WITH_STR_LIT(\"<invalid enum>\")"
        var vi = variant_count - 1
        while vi >= 0:
            let disc = self.sema.type_reflection_variant_discriminant(enum_tid, vi)
            let case_text = self.payload_enum_variant_format_expr(enum_tid, expr, vi, context)
            out = "((" ++ self.enum_tag_text(enum_tid, expr) ++ ") == " ++ f"{disc}" ++ " ? " ++ case_text ++ " : " ++ out ++ ")"
            if vi == 0:
                break
            vi = vi - 1
        out

    // D61 (§15.4.7): the `:?` text of the lvalue `expr` — the inline rows
    // here, a view as its pointee, every other type through its registered
    // formatter (the one the LLVM backend calls: identical text).
    mut fn debug_format_expr(tid: i32, expr: &str, context: &str) -> str:
        let resolved = self.sema.resolve_alias(tid as TypeId)
        let tk = self.sema.get_type_kind(resolved)
        if tk == TypeKind.TY_REF:
            // A `&str` view is the str's own {ptr, len} (#1810).
            if self.sema.type_layout_is_str_view(resolved as i32):
                return self.debug_format_expr(self.sema.get_type_d0(resolved), expr, context)
            return self.debug_format_expr(self.sema.get_type_d0(resolved), "(*(" ++ expr ++ "))", context)
        if tk == TypeKind.TY_VOID:
            return "WITH_STR_LIT(\"()\")"
        if tk == TypeKind.TY_STR:
            return "with_fmt_str_debug_ref(" ++ expr ++ ")"
        if tk == TypeKind.TY_BOOL:
            return "with_fmt_bool((int32_t)(" ++ expr ++ "))"
        if tk == TypeKind.TY_FLOAT:
            return "with_fmt_f64((double)(" ++ expr ++ "))"
        if tk == TypeKind.TY_PTR:
            // Its address in hexadecimal (§15.4.7, #1564): `{:#x}`, the
            // alternate-form flag bit 19 and mode 'x', as the LLVM backend.
            return f"with_fmt_int_spec((int64_t)(intptr_t)({expr}), 1, (int64_t){1 << 19}, 0, 0, {'x' as i32})"
        if tk == TypeKind.TY_INT:
            return self.debug_int_format_expr(resolved as i32, expr)
        self.debug_formatter_call_expr(resolved as i32, expr, context)

    fn debug_form_available(tid: i32) -> bool:
        var resolved = self.sema.resolve_alias(tid as TypeId) as i32
        while self.sema.get_type_kind(resolved as TypeId) == TypeKind.TY_REF:
            resolved = self.sema.resolve_alias(self.sema.get_type_d0(resolved as TypeId)) as i32
        self.sema.debug_fmt_is_inline(self.sema.get_type_kind(resolved as TypeId)) or self.sema.debug_fmt_index.contains(resolved)

    // An integer's decimal text at its own width and signedness, as the LLVM
    // backend formats it: a u64 above i64::MAX is positive, and a 128-bit
    // value keeps both words (#1922).
    fn debug_int_format_expr(resolved: i32, expr: &str) -> str:
        let unsigned_flag = if self.sema.get_type_d1(resolved as TypeId) == 0: "1" else: "0"
        if self.sema.get_type_d0(resolved as TypeId) == 128:
            return f"with_fmt_int128((uint64_t)({expr}), (uint64_t)(((unsigned __int128)({expr})) >> 64), {unsigned_flag})"
        if self.sema.get_type_d1(resolved as TypeId) == 0:
            return "with_fmt_u64((uint64_t)(" ++ expr ++ "))"
        "with_fmt_i64((int64_t)(" ++ expr ++ "))"

    // The value and signedness arguments an integer spec formatter takes,
    // and which one: with_fmt_int_spec / with_fmt_buf_write_i64_spec take the
    // value extended to 64 bits by its own signedness, the int128 forms its
    // two words (#1922).
    fn int_spec_value_args(resolved: i32, expr: &str) -> str:
        let unsigned_flag = if self.sema.get_type_kind(resolved as TypeId) == TypeKind.TY_INT and self.sema.get_type_d1(resolved as TypeId) == 0: "1" else: "0"
        if self.sema.get_type_kind(resolved as TypeId) == TypeKind.TY_INT and self.sema.get_type_d0(resolved as TypeId) == 128:
            return f"(uint64_t)({expr}), (uint64_t)(((unsigned __int128)({expr})) >> 64), {unsigned_flag}"
        if unsigned_flag == "1":
            return f"(int64_t)(uint64_t)({expr}), 1"
        f"(int64_t)({expr}), 0"

    // The spec's flags with the value's own bit width in bits 24-31 (none
    // for 64 or 128 bits), as the LLVM backend's mir_int_spec_flags (#1907).
    fn int_spec_flags_text(resolved: i32, flags_text: &str) -> str:
        let own_width = if self.sema.get_type_kind(resolved as TypeId) == TypeKind.TY_INT: self.sema.get_type_d0(resolved as TypeId) else: 64
        if own_width > 0 and own_width < 64: f"(({flags_text}) | ((int64_t){own_width} << 24))" else: flags_text.to_owned()

    fn int_spec_is_128(resolved: i32) -> bool:
        self.sema.get_type_kind(resolved as TypeId) == TypeKind.TY_INT and self.sema.get_type_d0(resolved as TypeId) == 128

    // The C name of a fn type is structural (#1766): Sema gives a closure
    // its own fn type, distinct from the structurally equal type of the
    // parameter it is passed to, and two typedef'd structs with different
    // names are incompatible in C whatever their members. The LLVM backend
    // has no such problem — every pair is {ptr, ptr}.
    fn fn_type_c_name(tid: i32) -> str:
        "with_fn_" ++ self.type_c_key(self.sema.resolve_alias(tid) as i32)

    // A structural key for a type, as a C identifier fragment: nominal types
    // keep their id, every structural type is spelled out.
    fn type_c_key(tid: i32) -> str:
        let resolved = self.sema.resolve_alias(tid)
        if resolved == 0:
            return "0"
        let tk = self.sema.get_type_kind(resolved)
        if tk == TypeKind.TY_INT:
            return f"i{self.sema.get_type_d0(resolved)}{self.sema.get_type_d1(resolved)}"
        if tk == TypeKind.TY_BOOL:
            return "b"
        if tk == TypeKind.TY_FLOAT:
            return f"f{self.sema.get_type_d0(resolved)}"
        if tk == TypeKind.TY_STR:
            return "s"
        if tk == TypeKind.TY_VOID:
            return "v"
        if tk == TypeKind.TY_REF or tk == TypeKind.TY_PTR:
            let head = if tk == TypeKind.TY_REF: "R" else: "P"
            return head ++ f"{self.sema.get_type_d1(resolved)}" ++ self.type_c_key(self.sema.get_type_d0(resolved))
        if tk == TypeKind.TY_ARRAY:
            return f"A{self.sema.get_type_d1(resolved)}_" ++ self.type_c_key(self.sema.get_type_d0(resolved))
        if tk == TypeKind.TY_SLICE:
            return "S" ++ self.type_c_key(self.sema.get_type_d0(resolved))
        if tk == TypeKind.TY_TUPLE:
            let start = self.sema.get_type_d0(resolved)
            let count = self.sema.get_type_d1(resolved)
            var out = f"T{count}"
            for i in 0..count:
                out = out ++ "_" ++ self.type_c_key(self.sema.type_extra[(start + i)])
            return out
        if tk == TypeKind.TY_FN or tk == TypeKind.TY_EXTERN_FN:
            let start = self.sema.get_type_d0(resolved)
            let count = self.sema.get_type_d1(resolved)
            var out = (if tk == TypeKind.TY_FN: "F" else: "E") ++ f"{count}"
            if tk == TypeKind.TY_EXTERN_FN and self.sema.fn_type_is_variadic(resolved as i32):
                out = out ++ "V"
            for i in 0..count:
                out = out ++ "_" ++ self.type_c_key(self.sema.type_extra[(start + i)])
            return out ++ "_r" ++ self.type_c_key(self.sema.get_type_d2(resolved))
        f"t{resolved as i32}"

    // With fn VALUES use native codegen's fat-pair convention: a struct
    // {fn_ptr, ctx} whose fn_ptr always takes ctx first (Codegen.w
    // gen_fn_to_fat_ptr_thunk). TY_EXTERN_FN stays a bare C function pointer —
    // it is a foreign ABI surface, not a With fn value.
    fn fn_tid_is_fat(tid: i32) -> i32:
        let resolved = self.sema.resolve_alias(tid)
        if self.sema.get_type_kind(resolved) == TypeKind.TY_FN: 1 else: 0

    fn fat_thunk_name(fn_sym: i32, canon_tid: i32) -> str:
        let _ = self
        f"__with_fn_thunk_{fn_sym}_{canon_tid}"

    // Materialize a named function as a fat fn value: register the static
    // C thunk (emitted between prototypes and bodies) and return the pair
    // compound literal.
    mut fn fat_fn_literal(fn_sym: i32, fn_tid: i32) -> str:
        let canon = self.sema.resolve_alias(fn_tid) as i32
        let key = (fn_sym as i64) * 4294967296 + (canon as i64)
        if not self.fat_thunk_keys.contains(key):
            self.fat_thunk_keys.insert(key, self.fat_thunk_syms.len() as i32)
            self.fat_thunk_syms.push(fn_sym)
            self.fat_thunk_tids.push(canon)
        "((" ++ self.fn_type_c_name(canon) ++ ")" ++ cc_lbrace() ++ " " ++ self.fat_thunk_name(fn_sym, canon) ++ ", 0 " ++ cc_rbrace() ++ ")"

    fn rvalue_is_str_const_use(body: &MirBody, rval_id: i32) -> i32:
        if rval_id < 0 or rval_id >= body.rval_kinds.len():
            return 0
        if body.rval_kinds[rval_id] != RvalueKind.RK_USE:
            return 0
        self.operand_is_str_const(body, body.rval_d0[rval_id])

    fn rvalue_ck_fn_sym(body: &MirBody, rval_id: i32) -> i32:
        if rval_id < 0 or rval_id >= body.rval_kinds.len():
            return 0
        if body.rval_kinds[rval_id] != RvalueKind.RK_USE:
            return 0
        let op_id = body.rval_d0[rval_id]
        self.operand_ck_fn_sym(body, op_id)

    fn operand_ck_fn_sym(body: &MirBody, op_id: i32) -> i32:
        if op_id < 0 or op_id >= body.operand_kinds.len():
            return 0
        if body.operand_kinds[op_id] != OperandKind.OK_CONSTANT:
            return 0
        let const_id = body.operand_d0[op_id]
        if const_id < 0 or const_id >= body.const_kinds.len():
            return 0
        if body.const_kinds[const_id] != ConstKind.CK_FN:
            return 0
        body.const_d0[const_id]

    mut fn emit_fat_thunk_defs() -> str:
        var out = ""
        var i = 0
        while i < self.fat_thunk_syms.len():
            let fn_sym: i32 = self.fat_thunk_syms[i]
            let tid: i32 = self.fat_thunk_tids[i]
            i = i + 1
            let ret_tid = self.sema.get_type_d2(tid as TypeId)
            let start = self.sema.get_type_d0(tid as TypeId)
            let count = self.sema.get_type_d1(tid as TypeId)
            // #1817: an array return's out-pointer sits right after the
            // context and is forwarded first to the named target.
            var params = "void* __with_ctx" ++ self.array_out_param(ret_tid, true, true)
            var args = if self.returns_array(ret_tid): "__with_ret" else: ""
            for pi in 0..count:
                let p_tid: i32 = self.sema.type_extra[(start + pi)]
                // c_decl, not c_type-plus-name: pointer-to-array params need
                // the name inside the declarator (int32_t (*_p0)[2]).
                params = params ++ ", " ++ self.c_decl(p_tid, f"_p{pi}")
                if args.len() > 0:
                    args = args ++ ", "
                args = args ++ f"_p{pi}"
            let body_sym = self.canonical_body_sym(fn_sym)
            let target = if body_sym != 0: self.fn_c_name(body_sym) else: self.extern_sym_c_name(fn_sym)
            let thunk_decl = self.return_decl(ret_tid, self.fat_thunk_name(fn_sym, tid) ++ "(" ++ params ++ ")")
            out = out ++ "static " ++ thunk_decl ++ " " ++ cc_lbrace() ++ " (void)__with_ctx; "
            if self.is_void_tid(ret_tid) != 0 or self.returns_array(ret_tid):
                out = out ++ target ++ "(" ++ args ++ "); "
            else:
                out = out ++ "return " ++ target ++ "(" ++ args ++ "); "
            out = out ++ cc_rbrace() ++ "\n"
        if out.len() > 0:
            out = out ++ "\n"
        out

    // A call whose callee is a fn-typed place (not devirtualized to a known
    // symbol) invokes the fat pair: callee.fn_ptr(callee.ctx, args...).
    mut fn indirect_callee_place_id(body: &MirBody, callee_operand: i32, args_id: i32) -> i32:
        if body.call_requires_contract(args_id):
            return -1
        if callee_operand < 0 or callee_operand >= body.operand_kinds.len():
            return -1
        let ok = body.operand_kinds[callee_operand]
        if ok != OperandKind.OK_COPY and ok != OperandKind.OK_MOVE:
            return -1
        let od = body.operand_d0[callee_operand]
        let local_id = self.place_local_id(body, od)
        if local_id >= 0 and self.place_is_direct_local(body, od, local_id) != 0:
            if self.local_assigned_fn_sym(body, local_id) != 0:
                return -1
        let callee_tid = self.callee_fn_type_from_operand(body, callee_operand)
        if callee_tid == 0:
            return -1
        if self.fn_tid_is_fat(callee_tid) == 0:
            return -1
        od

    fn storage_copy_assignment(dst_place: &str, rval: &str) -> str:
        let _ = self
        "    " ++ cc_lbrace() ++ " __typeof__(" ++ rval ++ ") __tmp = " ++ rval ++ "; memcpy(&(" ++ dst_place ++ "), &__tmp, sizeof(" ++ dst_place ++ ") < sizeof(__tmp) ? sizeof(" ++ dst_place ++ ") : sizeof(__tmp)); " ++ cc_rbrace()

    fn named_struct_tid(type_name: &str) -> i32:
        let sym = self.intern_intern(type_name)
        if not self.sema.named_types.contains(sym):
            return 0
        let tid = self.sema.named_types.get(sym).unwrap()
        let resolved = self.sema.resolve_alias(tid)
        if self.sema.get_type_kind(resolved) != TypeKind.TY_STRUCT:
            return 0
        resolved as i32

    fn struct_field_tid(struct_tid: i32, field_sym: i32) -> i32:
        let resolved = self.sema.resolve_alias(struct_tid)
        if self.sema.get_type_kind(resolved) != TypeKind.TY_STRUCT:
            return 0
        let start = self.sema.get_type_d1(resolved)
        let count = self.sema.get_type_d2(resolved)
        for fi in 0..count:
            let f_sym = self.sema.type_extra[(start + fi * 3)]
            if f_sym == field_sym:
                return self.sema.type_extra[(start + fi * 3 + 1)]
        0

    fn tuple_field_index(tuple_tid: i32, field_id: i32) -> i32:
        let resolved = self.sema.resolve_alias(tuple_tid)
        if self.sema.get_type_kind(resolved) != TypeKind.TY_TUPLE:
            return -1
        let count = self.sema.get_type_d1(resolved)
        if field_id >= 0 and field_id < count:
            return field_id
        let name = cc_intern_resolve(self.intern, field_id)
        if name.len() == 0:
            return -1
        var idx: i32 = 0
        for i in 0..name.len():
            let ch = name[i]
            if ch < 48 or ch > 57:
                return -1
            idx = idx * 10 + (ch - 48)
        if idx >= 0 and idx < count:
            return idx
        -1

    fn tuple_field_tid(tuple_tid: i32, field_idx: i32) -> i32:
        let resolved = self.sema.resolve_alias(tuple_tid)
        if self.sema.get_type_kind(resolved) != TypeKind.TY_TUPLE:
            return 0
        let count = self.sema.get_type_d1(resolved)
        if field_idx < 0 or field_idx >= count:
            return 0
        let start = self.sema.get_type_d0(resolved)
        self.sema.type_extra[(start + field_idx)]

    mut fn place_tid(body: &MirBody, place_id: i32) -> i32:
        let lid = self.place_local_id(body, place_id)
        var base_tid = self.local_effective_tid(body, lid)
        if self.is_void_tid(base_tid) != 0:
            base_tid = self.place_local_tid(body, place_id)
        if base_tid == 0:
            return 0
        var tid = base_tid
        if place_id < 0 or place_id >= body.place_locals.len():
            return tid
        let start = body.place_proj_starts[place_id]
        let count = body.place_proj_counts[place_id]
        // A payload enum's downcast names its variant; the field after it is
        // that variant's payload field `pd` (MirCore's projection typing).
        var downcast_enum_tid: i32 = 0
        var downcast_variant: i32 = -1
        for i in 0..count:
            let pk = body.proj_kinds[(start + i)]
            let pd = body.proj_d0[(start + i)]
            let resolved = self.sema.resolve_alias(tid as TypeId)
            let tk = self.sema.get_type_kind(resolved)
            if pk == ProjKind.PK_FIELD and downcast_variant >= 0:
                tid = self.sema.type_reflection_variant_payload_type_frozen(downcast_enum_tid, downcast_variant, pd)
                downcast_variant = -1
                if tid == 0:
                    return 0
                continue
            if pk == ProjKind.PK_FIELD:
                if tk == TypeKind.TY_TUPLE:
                    let field_idx = self.tuple_field_index(resolved as i32, pd)
                    let ft = self.tuple_field_tid(resolved as i32, field_idx)
                    if ft == 0:
                        return 0
                    tid = ft
                    continue
                if pd == 0:
                    continue
                if tk == TypeKind.TY_STRUCT:
                    let ft_raw = self.struct_field_tid(resolved as i32, pd)
                    let ft = self.effective_field_tid(resolved as i32, pd, ft_raw)
                    if ft == 0:
                        return 0
                    tid = ft
                    continue
                if tk == TypeKind.TY_GENERIC_INST:
                    let ft = self.generic_inst_field_tid(resolved as i32, pd)
                    if ft != 0:
                        tid = ft
                        continue
                    return 0
                if tk == TypeKind.TY_STR:
                    let field_name = cc_intern_resolve(self.intern, pd)
                    if field_name == "len":
                        tid = self.sema.ty_i64 as i32
                        continue
                    return 0
                return 0
            if pk == ProjKind.PK_INDEX:
                if tk == TypeKind.TY_STR:
                    tid = self.sema.ty_i32 as i32
                    continue
                if tk == TypeKind.TY_ARRAY or tk == TypeKind.TY_SLICE:
                    tid = self.sema.get_type_d0(resolved)
                    continue
                let list_elem_tid = self.list_element_tid(tid)
                let effective_list_elem_tid = if list_elem_tid != 0: list_elem_tid else: self.list_local_element_tid(body, lid)
                if effective_list_elem_tid != 0:
                    tid = effective_list_elem_tid
                    continue
                return 0
            if pk == ProjKind.PK_DEREF:
                if tk == TypeKind.TY_PTR or tk == TypeKind.TY_REF:
                    tid = self.sema.get_type_d0(resolved)
                    continue
                let box_pointee = self.std_box_pointee_tid(resolved as i32)
                if box_pointee != 0:
                    tid = box_pointee
                    continue
                return 0
            if pk == ProjKind.PK_DOWNCAST:
                if self.type_is_payload_enum(tid) != 0:
                    let payload_count = self.sema.type_reflection_variant_payload_count(tid, pd)
                    if payload_count > 0 and i + 1 < count and body.proj_kinds[(start + i + 1)] == ProjKind.PK_FIELD:
                        downcast_enum_tid = tid
                        downcast_variant = pd
                        continue
                    if payload_count == 1:
                        tid = self.sema.type_reflection_variant_payload_type_frozen(tid, pd, 0)
                        continue
                    return 0
                return 0
            if pk == ProjKind.PK_TUPLE_INDEX:
                if tk == TypeKind.TY_TUPLE:
                    let tuple_ft = self.tuple_field_tid(resolved as i32, pd)
                    if tuple_ft == 0:
                        return 0
                    tid = tuple_ft
                    continue
                return 0
            return 0
        tid

    mut fn place_ref_target_tid(body: &MirBody, place_id: i32) -> i32:
        let lid = self.place_local_id(body, place_id)
        var base_tid = self.local_effective_tid(body, lid)
        if self.is_void_tid(base_tid) != 0:
            base_tid = self.place_local_tid(body, place_id)
        if base_tid == 0:
            return 0
        var tid = base_tid
        if place_id < 0 or place_id >= body.place_locals.len():
            return tid
        let start = body.place_proj_starts[place_id]
        let count = body.place_proj_counts[place_id]
        // A payload enum's downcast names its variant; the field after it is
        // that variant's payload field `pd` (MirCore's projection typing).
        var downcast_enum_tid: i32 = 0
        var downcast_variant: i32 = -1
        for i in 0..count:
            let pk = body.proj_kinds[(start + i)]
            let pd = body.proj_d0[(start + i)]
            let resolved = self.sema.resolve_alias(tid as TypeId)
            let tk = self.sema.get_type_kind(resolved)
            if pk == ProjKind.PK_FIELD and downcast_variant >= 0:
                tid = self.sema.type_reflection_variant_payload_type_frozen(downcast_enum_tid, downcast_variant, pd)
                downcast_variant = -1
                if tid == 0:
                    return 0
                continue
            if pk == ProjKind.PK_FIELD:
                if tk == TypeKind.TY_TUPLE:
                    let field_idx = self.tuple_field_index(resolved as i32, pd)
                    let ft = self.tuple_field_tid(resolved as i32, field_idx)
                    if ft == 0:
                        return 0
                    tid = ft
                    continue
                if pd == 0:
                    continue
                if tk == TypeKind.TY_STRUCT:
                    let ft_raw = self.struct_field_tid(resolved as i32, pd)
                    let ft = self.effective_field_tid(resolved as i32, pd, ft_raw)
                    if ft == 0:
                        return 0
                    tid = ft
                    continue
                if tk == TypeKind.TY_GENERIC_INST:
                    let ft = self.generic_inst_field_tid(resolved as i32, pd)
                    if ft != 0:
                        tid = ft
                        continue
                    return 0
                if tk == TypeKind.TY_STR:
                    let field_name = cc_intern_resolve(self.intern, pd)
                    if field_name == "len":
                        tid = self.sema.ty_i64 as i32
                        continue
                    if field_name == "ptr":
                        tid = self.sema.find_exact_type(TypeKind.TY_PTR, self.sema.ty_i8 as i32, 0, 0) as i32
                        continue
                    return 0
                return 0
            if pk == ProjKind.PK_INDEX:
                if tk == TypeKind.TY_STR:
                    return self.sema.find_exact_type(TypeKind.TY_PTR, self.sema.ty_i8 as i32, 0, 0) as i32
                if tk == TypeKind.TY_ARRAY or tk == TypeKind.TY_SLICE:
                    tid = self.sema.get_type_d0(resolved)
                    continue
                let list_elem_tid = self.list_element_tid(tid)
                let effective_list_elem_tid = if list_elem_tid != 0: list_elem_tid else: self.list_local_element_tid(body, lid)
                if effective_list_elem_tid != 0:
                    tid = effective_list_elem_tid
                    continue
                return 0
            if pk == ProjKind.PK_DEREF:
                if tk == TypeKind.TY_PTR or tk == TypeKind.TY_REF:
                    tid = self.sema.get_type_d0(resolved)
                    continue
                let box_pointee = self.std_box_pointee_tid(resolved as i32)
                if box_pointee != 0:
                    tid = box_pointee
                    continue
                return 0
            if pk == ProjKind.PK_DOWNCAST:
                if self.type_is_payload_enum(tid) != 0:
                    let payload_count = self.sema.type_reflection_variant_payload_count(tid, pd)
                    if payload_count > 0 and i + 1 < count and body.proj_kinds[(start + i + 1)] == ProjKind.PK_FIELD:
                        downcast_enum_tid = tid
                        downcast_variant = pd
                        continue
                    if payload_count == 1:
                        tid = self.sema.type_reflection_variant_payload_type_frozen(tid, pd, 0)
                        continue
                    return 0
                return 0
            if pk == ProjKind.PK_TUPLE_INDEX:
                if tk == TypeKind.TY_TUPLE:
                    let tuple_ft = self.tuple_field_tid(resolved as i32, pd)
                    if tuple_ft == 0:
                        return 0
                    tid = tuple_ft
                    continue
                return 0
            return 0
        tid

    mut fn place_tid_no_infer(body: &MirBody, place_id: i32) -> i32:
        let base_tid = self.place_local_tid(body, place_id)
        if base_tid == 0:
            return 0
        var tid = base_tid
        if place_id < 0 or place_id >= body.place_locals.len():
            return tid
        let start = body.place_proj_starts[place_id]
        let count = body.place_proj_counts[place_id]
        // A payload enum's downcast names its variant; the field after it is
        // that variant's payload field `pd` (MirCore's projection typing).
        var downcast_enum_tid: i32 = 0
        var downcast_variant: i32 = -1
        for i in 0..count:
            let pk = body.proj_kinds[(start + i)]
            let pd = body.proj_d0[(start + i)]
            let resolved = self.sema.resolve_alias(tid as TypeId)
            let tk = self.sema.get_type_kind(resolved)
            if pk == ProjKind.PK_FIELD and downcast_variant >= 0:
                tid = self.sema.type_reflection_variant_payload_type_frozen(downcast_enum_tid, downcast_variant, pd)
                downcast_variant = -1
                if tid == 0:
                    return 0
                continue
            if pk == ProjKind.PK_FIELD:
                if tk == TypeKind.TY_TUPLE:
                    let field_idx = self.tuple_field_index(resolved as i32, pd)
                    let ft = self.tuple_field_tid(resolved as i32, field_idx)
                    if ft == 0:
                        return 0
                    tid = ft
                    continue
                if pd == 0:
                    continue
                if tk == TypeKind.TY_STRUCT:
                    let ft_raw = self.struct_field_tid(resolved as i32, pd)
                    let ft = self.effective_field_tid(resolved as i32, pd, ft_raw)
                    if ft == 0:
                        return 0
                    tid = ft
                    continue
                if tk == TypeKind.TY_GENERIC_INST:
                    let ft = self.generic_inst_field_tid(resolved as i32, pd)
                    if ft != 0:
                        tid = ft
                        continue
                    return 0
                if tk == TypeKind.TY_STR:
                    let field_name = cc_intern_resolve(self.intern, pd)
                    if field_name == "len":
                        tid = self.sema.ty_i64 as i32
                        continue
                    return 0
                return 0
            if pk == ProjKind.PK_INDEX:
                if tk == TypeKind.TY_STR:
                    tid = self.sema.ty_i32 as i32
                    continue
                if tk == TypeKind.TY_ARRAY or tk == TypeKind.TY_SLICE:
                    tid = self.sema.get_type_d0(resolved)
                    continue
                let list_elem_tid = self.list_element_tid(tid)
                if list_elem_tid != 0:
                    tid = list_elem_tid
                    continue
                return 0
            if pk == ProjKind.PK_DEREF:
                if tk == TypeKind.TY_PTR or tk == TypeKind.TY_REF:
                    tid = self.sema.get_type_d0(resolved)
                    continue
                let box_pointee = self.std_box_pointee_tid(resolved as i32)
                if box_pointee != 0:
                    tid = box_pointee
                    continue
                return 0
            if pk == ProjKind.PK_DOWNCAST:
                if self.type_is_payload_enum(tid) != 0:
                    let payload_count = self.sema.type_reflection_variant_payload_count(tid, pd)
                    if payload_count > 0 and i + 1 < count and body.proj_kinds[(start + i + 1)] == ProjKind.PK_FIELD:
                        downcast_enum_tid = tid
                        downcast_variant = pd
                        continue
                    if payload_count == 1:
                        tid = self.sema.type_reflection_variant_payload_type_frozen(tid, pd, 0)
                        continue
                    return 0
                return 0
            if pk == ProjKind.PK_TUPLE_INDEX:
                if tk == TypeKind.TY_TUPLE:
                    let tuple_ft = self.tuple_field_tid(resolved as i32, pd)
                    if tuple_ft == 0:
                        return 0
                    tid = tuple_ft
                    continue
                return 0
            return 0
        tid

    fn type_match(expected: i32, actual: i32) -> i32:
        if expected == 0 or actual == 0:
            return 1
        if self.sema.types_compatible_frozen(expected, actual) != 0:
            return 1
        if self.sema.types_compatible_frozen(actual, expected) != 0:
            return 1
        0

    fn strict_type_match(expected: i32, actual: i32) -> i32:
        if expected == 0 or actual == 0:
            return 1
        let e = self.sema.resolve_alias(expected)
        let a = self.sema.resolve_alias(actual)
        let ek = self.sema.get_type_kind(e)
        let ak = self.sema.get_type_kind(a)
        if ek == TypeKind.TY_STRUCT and ak == TypeKind.TY_STRUCT:
            let en = self.sema.get_type_d0(e)
            let an = self.sema.get_type_d0(a)
            if en == an:
                return 1
            return 0
        self.type_match(e, a)

    fn is_scalar_like_tid(tid: i32) -> i32:
        let resolved = self.sema.resolve_alias(tid)
        let tk = self.sema.get_type_kind(resolved)
        if tk == TypeKind.TY_INT or tk == TypeKind.TY_BOOL or tk == TypeKind.TY_FLOAT or tk == TypeKind.TY_ENUM:
            return 1
        if self.type_is_distinct(resolved as i32) != 0:
            return 1
        0

    fn prefer_inferred_tid(current_tid: i32, candidate_tid: i32) -> i32:
        let cand = self.sema.resolve_alias(candidate_tid as TypeId) as i32
        if cand == 0 or self.is_void_tid(cand) != 0:
            return current_tid
        if self.sema.get_type_kind(cand as TypeId) == TypeKind.TY_ERR:
            return current_tid
        if current_tid == 0 or self.is_void_tid(current_tid) != 0:
            return cand
        if self.strict_type_match(current_tid, cand) != 0:
            return current_tid
        let cur_scalar = self.is_scalar_like_tid(current_tid)
        let cand_scalar = self.is_scalar_like_tid(cand)
        if cur_scalar != 0 and cand_scalar == 0:
            return cand
        if cur_scalar == 0 and cand_scalar != 0:
            return current_tid
        cand

    mut fn c_type(tid: i32, as_return: i32) -> str:
        if tid == CC_PSEUDO_TID_LIST:
            return "with_vec"
        if tid == CC_PSEUDO_TID_FMT_BUF:
            return "uint8_t*"
        let resolved = self.sema.resolve_alias(tid)
        if resolved == CC_PSEUDO_TID_LIST:
            return "with_vec"
        if resolved == CC_PSEUDO_TID_FMT_BUF:
            return "uint8_t*"
        let tk = self.sema.get_type_kind(resolved)
        if tk == TypeKind.TY_VOID or tk == TypeKind.TY_NEVER:
            if as_return != 0:
                return "void"
            return "int32_t"
        if tk == TypeKind.TY_BOOL:
            return "bool"
        if tk == TypeKind.TY_VA_LIST:
            return "va_list"
        // §4.3d: the C emitter has no vector lowering yet; say so rather
        // than emit a type that is not the program's.
        if tk == TypeKind.TY_VECTOR or tk == TypeKind.TY_MASK:
            self.fail("--emit-c does not support SIMD vector types (§4.3d) yet: " ++ self.sema.type_name(resolved as i32))
            return "int32_t"
        if tk == TypeKind.TY_INT:
            let bits = self.sema.get_type_d0(resolved)
            let signed = self.sema.get_type_d1(resolved)
            if bits == 8:
                return if signed != 0: "int8_t" else: "uint8_t"
            if bits == 16:
                return if signed != 0: "int16_t" else: "uint16_t"
            if bits == 32:
                return if signed != 0: "int32_t" else: "uint32_t"
            if bits == 64:
                return if signed != 0: "int64_t" else: "uint64_t"
            if bits == 128:
                return if signed != 0: "__int128" else: "unsigned __int128"
            return "int64_t"
        if tk == TypeKind.TY_FLOAT:
            if self.sema.get_type_d0(resolved) == 32:
                return "float"
            return "double"
        if tk == TypeKind.TY_STR:
            return "with_str"
        if tk == TypeKind.TY_STRUCT:
            if self.type_is_c_void(resolved as i32) != 0:
                return "void"
            return self.struct_c_name(resolved)
        if tk == TypeKind.TY_ENUM:
            if self.type_is_payload_enum(resolved as i32) != 0:
                return self.struct_c_name(resolved)
            return "int32_t"
        // #1810: a shared `&str` is a view, `{ptr, len}` by value — the
        // with_str itself (TypeLayout.type_layout_is_str_view).
        if self.sema.type_layout_is_str_view(resolved as i32):
            return "with_str"
        if tk == TypeKind.TY_PTR or tk == TypeKind.TY_REF:
            let inner_tid = self.sema.get_type_d0(resolved)
            let inner_resolved = self.sema.resolve_alias(inner_tid)
            let inner_kind = self.sema.get_type_kind(inner_resolved)
            if inner_kind == TypeKind.TY_ARRAY:
                let array_pointer = self.c_decl(inner_tid, "(*)")
                if self.sema.get_type_d1(resolved) == 0:
                    return "const " ++ array_pointer
                return array_pointer
            // An extern C fn type is a C function pointer already; a With fn
            // value is a {fn_ptr, ctx} pair, so a pointer to one points at
            // the pair (`compare: *const fn(…)` was laid out as the pair).
            // A `&fn(…)` view is passed as the pair itself.
            if inner_kind == TypeKind.TY_FN and tk == TypeKind.TY_PTR:
                let pair = self.fn_type_c_name(inner_resolved as i32)
                return if self.sema.get_type_d1(resolved) == 0: "const " ++ pair ++ "*" else: pair ++ "*"
            if inner_kind == TypeKind.TY_FN or inner_kind == TypeKind.TY_EXTERN_FN:
                return self.fn_type_c_name(inner_resolved as i32)
            if inner_kind == TypeKind.TY_VOID:
                if (tk == TypeKind.TY_PTR or tk == TypeKind.TY_REF) and self.sema.get_type_d1(resolved) == 0:
                    return "const void*"
                return "void*"
            if self.type_is_c_void(inner_resolved as i32) != 0:
                if (tk == TypeKind.TY_PTR or tk == TypeKind.TY_REF) and self.sema.get_type_d1(resolved) == 0:
                    return "const void*"
                return "void*"
            var base = self.c_type(inner_tid, 0)
            if base == "void":
                base = "uint8_t"
            if (tk == TypeKind.TY_PTR or tk == TypeKind.TY_REF) and self.sema.get_type_d1(resolved) == 0:
                return "const " ++ base ++ "*"
            return base ++ "*"
        if tk == TypeKind.TY_GENERIC_INST:
            // Generic instances: List[T] → with_vec, HashMap[K,V] → void* (opaque handle)
            let base_sym = self.sema.get_type_d0(resolved)
            let base_name = cc_intern_resolve(self.intern, base_sym)
            if base_name == "List":
                return "with_vec"
            if base_name == "HashMap":
                return "int64_t"  // opaque handle, passed as int64_t to runtime functions
            if base_name == "HashSet":
                return "int64_t"  // opaque handle, same runtime representation as HashMap
            if base_name == "SlotMap":
                return "int64_t"  // opaque handle, LLVM backend owns SlotMap intrinsics
            let box_pointee = self.std_box_pointee_tid(resolved as i32)
            if box_pointee != 0:
                let pointee = self.c_type(box_pointee, 0)
                return if pointee == "void": "uint8_t*" else: pointee ++ "*"
            // with-abi §3 (#2036): the nullable pointer is its payload's type.
            if self.option_is_nullable_pointer(resolved as i32):
                return self.c_type(self.sema.get_generic_inst_arg(resolved as i32, 0), 0)
            if self.type_is_payload_enum(resolved as i32) != 0:
                return self.struct_c_name(resolved)
            // Other generic types: treat as opaque struct
            return self.struct_c_name(resolved)
        if tk == TypeKind.TY_ARRAY:
            let elem_tid = self.sema.get_type_d0(resolved)
            return self.c_type(elem_tid, 0) ++ "*"
        if tk == TypeKind.TY_SLICE:
            return self.struct_c_name(resolved as i32)
        if tk == TypeKind.TY_TUPLE:
            return self.struct_c_name(resolved as i32)
        if tk == TypeKind.TY_FN or tk == TypeKind.TY_EXTERN_FN:
            return self.fn_type_c_name(resolved as i32)
        // Conservative fallback
        "int64_t"

    fn checked_int_helper_suffix(tid: i32) -> str:
        let resolved = self.sema.resolve_alias(tid)
        if self.sema.get_type_kind(resolved) != TypeKind.TY_INT:
            return ""
        let bits = self.sema.get_type_d0(resolved)
        let signed = self.sema.get_type_d1(resolved) != 0
        if bits != 8 and bits != 16 and bits != 32 and bits != 64 and bits != 128:
            return ""
        let prefix = if signed: "i" else: "u"
        prefix ++ f"{bits}"

    mut fn checked_int_bin_op_text(op: i32, lhs: &str, rhs: &str, result_tid: i32) -> str:
        let suffix = self.checked_int_helper_suffix(result_tid)
        if suffix.len() == 0:
            self.fail("C backend does not support checked integer arithmetic for this integer width yet")
            return "0"
        let c_ty = self.c_type(result_tid, 0)
        var helper = ""
        if op == BinaryOp.OP_ADD:
            helper = "__with_checked_add_"
        else if op == BinaryOp.OP_SUB:
            helper = "__with_checked_sub_"
        else if op == BinaryOp.OP_MUL:
            helper = "__with_checked_mul_"
        else if op == BinaryOp.OP_DIV:
            helper = "__with_checked_div_"
        else if op == BinaryOp.OP_MOD:
            helper = "__with_checked_mod_"
        else:
            self.fail(f"unsupported checked integer binop {op}")
            return "0"
        helper ++ suffix ++ "((" ++ c_ty ++ ")(" ++ lhs ++ "), (" ++ c_ty ++ ")(" ++ rhs ++ "))"

    mut fn checked_int_neg_text(inner: &str, result_tid: i32) -> str:
        let suffix = self.checked_int_helper_suffix(result_tid)
        if suffix.len() == 0 or suffix[0] != 105:
            self.fail("C backend does not support checked integer negation for this integer type yet")
            return "0"
        let c_ty = self.c_type(result_tid, 0)
        "__with_checked_neg_" ++ suffix ++ "((" ++ c_ty ++ ")(" ++ inner ++ "))"

    mut fn c_decl(tid: i32, name: &str) -> str:
        let resolved = self.sema.resolve_alias(tid)
        if resolved != 0 and self.sema.get_type_kind(resolved) == TypeKind.TY_ARRAY:
            let elem_tid = self.sema.get_type_d0(resolved)
            let size = self.sema.get_type_d1(resolved)
            return self.c_decl(elem_tid, name ++ f"[{size}]")
        if resolved != 0:
            let kind = self.sema.get_type_kind(resolved)
            if kind == TypeKind.TY_PTR or kind == TypeKind.TY_REF:
                let inner_tid = self.sema.get_type_d0(resolved)
                let inner = self.sema.resolve_alias(inner_tid)
                if self.sema.get_type_kind(inner) == TypeKind.TY_ARRAY:
                    let decl = self.c_decl(inner_tid, "(*" ++ name ++ ")")
                    if self.sema.get_type_d1(resolved) == 0:
                        return "const " ++ decl
                    return decl
        self.c_type(tid, 0) ++ " " ++ name

    fn type_is_pointer_to_array(tid: i32) -> bool:
        let resolved = self.sema.resolve_alias(tid)
        let kind = self.sema.get_type_kind(resolved)
        if kind != TypeKind.TY_PTR and kind != TypeKind.TY_REF:
            return false
        let inner = self.sema.resolve_alias(self.sema.get_type_d0(resolved) as TypeId)
        self.sema.get_type_kind(inner) == TypeKind.TY_ARRAY

    // C returns no arrays (#1775): a function whose With return type is an
    // array takes the caller's destination as a leading `void* __with_ret`
    // and its return copies `_0` into it. The C emitter had declared
    // `uint16_t* arr()` returning `_0` — a pointer to its own dead frame —
    // and assigned the result to an array, which no C compiler accepts.
    fn returns_array(ret_tid: i32) -> bool:
        if ret_tid <= 0 or ret_tid == CC_PSEUDO_TID_LIST or ret_tid == CC_PSEUDO_TID_FMT_BUF:
            return false
        self.sema.get_type_kind(self.sema.resolve_alias(ret_tid)) == TypeKind.TY_ARRAY

    // #1817: the ONE rule every fn shape reads. A function whose With type
    // returns an array returns void in C and takes the destination as the
    // leading out-pointer: a named function as `(void* __with_ret, params)`,
    // and every fat fn value — the TY_FN typedef, a thunk materializing a
    // named function, a closure — right after the context:
    // `(void* ctx, void* __with_ret, params)`. The indirect call site passes
    // (ctx, dest, args...) and the direct one (dest, args...). This renders
    // the out-pointer's parameter text (with a leading ", " when `after` is
    // set, i.e. it follows the context) and nothing for every other return.
    fn array_out_param(ret_tid: i32, named: bool, after: bool) -> str:
        if not self.returns_array(ret_tid):
            return ""
        (if after: ", " else: "") ++ (if named: "void* __with_ret" else: "void*")

    // The C return-type-plus-declarator of a function or fn-pointer shape:
    // `void` when the array goes through the out-pointer, the declarator
    // inside the type for a pointer-to-array, the plain type otherwise.
    mut fn return_decl(ret_tid: i32, declarator: &str) -> str:
        if self.returns_array(ret_tid):
            return "void " ++ declarator
        if self.type_is_pointer_to_array(ret_tid):
            return self.c_decl(ret_tid, declarator)
        self.c_type(ret_tid, 1) ++ " " ++ declarator

    fn list_element_tid(tid: i32) -> i32:
        let resolved = self.sema.resolve_alias(tid)
        if self.sema.get_type_kind(resolved) != TypeKind.TY_GENERIC_INST:
            return 0
        let base_sym = self.sema.get_generic_inst_base(resolved as i32)
        let base_name = cc_intern_resolve(self.intern, base_sym)
        if base_name != "List":
            return 0
        if self.sema.get_generic_inst_arg_count(resolved as i32) <= 0:
            return 0
        self.sema.get_generic_inst_arg(resolved as i32, 0)

    fn list_synthetic_field_tid(list_tid: i32, field_sym: i32) -> i32:
        let resolved = self.sema.resolve_alias(list_tid as TypeId) as i32
        if self.sema.get_type_kind(resolved as TypeId) != TypeKind.TY_GENERIC_INST:
            return 0
        if self.generic_inst_base_name(resolved) != "List":
            return 0
        let field_name = cc_intern_resolve(self.intern, field_sym)
        if field_name == "len" or field_name == "cap" or field_name == "start":
            return self.sema.ty_i64 as i32
        if field_name != "ptr":
            return 0
        let elem_tid = self.list_element_tid(resolved)
        if elem_tid == 0 or self.is_void_tid(elem_tid) != 0:
            return 0
        let const_ptr = self.sema.find_exact_type(TypeKind.TY_PTR, elem_tid, 0, 0) as i32
        if const_ptr != 0:
            return const_ptr
        let mut_ptr = self.sema.find_exact_type(TypeKind.TY_PTR, elem_tid, 1, 0) as i32
        if mut_ptr != 0:
            return mut_ptr
        self.sema.find_exact_type(TypeKind.TY_PTR, elem_tid, 0, 0) as i32

    mut fn list_new_elem_size_text(body: &MirBody, dest_place: i32) -> str:
        var list_tid = self.place_tid_no_infer(body, dest_place)
        var elem_tid = self.list_element_tid(list_tid)
        if elem_tid == 0 or self.is_void_tid(elem_tid) != 0:
            list_tid = self.call_dest_expected_tid(body, dest_place)
            elem_tid = self.list_element_tid(list_tid)
        if elem_tid == 0 or self.is_void_tid(elem_tid) != 0:
            let dst_local = self.place_local_id(body, dest_place)
            elem_tid = self.list_local_element_tid(body, dst_local)
        if elem_tid == 0 or self.is_void_tid(elem_tid) != 0:
            "0"
        else:
            "sizeof(" ++ self.c_type(elem_tid, 0) ++ ")"

    fn generic_inst_base_name(tid: i32) -> str:
        let resolved = self.sema.resolve_alias(tid)
        if self.sema.get_type_kind(resolved) != TypeKind.TY_GENERIC_INST:
            return ""
        let base_sym = self.sema.get_generic_inst_base(resolved as i32)
        cc_intern_resolve(self.intern, base_sym)

    fn generic_inst_needs_struct_def(tid: i32) -> i32:
        let base_name = self.generic_inst_base_name(tid)
        if base_name == "ListSlot":
            return 1
        if base_name == "ListIter":
            return 1
        if base_name == "ListIterPlace":
            return 1
        if base_name == "HashMapEntry":
            return 1
        if base_name == "Handle":
            return 1
        if base_name == "SlotMapSlot":
            return 1
        if base_name == "Atomic":
            return 1
        0

    // An instance of a declared generic struct (`Wrap[str]`, std's
    // `Box[Node]`, `BTreeMap[i32, str]`): Sema's reflection names its fields
    // and their instantiated types. The containers the C backend models
    // itself (List, HashMap, HashSet, SlotMap, the synthetic structs above)
    // and payload enums have their own representations (#1562).
    fn generic_inst_is_declared_struct(tid: i32) -> bool:
        let resolved = self.sema.resolve_alias(tid)
        if self.sema.get_type_kind(resolved) != TypeKind.TY_GENERIC_INST or self.std_box_pointee_tid(resolved as i32) != 0:
            return false
        if self.generic_inst_needs_struct_def(resolved as i32) != 0 or self.type_is_payload_enum(resolved as i32) != 0:
            return false
        let base_name = self.generic_inst_base_name(resolved as i32)
        if base_name == "List" or base_name == "HashMap" or base_name == "HashSet" or base_name == "SlotMap":
            return false
        let base_tid = self.sema.generic_inst_template_tid(resolved as i32)
        base_tid != 0 and self.sema.get_type_kind(self.sema.resolve_alias(base_tid as TypeId)) == TypeKind.TY_STRUCT

    // std's `Box[T]` is the pointer to its T, as it is for Sema, MIR (a Box
    // place dereferences; Box.new casts its `*mut T` to the Box) and the
    // LLVM backend (sema_type_to_llvm): its T, or 0 for any other type.
    fn std_box_pointee_tid(tid: i32) -> i32:
        let resolved = self.sema.resolve_alias(tid)
        if self.sema.type_is_std_box_inst(resolved as i32) == 0:
            return 0
        self.sema.get_generic_inst_arg(resolved as i32, 0)

    // The instantiated type of a declared generic struct's field, or 0.
    fn generic_struct_field_tid(tid: i32, field_sym: i32) -> i32:
        let resolved = self.sema.resolve_alias(tid) as i32
        for fi in 0..self.sema.type_reflection_field_count(resolved):
            if self.sema.type_reflection_field_name(resolved, fi) == field_sym:
                return self.sema.type_reflection_field_type_frozen(resolved, fi)
        0

    // A type the C output holds by value as a struct, so a struct containing
    // it must follow its definition.
    // The struct a by-value member needs complete before its record: the
    // member's own, or a fixed array's element (`tab[265]` of a record); 0
    // when the member holds no struct by value.
    fn c_value_member_struct_tid(tid: i32) -> i32:
        var cur = self.sema.resolve_alias(tid as TypeId) as i32
        while self.sema.get_type_kind(cur as TypeId) == TypeKind.TY_ARRAY:
            cur = self.sema.resolve_alias(self.sema.get_type_d0(cur as TypeId) as TypeId) as i32
        if self.tid_is_c_struct_value(cur): cur else: 0

    fn tid_is_c_struct_value(tid: i32) -> bool:
        let resolved = self.sema.resolve_alias(tid as TypeId) as i32
        let kind = self.sema.get_type_kind(resolved as TypeId)
        if self.option_is_nullable_pointer(resolved):
            return false
        kind == TypeKind.TY_STRUCT or kind == TypeKind.TY_TUPLE or self.type_is_payload_enum(resolved) != 0 or self.generic_inst_is_declared_struct(resolved)

    // A field of a generic instance: a declared struct's own field, or a
    // field the backend synthesizes for a modeled container (List's ptr/len).
    fn generic_inst_field_tid(tid: i32, field_sym: i32) -> i32:
        if self.generic_inst_is_declared_struct(tid): self.generic_struct_field_tid(tid, field_sym) else: self.list_synthetic_field_tid(tid, field_sym)

    fn listslot_element_tid(tid: i32) -> i32:
        let resolved = self.sema.resolve_alias(tid)
        if self.sema.get_type_kind(resolved) != TypeKind.TY_GENERIC_INST:
            return 0
        if self.generic_inst_base_name(resolved as i32) != "ListSlot":
            return 0
        if self.sema.get_generic_inst_arg_count(resolved as i32) <= 0:
            return 0
        self.sema.get_generic_inst_arg(resolved as i32, 0)

    fn hashmap_value_tid(tid: i32) -> i32:
        let resolved = self.sema.resolve_alias(tid)
        if self.sema.get_type_kind(resolved) != TypeKind.TY_GENERIC_INST:
            return 0
        if self.generic_inst_base_name(resolved as i32) != "HashMap":
            return 0
        if self.sema.get_generic_inst_arg_count(resolved as i32) < 2:
            return 0
        self.sema.get_generic_inst_arg(resolved as i32, 1)

    fn hashmap_key_tid(tid: i32) -> i32:
        let resolved = self.sema.resolve_alias(tid)
        if self.sema.get_type_kind(resolved) != TypeKind.TY_GENERIC_INST:
            return 0
        let base = self.generic_inst_base_name(resolved as i32)
        if base == "HashSet":
            if self.sema.get_generic_inst_arg_count(resolved as i32) < 1:
                return 0
            return self.sema.get_generic_inst_arg(resolved as i32, 0)
        if base != "HashMap":
            return 0
        if self.sema.get_generic_inst_arg_count(resolved as i32) < 2:
            return 0
        self.sema.get_generic_inst_arg(resolved as i32, 0)

    mut fn map_call_key_tid(body: &MirBody, args_id: i32, key_operand: i32) -> i32:
        // The map's storage key size is fixed by the receiver's key type at
        // with_hashmap_new time; a narrower key operand (i32 literal into a
        // HashSet[i32] whose new-path sized keys as i64) would make insert
        // and contains read different garbage bytes. Prefer the receiver's
        // canonical key type, like the LLVM backend's key coercion.
        var key_tid = self.hashmap_key_tid(self.operand_tid(body, self.call_arg_operand(body, args_id, 0)))
        if key_tid == 0:
            key_tid = self.operand_tid(body, key_operand)
        if key_tid == 0 or self.is_void_tid(key_tid) != 0:
            key_tid = self.sema.ty_i64 as i32
        key_tid

    fn option_tid_for_payload(payload_tid: i32) -> i32:
        if payload_tid == 0 or self.is_void_tid(payload_tid) != 0:
            return 0
        let args: List[i32] = List.new()
        args.push(payload_tid)
        self.sema.find_generic_inst_type(self.sema.syms.option, args, 1) as i32

    fn option_ref_tid_for_payload(payload_tid: i32) -> i32:
        if payload_tid == 0 or self.is_void_tid(payload_tid) != 0:
            return 0
        let ref_tid = self.sema.find_exact_type(TypeKind.TY_REF, payload_tid, 0, 0) as i32
        if ref_tid == 0:
            return 0
        self.option_tid_for_payload(ref_tid)

    mut fn call_hashmap_get_option_tid(body: &MirBody, args_id: i32) -> i32:
        let recv_operand = self.call_arg_operand(body, args_id, 0)
        var value_tid = self.hashmap_value_tid(self.operand_tid(body, recv_operand))
        if value_tid == 0:
            value_tid = self.call_hashmap_value_tid_from_usage(body, args_id)
        self.option_ref_tid_for_payload(value_tid)

    mut fn call_hashmap_value_tid_from_usage(body: &MirBody, args_id: i32) -> i32:
        let recv_operand = self.call_arg_operand(body, args_id, 0)
        let recv_text = self.operand_text(body, recv_operand)
        if recv_text.len() == 0:
            return 0
        var out: i32 = 0
        for bb in 0..body.block_count():
            if body.term_kind(bb) != TermKind.TK_CALL:
                continue
            let callee_operand = body.term_data0(bb)
            let call_args_id = body.term_data1(bb)
            let dest_place = body.term_data2(bb)
            if self.call_builtin_kind(body, callee_operand, call_args_id, dest_place) != CcBuiltin.MAP_INSERT:
                continue
            if self.call_arg_count(body, call_args_id) < 3:
                continue
            let insert_recv = self.operand_text(body, self.call_arg_operand(body, call_args_id, 0))
            if insert_recv != recv_text:
                continue
            let value_tid = self.operand_tid(body, self.call_arg_operand(body, call_args_id, 2))
            if value_tid == 0 or self.is_void_tid(value_tid) != 0:
                continue
            if out == 0:
                out = value_tid
            else if self.strict_type_match(out, value_tid) == 0:
                return 0
        out

    mut fn list_local_element_tid(body: &MirBody, local_id: i32) -> i32:
        if local_id < 0:
            return 0
        var out: i32 = 0
        for bb in 0..body.block_count():
            let start = body.bb_stmt_starts[bb]
            let count = body.bb_stmt_counts[bb]
            for si in 0..count:
                let stmt_id = start + si
                if body.stmt_kinds[stmt_id] != StmtKind.Assign:
                    continue
                let dst_place = body.stmt_d0[stmt_id]
                if self.place_is_direct_local(body, dst_place, local_id) == 0:
                    continue
                let rval_id = body.stmt_d1[stmt_id]
                if rval_id < 0 or rval_id >= body.rval_kinds.len():
                    continue
                if body.rval_kinds[rval_id] != RvalueKind.RK_USE:
                    continue
                let src_operand = body.rval_d0[rval_id]
                if src_operand >= 0 and src_operand < body.operand_kinds.len():
                    let src_ok = body.operand_kinds[src_operand]
                    if src_ok == OperandKind.OK_COPY or src_ok == OperandKind.OK_MOVE:
                        let src_place = body.operand_d0[src_operand]
                        if self.place_is_direct_local(body, src_place, local_id) != 0:
                            continue
                let src_elem_tid = self.list_element_tid(self.operand_tid(body, src_operand))
                if src_elem_tid == 0 or self.is_void_tid(src_elem_tid) != 0:
                    continue
                if out == 0:
                    out = src_elem_tid
                else if self.strict_type_match(out, src_elem_tid) == 0:
                    return 0
            if body.term_kind(bb) != TermKind.TK_CALL:
                continue
            let args_id = body.term_data1(bb)
            if cc_builtin_from_mir_intrinsic(body.call_intrinsic(args_id)) != CcBuiltin.LIST_PUSH:
                continue
            if self.call_arg_count(body, args_id) < 2:
                continue
            let recv_place = self.call_first_arg_place_id(body, args_id)
            if self.place_is_direct_local(body, recv_place, local_id) == 0:
                continue
            let elem_tid = self.operand_tid(body, self.call_arg_operand(body, args_id, 1))
            if elem_tid == 0 or self.is_void_tid(elem_tid) != 0:
                continue
            if out == 0:
                out = elem_tid
            else if self.strict_type_match(out, elem_tid) == 0:
                return 0
        out

    fn place_local_id(body: &MirBody, place_id: i32) -> i32:
        if place_id < 0 or place_id >= body.place_locals.len():
            return 0
        body.place_locals[place_id]

    fn local_declared_tid(body: &MirBody, local_id: i32) -> i32:
        if local_id < 0 or local_id >= body.local_type_ids.len():
            return 0
        let declared = body.local_type_ids[local_id]
        if local_id <= 0:
            return declared
        if self.is_void_tid(declared) == 0:
            return declared
        let sig_idx = self.body_sig_index(body.fn_sym)
        if sig_idx < 0:
            return declared
        let param_count = self.sema.sig_get_param_count(sig_idx)
        if local_id >= 1 and local_id <= param_count:
            return self.sema.sig_param_type(sig_idx, local_id - 1)
        declared

    mut fn local_effective_tid(body: &MirBody, local_id: i32) -> i32:
        let declared = self.local_declared_tid(body, local_id)
        if local_id <= 0:
            return declared
        if self.local_global_sym(body, local_id) != 0:
            return declared
        if self.in_field_cache_build != 0:
            return declared
        let cache_key = cc_body_local_cache_key(body.fn_sym, local_id)
        let cached = self.local_effective_cache.get(cache_key)
        if cached.is_some():
            return cached.unwrap()
        // A closure body's captures and parameters (locals 1..n_params)
        // have the types its retained MIR declares (#1766).
        if local_id <= self.body_param_count(body):
            self.local_effective_cache.insert(cache_key, declared)
            return declared
        let declared_resolved = self.sema.resolve_alias(declared)
        let declared_kind = self.sema.get_type_kind(declared_resolved)
        let call_ret = self.local_direct_call_return_tid(body, local_id)
        if call_ret != 0 and self.is_void_tid(call_ret) == 0:
            let call_ret_resolved = self.sema.resolve_alias(call_ret)
            let call_ret_kind = self.sema.get_type_kind(call_ret_resolved)
            if self.type_is_payload_enum(call_ret) != 0:
                self.local_effective_cache.insert(cache_key, call_ret)
                return call_ret
            if self.is_void_tid(declared) != 0 or declared_resolved == 0 or declared_kind == TypeKind.TY_ERR:
                self.local_effective_cache.insert(cache_key, call_ret)
                return call_ret
            if declared_kind != call_ret_kind or self.strict_type_match(declared, call_ret) == 0:
                if declared_kind == TypeKind.TY_GENERIC_INST and call_ret_kind == TypeKind.TY_GENERIC_INST:
                    self.local_effective_cache.insert(cache_key, call_ret)
                    return call_ret
        let copied_payload_enum_tid = self.local_copied_payload_enum_tid(body, local_id)
        if copied_payload_enum_tid != 0 and self.is_void_tid(copied_payload_enum_tid) == 0:
            self.local_effective_cache.insert(cache_key, copied_payload_enum_tid)
            return copied_payload_enum_tid
        let downcast_opt_tid = self.local_payload_downcast_option_tid(body, local_id)
        if downcast_opt_tid != 0 and self.is_void_tid(downcast_opt_tid) == 0:
            self.local_effective_cache.insert(cache_key, downcast_opt_tid)
            return downcast_opt_tid
        if self.is_void_tid(declared) == 0 and (declared_resolved == 0 or declared_kind != TypeKind.TY_ERR):
            if declared_kind == TypeKind.TY_GENERIC_INST:
                let inferred_generic = self.infer_local_tid(body, local_id)
                if inferred_generic != 0 and self.is_void_tid(inferred_generic) == 0 and self.type_is_payload_enum(inferred_generic) != 0:
                    self.local_effective_cache.insert(cache_key, inferred_generic)
                    return inferred_generic
            self.local_effective_cache.insert(cache_key, declared)
            return declared
        let inferred = self.infer_local_tid(body, local_id)
        if inferred != 0 and self.is_void_tid(inferred) == 0:
            self.local_effective_cache.insert(cache_key, inferred)
            return inferred
        self.local_effective_cache.insert(cache_key, declared)
        declared

    fn local_struct_collection_tid(body: &MirBody, local_id: i32) -> i32:
        let declared = self.local_declared_tid(body, local_id)
        if local_id <= 0:
            return declared
        if self.local_global_sym(body, local_id) != 0:
            return declared
        let sig_idx = self.body_sig_index(body.fn_sym)
        let param_count = if sig_idx >= 0: self.sema.sig_get_param_count(sig_idx) else: 0
        if local_id <= param_count:
            return declared
        if self.is_void_tid(declared) == 0:
            let resolved = self.sema.resolve_alias(declared)
            let kind = self.sema.get_type_kind(resolved)
            if resolved == 0 or kind != TypeKind.TY_ERR:
                return declared
        declared

    mut fn local_direct_call_return_tid(body: &MirBody, local_id: i32) -> i32:
        if local_id < 0:
            return 0
        let cache_key = cc_body_local_cache_key(body.fn_sym, local_id)
        let cached = self.local_call_ret_cache.get(cache_key)
        if cached.is_some():
            let value = cached.unwrap()
            if value < 0:
                return 0
            return value
        self.local_call_ret_cache.insert(cache_key, -1)
        var out: i32 = 0
        for bb in 0..body.block_count():
            if body.term_kind(bb) != TermKind.TK_CALL:
                continue
            let dest_place = body.term_data2(bb)
            if self.place_is_direct_local(body, dest_place, local_id) == 0:
                continue
            let args_id = body.term_data1(bb)
            let callee_operand = body.term_data0(bb)
            let intrinsic = body.call_intrinsic(args_id)
            let intrinsic_kind = cc_builtin_from_mir_intrinsic(intrinsic)
            let kind = if intrinsic_kind != CcBuiltin.NONE:
                intrinsic_kind
            else:
                self.call_builtin_kind(body, callee_operand, args_id, dest_place)
            let ret_tid = self.call_builtin_ret_tid(body, callee_operand, args_id, dest_place)
            if ret_tid == 0 or self.is_void_tid(ret_tid) != 0:
                continue
            if self.type_is_payload_enum(ret_tid) == 0:
                continue
            if out == 0:
                out = ret_tid
            else if self.strict_type_match(out, ret_tid) == 0:
                out = 0
                break
        self.local_call_ret_cache.insert(cache_key, out)
        out

    mut fn local_copied_payload_enum_tid(body: &MirBody, local_id: i32) -> i32:
        if local_id < 0:
            return 0
        let cache_key = cc_body_local_cache_key(body.fn_sym, local_id)
        let cached = self.local_copied_payload_cache.get(cache_key)
        if cached.is_some():
            let value = cached.unwrap()
            if value < 0:
                return 0
            return value
        self.local_copied_payload_cache.insert(cache_key, -1)
        var out: i32 = 0
        for bb in 0..body.block_count():
            let start = body.bb_stmt_starts[bb]
            let count = body.bb_stmt_counts[bb]
            for si in 0..count:
                let stmt_id = start + si
                if body.stmt_kinds[stmt_id] != StmtKind.Assign:
                    continue
                let dst_place = body.stmt_d0[stmt_id]
                if self.place_is_direct_local(body, dst_place, local_id) == 0:
                    continue
                let rval_id = body.stmt_d1[stmt_id]
                if rval_id < 0 or rval_id >= body.rval_kinds.len():
                    continue
                if body.rval_kinds[rval_id] != RvalueKind.RK_USE:
                    continue
                let src_operand = body.rval_d0[rval_id]
                if src_operand < 0 or src_operand >= body.operand_kinds.len():
                    continue
                let ok = body.operand_kinds[src_operand]
                if ok != OperandKind.OK_COPY and ok != OperandKind.OK_MOVE:
                    continue
                let src_place = body.operand_d0[src_operand]
                let src_local = self.place_local_id(body, src_place)
                if src_local < 0 or self.place_is_direct_local(body, src_place, src_local) == 0:
                    continue
                var src_tid = self.local_direct_call_return_tid(body, src_local)
                if src_tid == 0:
                    src_tid = self.local_payload_downcast_option_tid(body, src_local)
                if self.type_is_payload_enum(src_tid) == 0:
                    continue
                if out == 0:
                    out = src_tid
                else if self.strict_type_match(out, src_tid) == 0:
                    self.local_copied_payload_cache.insert(cache_key, -1)
                    return 0
        self.local_copied_payload_cache.insert(cache_key, out)
        out

    fn place_has_downcast(body: &MirBody, place_id: i32) -> bool:
        let _ = self
        if place_id < 0 or place_id >= body.place_locals.len():
            return false
        let start = body.place_proj_starts[place_id]
        let count = body.place_proj_counts[place_id]
        for i in 0..count:
            if body.proj_kinds[(start + i)] == ProjKind.PK_DOWNCAST:
                return true
        false

    // MIR declares the local's type: a payload enum other than Option
    // (`zip_current_entry(h)?`'s Result) is what its downcasts project, never
    // an Option of the type a payload is copied into. The Option guess typed
    // such a Result local Option[ZipEntry] and refused its Err downcast as a
    // unit variant (#2017).
    // A local MIR declares as an enum with payloads (an Option included) has
    // that type (D65): a downcast read through it never re-types it. Read
    // from `copy _7<as v1>.f0.*`, an `Option[&i32]` became `Option[i32]`,
    // the projection after the downcast ignored.
    fn local_declared_non_option_payload_enum(body: &MirBody, local_id: i32) -> bool:
        let declared = self.sema.resolve_alias(self.local_declared_tid(body, local_id) as TypeId) as i32
        self.type_is_payload_enum(declared) != 0

    mut fn local_payload_downcast_option_tid(body: &MirBody, local_id: i32) -> i32:
        if local_id < 0:
            return 0
        let cache_key = cc_body_local_cache_key(body.fn_sym, local_id)
        let cached = self.local_downcast_option_cache.get(cache_key)
        if cached.is_some():
            let value = cached.unwrap()
            if value < 0:
                return 0
            return value
        self.local_downcast_option_cache.insert(cache_key, -1)
        if self.local_declared_non_option_payload_enum(body, local_id):
            return 0
        var out: i32 = 0
        for bb in 0..body.block_count():
            let start = body.bb_stmt_starts[bb]
            let count = body.bb_stmt_counts[bb]
            for si in 0..count:
                let stmt_id = start + si
                if body.stmt_kinds[stmt_id] != StmtKind.Assign:
                    continue
                let rval_id = body.stmt_d1[stmt_id]
                if rval_id < 0 or rval_id >= body.rval_kinds.len():
                    continue
                if body.rval_kinds[rval_id] != RvalueKind.RK_USE:
                    continue
                let src_operand = body.rval_d0[rval_id]
                if src_operand < 0 or src_operand >= body.operand_kinds.len():
                    continue
                let ok = body.operand_kinds[src_operand]
                if ok != OperandKind.OK_COPY and ok != OperandKind.OK_MOVE:
                    continue
                let src_place = body.operand_d0[src_operand]
                if self.place_local_id(body, src_place) != local_id:
                    continue
                if not self.place_has_downcast(body, src_place):
                    continue
                let dst_tid = self.place_tid(body, body.stmt_d0[stmt_id])
                let opt_tid = self.option_tid_for_payload(dst_tid)
                if opt_tid == 0:
                    continue
                if out == 0:
                    out = opt_tid
                else if self.strict_type_match(out, opt_tid) == 0:
                    self.local_downcast_option_cache.insert(cache_key, -1)
                    return 0
        self.local_downcast_option_cache.insert(cache_key, out)
        out

fn cc_zero_i32_list(count: i32) -> List[i32]:
    let out: List[i32] = List.new()
    for i in 0..count:
        out.push(0)
    out

fn cc_list_tid_at(values: &List[i32], local_id: i32) -> i32:
    if local_id < 0 or local_id >= values.len():
        return 0
    let value = values[local_id]
    if value < 0:
        return 0
    value

impl CCodegen:
    fn record_local_tid(values: List[i32], local_id: i32, tid: i32) -> List[i32]:
        if local_id < 0 or local_id >= values.len():
            return values
        if tid == 0 or self.is_void_tid(tid) != 0:
            return values
        let current = values[local_id]
        if current < 0:
            return values
        if current == 0:
            values[local_id] = tid
            return values
        if self.strict_type_match(current, tid) == 0:
            values[local_id] = -1
        values

    mut fn body_downcast_option_tids(body: &MirBody) -> List[i32]:
        var out = cc_zero_i32_list(body.local_count())
        for bb in 0..body.block_count():
            let start = body.bb_stmt_starts[bb]
            let count = body.bb_stmt_counts[bb]
            for si in 0..count:
                let stmt_id = start + si
                if body.stmt_kinds[stmt_id] != StmtKind.Assign:
                    continue
                let rval_id = body.stmt_d1[stmt_id]
                if rval_id < 0 or rval_id >= body.rval_kinds.len():
                    continue
                if body.rval_kinds[rval_id] != RvalueKind.RK_USE:
                    continue
                let src_operand = body.rval_d0[rval_id]
                if src_operand < 0 or src_operand >= body.operand_kinds.len():
                    continue
                let ok = body.operand_kinds[src_operand]
                if ok != OperandKind.OK_COPY and ok != OperandKind.OK_MOVE:
                    continue
                let src_place = body.operand_d0[src_operand]
                if not self.place_has_downcast(body, src_place):
                    continue
                let src_local = self.place_local_id(body, src_place)
                if src_local < 0 or self.local_declared_non_option_payload_enum(body, src_local):
                    continue
                let dst_tid = self.place_tid(body, body.stmt_d0[stmt_id])
                let opt_tid = self.option_tid_for_payload(dst_tid)
                out = self.record_local_tid(move out, src_local, opt_tid)
        out

    mut fn body_copied_payload_enum_tids(body: &MirBody, downcast_option_tids: &List[i32]) -> List[i32]:
        var out = cc_zero_i32_list(body.local_count())
        for bb in 0..body.block_count():
            let start = body.bb_stmt_starts[bb]
            let count = body.bb_stmt_counts[bb]
            for si in 0..count:
                let stmt_id = start + si
                if body.stmt_kinds[stmt_id] != StmtKind.Assign:
                    continue
                let dst_place = body.stmt_d0[stmt_id]
                let dst_local = self.place_local_id(body, dst_place)
                if self.place_is_direct_local(body, dst_place, dst_local) == 0:
                    continue
                let rval_id = body.stmt_d1[stmt_id]
                if rval_id < 0 or rval_id >= body.rval_kinds.len():
                    continue
                if body.rval_kinds[rval_id] != RvalueKind.RK_USE:
                    continue
                let src_operand = body.rval_d0[rval_id]
                if src_operand < 0 or src_operand >= body.operand_kinds.len():
                    continue
                let ok = body.operand_kinds[src_operand]
                if ok != OperandKind.OK_COPY and ok != OperandKind.OK_MOVE:
                    continue
                let src_place = body.operand_d0[src_operand]
                let src_local = self.place_local_id(body, src_place)
                if src_local < 0 or self.place_is_direct_local(body, src_place, src_local) == 0:
                    continue
                var src_tid = self.local_direct_call_return_tid(body, src_local)
                if src_tid == 0:
                    src_tid = cc_list_tid_at(downcast_option_tids, src_local)
                if self.type_is_payload_enum(src_tid) == 0:
                    continue
                out = self.record_local_tid(move out, dst_local, src_tid)
        out

    mut fn body_ref_target_tids(body: &MirBody) -> List[i32]:
        var out = cc_zero_i32_list(body.local_count())
        for li in 0..body.local_count():
            out = self.record_local_tid(move out, li, self.local_ref_target_tid(body, li))
        out

    fn place_local_tid(body: &MirBody, place_id: i32) -> i32:
        let local_id = self.place_local_id(body, place_id)
        self.local_declared_tid(body, local_id)

    fn place_is_direct_local(body: &MirBody, place_id: i32, local_id: i32) -> i32:
        let _ = self
        if place_id < 0 or place_id >= body.place_locals.len():
            return 0
        if body.place_locals[place_id] != local_id:
            return 0
        if body.place_proj_counts[place_id] != 0:
            return 0
        1

    fn place_uses_local(body: &MirBody, place_id: i32, local_id: i32) -> i32:
        let _ = self
        if place_id < 0 or place_id >= body.place_locals.len():
            return 0
        if body.place_locals[place_id] == local_id:
            return 1
        0

    fn local_is_read(body: &MirBody, local_id: i32) -> i32:
        if local_id < 0:
            return 0
        for oi in 0..body.operand_kinds.len():
            let ok = body.operand_kinds[oi]
            if ok != OperandKind.OK_COPY and ok != OperandKind.OK_MOVE:
                continue
            let place_id = body.operand_d0[oi]
            if self.place_uses_local(body, place_id, local_id) != 0:
                return 1
        0

    fn operand_uses_local(body: &MirBody, operand_id: i32, local_id: i32) -> i32:
        if operand_id < 0 or operand_id >= body.operand_kinds.len():
            return 0
        let ok = body.operand_kinds[operand_id]
        if ok != OperandKind.OK_COPY and ok != OperandKind.OK_MOVE:
            return 0
        let place_id = body.operand_d0[operand_id]
        self.place_uses_local(body, place_id, local_id)

    fn operand_direct_local_id(body: &MirBody, operand_id: i32) -> i32:
        if operand_id < 0 or operand_id >= body.operand_kinds.len():
            return -1
        let ok = body.operand_kinds[operand_id]
        if ok != OperandKind.OK_COPY and ok != OperandKind.OK_MOVE:
            return -1
        let place_id = body.operand_d0[operand_id]
        let local_id = self.place_local_id(body, place_id)
        if self.place_is_direct_local(body, place_id, local_id) == 0:
            return -1
        local_id

    fn rvalue_uses_local(body: &MirBody, rval_id: i32, local_id: i32) -> i32:
        if rval_id < 0 or rval_id >= body.rval_kinds.len():
            return 0
        let rk = body.rval_kinds[rval_id]
        let d0 = body.rval_d0[rval_id]
        let d1 = body.rval_d1[rval_id]
        let d2 = body.rval_d2[rval_id]
        if rk == RvalueKind.RK_USE:
            return self.operand_uses_local(body, d0, local_id)
        if rk == RvalueKind.RK_ARRAY_FILL:
            return self.operand_uses_local(body, d0, local_id)
        if rk == RvalueKind.RK_BIN_OP:
            if self.operand_uses_local(body, d1, local_id) != 0:
                return 1
            return self.operand_uses_local(body, d2, local_id)
        if rk == RvalueKind.RK_STR_CONCAT_N:
            if d0 < 0 or d0 >= body.call_arg_starts.len():
                return 0
            let start = body.call_arg_starts[d0]
            let count = body.call_arg_counts[d0]
            for i in 0..count:
                if self.operand_uses_local(body, body.call_arg_operands[(start + i)], local_id) != 0:
                    return 1
            return 0
        if rk == RvalueKind.RK_UN_OP:
            return self.operand_uses_local(body, d1, local_id)
        if rk == RvalueKind.RK_REF or rk == RvalueKind.RK_ADDR_OF or rk == RvalueKind.RK_DISCRIMINANT or rk == RvalueKind.RK_LEN:
            return self.place_uses_local(body, d0, local_id)
        if rk == RvalueKind.RK_SLICE:
            if self.place_uses_local(body, d0, local_id) != 0:
                return 1
            if self.operand_uses_local(body, d1, local_id) != 0:
                return 1
            return self.operand_uses_local(body, d2, local_id)
        if rk == RvalueKind.RK_CAST:
            return self.operand_uses_local(body, d0, local_id)
        if rk == RvalueKind.RK_AGGREGATE:
            let fields_id = body.rval_d1[rval_id]
            if fields_id < 0 or fields_id >= body.agg_field_starts.len():
                return 0
            let start = body.agg_field_starts[fields_id]
            let count = body.agg_field_counts[fields_id]
            for i in 0..count:
                if self.operand_uses_local(body, body.agg_field_operands[(start + i)], local_id) != 0:
                    return 1
        0

    fn local_value_use_mark_place(body: &MirBody, place_id: i32):
        let local_id = self.place_local_id(body, place_id)
        if local_id < 0:
            return
        self.local_value_use_cache.insert(cc_body_local_cache_key(body.fn_sym, local_id), 1)

    fn local_value_use_mark_operand(body: &MirBody, operand_id: i32):
        if operand_id < 0 or operand_id >= body.operand_kinds.len():
            return
        let ok = body.operand_kinds[operand_id]
        if ok != OperandKind.OK_COPY and ok != OperandKind.OK_MOVE:
            return
        self.local_value_use_mark_place(body, body.operand_d0[operand_id])

    fn local_value_use_mark_rvalue(body: &MirBody, rval_id: i32):
        if rval_id < 0 or rval_id >= body.rval_kinds.len():
            return
        let rk = body.rval_kinds[rval_id]
        let d0 = body.rval_d0[rval_id]
        let d1 = body.rval_d1[rval_id]
        let d2 = body.rval_d2[rval_id]
        if rk == RvalueKind.RK_USE:
            self.local_value_use_mark_operand(body, d0)
            return
        if rk == RvalueKind.RK_ARRAY_FILL:
            self.local_value_use_mark_operand(body, d0)
            return
        if rk == RvalueKind.RK_BIN_OP:
            self.local_value_use_mark_operand(body, d1)
            self.local_value_use_mark_operand(body, d2)
            return
        if rk == RvalueKind.RK_STR_CONCAT_N:
            if d0 < 0 or d0 >= body.call_arg_starts.len():
                return
            let start = body.call_arg_starts[d0]
            let count = body.call_arg_counts[d0]
            for i in 0..count:
                self.local_value_use_mark_operand(body, body.call_arg_operands[(start + i)])
            return
        if rk == RvalueKind.RK_UN_OP:
            self.local_value_use_mark_operand(body, d1)
            return
        if rk == RvalueKind.RK_REF or rk == RvalueKind.RK_ADDR_OF or rk == RvalueKind.RK_DISCRIMINANT or rk == RvalueKind.RK_LEN:
            self.local_value_use_mark_place(body, d0)
            return
        if rk == RvalueKind.RK_SLICE:
            self.local_value_use_mark_place(body, d0)
            self.local_value_use_mark_operand(body, d1)
            self.local_value_use_mark_operand(body, d2)
            return
        if rk == RvalueKind.RK_CAST:
            self.local_value_use_mark_operand(body, d0)
            return
        if rk == RvalueKind.RK_AGGREGATE:
            let fields_id = body.rval_d1[rval_id]
            if fields_id < 0 or fields_id >= body.agg_field_starts.len():
                return
            let start = body.agg_field_starts[fields_id]
            let count = body.agg_field_counts[fields_id]
            for i in 0..count:
                self.local_value_use_mark_operand(body, body.agg_field_operands[(start + i)])

    fn local_value_use_populate(body: &MirBody):
        for li in 0..body.local_count():
            self.local_value_use_cache.insert(cc_body_local_cache_key(body.fn_sym, li), 0)
        for bb in 0..body.block_count():
            let start = body.bb_stmt_starts[bb]
            let count = body.bb_stmt_counts[bb]
            for si in 0..count:
                let stmt_id = start + si
                if body.stmt_kinds[stmt_id] == StmtKind.Assign:
                    self.local_value_use_mark_rvalue(body, body.stmt_d1[stmt_id])
            let tk = body.term_kind(bb)
            if tk == TermKind.TK_SWITCH_INT:
                self.local_value_use_mark_operand(body, body.term_data0(bb))
            else if tk == TermKind.TK_CALL:
                self.local_value_use_mark_operand(body, body.term_data0(bb))
                let args_id = body.term_data1(bb)
                let argc = self.call_arg_count(body, args_id)
                for ai in 0..argc:
                    self.local_value_use_mark_operand(body, self.call_arg_operand(body, args_id, ai))
            else if tk == TermKind.TK_DROP_AND_GOTO:
                self.local_value_use_mark_place(body, body.term_data0(bb))
            else if tk == TermKind.TK_RETURN:
                // The return reads `_0`: a body that returns an aggregate
                // built straight into its result (a gen fn's state, D69)
                // is not a dead temp (#1766: nums(3) returned zeroes).
                self.local_value_use_cache.insert(cc_body_local_cache_key(body.fn_sym, 0), 1)

    fn local_has_value_use(body: &MirBody, local_id: i32) -> i32:
        if local_id < 0:
            return 0
        let cache_key = cc_body_local_cache_key(body.fn_sym, local_id)
        let cached = self.local_value_use_cache.get(cache_key)
        if cached.is_some():
            return cached.unwrap()
        self.local_value_use_populate(body)
        let populated = self.local_value_use_cache.get(cache_key)
        if populated.is_some():
            return populated.unwrap()
        0

    mut fn operand_tid(body: &MirBody, operand_id: i32) -> i32:
        if operand_id < 0 or operand_id >= body.operand_kinds.len():
            return 0
        let ok = body.operand_kinds[operand_id]
        let od = body.operand_d0[operand_id]
        if ok == OperandKind.OK_COPY or ok == OperandKind.OK_MOVE:
            return self.place_tid(body, od)
        if ok == OperandKind.OK_CONSTANT:
            if od < 0 or od >= body.const_types.len():
                return 0
            return body.const_types[od]
        0

    mut fn operand_tid_no_infer(body: &MirBody, operand_id: i32) -> i32:
        if operand_id < 0 or operand_id >= body.operand_kinds.len():
            return 0
        let ok = body.operand_kinds[operand_id]
        let od = body.operand_d0[operand_id]
        if ok == OperandKind.OK_COPY or ok == OperandKind.OK_MOVE:
            return self.place_tid_no_infer(body, od)
        if ok == OperandKind.OK_CONSTANT:
            if od < 0 or od >= body.const_types.len():
                return 0
            return body.const_types[od]
        0

    // #1810: whether `ref(borrow, place)` produces a `&str` view — a shared
    // borrow of a place laid out as str — rather than a pointer to the place.
    // A reference to a fn value is the {fn_ptr, ctx} pair itself, as c_type
    // spells `&fn(…)`: a view by value, like a `&str`.
    mut fn ref_rvalue_is_str_view(body: &MirBody, rval_id: i32) -> bool:
        if rval_id < 0 or rval_id >= body.rval_kinds.len() or body.rval_kinds[rval_id] != RvalueKind.RK_REF:
            return false
        let target = self.place_ref_target_tid(body, body.rval_d1[rval_id])
        if target > 0 and self.sema.get_type_kind(self.sema.resolve_alias(target as TypeId)) == TypeKind.TY_FN:
            return true
        if body.rval_d0[rval_id] == BorrowKind.EXCLUSIVE:
            return false
        self.sema.type_layout_repr_is_str(target)

    // The C lvalue of a bare local: a global's name, or the local's own
    // name, dereferenced when the local holds a pointer to its value — a
    // value-ref ABI parameter, or a closure capture by place or in an owned
    // cell (#1766), as the LLVM backend's indirect locals do.
    fn local_base_text(body: &MirBody, local_id: i32) -> str:
        let global_sym = self.local_global_sym(body, local_id)
        if global_sym != 0:
            return self.global_c_name(global_sym)
        if self.local_is_c_pointer_param(body, local_id) != 0 or self.local_is_indirect_capture(body, local_id):
            return f"(*_{local_id})"
        f"_{local_id}"

    mut fn place_text(body: &MirBody, place_id: i32) -> str:
        if place_id < 0 or place_id >= body.place_locals.len():
            self.fail(f"invalid place id {place_id}")
            return "_0"
        let base_local = body.place_locals[place_id]
        var out = self.local_base_text(body, base_local)
        var current_tid = self.local_effective_tid(body, base_local)
        if self.is_void_tid(current_tid) != 0:
            current_tid = self.place_local_tid(body, place_id)
        let start = body.place_proj_starts[place_id]
        let count = body.place_proj_counts[place_id]
        // A payload enum's downcast names its variant; the field after it is
        // that variant's payload field `pd` (MirCore's projection typing).
        var downcast_enum_tid: i32 = 0
        var downcast_variant: i32 = -1
        for i in 0..count:
            let pk = body.proj_kinds[(start + i)]
            let pd = body.proj_d0[(start + i)]
            let resolved = self.sema.resolve_alias(current_tid as TypeId)
            let tk = self.sema.get_type_kind(resolved)
            if pk == ProjKind.PK_FIELD and downcast_variant >= 0:
                out = out ++ self.payload_enum_field_path(downcast_enum_tid, downcast_variant, pd)
                current_tid = self.sema.type_reflection_variant_payload_type_frozen(downcast_enum_tid, downcast_variant, pd)
                downcast_variant = -1
                continue
            if pk == ProjKind.PK_FIELD:
                if tk == TypeKind.TY_TUPLE:
                    let field_idx = self.tuple_field_index(resolved as i32, pd)
                    let ft = self.tuple_field_tid(resolved as i32, field_idx)
                    if ft == 0:
                        self.fail("unsupported tuple field access in C backend")
                        current_tid = 0
                        continue
                    out = out ++ f".field{field_idx}"
                    current_tid = ft
                    continue
                if pd == 0:
                    continue
                if tk == TypeKind.TY_STR:
                    let field_name = cc_intern_resolve(self.intern, pd)
                    if field_name == "len":
                        out = out ++ ".len"
                        current_tid = self.sema.ty_i64 as i32
                        continue
                    if field_name == "ptr":
                        out = out ++ ".ptr"
                        current_tid = 0
                        continue
                    self.fail("unsupported str field access in C backend: " ++ field_name)
                    current_tid = 0
                    continue
                let field_name = cc_member(cc_intern_resolve(self.intern, pd))
                // A distinct type is its inner type in C (`typedef double
                // TotalF64`): `.value` is the same object, no member.
                if tk == TypeKind.TY_STRUCT and field_name == "value" and self.type_is_distinct(resolved as i32) != 0:
                    current_tid = self.struct_field_tid(resolved as i32, pd)
                    continue
                out = out ++ "." ++ field_name
                if tk == TypeKind.TY_STRUCT:
                    let ft_raw = self.struct_field_tid(resolved as i32, pd)
                    let ft = self.effective_field_tid(resolved as i32, pd, ft_raw)
                    current_tid = ft
                else if tk == TypeKind.TY_GENERIC_INST:
                    current_tid = self.generic_inst_field_tid(resolved as i32, pd)
                else:
                    current_tid = 0
                continue
            if pk == ProjKind.PK_INDEX:
                if tk == TypeKind.TY_STR:
                    out = f"{out}.ptr[_{pd}]"
                    current_tid = self.sema.ty_i32 as i32
                    continue
                if tk == TypeKind.TY_ARRAY:
                    out = f"{out}[_{pd}]"
                    current_tid = self.sema.get_type_d0(resolved)
                    continue
                if tk == TypeKind.TY_SLICE:
                    out = f"({out}).ptr[_{pd}]"
                    current_tid = self.sema.get_type_d0(resolved)
                    continue
                // List or other generic container: use with_vec_get_ptr runtime call
                let base_c = self.c_type(current_tid, 0)
                if base_c == "with_vec":
                    var elem_tid = self.list_element_tid(current_tid)
                    if elem_tid == 0:
                        elem_tid = self.list_local_element_tid(body, base_local)
                    let elem_c = if elem_tid != 0: self.c_type(elem_tid, 0) else: "int64_t"
                    out = "(*((" ++ elem_c ++ "*)with_vec_get_ptr_es(&(" ++ out ++ f"), (int64_t)(_{pd}), sizeof(" ++ elem_c ++ "))))"
                    current_tid = if elem_tid != 0: elem_tid else: self.sema.ty_i64 as i32
                    continue
                out = f"{out}[_{pd}]"
                current_tid = 0
                continue
            if pk == ProjKind.PK_DEREF:
                // A `&str` view is itself the str it names (#1810): its own
                // storage is the header, so there is nothing to dereference.
                let fn_view = tk == TypeKind.TY_REF and self.sema.get_type_kind(self.sema.resolve_alias(self.sema.get_type_d0(resolved) as TypeId)) == TypeKind.TY_FN
                if not self.sema.type_layout_is_str_view(resolved as i32) and not fn_view:
                    out = "(*" ++ out ++ ")"
                if tk == TypeKind.TY_PTR or tk == TypeKind.TY_REF:
                    current_tid = self.sema.get_type_d0(resolved)
                else:
                    current_tid = self.std_box_pointee_tid(resolved as i32)
                continue
            if pk == ProjKind.PK_DOWNCAST:
                if self.type_is_payload_enum(current_tid) != 0:
                    let payload_count = self.sema.type_reflection_variant_payload_count(current_tid, pd)
                    if payload_count == 0:
                        self.fail(f"payload downcast for unit variant {pd} of enum " ++ self.sema.type_name(current_tid))
                        current_tid = 0
                        continue
                    if i + 1 < count and body.proj_kinds[(start + i + 1)] == ProjKind.PK_FIELD:
                        downcast_enum_tid = current_tid
                        downcast_variant = pd
                        continue
                    // A trailing downcast names the variant's payload member:
                    // its one field, or its payload struct (#2017).
                    out = out ++ self.enum_payload_member(current_tid, pd)
                    current_tid = if payload_count == 1: self.sema.type_reflection_variant_payload_type_frozen(current_tid, pd, 0) else: 0
                    continue
                out = f"{out}/*downcast{pd}*/"
                current_tid = 0
                continue
            if pk == ProjKind.PK_TUPLE_INDEX:
                if tk == TypeKind.TY_TUPLE:
                    let elem_ft = self.tuple_field_tid(resolved as i32, pd)
                    if elem_ft == 0:
                        self.fail("unsupported tuple index access in C backend")
                        current_tid = 0
                        continue
                    out = out ++ f".field{pd}"
                    current_tid = elem_ft
                    continue
                if current_tid == 0:
                    // Unknown base type: tuples are emitted as field{N}
                    // structs, so render the member and let the C compiler
                    // reject it loudly if the base was not a tuple.
                    out = out ++ f".field{pd}"
                    continue
                self.fail("tuple index projection on non-tuple type in C backend")
                current_tid = 0
                continue
            self.fail(f"unsupported place projection kind {pk}")
        out

fn cc_hex_u64(value: i64) -> str:
    var out = ""
    var shift: i32 = 60
    var started = 0
    while shift >= 0:
        let nibble = (exact_int_logical_shr_word(value, shift) & 15) as i32
        if nibble != 0 or started != 0 or shift == 0:
            out = out ++ cc_hex_digit(nibble)
            started = 1
        if shift == 0:
            break
        shift = shift - 4
    out

fn cc_exact_uint_expr(lo: i64, hi: i64) -> str:
    if hi == 0:
        return "((uint64_t)0x" ++ cc_hex_u64(lo) ++ "ULL)"
    "((((unsigned __int128)0x" ++ cc_hex_u64(hi) ++ "ULL) << 64) | ((unsigned __int128)0x" ++ cc_hex_u64(lo) ++ "ULL))"

impl CCodegen:
    mut fn exact_int_const_text(body: &MirBody, const_id: i32) -> str:
        let node = body.const_d0[const_id]
        let tid = body.const_types[const_id]
        if tid == 0:
            return "0"
        let resolved = self.sema.resolve_alias(tid)
        let tk = self.sema.get_type_kind(resolved)
        let cty = self.c_type(tid, 0)
        if tk == TypeKind.TY_FLOAT:
            let expr = self.ast.int_literal_exact_expr(node)
            if expr.ok == 0 or expr.overflow != 0:
                return "0.0"
            let mag = exact_int_expr_magnitude(expr)
            let mag_text = cc_exact_uint_expr(mag.lo, mag.hi)
            if expr.negative != 0:
                return "(-((" ++ cty ++ ")(" ++ mag_text ++ ")))"
            return "((" ++ cty ++ ")(" ++ mag_text ++ "))"
        if tk != TypeKind.TY_INT and tk != TypeKind.TY_BOOL:
            return "0"
        let bits = if tk == TypeKind.TY_BOOL: 1 else: self.sema.get_type_d0(resolved)
        let signed = if tk == TypeKind.TY_INT: self.sema.get_type_d1(resolved) else: 0
        let words = self.ast.int_literal_expr_bits(node, bits, signed)
        if words.ok == 0 or words.overflow != 0:
            return "0"
        "((" ++ cty ++ ")(" ++ cc_exact_uint_expr(words.lo, words.hi) ++ "))"

    // An integer literal (or a negated one) as a C constant of `tid`, or ""
    // when `node` is not one: the global is then initialized at startup.
    mut fn exact_int_expr_text(node: i32, tid: i32) -> str:
        if tid == 0:
            return ""
        let resolved = self.sema.resolve_alias(tid)
        let tk = self.sema.get_type_kind(resolved)
        let cty = self.c_type(tid, 0)
        if tk == TypeKind.TY_FLOAT:
            let expr = self.ast.int_literal_exact_expr(node)
            if expr.ok == 0 or expr.overflow != 0:
                return ""
            let mag = exact_int_expr_magnitude(expr)
            let mag_text = cc_exact_uint_expr(mag.lo, mag.hi)
            if expr.negative != 0:
                return "(-((" ++ cty ++ ")(" ++ mag_text ++ ")))"
            return "((" ++ cty ++ ")(" ++ mag_text ++ "))"
        if tk != TypeKind.TY_INT and tk != TypeKind.TY_BOOL:
            return ""
        let bits = if tk == TypeKind.TY_BOOL: 1 else: self.sema.get_type_d0(resolved)
        let signed = if tk == TypeKind.TY_INT: self.sema.get_type_d1(resolved) else: 0
        let words = self.ast.int_literal_expr_bits(node, bits, signed)
        if words.ok == 0 or words.overflow != 0:
            return ""
        "((" ++ cty ++ ")(" ++ cc_exact_uint_expr(words.lo, words.hi) ++ "))"

    mut fn cstr_literal_ref_expr(text: &str, target_tid: i32) -> str:
        let tid = if target_tid != 0: target_tid else: self.sema.ty_cstr_view as i32
        "((" ++ self.c_type(tid, 0) ++ ")&" ++ cc_cstr_literal_view_name(text) ++ ")"

    mut fn collect_cstr_literal_texts() -> List[str]:
        var texts: List[str] = List.new()
        let used_globals = self.collect_referenced_global_syms()
        if self.had_error != 0:
            return texts
        for di in 0..self.ast.decl_count():
            if self.check_interrupted() != 0:
                return texts
            if self.sema.decl_is_lazy_skipped(di):
                continue
            let decl = self.ast.get_decl(di)
            if self.ast.kind(decl) != NodeKind.NK_LET_DECL:
                continue
            let sym = self.ast.get_data0(decl)
            let flags = self.ast.get_data2(decl)
            if flags % 2 == 0 and not used_globals.contains(sym):
                continue
            var expr = self.ast.get_data1(decl)
            while expr != 0:
                let k = self.ast.kind(expr)
                if k != NodeKind.NK_COMPTIME and k != NodeKind.NK_GROUPED:
                    break
                expr = self.ast.get_data0(expr)
            if expr != 0 and self.ast.kind(expr) == NodeKind.NK_C_STRING_LIT:
                let text = self.c_string_literal_node_payload_from_source(expr, self.decl_source_text(decl))
                texts = cc_push_unique_str(move texts, move text)
        for bi in 0..self.mir_mod.bodies.len():
            if self.check_interrupted() != 0:
                return texts
            let body = &self.mir_mod.bodies[bi]
            for ci in 0..body.const_kinds.len():
                if body.const_kinds[ci] != ConstKind.CK_C_STR:
                    continue
                let sym = body.const_d0[ci]
                let text = if sym != 0: cc_string_literal_payload(cc_intern_resolve(self.intern, sym)) else: ""
                texts = cc_push_unique_str(move texts, move text)
        texts

    mut fn emit_cstr_literal_defs() -> str:
        let texts = self.collect_cstr_literal_texts()
        if self.had_error != 0 or texts.len() == 0:
            return ""
        let cstr_c = self.c_type(self.sema.ty_cstr as i32, 0)
        var out = ""
        // One definition per text: a literal reached twice (a global the
        // lowering referenced twice) is still one C constant.
        var emitted: List[str] = List.new()
        for i in 0..texts.len():
            let text = texts[i]
            if emitted.contains(text): continue
            emitted.push(text)
            let data_name = cc_cstr_literal_data_name(text)
            let view_name = cc_cstr_literal_view_name(text)
            out = out ++ "static const uint8_t " ++ data_name ++ "[" ++ f"{text.len() + 1}" ++ "] = " ++ cc_cstr_literal_bytes_initializer(text) ++ ";\n"
            out = out ++ "static const " ++ cstr_c ++ " " ++ view_name ++ " = " ++ cc_lbrace() ++ " .ptr = (const int8_t*)" ++ data_name ++ ", .len = " ++ f"{text.len()}" ++ " " ++ cc_rbrace() ++ ";\n"
        out ++ "\n"

    // A float literal as C source. It differs from the literal's own text twice over:
    // digit separators are not C (§29.1 permits `3.141_592_653`), and an f32 literal
    // needs C's `f` suffix, or the C compiler parses it as a double and rounds twice.
    fn float_literal_c_text(text: &str, tid: i32) -> str:
        let value = float_literal_value_text(text)
        if tid != 0 and self.sema.resolve_alias(tid) == self.sema.ty_f32:
            return value ++ "f"
        value

    // Zeroed storage for a global: its value until a startup initializer
    // stores one, or its value when it has no initializer.
    mut fn global_zero_text(tid: i32) -> str:
        if self.sema.get_type_kind(self.sema.resolve_alias(tid)) == TypeKind.TY_ARRAY:
            return cc_lbrace() ++ "0" ++ cc_rbrace()
        self.zero_value_text(tid)

    // A global's initializer as a C constant, or "" when it is not a literal
    // C can state — a shift, an array or variant literal, a call (#1484).
    // Those run at startup: prepare_global_init_bodies lowers them.
    mut fn global_init_text(node: i32, tid: i32, src_text: &str) -> str:
        var expr = node
        while expr != 0:
            let k = self.ast.kind(expr)
            if k != NodeKind.NK_COMPTIME and k != NodeKind.NK_GROUPED:
                break
            expr = self.ast.get_data0(expr)
        if expr == 0:
            return self.global_zero_text(tid)
        let kind = self.ast.kind(expr)
        if kind == NodeKind.NK_INT_LIT or kind == NodeKind.NK_UNARY:
            return self.exact_int_expr_text(expr, tid)
        if kind == NodeKind.NK_BOOL_LIT:
            return if self.ast.get_data0(expr) != 0: "true" else: "false"
        if kind == NodeKind.NK_FLOAT_LIT:
            let str_idx = self.ast.get_data0(expr)
            if str_idx >= 0 and str_idx < self.ast.state.strings.len():
                return self.float_literal_c_text(self.ast.get_string(str_idx), tid)
            return ""
        if kind == NodeKind.NK_STRING_LIT:
            let text = self.string_literal_node_payload_from_source(expr, src_text)
            let resolved = self.sema.resolve_alias(tid)
            let tk = self.sema.get_type_kind(resolved)
            if tk == TypeKind.TY_PTR or tk == TypeKind.TY_REF:
                let inner_tid = self.sema.resolve_alias(self.sema.get_type_d0(resolved) as TypeId)
                if self.sema.get_type_kind(inner_tid) == TypeKind.TY_INT and self.sema.get_type_d0(inner_tid) == 8:
                    return "((" ++ self.c_type(tid, 0) ++ ")\"" ++ cc_escape_c_string(text) ++ "\")"
            return "WITH_STR_LIT(\"" ++ cc_escape_c_string(text) ++ "\")"
        if kind == NodeKind.NK_C_STRING_LIT:
            let text = self.c_string_literal_node_payload_from_source(expr, src_text)
            return self.cstr_literal_ref_expr(text, tid)
        if kind == NodeKind.NK_NULL_LIT:
            return "NULL"
        if kind == NodeKind.NK_ARRAY_LIT:
            return self.global_array_init_text(expr, tid, src_text)
        if kind == NodeKind.NK_STRUCT_LIT:
            return self.global_struct_init_text(expr, tid, src_text)
        ""

    // An array literal whose every element is a C constant is one too, as
    // the LLVM backend folds it (try_eval_const_llvm). Lowered at startup
    // instead, pcre2's 1543-record `_pcre2_ucd_records_8` table became a
    // function of 1543 temporaries that clang -O1 spent 155 s in SROA on.
    mut fn global_array_init_text(node: i32, tid: i32, src_text: &str) -> str:
        let resolved = self.sema.resolve_alias(tid)
        if self.sema.get_type_kind(resolved) != TypeKind.TY_ARRAY:
            return ""
        let elem_tid = self.sema.get_type_d0(resolved)
        let extra_start = self.ast.get_data0(node)
        let count = self.ast.get_data1(node)
        if count != self.sema.get_type_d1(resolved):
            return ""
        var out = cc_lbrace()
        for i in 0..count:
            let elem = self.global_init_text(self.ast.get_extra(extra_start + i), elem_tid, src_text)
            if elem.len() == 0:
                return ""
            out = out ++ (if i > 0: ", " ++ elem else: elem)
        out ++ cc_rbrace()

    // A struct literal that names every field with a C constant, in
    // declaration order. An omitted field takes its declared default, whose
    // text lives with the type's declaration, not this global's: that
    // literal runs at startup instead.
    mut fn global_struct_init_text(node: i32, tid: i32, src_text: &str) -> str:
        let resolved = self.sema.resolve_alias(tid)
        if self.sema.get_type_kind(resolved) != TypeKind.TY_STRUCT:
            return ""
        let start = self.sema.get_type_d1(resolved)
        let count = self.sema.get_type_d2(resolved)
        if count == 1 and self.sema.distinct_type_names.contains(self.sema.get_type_d0(resolved)):
            return ""
        let lit_start = self.ast.get_data1(node)
        let lit_count = self.ast.get_data2(node)
        var out = cc_lbrace()
        for fi in 0..count:
            let field_sym: i32 = self.sema.type_extra[(start + fi * 3)]
            let field_name = cc_member(cc_intern_resolve(self.intern, field_sym))
            let field_tid = self.effective_field_tid(resolved, field_sym, self.sema.type_extra[(start + fi * 3 + 1)])
            var value: i32 = 0
            for li in 0..lit_count:
                let lit_name = self.ast.get_extra(lit_start + li * 2)
                if (lit_name == 0 and li == fi) or (lit_name != 0 and cc_intern_resolve(self.intern, lit_name) == field_name):
                    value = self.ast.get_extra(lit_start + li * 2 + 1)
            if value == 0:
                return ""
            let text = self.global_init_text(value, field_tid, src_text)
            if text.len() == 0:
                return ""
            out = out ++ (if fi > 0: ", ." else: ".") ++ field_name ++ " = " ++ text
        out ++ cc_rbrace()

    mut fn const_text(body: &MirBody, const_id: i32) -> str:
        if const_id < 0 or const_id >= body.const_kinds.len():
            self.fail(f"invalid const id {const_id}")
            return "0"
        let ck = body.const_kinds[const_id]
        let cd = body.const_d0[const_id]
        if ck == ConstKind.CK_INT:
            return with_i64_to_str(mir_const_int_value(body, const_id))
        if ck == ConstKind.CK_INT_EXACT:
            return self.exact_int_const_text(body, const_id)
        if ck == ConstKind.CK_BOOL:
            return if cd != 0: "true" else: "false"
        if ck == ConstKind.CK_STR:
            let text = if cd != 0: cc_string_literal_payload(cc_intern_resolve(self.intern, cd)) else: ""
            return "WITH_STR_LIT(\"" ++ cc_escape_c_string(text) ++ "\")"
        if ck == ConstKind.CK_C_STR:
            let text = if cd != 0: cc_string_literal_payload(cc_intern_resolve(self.intern, cd)) else: ""
            return self.cstr_literal_ref_expr(text, body.const_types[const_id])
        if ck == ConstKind.CK_UNIT:
            let unit_tid = body.const_types[const_id]
            if unit_tid != 0:
                return self.zero_value_text(unit_tid)
            return "0"
        if ck == ConstKind.CK_FLOAT:
            if cd != 0:
                let lit = if cd >= 0 and cd < self.ast.state.strings.len(): self.float_literal_c_text(self.ast.get_string(cd), body.const_types[const_id]) else: ""
                if lit.len() > 0:
                    return lit
            return "0.0"
        if ck == ConstKind.CK_ZERO_SIZED:
            let zs_tid = body.const_types[const_id]
            if zs_tid != 0:
                return self.zero_value_text(zs_tid)
            return "0"
        if ck == ConstKind.CK_FN:
            if cd == 0:
                self.fail("invalid function symbol in constant")
                return "0"
            let body_sym = self.canonical_body_sym(cd)
            if body_sym != 0:
                return self.fn_c_name(body_sym)
            return self.extern_sym_c_name(cd)
        if ck == ConstKind.CK_CLOSURE:
            return self.closure_value_text(body, const_id)
        if ck == ConstKind.CK_ASYNC_BLOCK:
            self.fail("emit-c does not support an async block (its body runs on a fiber the C backend has no lowering for; " ++ self.node_site_text(cd) ++ " in " ++ cc_intern_resolve(self.intern, body.fn_sym) ++ ")")
            return "0"
        self.fail(f"unsupported const kind {ck}")
        "0"

    mut fn operand_text(body: &MirBody, operand_id: i32) -> str:
        if operand_id < 0 or operand_id >= body.operand_kinds.len():
            self.fail(f"invalid operand id {operand_id}")
            return "0"
        let ok = body.operand_kinds[operand_id]
        let od = body.operand_d0[operand_id]
        if ok == OperandKind.OK_COPY or ok == OperandKind.OK_MOVE:
            let text = self.place_text(body, od)
            let hold = if self.hold_active: body.operand_hold(operand_id) else: 0
            return if hold != 0: self.held_operand_text(body, operand_id, od, hold, text) else: text
        if ok == OperandKind.OK_CONSTANT:
            return self.const_text(body, od)
        self.fail(f"unsupported operand kind {ok}")
        "0"

    mut fn rvalue_tid(body: &MirBody, rval_id: i32) -> i32:
        if rval_id < 0 or rval_id >= body.rval_kinds.len():
            return 0
        let rk = body.rval_kinds[rval_id]
        let d0 = body.rval_d0[rval_id]
        let d1 = body.rval_d1[rval_id]
        if rk == RvalueKind.RK_USE:
            return self.operand_tid(body, d0)
        if rk == RvalueKind.RK_ARRAY_FILL:
            return self.operand_tid(body, d0)
        if rk == RvalueKind.RK_CAST:
            return d1
        if rk == RvalueKind.RK_BIN_OP:
            return self.operand_tid(body, d1)
        if rk == RvalueKind.RK_STR_CONCAT_N:
            return self.sema.ty_str as i32
        if rk == RvalueKind.RK_UN_OP:
            return self.operand_tid(body, d1)
        if rk == RvalueKind.RK_SLICE:
            let base_tid = self.place_tid(body, d0)
            let resolved = self.sema.resolve_alias(base_tid)
            let tk = self.sema.get_type_kind(resolved)
            if tk == TypeKind.TY_ARRAY:
                return self.sema.find_exact_type(TypeKind.TY_SLICE, self.sema.get_type_d0(resolved), 0, 0) as i32
            if tk == TypeKind.TY_SLICE:
                return resolved as i32
            if tk == TypeKind.TY_STR:
                return self.sema.find_exact_type(TypeKind.TY_REF, self.sema.ty_str as i32, 0, 0) as i32
            return 0
        0

    fn binop_token(op: i32) -> str:
        if op == BinaryOp.OP_ADD or op == BinaryOp.OP_ADD_WRAP or op == BinaryOp.OP_ADD_SAT: return "+"
        if op == BinaryOp.OP_SUB or op == BinaryOp.OP_SUB_WRAP or op == BinaryOp.OP_SUB_SAT: return "-"
        if op == BinaryOp.OP_MUL or op == BinaryOp.OP_MUL_WRAP or op == BinaryOp.OP_MUL_SAT: return "*"
        if op == BinaryOp.OP_DIV: return "/"
        if op == BinaryOp.OP_MOD: return "%"
        if op == BinaryOp.OP_EQ: return "=="
        if op == BinaryOp.OP_NEQ: return "!="
        if op == BinaryOp.OP_LT: return "<"
        if op == BinaryOp.OP_GT: return ">"
        if op == BinaryOp.OP_LTE: return "<="
        if op == BinaryOp.OP_GTE: return ">="
        if op == BinaryOp.OP_AND: return "&&"
        if op == BinaryOp.OP_OR: return "||"
        if op == BinaryOp.OP_BIT_AND: return "&"
        if op == BinaryOp.OP_BIT_OR: return "|"
        if op == BinaryOp.OP_BIT_XOR: return "^"
        if op == BinaryOp.OP_SHL: return "<<"
        if op == BinaryOp.OP_SHR: return ">>"
        ""

    // A pointer-valued operand: a raw pointer or a thin reference. A `&str`
    // view is `{ptr, len}` by value (#1810), never a pointer.
    fn type_is_raw_pointer_tid(tid: i32) -> bool:
        if tid == 0:
            return false
        let resolved = self.sema.resolve_alias(tid)
        let kind = self.sema.get_type_kind(resolved)
        (kind == TypeKind.TY_PTR or kind == TypeKind.TY_REF) and not self.sema.type_layout_is_str_view(resolved as i32)

    // A str, a `&str` view, or a reference to one (`&&str`, an element view
    // of `[&str; N]`): the operands a comparison reads as text.
    fn tid_is_str_or_str_view(tid: i32) -> bool:
        let resolved = self.sema.resolve_alias(tid)
        let kind = self.sema.get_type_kind(resolved)
        if kind == TypeKind.TY_STR:
            return true
        kind == TypeKind.TY_REF and self.tid_is_str_or_str_view(self.sema.get_type_d0(resolved))

    // A comparison of two strs, either of them a `&str` view or a reference
    // to one, compares the text (#293, #785; the LLVM backend's
    // mir_compare_dispatch_kind 1): a view observes the str it names, and
    // only raw pointers compare by address. Ahead of raw_pointer_binop_text,
    // which read two `&str` operands as pointers (#1560). "" when the
    // operands are not both text.
    mut fn str_compare_text(body: &MirBody, op: i32, lhs_op: i32, rhs_op: i32) -> str:
        let is_cmp = op == BinaryOp.OP_EQ or op == BinaryOp.OP_NEQ or op == BinaryOp.OP_LT or op == BinaryOp.OP_GT or op == BinaryOp.OP_LTE or op == BinaryOp.OP_GTE
        if not is_cmp or not self.tid_is_str_or_str_view(self.operand_tid(body, lhs_op)) or not self.tid_is_str_or_str_view(self.operand_tid(body, rhs_op)):
            return ""
        let args = self.str_value_text(body, lhs_op) ++ ", " ++ self.str_value_text(body, rhs_op)
        if op == BinaryOp.OP_EQ: return "with_str_eq_ref(" ++ args ++ ")"
        if op == BinaryOp.OP_NEQ: return "(!with_str_eq_ref(" ++ args ++ "))"
        "(with_str_cmp_ref(" ++ args ++ ") " ++ self.binop_token(op) ++ " 0)"

    mut fn raw_pointer_elem_size_expr(tid: i32) -> str:
        let resolved = self.sema.resolve_alias(tid)
        let kind = self.sema.get_type_kind(resolved)
        if kind != TypeKind.TY_PTR and kind != TypeKind.TY_REF:
            return "1"
        let inner = self.sema.get_type_d0(resolved)
        let inner_resolved = self.sema.resolve_alias(inner as TypeId)
        if self.sema.get_type_kind(inner_resolved) == TypeKind.TY_VOID or self.type_is_c_void(inner_resolved as i32) != 0:
            return "1"
        "sizeof(" ++ self.c_type(inner, 0) ++ ")"

    mut fn raw_pointer_binop_text(op: i32, lhs: &str, rhs: &str, lhs_tid: i32, rhs_tid: i32) -> str:
        let lhs_ptr = self.type_is_raw_pointer_tid(lhs_tid)
        let rhs_ptr = self.type_is_raw_pointer_tid(rhs_tid)
        if lhs_ptr and rhs_ptr and op == BinaryOp.OP_SUB:
            return "((intptr_t)((uintptr_t)(" ++ lhs ++ ") - (uintptr_t)(" ++ rhs ++ ")))"
        if lhs_ptr and rhs_ptr and (op == BinaryOp.OP_EQ or op == BinaryOp.OP_NEQ or op == BinaryOp.OP_LT or op == BinaryOp.OP_GT or op == BinaryOp.OP_LTE or op == BinaryOp.OP_GTE):
            let tok = self.binop_token(op)
            return "((uintptr_t)(" ++ lhs ++ ") " ++ tok ++ " (uintptr_t)(" ++ rhs ++ "))"
        if lhs_ptr and (op == BinaryOp.OP_ADD or op == BinaryOp.OP_SUB):
            let tok = self.binop_token(op)
            return "((" ++ self.c_type(lhs_tid, 0) ++ ")((uintptr_t)(" ++ lhs ++ ") " ++ tok ++ " ((uintptr_t)(" ++ rhs ++ ") * " ++ self.raw_pointer_elem_size_expr(lhs_tid) ++ ")))"
        if rhs_ptr and op == BinaryOp.OP_ADD:
            return "((" ++ self.c_type(rhs_tid, 0) ++ ")(((uintptr_t)(" ++ lhs ++ ") * " ++ self.raw_pointer_elem_size_expr(rhs_tid) ++ ") + (uintptr_t)(" ++ rhs ++ ")))"
        ""

    mut fn rvalue_text(body: &MirBody, rval_id: i32) -> str:
        if rval_id < 0 or rval_id >= body.rval_kinds.len():
            self.fail(f"invalid rvalue id {rval_id}")
            return "0"
        let rk = body.rval_kinds[rval_id]
        let d0 = body.rval_d0[rval_id]
        let d1 = body.rval_d1[rval_id]
        let d2 = body.rval_d2[rval_id]
        if rk == RvalueKind.RK_USE:
            return self.operand_text(body, d0)
        if rk == RvalueKind.RK_ARRAY_FILL:
            self.fail("array fill rvalue requires an array assignment destination")
            return "0"
        if rk == RvalueKind.RK_STR_CONCAT_N:
            return self.str_concat_n_text(body, d0, d2)
        if rk == RvalueKind.RK_BIN_OP:
            let lhs = self.operand_text(body, d1)
            let rhs = self.operand_text(body, d2)
            let str_cmp = self.str_compare_text(body, d0, d1, d2)
            if str_cmp.len() > 0:
                return str_cmp
            let lhs_tid = self.operand_tid(body, d1)
            let rhs_tid = self.operand_tid(body, d2)
            // #2137 (§11.7): `==` on an aggregate (an Option, a tuple, a
            // struct) is structural, through the walk map keys compare by;
            // C has no `==` on a struct.
            if d0 == BinaryOp.OP_EQ or d0 == BinaryOp.OP_NEQ:
                let eq_tid = self.operand_sema_tid(body, d1)
                if eq_tid > 0 and self.key_type_has_walk(self.sema.resolve_alias(eq_tid as TypeId) as i32):
                    // The walk reads both sides by address: each is held in
                    // a temporary (a constant operand is no lvalue).
                    let eq_c = self.c_type(eq_tid, 0)
                    let equal = self.key_eq_text("__with_eql", "__with_eqr", eq_tid)
                    let test = if d0 == BinaryOp.OP_EQ: equal else: "!" ++ equal
                    return "(" ++ cc_lbrace() ++ " " ++ eq_c ++ " __with_eql = " ++ lhs ++ "; " ++ eq_c ++ " __with_eqr = " ++ rhs ++ "; " ++ test ++ "; " ++ cc_rbrace() ++ ")"
            let raw_ptr_bin = self.raw_pointer_binop_text(d0, lhs, rhs, lhs_tid, rhs_tid)
            if raw_ptr_bin.len() > 0:
                return raw_ptr_bin
            if d0 == BinaryOp.OP_CONCAT:
                return "with_str_concat_ref(" ++ self.str_value_text(body, d1) ++ ", " ++ self.str_value_text(body, d2) ++ ")"
            let result_bin_tid = self.sema.resolve_alias(self.rvalue_tid(body, rval_id))
            let result_is_int_bin = self.sema.get_type_kind(result_bin_tid) == TypeKind.TY_INT
            let is_checked_arith_bin = d0 == BinaryOp.OP_ADD or d0 == BinaryOp.OP_SUB or d0 == BinaryOp.OP_MUL or d0 == BinaryOp.OP_DIV or d0 == BinaryOp.OP_MOD
            let is_saturating_arith_bin = d0 == BinaryOp.OP_ADD_SAT or d0 == BinaryOp.OP_SUB_SAT or d0 == BinaryOp.OP_MUL_SAT or (is_checked_arith_bin and self.overflow_mode == OVERFLOW_MODE_SATURATE())
            if result_is_int_bin and is_saturating_arith_bin:
                self.fail("C backend does not support saturating integer arithmetic yet")
                return "0"
            if result_is_int_bin and is_checked_arith_bin and self.overflow_mode != OVERFLOW_MODE_WRAP():
                return self.checked_int_bin_op_text(d0, lhs, rhs, result_bin_tid)
            let tok = self.binop_token(d0)
            if tok.len() == 0:
                self.fail(f"unsupported binop {d0}")
                return "0"
            return "(" ++ lhs ++ " " ++ tok ++ " " ++ rhs ++ ")"
        if rk == RvalueKind.RK_UN_OP:
            let inner = self.operand_text(body, d1)
            if d0 == UnaryOp.UOP_NEGATE:
                let inner_tid = self.sema.resolve_alias(self.operand_tid(body, d1))
                if self.sema.get_type_kind(inner_tid) == TypeKind.TY_INT and self.overflow_mode != OVERFLOW_MODE_WRAP():
                    if self.overflow_mode == OVERFLOW_MODE_SATURATE():
                        self.fail("C backend does not support saturating integer negation yet")
                        return "0"
                    return self.checked_int_neg_text(inner, inner_tid)
                return "(-(" ++ inner ++ "))"
            if d0 == UnaryOp.UOP_NOT:
                return "(!(" ++ inner ++ "))"
            if d0 == UnaryOp.UOP_BIT_NOT:
                return "(~(" ++ inner ++ "))"
            self.fail(f"unsupported unary op {d0}")
            return inner
        if rk == RvalueKind.RK_REF:
            // A shared reference to a str is the `&str` view: the header's
            // own {ptr, len}, read out of the place (#1810).
            if self.ref_rvalue_is_str_view(body, rval_id):
                return "(" ++ self.place_text(body, d1) ++ ")"
            return "(&" ++ self.place_text(body, d1) ++ ")"
        if rk == RvalueKind.RK_ADDR_OF:
            return "(&" ++ self.place_text(body, d0) ++ ")"
        if rk == RvalueKind.RK_SLICE:
            let base = self.place_text(body, d0)
            let start = self.operand_text(body, d1)
            let end_ = self.operand_text(body, d2)
            let base_tid = self.sema.resolve_alias(self.place_tid(body, d0))
            let base_tk = self.sema.get_type_kind(base_tid)
            let slice_tid = self.rvalue_tid(body, rval_id)
            let slice_c = self.c_type(slice_tid, 0)
            var ptr_expr = ""
            // D71 (§4.8a): a str range is a `&str` view of its bytes, checked
            // in every build as the LLVM backend checks it — past the end or
            // inside a UTF-8 character panics.
            if base_tk == TypeKind.TY_STR:
                return "__with_str_range_view(" ++ base ++ ", (int64_t)(" ++ start ++ "), (int64_t)(" ++ end_ ++ "))"
            if base_tk == TypeKind.TY_ARRAY:
                ptr_expr = "&((" ++ base ++ ")[(int64_t)(" ++ start ++ ")])"
            else if base_tk == TypeKind.TY_SLICE:
                ptr_expr = "((" ++ base ++ ").ptr + (int64_t)(" ++ start ++ "))"
            else:
                self.fail("C backend slice rvalue requires array or slice base")
                return "0"
            let len_expr = "((int64_t)(" ++ end_ ++ ") - (int64_t)(" ++ start ++ "))"
            return "((" ++ slice_c ++ ") " ++ cc_lbrace() ++ " .ptr = " ++ ptr_expr ++ ", .len = " ++ len_expr ++ " " ++ cc_rbrace() ++ ")"
        if rk == RvalueKind.RK_CAST:
            let dst_c = self.c_type(d1, 0)
            let src = self.operand_text(body, d0)
            let src_tid = self.sema.resolve_alias(self.operand_tid(body, d0))
            let dst_tid = self.sema.resolve_alias(d1)
            let src_tk = self.sema.get_type_kind(src_tid)
            let dst_tk = self.sema.get_type_kind(dst_tid)
            // #1810: a `&str` view is `{ptr, len}` by value. A raw pointer to
            // a str header cast to `&str` reads the view out of the header; a
            // view cast to a raw pointer names a header holding it — its own
            // storage when it is a place, else a compound literal.
            if self.sema.type_layout_is_str_view(dst_tid as i32):
                if self.type_is_raw_pointer_tid(src_tid as i32):
                    return "(*(const with_str*)(" ++ src ++ "))"
                return "(" ++ self.str_value_text(body, d0) ++ ")"
            if (dst_tk == TypeKind.TY_PTR or dst_tk == TypeKind.TY_REF) and self.sema.type_layout_is_str_view(src_tid as i32):
                return "((" ++ dst_c ++ ")(" ++ self.call_arg_address_text(body, d0, src) ++ "))"
            if dst_tk == TypeKind.TY_PTR or dst_tk == TypeKind.TY_REF:
                if src_tk == TypeKind.TY_STR:
                    // #747: a cast to `*const str`/`*mut str` is address-
                    // preserving — Sema auto-derefs a `&str` source, so the
                    // operand place IS the referenced str and its address is
                    // a header pointer. A byte-pointer target (`*const u8`)
                    // takes the data pointer.
                    if self.sema.type_layout_repr_is_str(self.sema.get_type_d0(dst_tid)):
                        return "((" ++ dst_c ++ ")(" ++ self.call_arg_address_text(body, d0, src) ++ "))"
                    return "((" ++ dst_c ++ ")(" ++ src ++ ".ptr))"
                if src_tk == TypeKind.TY_STRUCT:
                    return "((" ++ dst_c ++ ")(&(" ++ src ++ ")))"
            // `s as []u8` (§16.5): the byte view is the string's bytes and
            // length — a C cast of the str struct is not a slice (the prelude's
            // str.as_bytes() failed to compile under emit-c).
            if dst_tk == TypeKind.TY_SLICE and src_tk == TypeKind.TY_STR:
                return "((" ++ dst_c ++ "){ (uint8_t*)((" ++ src ++ ").ptr), with_len(" ++ src ++ ") })"
            return "((" ++ dst_c ++ ")(" ++ src ++ "))"
        if rk == RvalueKind.RK_DISCRIMINANT:
            return self.enum_tag_text(self.place_tid(body, d0), self.place_text(body, d0))
        if rk == RvalueKind.RK_LEN:
            let p = self.place_text(body, d0)
            let pt = self.place_tid(body, d0)
            if pt == CC_PSEUDO_TID_LIST:
                return "with_vec_len(&(" ++ p ++ "))"
            let resolved_pt = self.sema.resolve_alias(pt)
            if self.sema.get_type_kind(resolved_pt) == TypeKind.TY_ARRAY:
                return "((int64_t)(sizeof(" ++ p ++ ") / sizeof((" ++ p ++ ")[0])))"
            if self.sema.get_type_kind(resolved_pt) == TypeKind.TY_SLICE:
                return "((" ++ p ++ ").len)"
            return "with_len(" ++ p ++ ")"
        if rk == RvalueKind.RK_AGGREGATE:
            if d1 < 0 or d1 >= body.agg_field_starts.len():
                return "0"
            let start = body.agg_field_starts[d1]
            let count = body.agg_field_counts[d1]
            if count <= 0:
                return "0"
            // Conservative lowering: record updates and implicit wrappers both
            // preserve payload/shape in operand 0 for this bootstrap path.
            let first = body.agg_field_operands[start]
            return self.operand_text(body, first)
        self.fail(f"unknown MIR rvalue kind {rk}")
        "0"

    fn call_arg_count(body: &MirBody, args_id: i32) -> i32:
        if args_id < 0 or args_id >= body.call_arg_counts.len():
            return 0
        body.call_arg_counts[args_id]

    mut fn aggregate_compound_literal(body: &MirBody, rval_id: i32, dst_tid: i32) -> str:
        if rval_id < 0 or rval_id >= body.rval_kinds.len():
            return ""
        if body.rval_kinds[rval_id] != RvalueKind.RK_AGGREGATE:
            return ""
        let fields_id = body.rval_d1[rval_id]
        if fields_id < 0 or fields_id >= body.agg_field_starts.len():
            return ""
        let start = body.agg_field_starts[fields_id]
        let count = body.agg_field_counts[fields_id]
        let dst_resolved = self.sema.resolve_alias(dst_tid)
        let dst_tk = self.sema.get_type_kind(dst_resolved)
        let dst_c = self.c_type(dst_tid, 0)
        let aggregate_kind = body.rval_d0[rval_id]
        if aggregate_kind != 0:
            if self.type_is_payload_enum(dst_tid) == 0:
                if dst_tk == TypeKind.TY_ENUM:
                    let tag = self.sema.type_reflection_variant_discriminant(dst_tid, body.rval_d2[rval_id])
                    return f"{tag}"
                return ""
            let variant_index = body.rval_d2[rval_id]
            if count == 1:
                let payload_op: i32 = body.agg_field_operands[start]
                var payload_text = self.operand_text(body, payload_op)
                let payload_tid = self.sema.type_reflection_variant_payload_type_frozen(dst_tid, variant_index, 0)
                if self.fn_tid_is_fat(payload_tid) != 0:
                    let payload_fn_sym = self.operand_ck_fn_sym(body, payload_op)
                    if payload_fn_sym != 0:
                        payload_text = self.fat_fn_literal(payload_fn_sym, self.sema.resolve_alias(payload_tid) as i32)
                return self.payload_enum_literal(dst_tid, variant_index, payload_text)
            else if count > 1:
                // The variant's payload struct, field by field (#2017).
                if count != self.sema.type_reflection_variant_payload_count(dst_tid, variant_index):
                    self.fail(f"enum variant {variant_index} built from {count} operands for its {self.sema.type_reflection_variant_payload_count(dst_tid, variant_index)} payload fields")
                    return ""
                var fields_text = cc_lbrace()
                for pi in 0..count:
                    if pi > 0:
                        fields_text = fields_text ++ ", "
                    let field_op: i32 = body.agg_field_operands[(start + pi)]
                    var field_text = self.operand_text(body, field_op)
                    let field_tid = self.sema.type_reflection_variant_payload_type_frozen(dst_tid, variant_index, pi)
                    if self.fn_tid_is_fat(field_tid) != 0:
                        let field_fn_sym = self.operand_ck_fn_sym(body, field_op)
                        if field_fn_sym != 0:
                            field_text = self.fat_fn_literal(field_fn_sym, self.sema.resolve_alias(field_tid) as i32)
                    fields_text = fields_text ++ "." ++ cc_payload_struct_field(pi) ++ " = " ++ field_text
                return self.payload_enum_literal(dst_tid, variant_index, fields_text ++ cc_rbrace())
            var unit_variant: i32 = variant_index
            if self.sema.type_reflection_variant_payload_count(dst_tid, unit_variant) != 0:
                unit_variant = self.payload_enum_single_unit_variant(dst_tid)
            if unit_variant < 0:
                self.fail("C backend cannot identify payload enum unit variant")
                return ""
            return self.payload_enum_literal(dst_tid, unit_variant, "")
        var out = "(" ++ dst_c ++ ")" ++ cc_lbrace()
        if count <= 0:
            out = out ++ "0"
        else:
            for i in 0..count:
                if i > 0:
                    out = out ++ ", "
                let name_sym = if (start + i) >= 0 and (start + i) < body.agg_field_name_syms.len():
                    body.agg_field_name_syms[(start + i)]
                else:
                    0
                var agg_field_tid: i32 = 0
                if dst_tk == TypeKind.TY_STRUCT and name_sym != 0:
                    let field_name = cc_member(cc_intern_resolve(self.intern, name_sym))
                    if field_name.len() > 0 and self.struct_field_tid(dst_resolved as i32, name_sym) != 0:
                        out = out ++ "." ++ field_name ++ " = "
                        agg_field_tid = self.struct_field_tid(dst_resolved as i32, name_sym)
                else if dst_tk == TypeKind.TY_TUPLE:
                    let t_start = self.sema.get_type_d0(dst_resolved)
                    let t_count = self.sema.get_type_d1(dst_resolved)
                    if i < t_count:
                        agg_field_tid = self.sema.type_extra[(t_start + i)]
                let field_op: i32 = body.agg_field_operands[(start + i)]
                var field_text = self.operand_text(body, field_op)
                if agg_field_tid != 0 and self.fn_tid_is_fat(agg_field_tid) != 0:
                    let agg_fn_sym = self.operand_ck_fn_sym(body, field_op)
                    if agg_fn_sym != 0:
                        field_text = self.fat_fn_literal(agg_fn_sym, self.sema.resolve_alias(agg_field_tid) as i32)
                out = out ++ field_text
        // D72 (§2.5.1): a constructed value of a struct with the hidden
        // liveness byte is live; its zero-filled storage is the reset
        // sentinel the drop guard skips (mir_store_liveness_byte).
        if (dst_tk == TypeKind.TY_STRUCT or self.generic_inst_is_declared_struct(dst_resolved as i32)) and self.sema.struct_liveness_byte_frozen_tid(self.sema.get_type_d0(dst_resolved), dst_resolved as i32) != 0:
            out = out ++ ", .__with_live = 1"
        out = out ++ cc_rbrace()
        out

    mut fn aggregate_array_initializer(body: &MirBody, rval_id: i32) -> str:
        if rval_id < 0 or rval_id >= body.rval_kinds.len():
            return ""
        if body.rval_kinds[rval_id] != RvalueKind.RK_AGGREGATE:
            return ""
        let fields_id = body.rval_d1[rval_id]
        if fields_id < 0 or fields_id >= body.agg_field_starts.len():
            return ""
        let start = body.agg_field_starts[fields_id]
        let count = body.agg_field_counts[fields_id]
        var out = cc_lbrace()
        if count <= 0:
            out = out ++ "0"
        else:
            for i in 0..count:
                if i > 0:
                    out = out ++ ", "
                out = out ++ self.operand_text(body, body.agg_field_operands[(start + i)])
        out ++ cc_rbrace()

    // An array of arrays built from its rows (pcre2's `[[u8; 21]; 17]`
    // tables): a row is a C array, which no initializer list takes by name,
    // so each row is copied into a temporary and the temporary into the
    // destination. "" when the rvalue is not such an aggregate.
    mut fn aggregate_nested_array_assignment(body: &MirBody, rval_id: i32, dst_tid: i32, dst_place: &str) -> str:
        if rval_id < 0 or rval_id >= body.rval_kinds.len() or body.rval_kinds[rval_id] != RvalueKind.RK_AGGREGATE:
            return ""
        let elem_tid = self.sema.get_type_d0(self.sema.resolve_alias(dst_tid))
        if self.sema.get_type_kind(self.sema.resolve_alias(elem_tid as TypeId)) != TypeKind.TY_ARRAY:
            return ""
        let fields_id = body.rval_d1[rval_id]
        if fields_id < 0 or fields_id >= body.agg_field_starts.len():
            return ""
        let start = body.agg_field_starts[fields_id]
        var out = "    " ++ cc_lbrace() ++ " " ++ self.c_decl(dst_tid, "__with_arr_tmp") ++ ";"
        for i in 0..body.agg_field_counts[fields_id]:
            out = out ++ f" memcpy(__with_arr_tmp[{i}], " ++ self.operand_text(body, body.agg_field_operands[(start + i)]) ++ f", sizeof(__with_arr_tmp[{i}]));"
        out ++ " memcpy(" ++ dst_place ++ ", __with_arr_tmp, sizeof(" ++ dst_place ++ ")); " ++ cc_rbrace()

    mut fn aggregate_struct_assignment_with_array_fields(body: &MirBody, rval_id: i32, dst_tid: i32, dst_place: &str) -> str:
        if rval_id < 0 or rval_id >= body.rval_kinds.len():
            return ""
        if body.rval_kinds[rval_id] != RvalueKind.RK_AGGREGATE:
            return ""
        if body.rval_d0[rval_id] != 0:
            return ""
        let fields_id = body.rval_d1[rval_id]
        if fields_id < 0 or fields_id >= body.agg_field_starts.len():
            return ""
        let dst_resolved = self.sema.resolve_alias(dst_tid)
        if self.sema.get_type_kind(dst_resolved) != TypeKind.TY_STRUCT:
            return ""
        let start = body.agg_field_starts[fields_id]
        let count = body.agg_field_counts[fields_id]
        var has_array_field = false
        for i in 0..count:
            let name_sym = if (start + i) >= 0 and (start + i) < body.agg_field_name_syms.len():
                body.agg_field_name_syms[(start + i)]
            else:
                0
            let field_tid = if name_sym != 0: self.struct_field_tid(dst_resolved as i32, name_sym) else: 0
            if field_tid != 0 and self.sema.get_type_kind(self.sema.resolve_alias(field_tid)) == TypeKind.TY_ARRAY:
                has_array_field = true
        if not has_array_field:
            return ""
        var out = "    " ++ cc_lbrace() ++ " " ++ dst_place ++ " = (" ++ self.c_type(dst_tid, 0) ++ ")" ++ cc_lbrace() ++ "0" ++ cc_rbrace() ++ ";"
        for i in 0..count:
            let idx = start + i
            let name_sym = if idx >= 0 and idx < body.agg_field_name_syms.len():
                body.agg_field_name_syms[idx]
            else:
                0
            if name_sym == 0:
                self.fail("emit-c: struct aggregate assignment with array fields requires named fields")
                return ""
            let field_name = cc_member(cc_intern_resolve(self.intern, name_sym))
            let field_tid = self.struct_field_tid(dst_resolved as i32, name_sym)
            if field_name.len() == 0 or field_tid == 0:
                self.fail("emit-c: unresolved struct field in aggregate assignment")
                return ""
            let operand_id = body.agg_field_operands[idx]
            let field_place = dst_place ++ "." ++ field_name
            let field_tk = self.sema.get_type_kind(self.sema.resolve_alias(field_tid))
            let value_text = self.operand_text(body, operand_id)
            if field_tk == TypeKind.TY_ARRAY:
                let operand_tid = self.operand_tid(body, operand_id)
                let operand_tk = if operand_tid != 0: self.sema.get_type_kind(self.sema.resolve_alias(operand_tid)) else: 0
                if value_text == "0" or value_text == "0LL":
                    out = out ++ " memset(" ++ field_place ++ ", 0, sizeof(" ++ field_place ++ "));"
                else if operand_tk == TypeKind.TY_ARRAY:
                    out = out ++ " memcpy(" ++ field_place ++ ", " ++ value_text ++ ", sizeof(" ++ field_place ++ "));"
                else:
                    self.fail("emit-c: cannot initialize fixed-array struct field from non-array operand")
                    return ""
            else:
                out = out ++ " " ++ field_place ++ " = " ++ value_text ++ ";"
        // D72 (§2.5.1): a constructed value is live (mir_store_liveness_byte).
        if self.sema.struct_liveness_byte_frozen_tid(self.sema.get_type_d0(dst_resolved), dst_resolved as i32) != 0:
            out = out ++ " " ++ dst_place ++ ".__with_live = 1;"
        out ++ " " ++ cc_rbrace()

    mut fn map_recv_text(body: &MirBody, args_id: i32) -> str:
        let recv_operand = self.call_arg_operand(body, args_id, 0)
        let recv = self.operand_text(body, recv_operand)
        let recv_tid = self.sema.resolve_alias(self.operand_tid(body, recv_operand))
        let recv_tk = self.sema.get_type_kind(recv_tid)
        if recv_tk == TypeKind.TY_PTR or recv_tk == TypeKind.TY_REF:
            let inner = self.sema.resolve_alias(self.sema.get_type_d0(recv_tid))
            if inner != 0 and self.c_type(inner, 0) == "int64_t":
                return "(*(" ++ recv ++ "))"
        recv

    mut fn list_recv_ptr_text(body: &MirBody, args_id: i32) -> str:
        let recv_operand = self.call_arg_operand(body, args_id, 0)
        let recv = self.operand_text(body, recv_operand)
        let recv_tid = self.sema.resolve_alias(self.operand_tid(body, recv_operand))
        let recv_tk = self.sema.get_type_kind(recv_tid)
        if recv_tk == TypeKind.TY_PTR or recv_tk == TypeKind.TY_REF:
            let inner = self.sema.resolve_alias(self.sema.get_type_d0(recv_tid))
            if inner != 0 and self.c_type(inner, 0) == "with_vec":
                return "((with_vec*)(" ++ recv ++ "))"
        "&(" ++ recv ++ ")"

    // The collection a builtin's receiver names, through its reference.
    mut fn recv_value_tid(body: &MirBody, args_id: i32) -> i32:
        let recv_tid = self.sema.resolve_alias(self.operand_tid(body, self.call_arg_operand(body, args_id, 0)))
        let recv_tk = self.sema.get_type_kind(recv_tid)
        if recv_tk == TypeKind.TY_PTR or recv_tk == TypeKind.TY_REF:
            return self.sema.resolve_alias(self.sema.get_type_d0(recv_tid)) as i32
        recv_tid as i32

    // D115 Amendment 1: the `sizeof(elem)` a sized List helper takes, from
    // the receiver's element type (never from the header).
    mut fn list_recv_elem_sizeof_text(body: &MirBody, args_id: i32) -> str:
        let recv_operand = self.call_arg_operand(body, args_id, 0)
        var recv_tid = self.sema.resolve_alias(self.operand_tid(body, recv_operand))
        let recv_tk = self.sema.get_type_kind(recv_tid)
        if recv_tk == TypeKind.TY_PTR or recv_tk == TypeKind.TY_REF:
            recv_tid = self.sema.resolve_alias(self.sema.get_type_d0(recv_tid))
        var elem_tid = self.list_element_tid(recv_tid as i32)
        if elem_tid == 0 or self.is_void_tid(elem_tid) != 0:
            elem_tid = self.list_local_element_tid(body, self.place_local_id(body, body.operand_d0[recv_operand]))
        if elem_tid == 0 or self.is_void_tid(elem_tid) != 0:
            self.fail("a List helper's receiver has no element type (D115 Amendment 1 sizes every helper call statically)")
            return "0"
        "sizeof(" ++ self.c_type(elem_tid, 0) ++ ")"

    // D116 (§15.4.9): `a ++ b` (a new List) and `a ++= b` (in place).
    mut fn emit_list_concat(body: &MirBody, args_id: i32, dest_place: i32, kind: CcBuiltin, has_ret: i32, next_bb: i32) -> str:
        let in_place = kind == CcBuiltin.LIST_EXTEND
        var list_tid: i32 = 0
        if in_place:
            let recv_operand = self.call_arg_operand(body, args_id, 0)
            var recv_tid = self.sema.resolve_alias(self.operand_tid(body, recv_operand))
            let recv_tk = self.sema.get_type_kind(recv_tid)
            if recv_tk == TypeKind.TY_PTR or recv_tk == TypeKind.TY_REF:
                recv_tid = self.sema.resolve_alias(self.sema.get_type_d0(recv_tid))
            list_tid = recv_tid as i32
        else:
            list_tid = self.place_local_tid(body, dest_place)
        let elem_tid = self.list_element_tid(list_tid)
        if elem_tid == 0 or self.is_void_tid(elem_tid) != 0:
            self.fail("`++` over sequences without an element type (D116)")
            return "    abort();"
        let elem_c = self.c_type(elem_tid, 0)
        let es = "sizeof(" ++ elem_c ++ ")"
        let is_str = self.sema.resolve_alias(elem_tid as TypeId) == self.sema.ty_str
        let target = if in_place: self.list_recv_ptr_text(body, args_id) else: "&__with_cat"
        var out = "    " ++ cc_lbrace()
        if not in_place:
            out = out ++ " with_vec __with_cat; with_vec_new_out((uint8_t*)&__with_cat, " ++ es ++ ");"
        let first: i32 = if in_place: 1 else: 0
        for i in first..2:
            let op = self.call_arg_operand(body, args_id, i)
            let text = self.operand_text(body, op)
            var tid = self.sema.resolve_alias(self.operand_tid(body, op))
            let tk = self.sema.get_type_kind(tid)
            var deref = ""
            if tk == TypeKind.TY_PTR or tk == TypeKind.TY_REF:
                tid = self.sema.resolve_alias(self.sema.get_type_d0(tid))
                deref = "*"
            let src_kind = self.sema.get_type_kind(tid)
            var data = ""
            var n = ""
            if src_kind == TypeKind.TY_SLICE:
                data = "(uint8_t*)(" ++ deref ++ "(" ++ text ++ ")).ptr"
                n = "(int64_t)(" ++ deref ++ "(" ++ text ++ ")).len"
            else if src_kind == TypeKind.TY_ARRAY:
                data = "(uint8_t*)&(" ++ deref ++ "(" ++ text ++ "))"
                n = f"(int64_t){self.sema.get_type_d1(tid)}"
            else:
                let header = if deref == "*": "((with_vec*)(" ++ text ++ "))" else: "(&(" ++ text ++ "))"
                if body.operand_kinds[op] == OperandKind.OK_MOVE:
                    out = out ++ " with_vec_take_into_es((uint8_t*)" ++ target ++ ", (uint8_t*)" ++ header ++ ", " ++ es ++ ");"
                    continue
                data = "(uint8_t*)" ++ header ++ "->ptr"
                n = "(int64_t)" ++ header ++ "->len"
            if is_str:
                out = out ++ " with_vec_extend_str((uint8_t*)" ++ target ++ ", " ++ data ++ ", " ++ n ++ ");"
            else if self.glue_needed(elem_tid):
                // D111: each appended element with copy glue is one more
                // holder (mir_emit_list_extend_from).
                let hold = self.copy_call_text("((" ++ elem_c ++ "*)__with_dst->ptr)[__with_i]", elem_tid)
                out = out ++ " " ++ cc_lbrace() ++ " with_vec* __with_dst = (with_vec*)" ++ target ++ "; int64_t __with_from = __with_dst->len; with_vec_extend_bits_es((uint8_t*)__with_dst, " ++ data ++ ", " ++ n ++ ", " ++ es ++ "); for (int64_t __with_i = __with_from; __with_i < __with_dst->len; __with_i++) " ++ cc_lbrace() ++ " " ++ hold ++ " " ++ cc_rbrace() ++ " " ++ cc_rbrace()
            else:
                out = out ++ " with_vec_extend_bits_es((uint8_t*)" ++ target ++ ", " ++ data ++ ", " ++ n ++ ", " ++ es ++ ");"
        if not in_place and has_ret != 0:
            out = out ++ " " ++ self.place_text(body, dest_place) ++ " = __with_cat;"
        out = out ++ " " ++ cc_rbrace() ++ "\n"
        out ++ f"    goto bb{next_bb};"

    mut fn atomic_recv_ptr_text(body: &MirBody, args_id: i32) -> str:
        let recv_operand = self.call_arg_operand(body, args_id, 0)
        let recv = self.operand_text(body, recv_operand)
        let recv_tid = self.sema.resolve_alias(self.operand_tid(body, recv_operand))
        let recv_tk = self.sema.get_type_kind(recv_tid)
        if recv_tk == TypeKind.TY_PTR or recv_tk == TypeKind.TY_REF:
            return "(" ++ recv ++ ")"
        "&(" ++ recv ++ ")"

    mut fn atomic_recv_value_tid(body: &MirBody, args_id: i32) -> i32:
        let recv_operand = self.call_arg_operand(body, args_id, 0)
        var recv_tid = self.sema.resolve_alias(self.operand_tid(body, recv_operand))
        let recv_tk = self.sema.get_type_kind(recv_tid)
        if recv_tk == TypeKind.TY_PTR or recv_tk == TypeKind.TY_REF:
            recv_tid = self.sema.resolve_alias(self.sema.get_type_d0(recv_tid))
        if self.sema.get_type_kind(recv_tid) == TypeKind.TY_GENERIC_INST and self.generic_inst_base_name(recv_tid as i32) == "Atomic":
            if self.sema.get_generic_inst_arg_count(recv_tid as i32) > 0:
                return self.sema.get_generic_inst_arg(recv_tid as i32, 0)
        self.sema.ty_i64 as i32

    fn atomic_order_text(order_text: &str) -> str:
        let o = "(" ++ order_text ++ ")"
        "(" ++ o ++ " == 0 ? __ATOMIC_RELAXED : " ++ o ++ " == 1 ? __ATOMIC_ACQUIRE : " ++ o ++ " == 2 ? __ATOMIC_RELEASE : " ++ o ++ " == 3 ? __ATOMIC_ACQ_REL : __ATOMIC_SEQ_CST)"

    fn call_arg_operand(body: &MirBody, args_id: i32, idx: i32) -> i32:
        if args_id < 0 or args_id >= body.call_arg_starts.len():
            return 0
        let start = body.call_arg_starts[args_id]
        let count = body.call_arg_counts[args_id]
        if idx < 0 or idx >= count:
            return 0
        let at = start + idx
        if at < 0 or at >= body.call_arg_operands.len():
            return 0
        body.call_arg_operands[at]

    mut fn str_concat_n_text(body: &MirBody, args_id: i32, move_first: i32) -> str:
        if args_id < 0 or args_id >= body.call_arg_starts.len():
            self.fail(f"invalid str_concat_n args id {args_id}")
            return "WITH_STR_LIT(\"\")"
        let start = body.call_arg_starts[args_id]
        let count = body.call_arg_counts[args_id]
        if count <= 0:
            return "WITH_STR_LIT(\"\")"
        if count == 1:
            return self.operand_text(body, body.call_arg_operands[start])
        let concat_name = if move_first != 0: "with_str_concat_n_move_first" else: "with_str_concat_n"
        var out = concat_name ++ "((const with_str[]){"
        for i in 0..count:
            if i > 0:
                out = out ++ ", "
            out = out ++ self.str_value_text(body, body.call_arg_operands[(start + i)])
        out ++ "}, " ++ with_i64_to_str(count as i64) ++ ")"

    fn local_assigned_fn_sym_depth(body: &MirBody, local_id: i32, depth: i32) -> i32:
        if local_id < 0:
            return 0
        if depth > 8:
            return 0
        var out: i32 = 0
        for bb in 0..body.block_count():
            let start = body.bb_stmt_starts[bb]
            let count = body.bb_stmt_counts[bb]
            for si in 0..count:
                let stmt_id = start + si
                if body.stmt_kinds[stmt_id] != StmtKind.Assign:
                    continue
                let dst_place = body.stmt_d0[stmt_id]
                if self.place_is_direct_local(body, dst_place, local_id) == 0:
                    continue
                let rval_id = body.stmt_d1[stmt_id]
                if rval_id < 0 or rval_id >= body.rval_kinds.len():
                    continue
                if body.rval_kinds[rval_id] != RvalueKind.RK_USE:
                    continue
                let src_operand = body.rval_d0[rval_id]
                if src_operand < 0 or src_operand >= body.operand_kinds.len():
                    continue
                let ok = body.operand_kinds[src_operand]
                let od = body.operand_d0[src_operand]
                var cand: i32 = 0
                if ok == OperandKind.OK_CONSTANT:
                    if od < 0 or od >= body.const_kinds.len():
                        continue
                    if body.const_kinds[od] != ConstKind.CK_FN:
                        continue
                    cand = body.const_d0[od]
                else if ok == OperandKind.OK_COPY or ok == OperandKind.OK_MOVE:
                    let src_local = self.place_local_id(body, od)
                    if src_local < 0:
                        continue
                    if self.place_is_direct_local(body, od, src_local) == 0:
                        continue
                    cand = self.local_assigned_fn_sym_depth(body, src_local, depth + 1)
                    if cand == -2:
                        return -2
                else:
                    continue
                if cand <= 0:
                    continue
                if out == 0:
                    out = cand
                    continue
                if out != cand:
                    return -2
        out

    fn local_assigned_fn_sym(body: &MirBody, local_id: i32) -> i32:
        self.local_assigned_fn_sym_depth(body, local_id, 0)

    fn call_callee_fn_sym(body: &MirBody, callee_operand: i32) -> i32:
        if callee_operand < 0 or callee_operand >= body.operand_kinds.len():
            return 0
        let ok = body.operand_kinds[callee_operand]
        let od = body.operand_d0[callee_operand]
        if ok == OperandKind.OK_CONSTANT:
            let const_id = od
            if const_id < 0 or const_id >= body.const_kinds.len():
                return 0
            if body.const_kinds[const_id] != ConstKind.CK_FN:
                return 0
            return body.const_d0[const_id]
        if ok == OperandKind.OK_COPY or ok == OperandKind.OK_MOVE:
            let local_id = self.place_local_id(body, od)
            if local_id < 0:
                return 0
            if self.place_is_direct_local(body, od, local_id) == 0:
                return 0
            let inferred = self.local_assigned_fn_sym(body, local_id)
            if inferred > 0:
                return inferred
        0

    fn call_method_base_name(body: &MirBody, callee_operand: i32) -> str:
        let fn_sym = self.call_callee_fn_sym(body, callee_operand)
        if fn_sym == 0:
            return ""
        cc_base_name(cc_intern_resolve(self.intern, fn_sym))

    fn call_first_arg_place_id(body: &MirBody, args_id: i32) -> i32:
        if self.call_arg_count(body, args_id) <= 0:
            return -1
        let first_arg = self.call_arg_operand(body, args_id, 0)
        if first_arg < 0 or first_arg >= body.operand_kinds.len():
            return -1
        let ok = body.operand_kinds[first_arg]
        if ok != OperandKind.OK_COPY and ok != OperandKind.OK_MOVE:
            return -1
        body.operand_d0[first_arg]

    fn place_same(body: &MirBody, a: i32, b: i32) -> i32:
        let _ = self
        if a < 0 or b < 0:
            return 0
        if a >= body.place_locals.len() or b >= body.place_locals.len():
            return 0
        if body.place_locals[a] != body.place_locals[b]:
            return 0
        let ac = body.place_proj_counts[a]
        let bc = body.place_proj_counts[b]
        if ac != bc:
            return 0
        let astart = body.place_proj_starts[a]
        let bstart = body.place_proj_starts[b]
        for i in 0..ac:
            if body.proj_kinds[(astart + i)] != body.proj_kinds[(bstart + i)]:
                return 0
            if body.proj_d0[(astart + i)] != body.proj_d0[(bstart + i)]:
                return 0
        1

    fn place_kind_cache_lookup(body_fn_sym: i32, place_id: i32) -> Option[CcPlaceKind]:
        let raw = self.place_kind_cache.get(cc_body_local_cache_key(body_fn_sym, place_id))
        if raw.is_some():
            return Some(raw.unwrap() as CcPlaceKind)
        None

    fn place_kind_cache_store(body_fn_sym: i32, place_id: i32, kind: CcPlaceKind):
        self.place_kind_cache.insert(cc_body_local_cache_key(body_fn_sym, place_id), kind as i32)

    fn callee_hint_cache_lookup(fn_sym: i32) -> Option[CcCalleeHint]:
        let raw = self.callee_hint_cache.get(fn_sym)
        if raw.is_some():
            return Some(raw.unwrap() as CcCalleeHint)
        None

    fn callee_hint_cache_store(fn_sym: i32, kind: CcCalleeHint):
        self.callee_hint_cache.insert(fn_sym, kind as i32)

    fn callee_field_hint(fn_sym: i32) -> CcCalleeHint:
        if fn_sym == 0:
            return CcCalleeHint.NONE
        let cache_hit = self.callee_hint_cache_lookup(fn_sym)
        if cache_hit.is_some():
            return cache_hit.unwrap()

        let raw = cc_intern_resolve(self.intern, fn_sym)
        let base = cc_base_name(raw)
        let owner = cc_owner_prefix(raw)
        var out = CcCalleeHint.NONE

        if base == "new":
            if owner == "HashMap" or raw.starts_with("HashMap."):
                out = CcCalleeHint.MAP_NEW
            else if owner == "List" or raw.starts_with("List."):
                out = CcCalleeHint.LIST_NEW
            else if owner == "Option" or raw.starts_with("Option."):
                out = CcCalleeHint.OPT_NEW
        else if owner.len() > 0:
            if owner == "HashMap":
                if base == "insert" or base == "get" or base == "contains" or cc_is_len_method(base) or base == "remove":
                    out = CcCalleeHint.MAP_RECV
            else if owner == "List":
                if base == "push" or base == "get" or cc_is_len_method(base) or base == "remove" or base == "clear" or base == "pop":
                    out = CcCalleeHint.LIST_RECV
            else if owner == "Option":
                if base == "is_some" or base == "unwrap" or base == "expect":
                    out = CcCalleeHint.OPT_RECV

        self.callee_hint_cache_store(fn_sym, out)
        out

    fn infer_place_kind_impl(body: &MirBody, place_id: i32) -> CcPlaceKind:
        if place_id < 0 or place_id >= body.place_locals.len():
            return CcPlaceKind.UNKNOWN

        var list_score = 0
        var map_score = 0
        var opt_score = 0

        for bb in 0..body.block_count():
            if body.term_kind(bb) != TermKind.TK_CALL:
                continue
            let args_id = body.term_data1(bb)
            let first_place = self.call_first_arg_place_id(body, args_id)
            if self.place_same(body, first_place, place_id) == 0:
                continue
            let method = self.call_method_base_name(body, body.term_data0(bb))
            if method.len() == 0:
                continue
            if method == "push" or method == "clear" or method == "pop":
                list_score = list_score + 3
                continue
            if method == "insert":
                map_score = map_score + 3
                continue
            if method == "is_some" or method == "unwrap" or method == "expect":
                opt_score = opt_score + 3
                continue
            if method == "get" or cc_is_len_method(method):
                list_score = list_score + 1
                map_score = map_score + 1
                continue
            if method == "contains" or method == "remove":
                map_score = map_score + 1
                continue
            if method == "new":
                list_score = list_score + 1
                map_score = map_score + 1
                continue
        if list_score <= 0 and map_score <= 0 and opt_score <= 0:
            return CcPlaceKind.UNKNOWN
        if list_score >= map_score and list_score >= opt_score:
            return CcPlaceKind.LIST
        if map_score >= opt_score:
            return CcPlaceKind.HASHMAP
        CcPlaceKind.OPTION

    fn infer_place_kind(body: &MirBody, place_id: i32) -> CcPlaceKind:
        let cache_hit = self.place_kind_cache_lookup(body.fn_sym, place_id)
        if cache_hit.is_some():
            return cache_hit.unwrap()
        let kind = self.infer_place_kind_impl(body, place_id)
        self.place_kind_cache_store(body.fn_sym, place_id, kind)
        kind

    fn local_place_kind_depth(body: &MirBody, local_id: i32, depth: i32) -> CcPlaceKind:
        if local_id < 0:
            return CcPlaceKind.UNKNOWN
        if depth > 1:
            return CcPlaceKind.UNKNOWN

        var list_score = 0
        var map_score = 0
        var opt_score = 0

        for bb in 0..body.block_count():
            if body.term_kind(bb) != TermKind.TK_CALL:
                continue
            let args_id = body.term_data1(bb)
            let first_place = self.call_first_arg_place_id(body, args_id)
            if self.place_is_direct_local(body, first_place, local_id) == 0:
                continue
            let method = self.call_method_base_name(body, body.term_data0(bb))
            if method.len() == 0:
                continue
            if method == "push" or method == "clear" or method == "pop":
                list_score = list_score + 4
                continue
            if method == "insert" or method == "contains":
                map_score = map_score + 4
                continue
            if method == "is_some" or method == "unwrap" or method == "expect":
                opt_score = opt_score + 4
                continue
            if method == "get" or cc_is_len_method(method):
                list_score = list_score + 1
                map_score = map_score + 1
                continue
            if method == "remove":
                map_score = map_score + 2
                list_score = list_score + 1
                continue

        for bb in 0..body.block_count():
            let start = body.bb_stmt_starts[bb]
            let count = body.bb_stmt_counts[bb]
            for si in 0..count:
                let stmt_id = start + si
                if body.stmt_kinds[stmt_id] != StmtKind.Assign:
                    continue
                let rval_id = body.stmt_d1[stmt_id]
                if rval_id < 0 or rval_id >= body.rval_kinds.len():
                    continue
                if body.rval_kinds[rval_id] != RvalueKind.RK_USE:
                    continue
                let src_operand = body.rval_d0[rval_id]
                if src_operand < 0 or src_operand >= body.operand_kinds.len():
                    continue
                let ok = body.operand_kinds[src_operand]
                if ok != OperandKind.OK_COPY and ok != OperandKind.OK_MOVE:
                    continue
                let src_place = body.operand_d0[src_operand]
                let dst_place = body.stmt_d0[stmt_id]
                let src_local = self.place_local_id(body, src_place)
                let dst_local = self.place_local_id(body, dst_place)
                if src_local < 0 or dst_local < 0:
                    continue
                if self.place_is_direct_local(body, src_place, src_local) == 0:
                    continue
                if self.place_is_direct_local(body, dst_place, dst_local) == 0:
                    continue
                if src_local == local_id:
                    let k = self.local_place_kind_depth(body, dst_local, depth + 1)
                    if k == CcPlaceKind.LIST:
                        list_score = list_score + 2
                    else if k == CcPlaceKind.HASHMAP:
                        map_score = map_score + 2
                    else if k == CcPlaceKind.OPTION:
                        opt_score = opt_score + 2
                if dst_local == local_id:
                    let k = self.local_place_kind_depth(body, src_local, depth + 1)
                    if k == CcPlaceKind.LIST:
                        list_score = list_score + 2
                    else if k == CcPlaceKind.HASHMAP:
                        map_score = map_score + 2
                    else if k == CcPlaceKind.OPTION:
                        opt_score = opt_score + 2

        if list_score <= 0 and map_score <= 0 and opt_score <= 0:
            return CcPlaceKind.UNKNOWN
        if list_score >= map_score and list_score >= opt_score:
            return CcPlaceKind.LIST
        if map_score >= opt_score:
            return CcPlaceKind.HASHMAP
        CcPlaceKind.OPTION

    fn local_place_kind(body: &MirBody, local_id: i32) -> CcPlaceKind:
        self.local_place_kind_depth(body, local_id, 0)

    mut fn call_dest_expected_tid(body: &MirBody, dest_place: i32) -> i32:
        let dest_tid = self.place_local_tid(body, dest_place)
        if self.in_field_cache_build != 0:
            return dest_tid
        if dest_tid == CC_PSEUDO_TID_LIST:
            return dest_tid
        let dst_local = self.place_local_id(body, dest_place)
        if dst_local < 0:
            return dest_tid
        let sig_idx = self.body_sig_index(body.fn_sym)
        let param_count = if sig_idx >= 0: self.sema.sig_get_param_count(sig_idx) else: 0
        if dst_local >= 1 and dst_local <= param_count:
            return dest_tid
        let hinted = self.local_usage_hint_tid(body, dst_local)
        if hinted != 0 and self.is_void_tid(hinted) == 0:
            return hinted
        let resolved = self.sema.resolve_alias(dest_tid)
        let tk = self.sema.get_type_kind(resolved)
        if tk == TypeKind.TY_STRUCT or tk == TypeKind.TY_PTR or tk == TypeKind.TY_REF:
            return dest_tid
        0

    fn sig_matches_call_name(sig_sym: i32, fn_sym: i32) -> i32:
        if sig_sym == fn_sym:
            return 1
        let raw = cc_intern_resolve(self.intern, fn_sym)
        if raw.len() == 0:
            return 0
        let sig_text = cc_intern_resolve(self.intern, sig_sym)
        if cc_str_contains_dot(raw) != 0:
            if sig_text == raw:
                return 1
            return 0
        if sig_text == raw:
            return 1
        if cc_str_ends_with(sig_text, "." ++ raw) != 0:
            return 1
        0

    mut fn infer_named_call_sym_scan(body: &MirBody, fn_sym: i32, args_id: i32, dest_place: i32, only_local_defs: i32) -> i32:
        let raw = cc_intern_resolve(self.intern, fn_sym)
        if raw.len() == 0:
            return 0
        let base_name = cc_base_name(raw)
        let arg_count = self.call_arg_count(body, args_id)
        let want_ret_tid = self.call_dest_expected_tid(body, dest_place)
        var match_sym: i32 = 0
        var match_score = -1
        for si in 0..self.sema.sig_names.len() as i32:
            let sym: i32 = self.sema.sig_names[si]
            if only_local_defs != 0 and self.has_body_for_sym(sym) == 0:
                continue
            if self.sig_matches_call_name(sym, fn_sym) == 0:
                continue
            if self.sema.sig_get_param_count(si) != arg_count:
                continue
            let sym_text = cc_intern_resolve(self.intern, sym)
            let ret_tid = self.c_sig_return_type(si)
            if self.is_void_tid(want_ret_tid) == 0 and self.strict_type_match(want_ret_tid, ret_tid) == 0:
                continue
            var params_ok = 1
            for ai in 0..arg_count:
                let arg_operand = self.call_arg_operand(body, args_id, ai)
                var arg_tid = self.operand_tid_no_infer(body, arg_operand)
                if self.is_void_tid(arg_tid) != 0 and self.infer_local_depth == 0:
                    arg_tid = self.operand_tid(body, arg_operand)
                let p_tid = self.sema.sig_param_type(si, ai)
                if self.is_void_tid(arg_tid) == 0 and self.strict_type_match(p_tid, arg_tid) == 0:
                    params_ok = 0
                    break
            if params_ok == 0:
                continue
            var score = 0
            if sym == fn_sym or sym_text == raw:
                score = score + 4
            if cc_str_contains_dot(raw) == 0 and cc_str_ends_with(sym_text, "." ++ raw) != 0:
                score = score + 2
            if self.has_body_for_sym(sym) != 0:
                score = score + 1
            if score > match_score:
                match_score = score
                match_sym = sym
        match_sym

    mut fn infer_named_call_sym(body: &MirBody, fn_sym: i32, args_id: i32, dest_place: i32) -> i32:
        if self.infer_local_depth > 0:
            return self.infer_named_call_sym_scan(body, fn_sym, args_id, dest_place, 1)
        let cached = self.call_infer_cache_lookup("named", body.fn_sym, fn_sym, args_id, dest_place)
        if cached != -1234567:
            return cached
        let result = self.infer_named_call_sym_scan(body, fn_sym, args_id, dest_place, 1)
        self.call_infer_cache_store("named", body.fn_sym, fn_sym, args_id, dest_place, result)
        result

    mut fn infer_body_method_sym(body: &MirBody, fn_sym: i32, args_id: i32, dest_place: i32) -> i32:
        if self.infer_local_depth == 0:
            let cached = self.call_infer_cache_lookup("body-method", body.fn_sym, fn_sym, args_id, dest_place)
            if cached != -1234567:
                return cached
        let raw = cc_intern_resolve(self.intern, fn_sym)
        if raw.len() == 0:
            if self.infer_local_depth == 0:
                self.call_infer_cache_store("body-method", body.fn_sym, fn_sym, args_id, dest_place, 0)
            return 0
        let base_name = cc_base_name(raw)
        let argc = self.call_arg_count(body, args_id)
        let want_ret_tid = self.call_dest_expected_tid(body, dest_place)
        let first_arg_tid = self.call_first_arg_resolved_tid(body, args_id)
        let first_owner = self.type_owner_text(first_arg_tid)
        var match_sym: i32 = 0
        var match_score = -1
        for i in 0..self.mir_mod.body_fn_syms.len():
            let cand: i32 = self.mir_mod.body_fn_syms[i]
            let cand_text = cc_intern_resolve(self.intern, cand)
            if cc_name_matches(cand_text, raw) == 0:
                continue
            let sig_idx = self.sig_index_for_sym(cand)
            if sig_idx < 0:
                continue
            if self.sema.sig_get_param_count(sig_idx) != argc:
                continue
            let ret_tid = self.c_sig_return_type(sig_idx)
            if self.is_void_tid(want_ret_tid) == 0 and self.strict_type_match(want_ret_tid, ret_tid) == 0:
                continue
            var params_ok = 1
            for ai in 0..argc:
                let arg_operand = self.call_arg_operand(body, args_id, ai)
                var arg_tid = self.operand_tid_no_infer(body, arg_operand)
                if self.is_void_tid(arg_tid) != 0 and self.infer_local_depth == 0:
                    arg_tid = self.operand_tid(body, arg_operand)
                let p_tid = self.sema.sig_param_type(sig_idx, ai)
                if self.is_void_tid(arg_tid) == 0 and self.strict_type_match(p_tid, arg_tid) == 0:
                    params_ok = 0
                    break
            if params_ok == 0:
                continue
            var score = 0
            if cand_text == raw:
                score = score + 4
            if cc_str_ends_with(cand_text, "." ++ raw) != 0:
                score = score + 3
            if first_owner.len() > 0:
                let owner = cc_owner_prefix(cand_text)
                if owner == first_owner or cc_str_ends_with(owner, "." ++ first_owner) != 0:
                    score = score + 2
            if score > match_score:
                match_score = score
                match_sym = cand
        if self.infer_local_depth == 0:
            self.call_infer_cache_store("body-method", body.fn_sym, fn_sym, args_id, dest_place, match_sym)
        match_sym

    mut fn infer_direct_call_sym_scan(body: &MirBody, args_id: i32, dest_place: i32, only_local_defs: i32) -> i32:
        let arg_count = self.call_arg_count(body, args_id)
        let want_ret_tid = self.call_dest_expected_tid(body, dest_place)
        var match_sym: i32 = 0
        var match_score = -1
        for si in 0..self.sema.sig_names.len() as i32:
            let sym: i32 = self.sema.sig_names[si]
            if only_local_defs != 0 and self.has_body_for_sym(sym) == 0:
                continue
            if self.sema.sig_get_param_count(si) != arg_count:
                continue
            let ret_tid = self.c_sig_return_type(si)
            if self.is_void_tid(want_ret_tid) == 0 and self.strict_type_match(want_ret_tid, ret_tid) == 0:
                continue
            var params_ok = 1
            for ai in 0..arg_count:
                let arg_operand = self.call_arg_operand(body, args_id, ai)
                var arg_tid = self.operand_tid_no_infer(body, arg_operand)
                if self.is_void_tid(arg_tid) != 0 and self.infer_local_depth == 0:
                    arg_tid = self.operand_tid(body, arg_operand)
                let p_tid = self.sema.sig_param_type(si, ai)
                if self.is_void_tid(arg_tid) == 0 and self.strict_type_match(p_tid, arg_tid) == 0:
                    params_ok = 0
                    break
            if params_ok == 0:
                continue
            var score = 0
            if self.has_body_for_sym(sym) != 0:
                score = score + 2
            if self.is_void_tid(want_ret_tid) == 0:
                score = score + 1
            if score > match_score:
                match_score = score
                match_sym = sym
        match_sym

    mut fn describe_call_candidates(body: &MirBody, args_id: i32, dest_place: i32, only_local_defs: i32) -> str:
        let arg_count = self.call_arg_count(body, args_id)
        let dest_tid = self.place_local_tid(body, dest_place)
        var out = ""
        var kept = 0
        for si in 0..self.sema.sig_names.len() as i32:
            let sym: i32 = self.sema.sig_names[si]
            if only_local_defs != 0 and self.has_body_for_sym(sym) == 0:
                continue
            if self.sema.sig_get_param_count(si) != arg_count:
                continue
            let ret_tid = self.c_sig_return_type(si)
            if self.type_match(dest_tid, ret_tid) == 0:
                continue
            var params_ok = 1
            for ai in 0..arg_count:
                let arg_operand = self.call_arg_operand(body, args_id, ai)
                let arg_tid = self.operand_tid(body, arg_operand)
                let p_tid = self.sema.sig_param_type(si, ai)
                if self.type_match(p_tid, arg_tid) == 0:
                    params_ok = 0
                    break
            if params_ok == 0:
                continue
            if kept > 0:
                out = out ++ ","
            out = out ++ cc_intern_resolve(self.intern, sym) ++ f"#{sym}"
            kept = kept + 1
            if kept >= 12:
                out = out ++ ",..."
                break
        out

    fn describe_qualified_method_candidates(body: &MirBody, method_sym: i32, args_id: i32, only_local_defs: i32) -> str:
        let raw = cc_intern_resolve(self.intern, method_sym)
        if raw.len() == 0:
            return ""
        let wanted = "." ++ raw
        let arg_count = self.call_arg_count(body, args_id)
        var out = ""
        for si in 0..self.sema.sig_names.len():
            let sym = self.sema.sig_names[si]
            if only_local_defs != 0 and self.has_body_for_sym(sym) == 0:
                continue
            if self.sema.sig_get_param_count(si as i32) != arg_count:
                continue
            let sym_text = cc_intern_resolve(self.intern, sym)
            if cc_str_ends_with(sym_text, wanted) == 0:
                continue
            if out.len() > 0:
                out = out ++ ", "
            out = out ++ sym_text
            if out.len() > 512:
                return out ++ ", ..."
        out

    mut fn call_arg_tids_text(body: &MirBody, args_id: i32) -> str:
        let arg_count = self.call_arg_count(body, args_id)
        var out = ""
        for ai in 0..arg_count:
            if ai > 0:
                out = out ++ ","
            let arg_operand = self.call_arg_operand(body, args_id, ai)
            out = out ++ f"{self.operand_tid(body, arg_operand)}"
        out

    mut fn call_first_arg_hint_text(body: &MirBody, args_id: i32) -> str:
        if self.call_arg_count(body, args_id) <= 0:
            return ""
        let first_arg = self.call_arg_operand(body, args_id, 0)
        let first_arg_tid = self.operand_tid(body, first_arg)
        let owner_text = self.type_owner_text(first_arg_tid)
        f"tid={first_arg_tid} type={self.sema.type_name(first_arg_tid)} owner={owner_text}"

    mut fn call_first_arg_resolved_tid(body: &MirBody, args_id: i32) -> i32:
        if self.call_arg_count(body, args_id) <= 0:
            return 0
        let first_arg = self.call_arg_operand(body, args_id, 0)
        let first_arg_tid = self.operand_tid(body, first_arg)
        self.sema.resolve_alias(first_arg_tid as TypeId) as i32

    mut fn type_owner_text(tid: i32) -> str:
        let resolved = self.sema.resolve_alias(tid)
        if resolved == 0:
            return ""
        if self.sema.get_type_kind(resolved) == TypeKind.TY_STRUCT:
            let sym = self.sema.get_type_d0(resolved)
            if sym != 0:
                return cc_intern_resolve(self.intern, sym)
        let owner_sym = self.sema.dyn_arg_concrete_type_symbol(resolved)
        if owner_sym != 0:
            return cc_intern_resolve(self.intern, owner_sym)
        ""

    mut fn call_first_arg_owner_text(body: &MirBody, args_id: i32) -> str:
        let first_tid = self.call_first_arg_resolved_tid(body, args_id)
        self.type_owner_text(first_tid)

    mut fn owner_named_body_sym(body: &MirBody, fn_sym: i32, args_id: i32) -> i32:
        let raw = cc_intern_resolve(self.intern, fn_sym)
        if raw.len() == 0:
            return 0
        if cc_str_contains_dot(raw) != 0:
            return 0
        if self.call_arg_count(body, args_id) <= 0:
            return 0
        let owner_tid = self.call_first_arg_resolved_tid(body, args_id)
        let owner = self.type_owner_text(owner_tid)
        if owner.len() == 0:
            return 0
        let full = owner ++ "." ++ raw
        self.lookup_body_sym_by_name(full)

    fn method_infer_active(method_sym: i32, args_id: i32, dest_place: i32) -> i32:
        for i in 0..self.active_method_syms.len():
            if self.active_method_syms[i] != method_sym:
                continue
            if self.active_method_args[i] != args_id:
                continue
            if self.active_method_dests[i] != dest_place:
                continue
            return 1
        0

    fn method_infer_push(method_sym: i32, args_id: i32, dest_place: i32) -> Unit:
        self.active_method_syms.push(method_sym)
        self.active_method_args.push(args_id)
        self.active_method_dests.push(dest_place)

    fn method_infer_pop():
        if self.active_method_syms.len() == 0:
            return
        self.active_method_syms.pop()
        self.active_method_args.pop()
        self.active_method_dests.pop()

    fn direct_infer_active(args_id: i32, dest_place: i32) -> i32:
        for i in 0..self.active_direct_args.len():
            if self.active_direct_args[i] != args_id:
                continue
            if self.active_direct_dests[i] != dest_place:
                continue
            return 1
        0

    fn direct_infer_push(args_id: i32, dest_place: i32) -> Unit:
        self.active_direct_args.push(args_id)
        self.active_direct_dests.push(dest_place)

    fn direct_infer_pop():
        if self.active_direct_args.len() == 0:
            return
        self.active_direct_args.pop()
        self.active_direct_dests.pop()

fn cc_call_infer_cache_key(kind: &str, body_fn_sym: i32, callee_sym: i32, args_id: i32, dest_place: i32) -> str:
    kind ++ ":" ++ f"{body_fn_sym}" ++ ":" ++ f"{callee_sym}" ++ ":" ++ f"{args_id}" ++ ":" ++ f"{dest_place}"

impl CCodegen:
    fn call_infer_cache_lookup(kind: &str, body_fn_sym: i32, callee_sym: i32, args_id: i32, dest_place: i32) -> i32:
        let cached = self.call_infer_cache.get(cc_call_infer_cache_key(kind, body_fn_sym, callee_sym, args_id, dest_place))
        if cached.is_some():
            return cached.unwrap()
        -1234567

    fn call_infer_cache_store(kind: &str, body_fn_sym: i32, callee_sym: i32, args_id: i32, dest_place: i32, value: i32) -> Unit:
        self.call_infer_cache.insert(cc_call_infer_cache_key(kind, body_fn_sym, callee_sym, args_id, dest_place), value)

    fn field_cache_lookup(struct_tid: i32, field_sym: i32) -> i32:
        for i in 0..self.field_cache_struct_tids.len():
            if self.field_cache_struct_tids[i] != struct_tid:
                continue
            if self.field_cache_syms[i] != field_sym:
                continue
            return self.field_cache_tids[i]
        -1234567

    fn field_cache_store(struct_tid: i32, field_sym: i32, tid: i32) -> Unit:
        self.field_cache_struct_tids.push(struct_tid)
        self.field_cache_syms.push(field_sym)
        self.field_cache_tids.push(tid)

    fn field_cache_record(struct_tid: i32, field_sym: i32, tid: i32):
        if tid == 0 or self.is_void_tid(tid) != 0:
            return
        if self.field_cache_lookup(struct_tid, field_sym) != -1234567:
            return
        self.field_cache_store(struct_tid, field_sym, self.sema.resolve_alias(tid))

// The local statement `stmt_id` assigns as a whole, or -1.
fn cc_direct_assign_local(body: &MirBody, stmt_id: i32) -> i32:
    if body.stmt_kinds[stmt_id] != StmtKind.Assign: return -1
    let dst = body.stmt_d0[stmt_id]
    if dst < 0 or dst >= body.place_locals.len() or body.place_proj_counts[dst] != 0: return -1
    let local = body.place_locals[dst]
    if local < 0 or local >= body.local_count(): -1 else: local

// One global's C definition, and the C name that reaches it.
type CGlobalDef {
    sym: i32,
    name: str,
    text: str,
}

// Which bodies the emitted C reaches: a body is marked when C text names
// it (`scan`) or it is a root (`mark`), and emitted once (`take`).
type CReach {
    by_name: HashMap[str, i32],
    marked: List[bool],
    done: List[bool],
    waiting: isize,
}

fn CReach.new(n: isize) -> CReach:
    var marked: List[bool] = List.new()
    var done: List[bool] = List.new()
    for _ in 0..n:
        marked.push(false)
        done.push(false)
    CReach { by_name: HashMap.new(), marked, done, waiting: 0 }

impl CReach:
    mut fn name(c_name: str, body: i32): self.by_name.insert(c_name, body)

    mut fn mark(body: i32):
        if self.marked[body]: return
        self.marked[body] = true
        self.waiting += 1

    // Mark every body an identifier of `text` names. Internal names end in
    // `__<sym>` (fn_c_name), so only such identifiers are looked up.
    mut fn scan(text: &str):
        var i: isize = 0
        let n = text.len()
        while i < n:
            let c = text[i]
            if cc_is_ident_char(c) == 0:
                i += 1
                continue
            let start = i
            while i < n and cc_is_ident_char(text[i]) != 0: i += 1
            if not is_digit(text[i - 1] as i32) or i - start < 4: continue
            let id = text.slice(start, i)
            if not id.contains("__"): continue
            let body: i32 = self.by_name.get(id) ?? -1
            if body >= 0: self.mark(body)

    // Whether `body` is marked and not yet emitted; marks it emitted.
    mut fn take(body: i32) -> bool:
        if not self.marked[body] or self.done[body]: return false
        self.done[body] = true
        self.waiting -= 1
        true

    fn pending(): self.waiting > 0

    fn emitted(body: i32): self.done[body]

fn cc_body_local_cache_key(body_fn_sym: i32, local_id: i32) -> i64:
    (body_fn_sym as i64) + ((local_id as i64) * 4294967296)

impl CCodegen:
    fn local_infer_cache_lookup(body_fn_sym: i32, local_id: i32) -> i32:
        let cached = self.local_infer_cache.get(cc_body_local_cache_key(body_fn_sym, local_id))
        if cached.is_some():
            return cached.unwrap()
        -1234567

    fn local_infer_cache_store(body_fn_sym: i32, local_id: i32, tid: i32):
        self.local_infer_cache.insert(cc_body_local_cache_key(body_fn_sym, local_id), tid)

    fn local_usage_hint_cache_lookup(body_fn_sym: i32, local_id: i32) -> i32:
        let cached = self.local_usage_hint_cache.get(cc_body_local_cache_key(body_fn_sym, local_id))
        if cached.is_some():
            return cached.unwrap()
        -1234567

    fn local_usage_hint_cache_store(body_fn_sym: i32, local_id: i32, tid: i32):
        self.local_usage_hint_cache.insert(cc_body_local_cache_key(body_fn_sym, local_id), tid)

    mut fn local_usage_hint_tid(body: &MirBody, local_id: i32) -> i32:
        if local_id < 0:
            return 0
        let cache_hit = self.local_usage_hint_cache_lookup(body.fn_sym, local_id)
        if cache_hit != -1234567:
            return cache_hit
        var hint_tid: i32 = 0

        // Prefer concrete typed use-sites where this local flows into a known call parameter.
        for bb in 0..body.block_count():
            if body.term_kind(bb) != TermKind.TK_CALL:
                continue
            let callee_operand = body.term_data0(bb)
            let args_id = body.term_data1(bb)
            var sig_idx: i32 = -1
            let fn_sym = self.call_callee_fn_sym(body, callee_operand)
            if fn_sym != 0:
                sig_idx = self.sig_index_for_sym(fn_sym)
            if sig_idx < 0:
                continue
            let argc = self.call_arg_count(body, args_id)
            for ai in 0..argc:
                let arg_operand = self.call_arg_operand(body, args_id, ai)
                if arg_operand < 0 or arg_operand >= body.operand_kinds.len():
                    continue
                let ok = body.operand_kinds[arg_operand]
                if ok != OperandKind.OK_COPY and ok != OperandKind.OK_MOVE:
                    continue
                let p = body.operand_d0[arg_operand]
                if self.place_is_direct_local(body, p, local_id) == 0:
                    continue
                let param_count = self.sema.sig_get_param_count(sig_idx)
                if ai < 0 or ai >= param_count:
                    continue
                let p_tid = self.sema.sig_param_type(sig_idx, ai)
                if p_tid == 0 or self.is_void_tid(p_tid) != 0:
                    continue
                if hint_tid == 0 or self.is_void_tid(hint_tid) != 0:
                    hint_tid = p_tid
                    continue
                if self.type_match(hint_tid, p_tid) != 0:
                    continue
            if hint_tid != 0 and self.is_void_tid(hint_tid) == 0:
                self.local_usage_hint_cache_store(body.fn_sym, local_id, hint_tid)
                return hint_tid

        // Locals that are first initialized independently and then moved into a
        // typed aggregate field still need the field's semantic type. This is
        // especially important for erased runtime handles such as HashMap[K, V]:
        // the C storage is an i64, but HashMap.new() must know K and V to allocate
        // the runtime map with the right key/value slot sizes.
        for bb in 0..body.block_count():
            let start = body.bb_stmt_starts[bb]
            let count = body.bb_stmt_counts[bb]
            for si in 0..count:
                let stmt_id = start + si
                if body.stmt_kinds[stmt_id] != StmtKind.Assign:
                    continue
                let rval_id = body.stmt_d1[stmt_id]
                if rval_id < 0 or rval_id >= body.rval_kinds.len():
                    continue
                if body.rval_kinds[rval_id] != RvalueKind.RK_AGGREGATE:
                    continue
                let fields_id = body.rval_d1[rval_id]
                if fields_id < 0 or fields_id >= body.agg_field_starts.len():
                    continue
                let dst_tid = self.place_tid_no_infer(body, body.stmt_d0[stmt_id])
                let dst_resolved = self.sema.resolve_alias(dst_tid)
                if self.sema.get_type_kind(dst_resolved) != TypeKind.TY_STRUCT:
                    continue
                let field_start = body.agg_field_starts[fields_id]
                let field_count = body.agg_field_counts[fields_id]
                for fi in 0..field_count:
                    let operand_id = body.agg_field_operands[(field_start + fi)]
                    if self.operand_direct_local_id(body, operand_id) != local_id:
                        continue
                    let name_sym = body.agg_field_name_syms[(field_start + fi)]
                    if name_sym == 0:
                        continue
                    let field_tid = self.struct_field_tid(dst_resolved as i32, name_sym)
                    if field_tid == 0 or self.is_void_tid(field_tid) != 0:
                        continue
                    hint_tid = field_tid
                    self.local_usage_hint_cache_store(body.fn_sym, local_id, hint_tid)
                    return hint_tid

        // Fallback: assignments from this local into a concretely typed local.
        for bb in 0..body.block_count():
            let start = body.bb_stmt_starts[bb]
            let count = body.bb_stmt_counts[bb]
            for si in 0..count:
                let stmt_id = start + si
                if body.stmt_kinds[stmt_id] != StmtKind.Assign:
                    continue
                let rval_id = body.stmt_d1[stmt_id]
                if rval_id < 0 or rval_id >= body.rval_kinds.len():
                    continue
                if body.rval_kinds[rval_id] != RvalueKind.RK_USE:
                    continue
                let src_operand = body.rval_d0[rval_id]
                if src_operand < 0 or src_operand >= body.operand_kinds.len():
                    continue
                let ok = body.operand_kinds[src_operand]
                if ok != OperandKind.OK_COPY and ok != OperandKind.OK_MOVE:
                    continue
                let src_place = body.operand_d0[src_operand]
                if self.place_is_direct_local(body, src_place, local_id) == 0:
                    continue
                let dst_place = body.stmt_d0[stmt_id]
                if self.place_is_direct_local(body, dst_place, local_id) != 0:
                    continue
                let dst_tid = self.place_tid_no_infer(body, dst_place)
                if dst_tid == 0 or self.is_void_tid(dst_tid) != 0:
                    continue
                hint_tid = dst_tid
                self.local_usage_hint_cache_store(body.fn_sym, local_id, hint_tid)
                return hint_tid

        self.local_usage_hint_cache_store(body.fn_sym, local_id, hint_tid)
        hint_tid

    mut fn infer_direct_call_sym(body: &MirBody, args_id: i32, dest_place: i32) -> i32:
        let cache_hit = self.call_infer_cache_lookup("direct", body.fn_sym, 0, args_id, dest_place)
        if cache_hit != -1234567:
            return cache_hit
        if self.direct_infer_active(args_id, dest_place) != 0:
            self.call_infer_cache_store("direct", body.fn_sym, 0, args_id, dest_place, 0)
            return 0
        self.direct_infer_push(args_id, dest_place)
        let local_scan = self.infer_direct_call_sym_scan(body, args_id, dest_place, 1)
        var result: i32 = 0
        if local_scan == -2 or local_scan > 0:
            result = local_scan
        else:
            result = self.infer_direct_call_sym_scan(body, args_id, dest_place, 0)
        self.direct_infer_pop()
        self.call_infer_cache_store("direct", body.fn_sym, 0, args_id, dest_place, result)
        result

    fn unique_method_owner_from_name(body: &MirBody, fn_sym: i32, args_id: i32) -> str:
        let raw = cc_intern_resolve(self.intern, fn_sym)
        if raw.len() == 0:
            return ""
        if cc_str_contains_dot(raw) != 0:
            return cc_owner_prefix(raw)
        let wanted = "." ++ raw
        let arg_count = self.call_arg_count(body, args_id)
        var out = ""
        for si in 0..self.sema.sig_names.len():
            if self.sema.sig_get_param_count(si as i32) != arg_count:
                continue
            let sym_text = cc_intern_resolve(self.intern, self.sema.sig_names[si])
            if cc_str_ends_with(sym_text, wanted) == 0:
                continue
            let owner = cc_owner_prefix(sym_text)
            if owner.len() == 0:
                continue
            if out.len() == 0:
                out = owner
            else if out != owner:
                return ""
        out

    fn local_owner_hint_depth(body: &MirBody, local_id: i32, depth: i32) -> str:
        if depth > 8:
            return ""
        for bb in 0..body.block_count():
            if body.term_kind(bb) != TermKind.TK_CALL:
                continue
            let dest_place = body.term_data2(bb)
            if self.place_is_direct_local(body, dest_place, local_id) == 0:
                continue
            let callee_operand = body.term_data0(bb)
            if callee_operand < 0 or callee_operand >= body.operand_kinds.len():
                continue
            if body.operand_kinds[callee_operand] != OperandKind.OK_CONSTANT:
                continue
            let const_id = body.operand_d0[callee_operand]
            if const_id < 0 or const_id >= body.const_kinds.len():
                continue
            if body.const_kinds[const_id] != ConstKind.CK_FN:
                continue
            let fn_sym = body.const_d0[const_id]
            if fn_sym == 0:
                continue
            let raw = cc_intern_resolve(self.intern, fn_sym)
            let owner = cc_owner_prefix(raw)
            if owner.len() > 0:
                return owner

        for bb in 0..body.block_count():
            let start = body.bb_stmt_starts[bb]
            let count = body.bb_stmt_counts[bb]
            for si in 0..count:
                let stmt_id = start + si
                if body.stmt_kinds[stmt_id] != StmtKind.Assign:
                    continue
                let dst_place = body.stmt_d0[stmt_id]
                if self.place_is_direct_local(body, dst_place, local_id) == 0:
                    continue
                let rval_id = body.stmt_d1[stmt_id]
                if rval_id < 0 or rval_id >= body.rval_kinds.len():
                    continue
                if body.rval_kinds[rval_id] != RvalueKind.RK_USE:
                    continue
                let op = body.rval_d0[rval_id]
                if op < 0 or op >= body.operand_kinds.len():
                    continue
                let ok = body.operand_kinds[op]
                if ok != OperandKind.OK_COPY and ok != OperandKind.OK_MOVE:
                    continue
                let p = body.operand_d0[op]
                let src_local = self.place_local_id(body, p)
                if src_local < 0 or src_local == local_id:
                    continue
                let owner = self.local_owner_hint_depth(body, src_local, depth + 1)
                if owner.len() > 0:
                    return owner
        for bb in 0..body.block_count():
            if body.term_kind(bb) != TermKind.TK_CALL:
                continue
            let args_id = body.term_data1(bb)
            if self.call_arg_count(body, args_id) <= 0:
                continue
            let first_arg = self.call_arg_operand(body, args_id, 0)
            if first_arg < 0 or first_arg >= body.operand_kinds.len():
                continue
            let ok = body.operand_kinds[first_arg]
            if ok != OperandKind.OK_COPY and ok != OperandKind.OK_MOVE:
                continue
            let p = body.operand_d0[first_arg]
            if self.place_is_direct_local(body, p, local_id) == 0:
                continue
            let callee_operand = body.term_data0(bb)
            if callee_operand < 0 or callee_operand >= body.operand_kinds.len():
                continue
            if body.operand_kinds[callee_operand] != OperandKind.OK_CONSTANT:
                continue
            let const_id = body.operand_d0[callee_operand]
            if const_id < 0 or const_id >= body.const_kinds.len():
                continue
            if body.const_kinds[const_id] != ConstKind.CK_FN:
                continue
            let fn_sym = body.const_d0[const_id]
            if fn_sym == 0:
                continue
            let owner = self.unique_method_owner_from_name(body, fn_sym, args_id)
            if owner.len() > 0:
                return owner
        ""

    fn local_owner_hint(body: &MirBody, local_id: i32) -> str:
        self.local_owner_hint_depth(body, local_id, 0)

    mut fn infer_qualified_method_sym_scan(body: &MirBody, method_sym: i32, args_id: i32, dest_place: i32, only_local_defs: i32) -> i32:
        let raw = cc_intern_resolve(self.intern, method_sym)
        if raw.len() == 0:
            return 0
        let wanted = "." ++ raw
        let arg_count = self.call_arg_count(body, args_id)
        let want_ret_tid = self.call_dest_expected_tid(body, dest_place)
        var preferred_owner = ""
        if arg_count > 0:
            let first_arg_tid = self.call_first_arg_resolved_tid(body, args_id)
            preferred_owner = self.type_owner_text(first_arg_tid)

        var match_sym: i32 = 0
        var match_score = -1
        for si in 0..self.sema.sig_names.len() as i32:
            let sym: i32 = self.sema.sig_names[si]
            if only_local_defs != 0 and self.has_body_for_sym(sym) == 0:
                continue
            if self.sema.sig_get_param_count(si) != arg_count:
                continue
            let sym_text = cc_intern_resolve(self.intern, sym)
            if cc_str_ends_with(sym_text, wanted) == 0:
                continue
            let owner = cc_owner_prefix(sym_text)
            let owner_matched = if preferred_owner.len() > 0 and owner == preferred_owner: 1 else: 0
            let ret_tid = self.c_sig_return_type(si)
            if self.is_void_tid(want_ret_tid) == 0 and self.strict_type_match(want_ret_tid, ret_tid) == 0:
                continue
            var params_ok = 1
            for ai in 0..arg_count:
                let arg_operand = self.call_arg_operand(body, args_id, ai)
                var arg_tid = self.operand_tid_no_infer(body, arg_operand)
                if self.is_void_tid(arg_tid) != 0 and self.infer_local_depth == 0:
                    arg_tid = self.operand_tid(body, arg_operand)
                let p_tid = self.sema.sig_param_type(si, ai)
                if ai == 0 and owner_matched != 0:
                    continue
                if self.is_void_tid(arg_tid) == 0 and self.strict_type_match(p_tid, arg_tid) == 0:
                    params_ok = 0
                    break
            if params_ok == 0:
                continue
            var score = 0
            if owner_matched != 0:
                score = score + 4
            if self.has_body_for_sym(sym) != 0:
                score = score + 2
            if score > match_score:
                match_score = score
                match_sym = sym
        match_sym

    mut fn infer_qualified_method_sym(body: &MirBody, method_sym: i32, args_id: i32, dest_place: i32) -> i32:
        if self.infer_local_depth > 0:
            return self.infer_qualified_method_sym_scan(body, method_sym, args_id, dest_place, 1)
        let cache_hit = self.call_infer_cache_lookup("qualified-method", body.fn_sym, method_sym, args_id, dest_place)
        if cache_hit != -1234567:
            return cache_hit
        if self.method_infer_active(method_sym, args_id, dest_place) != 0:
            self.call_infer_cache_store("qualified-method", body.fn_sym, method_sym, args_id, dest_place, 0)
            return 0
        self.method_infer_push(method_sym, args_id, dest_place)
        let local_scan = self.infer_qualified_method_sym_scan(body, method_sym, args_id, dest_place, 1)
        var result: i32 = 0
        if local_scan == -2 or local_scan > 0:
            result = local_scan
        else:
            result = self.infer_qualified_method_sym_scan(body, method_sym, args_id, dest_place, 0)
        self.method_infer_pop()
        self.call_infer_cache_store("qualified-method", body.fn_sym, method_sym, args_id, dest_place, result)
        result

    mut fn infer_owner_method_sym_scan(body: &MirBody, fn_sym: i32, args_id: i32, dest_place: i32, only_local_defs: i32) -> i32:
        if self.call_arg_count(body, args_id) <= 0:
            return 0
        let raw = cc_intern_resolve(self.intern, fn_sym)
        if raw.len() == 0:
            return 0
        if cc_str_contains_dot(raw) != 0:
            return 0
        let first_arg_tid = self.call_first_arg_resolved_tid(body, args_id)
        let owner_text = self.type_owner_text(first_arg_tid)
        if owner_text.len() == 0:
            return 0
        let wanted = "." ++ raw
        let argc = self.call_arg_count(body, args_id)
        let want_ret_tid = self.call_dest_expected_tid(body, dest_place)
        var match_sym: i32 = 0
        var match_score = -1
        for si in 0..self.sema.sig_names.len() as i32:
            let sym: i32 = self.sema.sig_names[si]
            if only_local_defs != 0 and self.has_body_for_sym(sym) == 0:
                continue
            if self.sema.sig_get_param_count(si) != argc:
                continue
            let sym_text = cc_intern_resolve(self.intern, sym)
            if cc_str_ends_with(sym_text, wanted) == 0:
                continue
            let owner = cc_owner_prefix(sym_text)
            if owner != owner_text and cc_str_ends_with(owner, "." ++ owner_text) == 0:
                continue
            let ret_tid = self.c_sig_return_type(si)
            if self.is_void_tid(want_ret_tid) == 0 and self.strict_type_match(want_ret_tid, ret_tid) == 0:
                continue
            var params_ok = 1
            for ai in 0..argc:
                let arg_operand = self.call_arg_operand(body, args_id, ai)
                var arg_tid = self.operand_tid_no_infer(body, arg_operand)
                if self.is_void_tid(arg_tid) != 0 and self.infer_local_depth == 0:
                    arg_tid = self.operand_tid(body, arg_operand)
                let p_tid = self.sema.sig_param_type(si, ai)
                if self.is_void_tid(arg_tid) == 0 and self.strict_type_match(p_tid, arg_tid) == 0:
                    params_ok = 0
                    break
            if params_ok == 0:
                continue
            var score = 0
            if owner == owner_text:
                score = score + 4
            if self.has_body_for_sym(sym) != 0:
                score = score + 2
            if score > match_score:
                match_score = score
                match_sym = sym
        match_sym

    mut fn infer_owner_method_sym(body: &MirBody, fn_sym: i32, args_id: i32, dest_place: i32) -> i32:
        if self.infer_local_depth > 0:
            return self.infer_owner_method_sym_scan(body, fn_sym, args_id, dest_place, 1)
        let cached = self.call_infer_cache_lookup("owner-method", body.fn_sym, fn_sym, args_id, dest_place)
        if cached != -1234567:
            return cached
        let local = self.infer_owner_method_sym_scan(body, fn_sym, args_id, dest_place, 1)
        if local > 0:
            self.call_infer_cache_store("owner-method", body.fn_sym, fn_sym, args_id, dest_place, local)
            return local
        let result = self.infer_owner_method_sym_scan(body, fn_sym, args_id, dest_place, 0)
        self.call_infer_cache_store("owner-method", body.fn_sym, fn_sym, args_id, dest_place, result)
        result

    fn infer_builtin_call_name(body: &MirBody, args_id: i32, dest_place: i32) -> str:
        let _ = self
        let _ = body
        let _ = args_id
        let _ = dest_place
        ""

    fn infer_print_call_name(body: &MirBody, args_id: i32, dest_place: i32) -> str:
        let _ = self
        let _ = body
        let _ = args_id
        let _ = dest_place
        ""

    fn extern_call_name(sym: i32, body: &MirBody, args_id: i32, dest_place: i32) -> str:
        let _ = body
        let _ = args_id
        let _ = dest_place
        self.extern_sym_c_name(sym)

    fn sig_index_for_sym(fn_sym: i32) -> i32:
        let raw = cc_intern_resolve(self.intern, fn_sym)
        if self.sig_idx_cache.contains(fn_sym):
            return self.sig_idx_cache.get(fn_sym).unwrap()

        var out: i32 = -1
        let canon = self.canonical_body_sym(fn_sym)
        if canon != 0:
            let canon_sig = self.sema.get_sig(canon)
            if canon_sig >= 0:
                out = canon_sig
        if out < 0:
            let direct = self.sema.get_sig(fn_sym)
            if direct >= 0:
                out = direct
        if out < 0 and raw.len() > 0:
            for si in 0..self.sema.sig_names.len():
                let sym = self.sema.sig_names[si]
                if sym == fn_sym:
                    out = si as i32
                    break
            if out < 0 and cc_str_contains_dot(raw) != 0:
                var match_idx: i32 = -1
                for si in 0..self.sema.sig_names.len():
                    let sym_text = cc_intern_resolve(self.intern, self.sema.sig_names[si])
                    if sym_text != raw:
                        continue
                    if match_idx < 0:
                        match_idx = si as i32
                    else:
                        match_idx = -2
                        break
                if match_idx >= 0:
                    out = match_idx
            if out < 0 and cc_str_contains_dot(raw) == 0:
                // #785: a dotless name (plain extern like with_print_str) must
                // first try the EXACT sig-name match; without it the callee sig
                // stays unresolved and call args skip pointer marshalling.
                var exact_idx: i32 = -1
                for si in 0..self.sema.sig_names.len():
                    let sym_text = cc_intern_resolve(self.intern, self.sema.sig_names[si])
                    if sym_text != raw:
                        continue
                    if exact_idx < 0:
                        exact_idx = si as i32
                    else:
                        exact_idx = -2
                        break
                if exact_idx >= 0:
                    out = exact_idx
            if out < 0 and cc_str_contains_dot(raw) == 0:
                let wanted = "." ++ raw
                var match_idx: i32 = -1
                for si in 0..self.sema.sig_names.len():
                    let sym_text = cc_intern_resolve(self.intern, self.sema.sig_names[si])
                    if cc_str_ends_with(sym_text, wanted) == 0:
                        continue
                    if match_idx < 0:
                        match_idx = si as i32
                    else:
                        match_idx = -2
                        break
                if match_idx >= 0:
                    out = match_idx

        self.sig_idx_cache.insert(fn_sym, out)
        out

    mut fn unqualified_builtin_method_name(body: &MirBody, fn_sym: i32, args_id: i32) -> str:
        let raw = cc_intern_resolve(self.intern, fn_sym)
        if raw.len() == 0:
            return ""
        if cc_str_contains_dot(raw) != 0:
            return ""
        let first_kind = self.sema.get_type_kind(self.call_first_arg_resolved_tid(body, args_id))
        if first_kind != TypeKind.TY_STR:
            return ""
        let argc = self.call_arg_count(body, args_id)
        if raw == "len" and argc == 1:
            return "with_len"
        if raw == "is_empty" and argc == 1:
            return "with_is_empty"
        if raw == "starts_with" and argc == 2:
            return "with_str_starts_with_ref"
        if raw == "ends_with" and argc == 2:
            return "with_str_ends_with_ref"
        if raw == "contains" and argc == 2:
            return "with_str_contains_ref"
        if raw == "find" and argc == 2:
            return "with_str_index_of_ref"
        if raw == "slice" and argc == 3:
            return "with_str_slice_ref"
        if raw == "byte_at" and argc == 2:
            return "with_str_byte_at_ref"
        ""

    mut fn unqualified_builtin_method_ret_tid(body: &MirBody, fn_sym: i32, args_id: i32) -> i32:
        let raw = cc_intern_resolve(self.intern, fn_sym)
        if raw.len() == 0:
            return 0
        if cc_str_contains_dot(raw) != 0:
            return 0
        let first_kind = self.sema.get_type_kind(self.call_first_arg_resolved_tid(body, args_id))
        if first_kind != TypeKind.TY_STR:
            return 0
        let argc = self.call_arg_count(body, args_id)
        if raw == "len" and argc == 1:
            return self.sema.ty_i64 as i32
        if raw == "is_empty" and argc == 1:
            return self.sema.ty_bool as i32
        if raw == "starts_with" and argc == 2:
            return self.sema.ty_bool as i32
        if raw == "ends_with" and argc == 2:
            return self.sema.ty_bool as i32
        if raw == "contains" and argc == 2:
            return self.sema.ty_bool as i32
        if raw == "find" and argc == 2:
            return self.sema.ty_i64 as i32
        if raw == "slice" and argc == 3:
            return self.sema.ty_str as i32
        if raw == "byte_at" and argc == 2:
            return self.sema.ty_i32 as i32
        0

    mut fn call_builtin_kind(body: &MirBody, callee_operand: i32, args_id: i32, dest_place: i32) -> CcBuiltin:
        let method = self.call_method_base_name(body, callee_operand)
        if method.len() == 0:
            return CcBuiltin.NONE

        let callee_sym = self.call_callee_fn_sym(body, callee_operand)
        let callee_hint = self.callee_field_hint(callee_sym)
        let first_owner_tid = self.call_first_arg_resolved_tid(body, args_id)
        let first_owner = self.type_owner_text(first_owner_tid)
        let recv_is_list =
            if callee_hint == CcCalleeHint.LIST_RECV:
                1
            else if first_owner == "List":
                1
            else:
                0
        let recv_is_map =
            if callee_hint == CcCalleeHint.MAP_RECV:
                1
            else if first_owner == "HashMap":
                1
            else:
                0
        let recv_is_opt =
            if callee_hint == CcCalleeHint.OPT_RECV:
                1
            else if first_owner == "Option":
                1
            else:
                0
        let recv_is_listslot = if first_owner == "ListSlot": 1 else: 0

        if method == "new":
            let concrete_new_sym = self.canonical_body_sym(callee_sym)
            if concrete_new_sym != 0:
                let concrete_name = cc_intern_resolve(self.intern, concrete_new_sym)
                let concrete_owner = cc_owner_prefix(concrete_name)
                if concrete_owner != "List" and concrete_owner != "HashMap":
                    return CcBuiltin.NONE
            var dst_kind = self.infer_place_kind(body, dest_place)
            if dst_kind == CcPlaceKind.UNKNOWN:
                let dst_local = self.place_local_id(body, dest_place)
                if dst_local >= 0:
                    dst_kind = self.local_place_kind(body, dst_local)
            if dst_kind == CcPlaceKind.LIST:
                return CcBuiltin.LIST_NEW
            if dst_kind == CcPlaceKind.HASHMAP:
                return CcBuiltin.MAP_NEW
            if callee_hint == CcCalleeHint.LIST_NEW:
                return CcBuiltin.LIST_NEW
            if callee_hint == CcCalleeHint.MAP_NEW:
                return CcBuiltin.MAP_NEW
            let hinted = self.call_dest_expected_tid(body, dest_place)
            if hinted == CC_PSEUDO_TID_LIST:
                return CcBuiltin.LIST_NEW
            return CcBuiltin.NONE

        let argc = self.call_arg_count(body, args_id)
        if argc <= 0:
            return CcBuiltin.NONE

        let first_place = self.call_first_arg_place_id(body, args_id)
        let place_kind = if first_place >= 0: self.infer_place_kind(body, first_place) else: CcPlaceKind.UNKNOWN
        let first_tid = self.sema.resolve_alias(self.call_first_arg_resolved_tid(body, args_id))
        let first_tk = self.sema.get_type_kind(first_tid)
        var first_atomic_tid = first_tid
        if first_tk == TypeKind.TY_PTR or first_tk == TypeKind.TY_REF:
            first_atomic_tid = self.sema.resolve_alias(self.sema.get_type_d0(first_tid))
        let recv_is_atomic =
            if self.sema.get_type_kind(first_atomic_tid) == TypeKind.TY_GENERIC_INST and self.generic_inst_base_name(first_atomic_tid as i32) == "Atomic":
                1
            else if first_owner == "Atomic":
                1
            else:
                0
        let allow_place_kind_guess = if first_owner.len() == 0: 1 else: 0
        let recv_kind_is_list = if recv_is_list != 0 or (allow_place_kind_guess != 0 and place_kind == CcPlaceKind.LIST): 1 else: 0
        let recv_kind_is_map = if recv_is_map != 0 or (allow_place_kind_guess != 0 and place_kind == CcPlaceKind.HASHMAP): 1 else: 0
        let recv_kind_is_opt = if recv_is_opt != 0 or (allow_place_kind_guess != 0 and place_kind == CcPlaceKind.OPTION): 1 else: 0

        if method == "load":
            if recv_is_atomic != 0:
                return CcBuiltin.ATOMIC_LOAD
            return CcBuiltin.NONE
        if method == "store":
            if recv_is_atomic != 0:
                return CcBuiltin.ATOMIC_STORE
            return CcBuiltin.NONE
        if method == "swap":
            if recv_is_atomic != 0:
                return CcBuiltin.ATOMIC_SWAP
            return CcBuiltin.NONE
        if method == "fetch_add":
            if recv_is_atomic != 0:
                return CcBuiltin.ATOMIC_FETCH_ADD
            return CcBuiltin.NONE
        if method == "fetch_sub":
            if recv_is_atomic != 0:
                return CcBuiltin.ATOMIC_FETCH_SUB
            return CcBuiltin.NONE
        if method == "fetch_and":
            if recv_is_atomic != 0:
                return CcBuiltin.ATOMIC_FETCH_AND
            return CcBuiltin.NONE
        if method == "fetch_or":
            if recv_is_atomic != 0:
                return CcBuiltin.ATOMIC_FETCH_OR
            return CcBuiltin.NONE
        if method == "fetch_xor":
            if recv_is_atomic != 0:
                return CcBuiltin.ATOMIC_FETCH_XOR
            return CcBuiltin.NONE
        if method == "fetch_min":
            if recv_is_atomic != 0:
                return CcBuiltin.ATOMIC_FETCH_MIN
            return CcBuiltin.NONE
        if method == "fetch_max":
            if recv_is_atomic != 0:
                return CcBuiltin.ATOMIC_FETCH_MAX
            return CcBuiltin.NONE
        if method == "compare_exchange":
            if recv_is_atomic != 0:
                return CcBuiltin.ATOMIC_CAS
            return CcBuiltin.NONE
        if method == "compare_exchange_weak":
            if recv_is_atomic != 0:
                return CcBuiltin.ATOMIC_CAS_WEAK
            return CcBuiltin.NONE

        if method == "slot":
            if recv_kind_is_list != 0:
                return CcBuiltin.LIST_SLOT
            return CcBuiltin.NONE
        if method == "get_disjoint":
            if recv_kind_is_list != 0:
                return CcBuiltin.LIST_GET_DISJOINT
            return CcBuiltin.NONE

        if method == "push":
            if recv_kind_is_list != 0:
                return CcBuiltin.LIST_PUSH
            return CcBuiltin.NONE
        if method == "clear":
            if recv_kind_is_list != 0:
                return CcBuiltin.LIST_CLEAR
            return CcBuiltin.NONE
        if method == "pop":
            if recv_kind_is_list != 0:
                return CcBuiltin.LIST_POP
            return CcBuiltin.NONE
        if method == "insert":
            if recv_kind_is_map != 0:
                return CcBuiltin.MAP_INSERT
            return CcBuiltin.NONE
        if method == "is_some":
            if recv_kind_is_opt != 0:
                return CcBuiltin.OPT_IS_SOME
            return CcBuiltin.NONE
        if method == "unwrap":
            if recv_kind_is_opt != 0:
                return CcBuiltin.OPT_UNWRAP
            return CcBuiltin.NONE
        if method == "expect":
            if recv_kind_is_opt != 0:
                return CcBuiltin.OPT_EXPECT
            return CcBuiltin.NONE

        if method == "set":
            if recv_is_listslot != 0:
                return CcBuiltin.VECSLOT_SET
            return CcBuiltin.NONE

        if method == "get":
            if recv_is_listslot != 0:
                return CcBuiltin.VECSLOT_GET
            if recv_kind_is_map != 0:
                return CcBuiltin.MAP_GET
            if recv_kind_is_list != 0:
                return CcBuiltin.LIST_GET
            return CcBuiltin.NONE

        if method == "len":
            if first_tk == TypeKind.TY_STR:
                return CcBuiltin.NONE
            if recv_kind_is_map != 0:
                return CcBuiltin.MAP_LEN
            if recv_kind_is_list != 0:
                return CcBuiltin.LIST_LEN
            return CcBuiltin.NONE

        if method == "contains":
            if first_tk == TypeKind.TY_STR:
                return CcBuiltin.NONE
            if recv_kind_is_map != 0:
                return CcBuiltin.MAP_CONTAINS
            return CcBuiltin.NONE

        if method == "remove":
            if recv_kind_is_map != 0:
                return CcBuiltin.MAP_REMOVE
            if recv_kind_is_list != 0:
                return CcBuiltin.LIST_REMOVE
            return CcBuiltin.NONE

        CcBuiltin.NONE

    mut fn call_builtin_ret_tid(body: &MirBody, callee_operand: i32, args_id: i32, dest_place: i32) -> i32:
        let mir_intrinsic = body.call_intrinsic(args_id)
        var kind = cc_builtin_from_mir_intrinsic(mir_intrinsic)
        if kind == CcBuiltin.NONE:
            kind = self.call_builtin_kind(body, callee_operand, args_id, dest_place)
        if kind == CcBuiltin.NONE:
            return 0
        if kind == CcBuiltin.LIST_NEW:
            return CC_PSEUDO_TID_LIST
        // D116: `a ++ b` is a new List of its destination's type; `++=`
        // appends in place. With no result type the concatenation was
        // built and never stored: `a ++ a` read as an empty List.
        if kind == CcBuiltin.LIST_CONCAT:
            return if dest_place >= 0 and dest_place < body.place_locals.len(): self.place_sema_tid(body, dest_place) else: self.sema.ty_void as i32
        if kind == CcBuiltin.LIST_EXTEND:
            return self.sema.ty_void as i32
        // The slot walk's destinations are MirLower's typed temps (#1434).
        if kind == CcBuiltin.MAP_SLOT_WALK:
            return self.place_tid_no_infer(body, dest_place)
        // D75: the list binding, the argument's Sema-chosen type, the
        // end's i32 status temp — each destination is typed by MirLower.
        if kind == CcBuiltin.VA_START or kind == CcBuiltin.VA_ARG or kind == CcBuiltin.VA_END:
            return self.place_tid_no_infer(body, dest_place)
        if kind == CcBuiltin.LIST_SLOT:
            let hinted = self.call_dest_expected_tid(body, dest_place)
            if hinted != 0 and self.is_void_tid(hinted) == 0:
                return hinted
            let dst = self.place_local_tid(body, dest_place)
            if dst != 0 and self.is_void_tid(dst) == 0:
                return dst
            return self.sema.ty_i64 as i32
        if kind == CcBuiltin.LIST_PUSH:
            let dst = self.place_local_tid(body, dest_place)
            if dst != 0 and self.is_void_tid(dst) != 0:
                return self.sema.ty_void as i32
            let hinted = self.call_dest_expected_tid(body, dest_place)
            if hinted != 0 and self.is_void_tid(hinted) == 0:
                return hinted
            if dst != 0 and self.is_void_tid(dst) == 0:
                return dst
            return self.operand_tid(body, self.call_arg_operand(body, args_id, 0))
        // `remove` transfers the element out (D27).
        if kind == CcBuiltin.LIST_REMOVE:
            return self.list_element_tid(self.recv_value_tid(body, args_id))
        if kind == CcBuiltin.LIST_CLEAR:
            return self.sema.ty_void as i32
        if kind == CcBuiltin.VECSLOT_SET:
            return self.sema.ty_void as i32
        if kind == CcBuiltin.VECSLOT_GET:
            let hinted = self.call_dest_expected_tid(body, dest_place)
            if hinted != 0 and self.is_void_tid(hinted) == 0:
                return hinted
            let slot_tid = self.operand_tid(body, self.call_arg_operand(body, args_id, 0))
            let elem_tid = self.listslot_element_tid(slot_tid)
            if elem_tid != 0:
                return elem_tid
            let dst = self.place_local_tid(body, dest_place)
            if dst != 0 and self.is_void_tid(dst) == 0:
                return dst
            return self.sema.ty_i64 as i32
        if kind == CcBuiltin.LIST_POP:
            let hinted = self.call_dest_expected_tid(body, dest_place)
            if hinted != 0 and self.is_void_tid(hinted) == 0:
                return hinted
            let dst = self.place_local_tid(body, dest_place)
            if dst != 0 and self.is_void_tid(dst) == 0:
                return dst
            return self.sema.ty_i64 as i32
        if kind == CcBuiltin.LIST_GET:
            let hinted = self.call_dest_expected_tid(body, dest_place)
            if hinted != 0 and self.is_void_tid(hinted) == 0:
                return hinted
            let dst = self.place_local_tid(body, dest_place)
            if dst != 0 and self.is_void_tid(dst) == 0:
                return dst
            return self.sema.ty_i64 as i32
        if kind == CcBuiltin.LIST_LEN:
            return self.sema.ty_usize as i32
        if kind == CcBuiltin.LIST_IS_EMPTY:
            return self.sema.ty_bool as i32
        if kind == CcBuiltin.LIST_LEN32:
            return self.sema.ty_i32 as i32
        if kind == CcBuiltin.LIST_LEN64:
            return self.sema.ty_i64 as i32
        if kind == CcBuiltin.LIST_ULEN32:
            return self.sema.ty_u32 as i32
        if kind == CcBuiltin.LIST_CONTAINS:
            return self.sema.ty_bool as i32
        if kind == CcBuiltin.LIST_JOIN:
            return self.sema.ty_str as i32
        if kind == CcBuiltin.LIST_WITH_CAPACITY:
            return CC_PSEUDO_TID_LIST
        if kind == CcBuiltin.MAP_NEW:
            return self.sema.ty_i64 as i32
        if kind == CcBuiltin.MAP_INSERT:
            return self.sema.ty_void as i32
        if kind == CcBuiltin.MAP_GET:
            let dst_local = self.place_local_id(body, dest_place)
            if dst_local >= 0:
                let downcast_opt_tid = self.local_payload_downcast_option_tid(body, dst_local)
                if downcast_opt_tid != 0 and self.is_void_tid(downcast_opt_tid) == 0:
                    return downcast_opt_tid
            let opt_tid = self.call_hashmap_get_option_tid(body, args_id)
            if opt_tid != 0 and self.is_void_tid(opt_tid) == 0:
                return opt_tid
            let hinted = self.call_dest_expected_tid(body, dest_place)
            if hinted != 0 and self.is_void_tid(hinted) == 0 and self.type_is_payload_enum(hinted) != 0:
                return hinted
            let dst = self.place_local_tid(body, dest_place)
            if dst != 0 and self.is_void_tid(dst) == 0 and self.type_is_payload_enum(dst) != 0:
                return dst
            if hinted != 0 and self.is_void_tid(hinted) == 0 and self.is_scalar_like_tid(hinted) == 0:
                let hinted_opt = self.option_tid_for_payload(hinted)
                if hinted_opt != 0 and self.is_void_tid(hinted_opt) == 0:
                    return hinted_opt
            if dst != 0 and self.is_void_tid(dst) == 0 and self.is_scalar_like_tid(dst) == 0:
                let dst_opt = self.option_tid_for_payload(dst)
                if dst_opt != 0 and self.is_void_tid(dst_opt) == 0:
                    return dst_opt
            if dst != 0 and self.is_void_tid(dst) == 0 and self.is_scalar_like_tid(dst) != 0:
                return dst
            if hinted != 0 and self.is_void_tid(hinted) == 0 and self.is_scalar_like_tid(hinted) != 0:
                return hinted
            if dst != 0 and self.is_void_tid(dst) == 0:
                return dst
            if hinted != 0 and self.is_void_tid(hinted) == 0:
                return hinted
            return self.sema.ty_i64 as i32
        if kind == CcBuiltin.MAP_CONTAINS:
            return self.sema.ty_bool as i32
        if kind == CcBuiltin.MAP_LEN:
            return self.sema.ty_usize as i32
        if kind == CcBuiltin.MAP_LEN32:
            return self.sema.ty_i32 as i32
        if kind == CcBuiltin.MAP_LEN64:
            return self.sema.ty_i64 as i32
        if kind == CcBuiltin.MAP_ULEN32:
            return self.sema.ty_u32 as i32
        if kind == CcBuiltin.MAP_REMOVE:
            let owner = self.call_first_arg_owner_text(body, args_id)
            if owner == "HashMap":
                let hinted = self.call_dest_expected_tid(body, dest_place)
                if hinted != 0 and self.is_void_tid(hinted) == 0:
                    return hinted
                let dst = self.place_local_tid(body, dest_place)
                if dst != 0 and self.is_void_tid(dst) == 0:
                    return dst
                return self.sema.ty_i64 as i32
            return self.sema.ty_bool as i32
        if kind == CcBuiltin.OPT_IS_SOME:
            return self.sema.ty_bool as i32
        if kind == CcBuiltin.OPT_IS_NONE:
            return self.sema.ty_bool as i32
        if kind == CcBuiltin.OPT_UNWRAP or kind == CcBuiltin.OPT_EXPECT:
            let hinted = self.call_dest_expected_tid(body, dest_place)
            if hinted != 0 and self.is_void_tid(hinted) == 0:
                return hinted
            let dst = self.place_local_tid(body, dest_place)
            if dst != 0 and self.is_void_tid(dst) == 0:
                return dst
            return self.sema.ty_i64 as i32
        if kind == CcBuiltin.ATOMIC_LOAD or kind == CcBuiltin.ATOMIC_SWAP or kind == CcBuiltin.ATOMIC_FETCH_ADD or kind == CcBuiltin.ATOMIC_FETCH_SUB or kind == CcBuiltin.ATOMIC_FETCH_AND or kind == CcBuiltin.ATOMIC_FETCH_OR or kind == CcBuiltin.ATOMIC_FETCH_XOR or kind == CcBuiltin.ATOMIC_FETCH_MIN or kind == CcBuiltin.ATOMIC_FETCH_MAX:
            return self.atomic_recv_value_tid(body, args_id)
        if kind == CcBuiltin.ATOMIC_CAS or kind == CcBuiltin.ATOMIC_CAS_WEAK:
            let hinted_atomic = self.call_dest_expected_tid(body, dest_place)
            if hinted_atomic != 0 and self.is_void_tid(hinted_atomic) == 0:
                return hinted_atomic
            let dst_atomic = self.place_local_tid(body, dest_place)
            if dst_atomic != 0 and self.is_void_tid(dst_atomic) == 0:
                return dst_atomic
            let payload = self.atomic_recv_value_tid(body, args_id)
            let args: List[i32] = List.new()
            args.push(payload)
            args.push(payload)
            return self.sema.find_generic_inst_type(self.sema.syms.result, args, 2) as i32
        if kind == CcBuiltin.ATOMIC_STORE:
            return self.sema.ty_void as i32
        if kind == CcBuiltin.ATOMIC_FENCE:
            return self.sema.ty_void as i32
        if kind == CcBuiltin.FIBER_SET_CANCELLED_RETURN:
            return self.sema.ty_void as i32
        if kind == CcBuiltin.FIBER_IS_CANCELLED or kind == CcBuiltin.FIBER_WAIT_CANCELLED or kind == CcBuiltin.FIBER_WAS_CANCELLED_RETURN:
            return self.sema.ty_i32 as i32
        if kind == CcBuiltin.STR_LEN:
            return self.sema.ty_usize as i32
        if kind == CcBuiltin.STR_LEN32:
            return self.sema.ty_i32 as i32
        if kind == CcBuiltin.STR_LEN64:
            return self.sema.ty_i64 as i32
        if kind == CcBuiltin.STR_ULEN32:
            return self.sema.ty_u32 as i32
        if kind == CcBuiltin.STR_BYTE_AT:
            return self.sema.ty_i32 as i32
        if kind == CcBuiltin.STR_SLICE:
            return self.sema.ty_str as i32
        if kind == CcBuiltin.STR_CONTAINS or kind == CcBuiltin.STR_STARTS_WITH or kind == CcBuiltin.STR_ENDS_WITH:
            return self.sema.ty_bool as i32
        if kind == CcBuiltin.STR_FIND or kind == CcBuiltin.STR_INDEX_OF:
            return self.sema.ty_i64 as i32
        if kind == CcBuiltin.STR_SPLIT:
            let hinted = self.call_dest_expected_tid(body, dest_place)
            if hinted != 0 and self.is_void_tid(hinted) == 0:
                return hinted
            let dst = self.place_local_tid(body, dest_place)
            if dst != 0 and self.is_void_tid(dst) == 0:
                return dst
            return CC_PSEUDO_TID_LIST
        if kind == CcBuiltin.STR_TO_UPPER or kind == CcBuiltin.STR_TO_LOWER or kind == CcBuiltin.STR_REPLACE or kind == CcBuiltin.STR_REPEAT:
            return self.sema.ty_str as i32
        if kind == CcBuiltin.ARR_LEN:
            return self.sema.ty_usize as i32
        if kind == CcBuiltin.ARR_LEN32:
            return self.sema.ty_i32 as i32
        if kind == CcBuiltin.ARR_LEN64:
            return self.sema.ty_i64 as i32
        if kind == CcBuiltin.ARR_ULEN32:
            return self.sema.ty_u32 as i32
        if kind == CcBuiltin.ROTATE_LEFT or kind == CcBuiltin.ROTATE_RIGHT or kind == CcBuiltin.INT_SWAP_BYTES or kind == CcBuiltin.POPCOUNT or kind == CcBuiltin.CLZ or kind == CcBuiltin.CTZ or kind == CcBuiltin.BITREVERSE:
            let hinted = self.call_dest_expected_tid(body, dest_place)
            if hinted != 0 and self.is_void_tid(hinted) == 0:
                return hinted
            let dst = self.place_local_tid(body, dest_place)
            if dst != 0 and self.is_void_tid(dst) == 0:
                return dst
            return self.sema.ty_i32 as i32
        if kind == CcBuiltin.MIN or kind == CcBuiltin.MAX or kind == CcBuiltin.ABS or kind == CcBuiltin.MATH_FN:
            let hinted = self.call_dest_expected_tid(body, dest_place)
            if hinted != 0 and self.is_void_tid(hinted) == 0:
                return hinted
            let dst = self.place_local_tid(body, dest_place)
            if dst != 0 and self.is_void_tid(dst) == 0:
                return dst
            let operand_tid = self.operand_tid(body, self.call_arg_operand(body, args_id, 0))
            if operand_tid != 0 and self.is_void_tid(operand_tid) == 0:
                return operand_tid
            return self.sema.ty_i64 as i32
        if kind == CcBuiltin.FMA:
            let hinted = self.call_dest_expected_tid(body, dest_place)
            if hinted != 0 and self.is_void_tid(hinted) == 0:
                return hinted
            let dst = self.place_local_tid(body, dest_place)
            if dst != 0 and self.is_void_tid(dst) == 0:
                return dst
            return self.sema.ty_f64 as i32
        if kind == CcBuiltin.CLOSURE_CLONE:
            return self.place_local_tid(body, dest_place)
        if kind == CcBuiltin.FMT_TO_STR or kind == CcBuiltin.FMT_DEBUG_STR or kind == CcBuiltin.FMT_DEBUG or kind == CcBuiltin.FMT_SPEC or kind == CcBuiltin.STR_CLONE_REF:
            return self.sema.ty_str as i32
        if kind == CcBuiltin.FMT_BUF_NEW:
            return CC_PSEUDO_TID_FMT_BUF
        if kind == CcBuiltin.FMT_BUF_WRITE_STR or kind == CcBuiltin.FMT_BUF_WRITE_STR_REF or kind == CcBuiltin.FMT_BUF_WRITE_FMT:
            return self.sema.ty_void as i32
        if kind == CcBuiltin.FMT_BUF_FINISH:
            return self.sema.ty_str as i32
        if kind == CcBuiltin.DYN_VTABLE_CMP:
            return self.sema.ty_bool as i32
        0

    mut fn resolve_call_named_callee(body: &MirBody, fn_sym: i32, args_id: i32, dest_place: i32) -> str:
        let fn_body_sym = self.canonical_body_sym(fn_sym)
        if fn_body_sym != 0:
            return self.fn_c_name(fn_body_sym)
        let owner_named = self.owner_named_body_sym(body, fn_sym, args_id)
        if owner_named != 0:
            return self.fn_c_name(owner_named)
        let builtin_method = self.unqualified_builtin_method_name(body, fn_sym, args_id)
        if builtin_method.len() > 0:
            if builtin_method != "with_len" and builtin_method != "with_is_empty":
                self.callee_is_str_builtin_ref = 1
            return builtin_method
        let inferred_named = self.infer_named_call_sym(body, fn_sym, args_id, dest_place)
        if inferred_named > 0:
            let named_body_sym = self.canonical_body_sym(inferred_named)
            if named_body_sym != 0:
                return self.fn_c_name(named_body_sym)
            return self.extern_call_name(inferred_named, body, args_id, dest_place)
        let inferred_method = self.infer_qualified_method_sym(body, fn_sym, args_id, dest_place)
        if inferred_method == -2:
            self.fail("C backend cannot lower ambiguous method call")
            return "/*ambiguous_method*/"
        if inferred_method > 0:
            let method_body_sym = self.canonical_body_sym(inferred_method)
            if method_body_sym != 0:
                return self.fn_c_name(method_body_sym)
            return self.extern_call_name(inferred_method, body, args_id, dest_place)
        let owner_method = self.infer_owner_method_sym(body, fn_sym, args_id, dest_place)
        if owner_method > 0:
            let owner_body_sym = self.canonical_body_sym(owner_method)
            if owner_body_sym != 0:
                return self.fn_c_name(owner_body_sym)
            return self.extern_call_name(owner_method, body, args_id, dest_place)
        let body_method = self.infer_body_method_sym(body, fn_sym, args_id, dest_place)
        if body_method > 0:
            return self.fn_c_name(body_method)
        self.extern_call_name(fn_sym, body, args_id, dest_place)

    // The C backend has no fiber runtime: an `async fn` is emitted as a
    // synchronous C function that returns the awaited T (its body type), and a
    // call of it yields that T. Every signature return type read here goes
    // through this, so the `Task[T]` a Sema signature declares (§14.4; #1464
    // made the inferred ones agree with the annotated ones) never names a C
    // type the backend does not define (`Task_Unit_ task_cancel_point()`).
    fn c_sig_return_type(sig_idx: i32) -> i32:
        self.sema.unwrap_task_type(self.sema.sig_return_type(sig_idx) as TypeId) as i32

    mut fn call_return_tid_for_fn_sym(body: &MirBody, fn_sym: i32, args_id: i32, dest_place: i32, fallback: i32) -> i32:
        let fn_body_sym = self.canonical_body_sym(fn_sym)
        if fn_body_sym != 0:
            let body_sig = self.sig_index_for_sym(fn_body_sym)
            if body_sig >= 0:
                return self.c_sig_return_type(body_sig)
        let owner_named = self.owner_named_body_sym(body, fn_sym, args_id)
        if owner_named != 0:
            let owner_named_sig = self.sig_index_for_sym(owner_named)
            if owner_named_sig >= 0:
                return self.c_sig_return_type(owner_named_sig)
        let builtin_method_ret = self.unqualified_builtin_method_ret_tid(body, fn_sym, args_id)
        if builtin_method_ret != 0:
            return builtin_method_ret
        let inferred_named = self.infer_named_call_sym(body, fn_sym, args_id, dest_place)
        if inferred_named > 0:
            let named_sig = self.sig_index_for_sym(inferred_named)
            if named_sig >= 0:
                return self.c_sig_return_type(named_sig)
        let inferred_method = self.infer_qualified_method_sym(body, fn_sym, args_id, dest_place)
        if inferred_method > 0:
            let method_sig = self.sig_index_for_sym(inferred_method)
            if method_sig >= 0:
                return self.c_sig_return_type(method_sig)
        let owner_method = self.infer_owner_method_sym(body, fn_sym, args_id, dest_place)
        if owner_method > 0:
            let owner_sig = self.sig_index_for_sym(owner_method)
            if owner_sig >= 0:
                return self.c_sig_return_type(owner_sig)
        let body_method = self.infer_body_method_sym(body, fn_sym, args_id, dest_place)
        if body_method > 0:
            let body_sig = self.sig_index_for_sym(body_method)
            if body_sig >= 0:
                return self.c_sig_return_type(body_sig)
        let sig_idx = self.sig_index_for_sym(fn_sym)
        if sig_idx >= 0:
            return self.c_sig_return_type(sig_idx)
        let raw = cc_intern_resolve(self.intern, fn_sym)
        if raw == "with_str_concat_ref" or raw == "with_fs_read_file" or raw == "int_to_string":
            return self.sema.ty_str as i32
        if raw == "with_str_eq_ref":
            return self.sema.ty_bool as i32
        if raw == "with_str_cmp_ref":
            return self.sema.ty_i32 as i32
        if raw == "dump_async_mir" or raw == "Driver.dump_async_mir":
            return self.sema.ty_str as i32
        fallback

    mut fn resolve_call_callee_text(body: &MirBody, bb: i32, callee_operand: i32, args_id: i32, dest_place: i32) -> str:
        let _ = bb
        self.callee_is_str_builtin_ref = 0
        if body.call_requires_contract(args_id):
            return self.fn_c_name(body.call_mono_sym(args_id))
        if callee_operand < 0 or callee_operand >= body.operand_kinds.len():
            self.fail(f"invalid call callee operand id {callee_operand}")
            return "/*invalid_callee*/"

        let ok = body.operand_kinds[callee_operand]
        let od = body.operand_d0[callee_operand]
        if ok == OperandKind.OK_COPY or ok == OperandKind.OK_MOVE:
            let local_id = self.place_local_id(body, od)
            if local_id >= 0 and self.place_is_direct_local(body, od, local_id) != 0:
                let local_fn_sym = self.local_assigned_fn_sym(body, local_id)
                if local_fn_sym == -2:
                    self.fail("C backend cannot lower ambiguous indirect call")
                    return "/*ambiguous_call*/"
                if local_fn_sym > 0:
                    return self.resolve_call_named_callee(body, local_fn_sym, args_id, dest_place)
            let callee_tid = self.callee_fn_type_from_operand(body, callee_operand)
            if callee_tid != 0:
                if self.fn_tid_is_fat(callee_tid) != 0:
                    return self.place_text(body, od) ++ ".fn_ptr"
                return self.place_text(body, od)
            let inferred = self.infer_direct_call_sym(body, args_id, dest_place)
            if inferred == -2:
                self.fail("C backend cannot lower ambiguous direct call")
                return "/*ambiguous_call*/"
            if inferred > 0:
                let inferred_body_sym = self.canonical_body_sym(inferred)
                if inferred_body_sym != 0:
                    return self.fn_c_name(inferred_body_sym)
                return self.extern_call_name(inferred, body, args_id, dest_place)
            self.fail("C backend cannot resolve call callee")
            return "/*unresolved_call*/"

        if ok == OperandKind.OK_CONSTANT:
            if od < 0 or od >= body.const_kinds.len():
                self.fail(f"invalid call callee constant id {od}")
                return "/*invalid_call_const*/"
            let ck = body.const_kinds[od]
            if ck == ConstKind.CK_FN:
                let fn_sym = body.const_d0[od]
                if fn_sym == 0:
                    self.fail("invalid function symbol in call constant")
                    return "/*invalid_fn_symbol*/"
                return self.resolve_call_named_callee(body, fn_sym, args_id, dest_place)
            // Current MIR lowering often uses a unit-const placeholder for direct
            // calls. Recover the callee from semantic signatures.
            let inferred = self.infer_direct_call_sym(body, args_id, dest_place)
            if inferred == -2:
                self.fail("C backend cannot lower ambiguous direct call")
                return "/*ambiguous_call*/"
            if inferred > 0:
                let inferred_body_sym = self.canonical_body_sym(inferred)
                if inferred_body_sym != 0:
                    return self.fn_c_name(inferred_body_sym)
                return self.extern_call_name(inferred, body, args_id, dest_place)
            self.fail("C backend cannot resolve call callee")
            return "/*unresolved_call*/"

        self.fail(f"unsupported call callee operand kind {ok}")
        "/*unsupported_callee*/"

    mut fn call_return_tid(body: &MirBody, bb: i32, callee_operand: i32, args_id: i32, dest_place: i32) -> i32:
        let fallback = self.place_local_tid(body, dest_place)
        let _ = bb
        if body.call_requires_contract(args_id):
            let sig_idx = body.call_sig_index(args_id)
            if sig_idx >= 0:
                return self.c_sig_return_type(sig_idx)
        // `Atomic.new(v)` is the generic `new` MIR typed by its destination;
        // by name alone it resolved to another type's `new` (StringBuilder).
        if dest_place >= 0 and cc_base_name(cc_intern_resolve(self.intern, self.call_callee_fn_sym(body, callee_operand))) == "new":
            let dest_tid = self.place_sema_tid(body, dest_place)
            if self.generic_inst_base_name(dest_tid) == "Atomic":
                return dest_tid
        let builtin_ret = self.call_builtin_ret_tid(body, callee_operand, args_id, dest_place)
        if builtin_ret != 0:
            return builtin_ret
        if callee_operand < 0 or callee_operand >= body.operand_kinds.len():
            return fallback

        let ok = body.operand_kinds[callee_operand]
        let od = body.operand_d0[callee_operand]

        if ok == OperandKind.OK_COPY or ok == OperandKind.OK_MOVE:
            let callee_tid = self.sema.callable_any_fn_type(self.operand_tid(body, callee_operand) as TypeId)
            if callee_tid != 0:
                return self.sema.get_type_d2(callee_tid)
            let local_id = self.place_local_id(body, od)
            if local_id >= 0 and self.place_is_direct_local(body, od, local_id) != 0:
                let local_fn_sym = self.local_assigned_fn_sym(body, local_id)
                if local_fn_sym > 0:
                    return self.call_return_tid_for_fn_sym(body, local_fn_sym, args_id, dest_place, fallback)
            let inferred = self.infer_direct_call_sym(body, args_id, dest_place)
            if inferred > 0:
                let sig_idx = self.sig_index_for_sym(inferred)
                if sig_idx >= 0:
                    return self.c_sig_return_type(sig_idx)
            return fallback

        if ok == OperandKind.OK_CONSTANT:
            if od < 0 or od >= body.const_kinds.len():
                return fallback
            let ck = body.const_kinds[od]
            if ck == ConstKind.CK_FN:
                let fn_sym = body.const_d0[od]
                if fn_sym > 0:
                    return self.call_return_tid_for_fn_sym(body, fn_sym, args_id, dest_place, fallback)
            let inferred = self.infer_direct_call_sym(body, args_id, dest_place)
            if inferred > 0:
                let sig_idx = self.sig_index_for_sym(inferred)
                if sig_idx >= 0:
                    return self.c_sig_return_type(sig_idx)
            return fallback

        fallback

    fn call_callee_sig_return_tid(body: &MirBody, callee_operand: i32) -> i32:
        if callee_operand < 0 or callee_operand >= body.operand_kinds.len():
            return 0
        if body.operand_kinds[callee_operand] != OperandKind.OK_CONSTANT:
            return 0
        let const_id = body.operand_d0[callee_operand]
        if const_id < 0 or const_id >= body.const_kinds.len():
            return 0
        if body.const_kinds[const_id] != ConstKind.CK_FN:
            return 0
        let fn_sym = body.const_d0[const_id]
        if fn_sym == 0:
            return 0
        let sig_idx = self.sig_index_for_sym(fn_sym)
        if sig_idx < 0:
            return 0
        self.c_sig_return_type(sig_idx)

    mut fn infer_local_tid_impl(body: &MirBody, local_id: i32) -> i32:
        let declared = self.local_declared_tid(body, local_id)
        let declared_resolved = self.sema.resolve_alias(declared)
        let allow_container_receiver_infer =
            if self.is_void_tid(declared) == 0 and self.sema.get_type_kind(declared_resolved) != TypeKind.TY_ERR:
                0
            else:
                1
        var recv_hint: i32 = 0

        for bb in 0..body.block_count():
            let tk = body.term_kind(bb)
            if tk == TermKind.TK_CALL:
                let callee_operand = body.term_data0(bb)
                let args_id = body.term_data1(bb)
                let dest_place = body.term_data2(bb)
                let recv_place = self.call_first_arg_place_id(body, args_id)
                // Don't infer container type if this local is the call destination (it's the result, not the receiver)
                if allow_container_receiver_infer != 0 and self.place_is_direct_local(body, recv_place, local_id) != 0 and self.place_is_direct_local(body, dest_place, local_id) == 0:
                    let kind = self.call_builtin_kind(body, callee_operand, args_id, dest_place)
                    if kind == CcBuiltin.LIST_NEW or kind == CcBuiltin.LIST_PUSH or kind == CcBuiltin.LIST_GET or kind == CcBuiltin.LIST_LEN or kind == CcBuiltin.LIST_REMOVE or kind == CcBuiltin.LIST_CLEAR or kind == CcBuiltin.LIST_POP:
                        if recv_hint == 0:
                            recv_hint = CC_PSEUDO_TID_LIST
                    if kind == CcBuiltin.MAP_NEW or kind == CcBuiltin.MAP_INSERT or kind == CcBuiltin.MAP_GET or kind == CcBuiltin.MAP_CONTAINS or kind == CcBuiltin.MAP_LEN or kind == CcBuiltin.MAP_REMOVE:
                        if recv_hint == 0:
                            recv_hint = self.sema.ty_i64 as i32
                    if kind == CcBuiltin.OPT_IS_SOME or kind == CcBuiltin.OPT_UNWRAP or kind == CcBuiltin.OPT_EXPECT:
                        if recv_hint == 0:
                            recv_hint = self.sema.ty_i64 as i32
                if self.place_is_direct_local(body, dest_place, local_id) != 0:
                    // Map get/contains/len return int64_t, not the receiver type
                    let call_kind = self.call_builtin_kind(body, callee_operand, args_id, dest_place)
                    if call_kind == CcBuiltin.MAP_GET or call_kind == CcBuiltin.MAP_CONTAINS or call_kind == CcBuiltin.MAP_LEN or call_kind == CcBuiltin.OPT_IS_SOME:
                        if call_kind == CcBuiltin.OPT_IS_SOME:
                            return self.sema.ty_bool as i32
                        if call_kind == CcBuiltin.MAP_GET:
                            let rt = self.call_return_tid(body, bb, callee_operand, args_id, dest_place)
                            if rt != 0 and self.is_void_tid(rt) == 0:
                                return rt
                        return self.sema.ty_i64 as i32
                    let rt = self.call_return_tid(body, bb, callee_operand, args_id, dest_place)
                    if rt != 0 and self.is_void_tid(rt) == 0:
                        return rt

            let start = body.bb_stmt_starts[bb]
            let count = body.bb_stmt_counts[bb]
            for si in 0..count:
                let stmt_id = start + si
                if body.stmt_kinds[stmt_id] != StmtKind.Assign:
                    continue
                let dst_place = body.stmt_d0[stmt_id]
                if self.place_is_direct_local(body, dst_place, local_id) == 0:
                    continue
                let rval_id = body.stmt_d1[stmt_id]
                if rval_id < 0 or rval_id >= body.rval_kinds.len():
                    continue
                let rk = body.rval_kinds[rval_id]
                let d0 = body.rval_d0[rval_id]
                let d1 = body.rval_d1[rval_id]
                let d2 = body.rval_d2[rval_id]
                if rk == RvalueKind.RK_USE:
                    let t = self.operand_tid(body, d0)
                    if t != 0 and self.is_void_tid(t) == 0:
                        return t
                    continue
                if rk == RvalueKind.RK_BIN_OP:
                    if d0 == BinaryOp.OP_EQ or d0 == BinaryOp.OP_NEQ or d0 == BinaryOp.OP_LT or d0 == BinaryOp.OP_GT or d0 == BinaryOp.OP_LTE or d0 == BinaryOp.OP_GTE or d0 == BinaryOp.OP_AND or d0 == BinaryOp.OP_OR:
                        return self.sema.ty_bool as i32
                    if d0 == BinaryOp.OP_CONCAT:
                        return self.sema.ty_str as i32
                    let lt = self.operand_tid(body, d1)
                    if lt != 0 and self.is_void_tid(lt) == 0:
                        return lt
                    let rt = self.operand_tid(body, d2)
                    if rt != 0 and self.is_void_tid(rt) == 0:
                        return rt
                    continue
                if rk == RvalueKind.RK_STR_CONCAT_N:
                    return self.sema.ty_str as i32
                if rk == RvalueKind.RK_UN_OP:
                    if d0 == UnaryOp.UOP_NOT:
                        return self.sema.ty_bool as i32
                    let t = self.operand_tid(body, d1)
                    if t != 0 and self.is_void_tid(t) == 0:
                        return t
                    continue
                if rk == RvalueKind.RK_CAST:
                    if d1 != 0 and self.is_void_tid(d1) == 0:
                        return d1
                    continue
                if rk == RvalueKind.RK_DISCRIMINANT:
                    return self.sema.ty_i32 as i32
                if rk == RvalueKind.RK_LEN:
                    return self.sema.ty_i64 as i32
                if rk == RvalueKind.RK_SLICE:
                    let base_tid = self.place_tid(body, d0)
                    let base_resolved = self.sema.resolve_alias(base_tid)
                    let base_kind = self.sema.get_type_kind(base_resolved)
                    if base_kind == TypeKind.TY_ARRAY:
                        return self.sema.find_exact_type(TypeKind.TY_SLICE, self.sema.get_type_d0(base_resolved), 0, 0) as i32
                    if base_kind == TypeKind.TY_SLICE:
                        return base_resolved as i32

        if recv_hint != 0 and self.is_void_tid(recv_hint) == 0:
            return recv_hint
        0

    mut fn infer_local_tid(body: &MirBody, local_id: i32) -> i32:
        if local_id < 0 or local_id >= body.local_type_ids.len():
            return 0
        let cache_hit = self.local_infer_cache_lookup(body.fn_sym, local_id)
        if cache_hit != -1234567:
            return cache_hit
        let declared = self.local_declared_tid(body, local_id)
        let declared_resolved = self.sema.resolve_alias(declared)
        let declared_kind = self.sema.get_type_kind(declared_resolved)
        if local_id == 0:
            self.local_infer_cache_store(body.fn_sym, local_id, declared)
            return declared
        let sig_idx = self.body_sig_index(body.fn_sym)
        let param_count = if sig_idx >= 0: self.sema.sig_get_param_count(sig_idx) else: 0
        if local_id >= 1 and local_id <= param_count and self.is_void_tid(declared) == 0:
            self.local_infer_cache_store(body.fn_sym, local_id, declared)
            return declared
        var active = 0
        for i in 0..self.active_local_ids.len():
            if self.active_local_body_fns[i] != body.fn_sym:
                continue
            if self.active_local_ids[i] == local_id:
                active = 1
                break
        if active != 0:
            return declared

        self.infer_local_depth = self.infer_local_depth + 1
        self.active_local_body_fns.push(body.fn_sym)
        self.active_local_ids.push(local_id)
        let inferred = self.infer_local_tid_impl(body, local_id)
        self.active_local_ids.pop()
        self.active_local_body_fns.pop()
        self.infer_local_depth = self.infer_local_depth - 1
        let hinted = self.local_usage_hint_tid(body, local_id)
        if hinted != 0 and self.is_void_tid(hinted) == 0:
            if inferred == 0 or self.is_void_tid(inferred) != 0:
                self.local_infer_cache_store(body.fn_sym, local_id, hinted)
                return hinted
            if self.strict_type_match(inferred, hinted) == 0:
                let inferred_scalar = self.is_scalar_like_tid(inferred)
                let hinted_scalar = self.is_scalar_like_tid(hinted)
                if inferred_scalar != 0 and hinted_scalar != 0:
                    self.local_infer_cache_store(body.fn_sym, local_id, hinted)
                    return hinted
        if inferred != 0 and self.is_void_tid(inferred) == 0:
            self.local_infer_cache_store(body.fn_sym, local_id, inferred)
            return inferred
        self.local_infer_cache_store(body.fn_sym, local_id, declared)
        declared

    mut fn callee_fn_type_from_operand(body: &MirBody, callee_op: i32) -> i32:
        if callee_op < 0 or callee_op >= body.operand_kinds.len():
            return 0
        let ok = body.operand_kinds[callee_op]
        if ok == OperandKind.OK_COPY or ok == OperandKind.OK_MOVE:
            return self.sema.callable_any_fn_type(self.operand_tid_no_infer(body, callee_op) as TypeId)
        0

    mut fn operand_ref_target_tid(body: &MirBody, operand_id: i32) -> i32:
        if operand_id < 0 or operand_id >= body.operand_kinds.len():
            return 0
        let ok = body.operand_kinds[operand_id]
        if ok != OperandKind.OK_COPY and ok != OperandKind.OK_MOVE:
            return 0
        let place_id = body.operand_d0[operand_id]
        let local_id = self.place_local_id(body, place_id)
        if local_id < 0:
            return 0
        if self.place_is_direct_local(body, place_id, local_id) == 0:
            return 0
        self.local_ref_target_tid(body, local_id)

    mut fn operand_is_pointer_value(body: &MirBody, operand_id: i32) -> i32:
        if self.type_is_raw_pointer_tid(self.operand_tid(body, operand_id)): 1 else: 0

    mut fn call_arg_address_text(body: &MirBody, op_id: i32, arg_text: &str) -> str:
        // A constant operand has no address; materialize it as a C99
        // compound literal, an addressable lvalue for the call's duration
        // (the LLVM backend's entry-alloca-and-store for the same shape).
        if body.operand_kinds[op_id] != OperandKind.OK_CONSTANT:
            return "&(" ++ arg_text ++ ")"
        // A str constant is already the WITH_STR_LIT compound literal, an
        // lvalue of its own; wrapping it again initializes `ptr` with a
        // with_str ("initializing 'const char *' with … 'with_str'").
        if cc_str_starts_with(arg_text, "WITH_STR_LIT(") != 0:
            return "&(" ++ arg_text ++ ")"
        var lit_tid = self.operand_tid(body, op_id)
        if lit_tid == 0 or self.is_void_tid(lit_tid) != 0:
            lit_tid = self.sema.ty_i64 as i32
        "&((" ++ self.c_type(lit_tid, 0) ++ ")" ++ cc_lbrace() ++ arg_text ++ cc_rbrace() ++ ")"

    // Args for an unqualified str-builtin `_ref` callee
    // (unqualified_builtin_method_name): each str-ish operand — a str, a
    // `&str` view, or a reference to one — passes as the view the runtime
    // takes, the str's own {ptr, len} (#1810); scalar operands pass through.
    mut fn builtin_method_ref_args_text(body: &MirBody, args_id: i32) -> str:
        if args_id < 0 or args_id >= body.call_arg_starts.len():
            return ""
        let start = body.call_arg_starts[args_id]
        let count = body.call_arg_counts[args_id]
        var out = ""
        for i in 0..count:
            if i > 0:
                out = out ++ ", "
            let op_id = body.call_arg_operands[(start + i)]
            if self.tid_is_str_or_str_view(self.operand_tid(body, op_id)):
                out = out ++ self.str_value_text(body, op_id)
                continue
            out = out ++ self.operand_text(body, op_id)
        out

    mut fn call_args_text(body: &MirBody, args_id: i32, callee_operand: i32) -> str:
        if args_id < 0 or args_id >= body.call_arg_starts.len():
            return ""
        let start = body.call_arg_starts[args_id]
        let count = body.call_arg_counts[args_id]
        // Resolve callee signature to know which params expect pointers
        let callee_sig = if body.call_requires_contract(args_id): body.call_sig_index(args_id) else: self.callee_sig_from_operand(body, callee_operand)
        let callee_extern_name = self.callee_extern_name_from_operand(body, callee_operand)
        let callee_fn_tid = if callee_sig >= 0: 0 else: self.callee_fn_type_from_operand(body, callee_operand)
        let callee_param_count = if callee_sig >= 0: self.sema.sig_get_param_count(callee_sig) else if callee_fn_tid != 0: self.sema.get_type_d1(callee_fn_tid) else: 0
        if with_getenv_str("WITH_TRACE_CARGS").len() > 0:
            with_eprint(f"[cargs] extern={callee_extern_name} sig={callee_sig} fn_tid={callee_fn_tid} params={callee_param_count} argc={count}")
        var out = ""
        for i in 0..count:
            if i > 0:
                out = out ++ ", "
            let op_id = body.call_arg_operands[(start + i)]
            let arg_text = self.operand_text(body, op_id)
            // #1810: a `&str` parameter takes the view by value — the str's
            // own {ptr, len} (TypeLayout.type_layout_is_str_view) — from any
            // str-ish operand: a str, a view, a str constant, or a reference
            // to one (dereferenced down to the str by str_value_text).
            if i < callee_param_count:
                let view_p_tid = if callee_sig >= 0: self.sema.sig_param_type(callee_sig, i) else: self.sema.fn_type_param_type(callee_fn_tid, i)
                if self.sema.type_layout_is_str_view(view_p_tid) and self.tid_is_str_or_str_view(self.operand_tid(body, op_id)):
                    out = out ++ self.str_value_text(body, op_id)
                    continue
            // #2769: a function the included headers declare takes its
            // `c_char` pointer chains as the header spells them. Only a
            // bodiless extern: std.libc's own `strtol` is a With function
            // whose emitted prototype says int8_t**.
            if i < callee_param_count and callee_extern_name.len() > 0 and self.callee_is_bodiless(body, callee_operand) and self.extern_declared_by_included_headers(callee_extern_name):
                let header_p_tid = if callee_sig >= 0: self.sema.sig_param_type(callee_sig, i) else: self.sema.fn_type_param_type(callee_fn_tid, i)
                let char_spelled = self.header_char_pointer_type(header_p_tid)
                if char_spelled.len() > 0:
                    out = out ++ "((" ++ char_spelled ++ ")" ++ arg_text ++ ")"
                    continue
            if self.call_param_expects_c_pointer(body, args_id, callee_operand, i) != 0:
                if arg_text == "0" or arg_text == "NULL":
                    out = out ++ "NULL"
                    continue
                if self.operand_is_pointer_value(body, op_id) != 0:
                    out = out ++ arg_text
                    continue
                out = out ++ self.call_arg_address_text(body, op_id, arg_text)
                continue
            // If the argument is a struct value but the callee expects a pointer, emit &
            if i < callee_param_count:
                let p_tid = if callee_sig >= 0: self.sema.sig_param_type(callee_sig, i) else: self.sema.fn_type_param_type(callee_fn_tid, i)
                let p_resolved = self.sema.resolve_alias(p_tid)
                let p_tk = self.sema.get_type_kind(p_resolved)
                if p_tk == TypeKind.TY_FN:
                    let fat_arg_sym = self.operand_ck_fn_sym(body, op_id)
                    if fat_arg_sym != 0:
                        out = out ++ self.fat_fn_literal(fat_arg_sym, p_resolved as i32)
                        continue
                if p_tk == TypeKind.TY_PTR or p_tk == TypeKind.TY_REF:
                    if arg_text == "0" or arg_text == "NULL":
                        out = out ++ "NULL"
                        continue
                    let p_inner_tid = self.sema.resolve_alias(self.sema.get_type_d0(p_resolved) as TypeId)
                    let p_inner_tk = self.sema.get_type_kind(p_inner_tid)
                    let arg_tid_for_ptr = self.operand_tid(body, op_id)
                    let arg_resolved_for_ptr = self.sema.resolve_alias(arg_tid_for_ptr)
                    let arg_tk_for_ptr = self.sema.get_type_kind(arg_resolved_for_ptr)
                    if (p_inner_tk == TypeKind.TY_FN or p_inner_tk == TypeKind.TY_EXTERN_FN) and (arg_tk_for_ptr == TypeKind.TY_FN or arg_tk_for_ptr == TypeKind.TY_EXTERN_FN):
                        out = out ++ arg_text
                        continue
                    // A str or a `&str` view (a value, #1810) to a pointer
                    // parameter.
                    if arg_tk_for_ptr == TypeKind.TY_STR or self.sema.type_layout_is_str_view(arg_resolved_for_ptr as i32):
                        let str_arg = self.str_value_text(body, op_id)
                        if p_inner_tk == TypeKind.TY_STR:
                            // A `*const str` / `&mut str` param takes a HEADER
                            // pointer (a `&str` one took the view above). An
                            // array compound literal materializes the value
                            // and decays to with_str* (block lifetime covers
                            // the call). The old .ptr cast passed the DATA
                            // pointer as a header — reads garbage (#785).
                            out = out ++ "((with_str[]){ " ++ str_arg ++ " })"
                            continue
                        // §16.3c, D47: a `const char *` parameter borrows a C
                        // string for the call. A literal is its own
                        // NUL-terminated bytes; any other str or view — a
                        // range view is not terminated at its end — is lent
                        // a NUL-terminated copy (with_cstr_lend), released
                        // after the call, as the LLVM backend lends it.
                        if self.sema.sema_type_is_c_char_pointer(p_tid) != 0 and self.operand_is_str_const(body, op_id) == 0:
                            let lend_name = f"__with_lend{self.call_lends.len()}"
                            self.call_lends.push("with_cstr_lend(" ++ str_arg ++ ")")
                            out = out ++ "((" ++ self.c_type(p_tid, 0) ++ ")" ++ lend_name ++ ")"
                            continue
                        out = out ++ "((" ++ self.c_type(p_tid, 0) ++ ")((" ++ str_arg ++ ").ptr))"
                        continue
                    if self.operand_ref_target_tid(body, op_id) != 0:
                        out = out ++ arg_text
                        continue
                    let arg_tid = arg_tid_for_ptr
                    let arg_resolved = arg_resolved_for_ptr
                    let arg_tk = arg_tk_for_ptr
                    if arg_tk != TypeKind.TY_PTR and arg_tk != TypeKind.TY_REF:
                        out = out ++ self.call_arg_address_text(body, op_id, arg_text)
                        continue
                    // #785: a str CONSTANT typed &str by expected-type
                    // propagation renders as a with_str VALUE; a `*const str`
                    // param needs a real header pointer. The array compound
                    // literal materializes it with block lifetime.
                    if p_inner_tk == TypeKind.TY_STR and self.operand_is_str_const(body, op_id) != 0:
                        out = out ++ "((with_str[]){ " ++ arg_text ++ " })"
                        continue
                // Reverse: callee expects struct by value but arg is a pointer — dereference
                if p_tk == TypeKind.TY_STRUCT:
                    if self.operand_ref_target_tid(body, op_id) != 0:
                        out = out ++ "(*(" ++ arg_text ++ "))"
                        continue
                    let arg_tid = self.operand_tid(body, op_id)
                    let arg_resolved = self.sema.resolve_alias(arg_tid)
                    let arg_tk = self.sema.get_type_kind(arg_resolved)
                    if arg_tk == TypeKind.TY_PTR or arg_tk == TypeKind.TY_REF:
                        out = out ++ "(*(" ++ arg_text ++ "))"
                        continue
            out = out ++ arg_text
        out

    fn operand_is_str_const(body: &MirBody, op_id: i32) -> i32:
        if op_id < 0 or op_id >= body.operand_kinds.len():
            return 0
        if body.operand_kinds[op_id] != OperandKind.OK_CONSTANT:
            return 0
        let cd = body.operand_d0[op_id]
        if cd < 0 or cd >= body.const_kinds.len():
            return 0
        if body.const_kinds[cd] == ConstKind.CK_STR: 1 else: 0

    // The with_str VALUE of a str-ish operand. A str and a `&str` view both
    // render as it — a view is the str's own {ptr, len} (#1810); a thin
    // reference to one (`&&str`, `&mut str`) is dereferenced down to it.
    mut fn str_value_text(body: &MirBody, op_id: i32) -> str:
        var rendered = self.operand_text(body, op_id)
        var tid = self.sema.resolve_alias(self.operand_tid(body, op_id)) as i32
        while self.sema.get_type_kind(tid as TypeId) == TypeKind.TY_REF and not self.sema.type_layout_is_str_view(tid) and self.tid_is_str_or_str_view(tid):
            rendered = "(*(" ++ rendered ++ "))"
            tid = self.sema.resolve_alias(self.sema.get_type_d0(tid as TypeId) as TypeId) as i32
        rendered

    fn callee_extern_name_from_operand(body: &MirBody, callee_op: i32) -> str:
        if callee_op < 0 or callee_op >= body.operand_kinds.len():
            return ""
        let ok = body.operand_kinds[callee_op]
        if ok == OperandKind.OK_CONSTANT:
            let cd = body.operand_d0[callee_op]
            if cd >= 0 and cd < body.const_kinds.len():
                let ck = body.const_kinds[cd]
                if ck == ConstKind.CK_FN:
                    let fn_sym = body.const_d0[cd]
                    return self.canonical_extern_name(cc_intern_resolve(self.intern, fn_sym))
        ""

    // Whether a constant callee has no With body (an `extern fn`).
    fn callee_is_bodiless(body: &MirBody, callee_op: i32) -> bool:
        if callee_op < 0 or callee_op >= body.operand_kinds.len() or body.operand_kinds[callee_op] != OperandKind.OK_CONSTANT:
            return false
        let cd = body.operand_d0[callee_op]
        if cd < 0 or cd >= body.const_kinds.len() or body.const_kinds[cd] != ConstKind.CK_FN:
            return false
        self.has_body_for_sym(body.const_d0[cd]) == 0

    fn callee_sig_from_operand(body: &MirBody, callee_op: i32) -> i32:
        if callee_op < 0 or callee_op >= body.operand_kinds.len():
            return -1
        let ok = body.operand_kinds[callee_op]
        if ok == OperandKind.OK_CONSTANT:
            let cd = body.operand_d0[callee_op]
            if cd >= 0 and cd < body.const_kinds.len():
                let ck = body.const_kinds[cd]
                if ck == ConstKind.CK_FN:
                    let fn_sym = body.const_d0[cd]
                    return self.body_sig_index(fn_sym)
        -1

    mut fn emit_len_result(body: &MirBody, dest_place: i32, raw_expr: &str, kind: CcBuiltin, has_ret: i32) -> str:
        let mode = cc_builtin_len_mode(kind)
        var out = "    " ++ cc_lbrace() ++ " int64_t __with_len = (int64_t)(" ++ raw_expr ++ ");"
        if mode == CcLenMode.I32:
            out = out ++ " if (__with_len > 2147483647LL) with_panic(WITH_STR_LIT(\"collection length does not fit in len32()\"), WITH_STR_LIT(\"\"), 0);"
        else if mode == CcLenMode.U32:
            out = out ++ " if (__with_len > 4294967295LL) with_panic(WITH_STR_LIT(\"collection length does not fit in ulen32()\"), WITH_STR_LIT(\"\"), 0);"
        if has_ret != 0:
            out = out ++ " " ++ self.place_text(body, dest_place) ++ " = (" ++ cc_len_result_c_type(mode) ++ ")__with_len;"
        else:
            out = out ++ " (void)__with_len;"
        out ++ " " ++ cc_rbrace() ++ "\n"

fn cc_builtin_from_mir_intrinsic(intrinsic: MirIntrinsic) -> CcBuiltin:
    if intrinsic == MirIntrinsic.MATH_FN: return CcBuiltin.MATH_FN
    if intrinsic == MirIntrinsic.VA_START: return CcBuiltin.VA_START
    if intrinsic == MirIntrinsic.VA_ARG: return CcBuiltin.VA_ARG
    if intrinsic == MirIntrinsic.VA_END: return CcBuiltin.VA_END
    if intrinsic == MirIntrinsic.LIST_NEW: return CcBuiltin.LIST_NEW
    if intrinsic == MirIntrinsic.LIST_PUSH: return CcBuiltin.LIST_PUSH
    if intrinsic == MirIntrinsic.LIST_CONCAT: return CcBuiltin.LIST_CONCAT
    if intrinsic == MirIntrinsic.LIST_EXTEND: return CcBuiltin.LIST_EXTEND
    if intrinsic == MirIntrinsic.LIST_TAKE_FRONT: return CcBuiltin.LIST_TAKE_FRONT
    if intrinsic == MirIntrinsic.LIST_RESTORE_FRONT: return CcBuiltin.LIST_RESTORE_FRONT
    if intrinsic == MirIntrinsic.LIST_GET: return CcBuiltin.LIST_GET
    if intrinsic == MirIntrinsic.LIST_GET_REF: return CcBuiltin.LIST_GET
    if intrinsic == MirIntrinsic.LIST_LEN: return CcBuiltin.LIST_LEN
    if intrinsic == MirIntrinsic.LIST_IS_EMPTY: return CcBuiltin.LIST_IS_EMPTY
    if intrinsic == MirIntrinsic.LIST_LEN32: return CcBuiltin.LIST_LEN32
    if intrinsic == MirIntrinsic.LIST_LEN64: return CcBuiltin.LIST_LEN64
    if intrinsic == MirIntrinsic.LIST_ULEN32: return CcBuiltin.LIST_ULEN32

    if intrinsic == MirIntrinsic.LIST_REMOVE: return CcBuiltin.LIST_REMOVE
    if intrinsic == MirIntrinsic.LIST_CLEAR: return CcBuiltin.LIST_CLEAR
    if intrinsic == MirIntrinsic.LIST_MAKE_UNIQUE: return CcBuiltin.LIST_MAKE_UNIQUE
    if intrinsic == MirIntrinsic.MAP_MAKE_UNIQUE: return CcBuiltin.MAP_MAKE_UNIQUE
    if intrinsic == MirIntrinsic.LIST_POP: return CcBuiltin.LIST_POP
    if intrinsic == MirIntrinsic.MAP_NEW: return CcBuiltin.MAP_NEW
    if intrinsic == MirIntrinsic.MAP_INSERT: return CcBuiltin.MAP_INSERT
    if intrinsic == MirIntrinsic.MAP_GET: return CcBuiltin.MAP_GET
    if intrinsic == MirIntrinsic.MAP_CONTAINS: return CcBuiltin.MAP_CONTAINS
    if intrinsic == MirIntrinsic.MAP_LEN: return CcBuiltin.MAP_LEN
    if intrinsic == MirIntrinsic.MAP_LEN32: return CcBuiltin.MAP_LEN32
    if intrinsic == MirIntrinsic.MAP_LEN64: return CcBuiltin.MAP_LEN64
    if intrinsic == MirIntrinsic.MAP_ULEN32: return CcBuiltin.MAP_ULEN32
    if intrinsic == MirIntrinsic.MAP_REMOVE: return CcBuiltin.MAP_REMOVE
    if intrinsic == MirIntrinsic.COLLECTION_LITERAL or intrinsic == MirIntrinsic.MAP_LITERAL: return CcBuiltin.GENERIC_CALL
    if intrinsic == MirIntrinsic.OPT_IS_SOME: return CcBuiltin.OPT_IS_SOME
    if intrinsic == MirIntrinsic.OPT_UNWRAP: return CcBuiltin.OPT_UNWRAP
    if intrinsic == MirIntrinsic.OPT_EXPECT: return CcBuiltin.OPT_EXPECT
    if intrinsic == MirIntrinsic.ATOMIC_LOAD: return CcBuiltin.ATOMIC_LOAD
    if intrinsic == MirIntrinsic.ATOMIC_STORE: return CcBuiltin.ATOMIC_STORE
    if intrinsic == MirIntrinsic.ATOMIC_SWAP: return CcBuiltin.ATOMIC_SWAP
    if intrinsic == MirIntrinsic.ATOMIC_FETCH_ADD: return CcBuiltin.ATOMIC_FETCH_ADD
    if intrinsic == MirIntrinsic.ATOMIC_FETCH_SUB: return CcBuiltin.ATOMIC_FETCH_SUB
    if intrinsic == MirIntrinsic.ATOMIC_FETCH_AND: return CcBuiltin.ATOMIC_FETCH_AND
    if intrinsic == MirIntrinsic.ATOMIC_FETCH_OR: return CcBuiltin.ATOMIC_FETCH_OR
    if intrinsic == MirIntrinsic.ATOMIC_FETCH_XOR: return CcBuiltin.ATOMIC_FETCH_XOR
    if intrinsic == MirIntrinsic.ATOMIC_FETCH_MIN: return CcBuiltin.ATOMIC_FETCH_MIN
    if intrinsic == MirIntrinsic.ATOMIC_FETCH_MAX: return CcBuiltin.ATOMIC_FETCH_MAX
    if intrinsic == MirIntrinsic.ATOMIC_CAS: return CcBuiltin.ATOMIC_CAS
    if intrinsic == MirIntrinsic.ATOMIC_CAS_WEAK: return CcBuiltin.ATOMIC_CAS_WEAK
    if intrinsic == MirIntrinsic.ATOMIC_FENCE: return CcBuiltin.ATOMIC_FENCE
    if intrinsic == MirIntrinsic.STR_LEN: return CcBuiltin.STR_LEN
    if intrinsic == MirIntrinsic.STR_LEN32: return CcBuiltin.STR_LEN32
    if intrinsic == MirIntrinsic.STR_LEN64: return CcBuiltin.STR_LEN64
    if intrinsic == MirIntrinsic.STR_ULEN32: return CcBuiltin.STR_ULEN32
    if intrinsic == MirIntrinsic.STR_BYTE_AT: return CcBuiltin.STR_BYTE_AT
    if intrinsic == MirIntrinsic.STR_SLICE: return CcBuiltin.STR_SLICE
    if intrinsic == MirIntrinsic.STR_CONTAINS: return CcBuiltin.STR_CONTAINS
    if intrinsic == MirIntrinsic.STR_CONTAINS_CHAR: return CcBuiltin.STR_CONTAINS_CHAR
    if intrinsic == MirIntrinsic.STR_STARTS_WITH: return CcBuiltin.STR_STARTS_WITH
    if intrinsic == MirIntrinsic.STR_ENDS_WITH: return CcBuiltin.STR_ENDS_WITH
    if intrinsic == MirIntrinsic.STR_FIND: return CcBuiltin.STR_FIND
    if intrinsic == MirIntrinsic.MAP_CLEAR: return CcBuiltin.MAP_CLEAR
    if intrinsic == MirIntrinsic.OPT_IS_NONE: return CcBuiltin.OPT_IS_NONE
    if intrinsic == MirIntrinsic.STR_SPLIT: return CcBuiltin.STR_SPLIT
    if intrinsic == MirIntrinsic.STR_TO_UPPER: return CcBuiltin.STR_TO_UPPER
    if intrinsic == MirIntrinsic.STR_TO_LOWER: return CcBuiltin.STR_TO_LOWER
    if intrinsic == MirIntrinsic.STR_REPLACE: return CcBuiltin.STR_REPLACE
    if intrinsic == MirIntrinsic.STR_INDEX_OF: return CcBuiltin.STR_INDEX_OF
    if intrinsic == MirIntrinsic.MAP_INCREMENT: return CcBuiltin.MAP_INCREMENT
    if intrinsic == MirIntrinsic.MAP_DECREMENT: return CcBuiltin.MAP_DECREMENT
    if intrinsic == MirIntrinsic.MAP_UPDATE: return CcBuiltin.MAP_UPDATE
    if intrinsic == MirIntrinsic.MAP_CAPACITY or intrinsic == MirIntrinsic.MAP_SLOT_OCCUPIED or intrinsic == MirIntrinsic.MAP_KEY_AT or intrinsic == MirIntrinsic.MAP_VALUE_AT or intrinsic == MirIntrinsic.MAP_TAKE_AT: return CcBuiltin.MAP_SLOT_WALK
    if intrinsic == MirIntrinsic.LIST_CONTAINS: return CcBuiltin.LIST_CONTAINS
    if intrinsic == MirIntrinsic.STR_REPEAT: return CcBuiltin.STR_REPEAT
    if intrinsic == MirIntrinsic.ARR_LEN: return CcBuiltin.ARR_LEN
    if intrinsic == MirIntrinsic.ARR_LEN32: return CcBuiltin.ARR_LEN32
    if intrinsic == MirIntrinsic.ARR_LEN64: return CcBuiltin.ARR_LEN64
    if intrinsic == MirIntrinsic.ARR_ULEN32: return CcBuiltin.ARR_ULEN32
    if intrinsic == MirIntrinsic.GENERIC_CALL: return CcBuiltin.GENERIC_CALL
    if intrinsic == MirIntrinsic.LIST_JOIN: return CcBuiltin.LIST_JOIN
    if intrinsic == MirIntrinsic.DYN_VTABLE_CMP: return CcBuiltin.DYN_VTABLE_CMP
    if intrinsic == MirIntrinsic.DYN_DOWNCAST: return CcBuiltin.DYN_DOWNCAST
    if intrinsic == MirIntrinsic.DYN_CALL: return CcBuiltin.DYN_CALL
    if intrinsic == MirIntrinsic.OPT_FILTER: return CcBuiltin.OPT_FILTER
    if intrinsic == MirIntrinsic.ROTATE_LEFT: return CcBuiltin.ROTATE_LEFT
    if intrinsic == MirIntrinsic.ROTATE_RIGHT: return CcBuiltin.ROTATE_RIGHT
    if intrinsic == MirIntrinsic.LIST_WITH_CAPACITY: return CcBuiltin.LIST_WITH_CAPACITY
    if intrinsic == MirIntrinsic.FMT_TO_STR: return CcBuiltin.FMT_TO_STR
    if intrinsic == MirIntrinsic.FMT_DEBUG_STR: return CcBuiltin.FMT_DEBUG_STR
    if intrinsic == MirIntrinsic.FMT_DEBUG: return CcBuiltin.FMT_DEBUG
    if intrinsic == MirIntrinsic.FMT_SPEC: return CcBuiltin.FMT_SPEC
    if intrinsic == MirIntrinsic.FMT_BUF_NEW: return CcBuiltin.FMT_BUF_NEW
    if intrinsic == MirIntrinsic.FMT_BUF_WRITE_STR: return CcBuiltin.FMT_BUF_WRITE_STR
    if intrinsic == MirIntrinsic.FMT_BUF_WRITE_STR_REF: return CcBuiltin.FMT_BUF_WRITE_STR_REF
    if intrinsic == MirIntrinsic.STR_CLONE_REF: return CcBuiltin.STR_CLONE_REF
    if intrinsic == MirIntrinsic.CLOSURE_CLONE: return CcBuiltin.CLOSURE_CLONE
    if intrinsic == MirIntrinsic.FMT_BUF_WRITE_FMT: return CcBuiltin.FMT_BUF_WRITE_FMT
    if intrinsic == MirIntrinsic.FMT_BUF_FINISH: return CcBuiltin.FMT_BUF_FINISH
    if intrinsic == MirIntrinsic.LIST_SLOT: return CcBuiltin.LIST_SLOT
    if intrinsic == MirIntrinsic.LIST_GET_DISJOINT: return CcBuiltin.LIST_GET_DISJOINT
    if intrinsic == MirIntrinsic.VECSLOT_GET: return CcBuiltin.VECSLOT_GET
    if intrinsic == MirIntrinsic.VECSLOT_SET: return CcBuiltin.VECSLOT_SET
    if intrinsic == MirIntrinsic.SLOTMAP_NEW: return CcBuiltin.SLOTMAP
    if intrinsic == MirIntrinsic.SLOTMAP_INSERT: return CcBuiltin.SLOTMAP
    if intrinsic == MirIntrinsic.SLOTMAP_GET: return CcBuiltin.SLOTMAP
    if intrinsic == MirIntrinsic.SLOTMAP_SLOT: return CcBuiltin.SLOTMAP
    if intrinsic == MirIntrinsic.SLOTMAP_REMOVE: return CcBuiltin.SLOTMAP
    if intrinsic == MirIntrinsic.SLOTMAP_REPLACE: return CcBuiltin.SLOTMAP
    if intrinsic == MirIntrinsic.SLOTMAP_CONTAINS: return CcBuiltin.SLOTMAP
    if intrinsic == MirIntrinsic.SLOTMAP_LEN: return CcBuiltin.SLOTMAP
    if intrinsic == MirIntrinsic.SLOTMAP_LEN32: return CcBuiltin.SLOTMAP
    if intrinsic == MirIntrinsic.SLOTMAP_LEN64: return CcBuiltin.SLOTMAP
    if intrinsic == MirIntrinsic.SLOTMAP_ULEN32: return CcBuiltin.SLOTMAP
    if intrinsic == MirIntrinsic.SLOTMAP_GET_DISJOINT: return CcBuiltin.SLOTMAP
    if intrinsic == MirIntrinsic.SLOTMAPSLOT_GET: return CcBuiltin.SLOTMAP
    if intrinsic == MirIntrinsic.SLOTMAPSLOT_SET: return CcBuiltin.SLOTMAP
    if intrinsic == MirIntrinsic.VECRANGE_LEN: return CcBuiltin.VECRANGE
    if intrinsic == MirIntrinsic.VECRANGE_LEN32: return CcBuiltin.VECRANGE
    if intrinsic == MirIntrinsic.VECRANGE_LEN64: return CcBuiltin.VECRANGE
    if intrinsic == MirIntrinsic.VECRANGE_ULEN32: return CcBuiltin.VECRANGE
    if intrinsic == MirIntrinsic.SPLIT_AT or intrinsic == MirIntrinsic.SPLIT_AT_MUT:
        return CcBuiltin.VECRANGE
    if intrinsic == MirIntrinsic.MULTI_INDEX: return CcBuiltin.MULTI_INDEX
    if intrinsic == MirIntrinsic.MULTI_INDEX_SET: return CcBuiltin.MULTI_INDEX
    if intrinsic == MirIntrinsic.INT_SWAP_BYTES: return CcBuiltin.INT_SWAP_BYTES
    if intrinsic == MirIntrinsic.POPCOUNT: return CcBuiltin.POPCOUNT
    if intrinsic == MirIntrinsic.CLZ: return CcBuiltin.CLZ
    if intrinsic == MirIntrinsic.CTZ: return CcBuiltin.CTZ
    if intrinsic == MirIntrinsic.BITREVERSE: return CcBuiltin.BITREVERSE
    if intrinsic == MirIntrinsic.MIN: return CcBuiltin.MIN
    if intrinsic == MirIntrinsic.MAX: return CcBuiltin.MAX
    if intrinsic == MirIntrinsic.ABS: return CcBuiltin.ABS
    if intrinsic == MirIntrinsic.FMA: return CcBuiltin.FMA
    // §14.7: the cancellation checks MIR places after a call that may
    // suspend (#1985) are calls of the fiber runtime's own functions.
    if intrinsic == MirIntrinsic.FIBER_IS_CANCELLED: return CcBuiltin.FIBER_IS_CANCELLED
    if intrinsic == MirIntrinsic.FIBER_WAIT_CANCELLED: return CcBuiltin.FIBER_WAIT_CANCELLED
    if intrinsic == MirIntrinsic.FIBER_SET_CANCELLED_RETURN: return CcBuiltin.FIBER_SET_CANCELLED_RETURN
    if intrinsic == MirIntrinsic.FIBER_WAS_CANCELLED_RETURN: return CcBuiltin.FIBER_WAS_CANCELLED_RETURN
    CcBuiltin.NONE

impl CCodegen:
    mut fn emit_builtin_list_core_call_term(body: &MirBody, kind: CcBuiltin, args_id: i32, dest_place: i32, next_bb: i32, argc: i32, ret_tid: i32, has_ret: i32) -> str:
        if kind == CcBuiltin.DYN_CALL:
            self.fail("C backend is LLVM-only for dyn trait method dispatch by design (#301); compile this program with the LLVM backend")
            return "    abort();"

        if kind == CcBuiltin.MULTI_INDEX:
            self.fail("C backend is LLVM-only for MultiIndex intrinsics by design (#301); compile this program with the LLVM backend")
            return "    abort();"

        if kind == CcBuiltin.LIST_NEW:
            var out = ""
            if has_ret != 0:
                let elem_size = self.list_new_elem_size_text(body, dest_place)
                out = out ++ "    " ++ self.place_text(body, dest_place) ++ " = (with_vec)" ++ cc_lbrace() ++ " .ptr = NULL, .len = 0, .cap = 0, .start = 0 " ++ cc_rbrace() ++ ";\n"
            else:
                out = out ++ "    (void)0;\n"
            out = out ++ f"    goto bb{next_bb};"
            return out

        if kind == CcBuiltin.LIST_SLOT:
            if argc < 2:
                self.fail("vec.slot expects two arguments")
                return "    abort();"
            let recv = self.operand_text(body, self.call_arg_operand(body, args_id, 0))
            let idx = self.operand_text(body, self.call_arg_operand(body, args_id, 1))
            var out = ""
            if has_ret != 0:
                let dst = self.place_text(body, dest_place)
                let slot_ty = self.c_type(ret_tid, 0)
                out = out ++ "    " ++ dst ++ " = (" ++ slot_ty ++ ")" ++ cc_lbrace() ++ " .data_ptr = (int64_t)(intptr_t)((" ++ recv ++ ").ptr), .index = (int64_t)(" ++ idx ++ ") " ++ cc_rbrace() ++ ";\n"
            else:
                out = out ++ "    (void)0;\n"
            out = out ++ f"    goto bb{next_bb};"
            return out

        // See the LLVM-only-by-design note above (#301). get_disjoint / SlotMap /
        // ListRange (and their *_LEN32/64/ULEN32 variants, which route here) are
        // intentionally unsupported in the C backend.
        if kind == CcBuiltin.LIST_GET_DISJOINT:
            self.fail("C backend is LLVM-only for List.get_disjoint by design (#301); compile this program with the LLVM backend")
            return "    abort();"

        if kind == CcBuiltin.SLOTMAP:
            self.fail("C backend is LLVM-only for SlotMap intrinsics by design (#301); compile this program with the LLVM backend")
            return "    abort();"

        if kind == CcBuiltin.VECRANGE:
            self.fail("C backend is LLVM-only for ListRange intrinsics by design (#301); compile this program with the LLVM backend")
            return "    abort();"

        if kind == CcBuiltin.VECSLOT_GET:
            if argc < 1:
                self.fail("ListSlot.get expects one argument")
                return "    abort();"
            let recv = self.operand_text(body, self.call_arg_operand(body, args_id, 0))
            var elem_tid = ret_tid
            if elem_tid == 0 or self.is_void_tid(elem_tid) != 0:
                elem_tid = self.listslot_element_tid(self.operand_tid(body, self.call_arg_operand(body, args_id, 0)))
            if elem_tid == 0 or self.is_void_tid(elem_tid) != 0:
                elem_tid = self.sema.ty_i64 as i32
            let elem_ty = self.c_type(elem_tid, 0)
            var out = ""
            if has_ret != 0:
                let dst = self.place_text(body, dest_place)
                out = out ++ "    " ++ dst ++ " = ((" ++ elem_ty ++ "*)(intptr_t)((" ++ recv ++ ").data_ptr))[(" ++ recv ++ ").index];\n"
                // D111: the element read out is one more holder.
                let read_tid = self.place_sema_tid(body, dest_place)
                let hold = self.copy_call_text(dst, read_tid)
                if hold.len() > 0:
                    out = out ++ "    " ++ hold ++ "\n"
            else:
                out = out ++ "    (void)((" ++ elem_ty ++ "*)(intptr_t)((" ++ recv ++ ").data_ptr))[(" ++ recv ++ ").index];\n"
            out = out ++ f"    goto bb{next_bb};"
            return out

        if kind == CcBuiltin.VECSLOT_SET:
            if argc < 2:
                self.fail("ListSlot.set expects two arguments")
                return "    abort();"
            let recv = self.operand_text(body, self.call_arg_operand(body, args_id, 0))
            let val_operand = self.call_arg_operand(body, args_id, 1)
            let val = self.operand_text(body, val_operand)
            var elem_tid = self.operand_tid(body, val_operand)
            if elem_tid == 0 or self.is_void_tid(elem_tid) != 0:
                elem_tid = self.listslot_element_tid(self.operand_tid(body, self.call_arg_operand(body, args_id, 0)))
            if elem_tid == 0 or self.is_void_tid(elem_tid) != 0:
                elem_tid = self.sema.ty_i64 as i32
            let elem_ty = self.c_type(elem_tid, 0)
            let slot = "((" ++ elem_ty ++ "*)(intptr_t)((" ++ recv ++ ").data_ptr))[(" ++ recv ++ ").index]"
            // The replaced element's owner drops before the store.
            let old_drop = self.drop_call_text(slot, elem_tid, true)
            var out = if old_drop.len() > 0: "    " ++ old_drop ++ "\n" else: ""
            out = out ++ "    " ++ slot ++ " = " ++ val ++ ";\n"
            out = out ++ f"    goto bb{next_bb};"
            return out

        if kind == CcBuiltin.LIST_PUSH:
            if argc < 2:
                self.fail("vec.push expects two arguments")
                return "    abort();"
            let recv_ptr = self.list_recv_ptr_text(body, args_id)
            let elem_operand = self.call_arg_operand(body, args_id, 1)
            let elem_text = self.operand_text(body, elem_operand)
            var elem_tid = self.operand_tid(body, elem_operand)
            if elem_tid == 0 or self.is_void_tid(elem_tid) != 0:
                elem_tid = self.sema.ty_i64 as i32
            let elem_ty = self.c_type(elem_tid, 0)
            var out = "    " ++ cc_lbrace() ++ " " ++ elem_ty ++ " __with_tmp = " ++ elem_text ++ "; with_vec_push_es(" ++ recv_ptr ++ ", &__with_tmp, sizeof(" ++ elem_ty ++ ")); " ++ cc_rbrace() ++ "\n"
            out = out ++ f"    goto bb{next_bb};"
            return out

        if kind == CcBuiltin.LIST_GET:
            if argc < 2:
                self.fail("vec.get expects two arguments")
                return "    abort();"
            let recv_ptr = self.list_recv_ptr_text(body, args_id)
            let idx = self.operand_text(body, self.call_arg_operand(body, args_id, 1))
            let dst = self.place_text(body, dest_place)
            let get_ret_resolved = self.sema.resolve_alias(ret_tid as TypeId)
            if self.sema.get_type_kind(get_ret_resolved) == TypeKind.TY_REF:
                // D27 E2: VEC_GET_REF returns the address of vec-owned storage.
                // Copying sizeof(&T) bytes from the element fabricated a pointer
                // from the element's leading bytes (Option.Some's zero tag became
                // null) and lost the view entirely.
                let get_es = self.list_recv_elem_sizeof_text(body, args_id)
                var ref_out = "    " ++ dst ++ " = " ++ self.ref_from_slot_ptr_text("with_vec_get_ptr_es(" ++ recv_ptr ++ ", (int64_t)(" ++ idx ++ "), " ++ get_es ++ ")", ret_tid) ++ ";\n"
                ref_out = ref_out ++ f"    goto bb{next_bb};"
                return ref_out
            var out = "    memset(&(" ++ dst ++ "), 0, sizeof(" ++ dst ++ "));\n"
            out = out ++ "    if ((int64_t)(" ++ idx ++ ") >= 0 && (int64_t)(" ++ idx ++ ") < with_vec_len(" ++ recv_ptr ++ ")) " ++ cc_lbrace() ++ " memcpy(&(" ++ dst ++ "), with_vec_get_ptr_es(" ++ recv_ptr ++ ", (int64_t)(" ++ idx ++ "), " ++ self.list_recv_elem_sizeof_text(body, args_id) ++ "), sizeof(" ++ dst ++ ")); " ++ cc_rbrace() ++ "\n"
            out = out ++ f"    goto bb{next_bb};"
            return out

        if cc_builtin_is_list_len(kind):
            if argc < 1:
                self.fail("vec.len expects one argument")
                return "    abort();"
            let recv_ptr = self.list_recv_ptr_text(body, args_id)
            var out = self.emit_len_result(body, dest_place, "with_vec_len(" ++ recv_ptr ++ ")", kind, has_ret)
            out = out ++ f"    goto bb{next_bb};"
            return out

        if kind == CcBuiltin.LIST_IS_EMPTY:
            if argc < 1:
                self.fail("vec.is_empty expects one argument")
                return "    abort();"
            let recv_ptr = self.list_recv_ptr_text(body, args_id)
            var out = ""
            if has_ret != 0:
                out = out ++ "    " ++ self.place_text(body, dest_place) ++ " = with_vec_len(" ++ recv_ptr ++ ") == 0;\n"
            out = out ++ f"    goto bb{next_bb};"
            return out

        if kind == CcBuiltin.LIST_REMOVE:
            if argc < 2:
                self.fail("vec.remove expects two arguments")
                return "    abort();"
            let recv_ptr = self.list_recv_ptr_text(body, args_id)
            let idx = self.operand_text(body, self.call_arg_operand(body, args_id, 1))
            let es = self.list_recv_elem_sizeof_text(body, args_id)
            // #606: the element moves into the result, then the tail closes
            // over its slot, so it lives only in the result (#983: the
            // result was never written; `xs.remove(i)` read as zero).
            var out = "    " ++ cc_lbrace() ++ " void* __with_e = with_vec_get_ptr_es(" ++ recv_ptr ++ ", (int64_t)(" ++ idx ++ "), " ++ es ++ ");"
            if has_ret != 0:
                let dst = self.place_text(body, dest_place)
                out = out ++ " memcpy(&(" ++ dst ++ "), __with_e, sizeof(" ++ dst ++ "));"
            out = out ++ " with_vec_remove_es(" ++ recv_ptr ++ ", (int64_t)(" ++ idx ++ "), " ++ es ++ "); " ++ cc_rbrace() ++ "\n"
            out = out ++ f"    goto bb{next_bb};"
            return out

        if kind == CcBuiltin.LIST_CLEAR:
            if argc < 1:
                self.fail("vec.clear expects one argument")
                return "    abort();"
            let recv_ptr = self.list_recv_ptr_text(body, args_id)
            // #606: each live element drops before the length resets.
            let elem = self.list_element_tid(self.recv_value_tid(body, args_id))
            var out = ""
            if self.glue_needed(elem):
                let elem_c = self.c_type(elem, 0)
                out = "    " ++ cc_lbrace() ++ " with_vec* __l = " ++ recv_ptr ++ "; for (int64_t __i = 0; __i < __l->len; __i++) " ++ cc_lbrace() ++ " " ++ self.drop_call_text("((" ++ elem_c ++ "*)__l->ptr)[__i]", elem, true) ++ " " ++ cc_rbrace() ++ " " ++ cc_rbrace() ++ "\n"
            out = out ++ "    with_vec_clear(" ++ recv_ptr ++ ");\n"
            out = out ++ f"    goto bb{next_bb};"
            return out

        if kind == CcBuiltin.LIST_MAKE_UNIQUE:
            // D120: copy-on-write before a mutation of a value List; a fresh
            // buffer's elements with copy glue take their holds.
            if argc < 1:
                self.fail("list make-unique expects one argument")
                return "    abort();"
            let recv_ptr = self.list_recv_ptr_text(body, args_id)
            let elem = self.list_element_tid(self.recv_value_tid(body, args_id))
            return self.list_make_unique_text(recv_ptr, elem) ++ f"    goto bb{next_bb};"

        if kind == CcBuiltin.MAP_MAKE_UNIQUE:
            // D120 stage 2: the same before a mutation of a value HashMap or
            // HashSet; the handle slot is rewritten when the table is copied.
            if argc < 1:
                self.fail("map make-unique expects one argument")
                return "    abort();"
            let recv = self.map_recv_text(body, args_id)
            let map_tid = self.recv_value_tid(body, args_id)
            return self.map_make_unique_text(recv, map_tid) ++ f"    goto bb{next_bb};"

        if kind == CcBuiltin.LIST_CONCAT or kind == CcBuiltin.LIST_EXTEND:
            return self.emit_list_concat(body, args_id, dest_place, kind, has_ret, next_bb)

        if kind == CcBuiltin.LIST_RESTORE_FRONT:
            let recv_ptr = self.list_recv_ptr_text(body, args_id)
            let rf_es = self.list_recv_elem_sizeof_text(body, args_id)
            let elem_text = self.operand_text(body, self.call_arg_operand(body, args_id, 1))
            var out = "    " ++ cc_lbrace() ++ " with_vec_restore_front_es((uint8_t*)" ++ recv_ptr ++ ", (const uint8_t*)&(" ++ elem_text ++ "), " ++ rf_es ++ "); " ++ cc_rbrace() ++ "\n"
            return out ++ f"    goto bb{next_bb};"

        if kind == CcBuiltin.LIST_TAKE_FRONT:
            let recv_ptr = self.list_recv_ptr_text(body, args_id)
            let tf_es = self.list_recv_elem_sizeof_text(body, args_id)
            var out = "    " ++ cc_lbrace()
            if has_ret != 0:
                let dst = self.place_text(body, dest_place)
                out = out ++ " memcpy(&(" ++ dst ++ "), with_vec_get_ptr_es(" ++ recv_ptr ++ ", 0, " ++ tf_es ++ "), sizeof(" ++ dst ++ "));"
            out = out ++ " with_vec_take_front_es((uint8_t*)" ++ recv_ptr ++ ", " ++ tf_es ++ "); " ++ cc_rbrace() ++ "\n"
            return out ++ f"    goto bb{next_bb};"

        if kind == CcBuiltin.LIST_POP:
            if argc < 1:
                self.fail("vec.pop expects one argument")
                return "    abort();"
            let recv_ptr = self.list_recv_ptr_text(body, args_id)
            let pop_es = self.list_recv_elem_sizeof_text(body, args_id)
            var out = "    " ++ cc_lbrace() ++ " int64_t __with_n = with_vec_len(" ++ recv_ptr ++ ");\n"
            if has_ret != 0:
                let dst = self.place_text(body, dest_place)
                let dst_tid = ret_tid
                if self.type_is_payload_enum(dst_tid) != 0:
                    let some_variant = self.payload_enum_single_payload_variant(dst_tid)
                    let none_variant = self.payload_enum_single_unit_variant(dst_tid)
                    if some_variant < 0 or none_variant < 0:
                        self.fail("List.pop Option result requires one payload variant and one unit variant")
                        return "    abort();"
                    let payload_tid = self.sema.type_reflection_variant_payload_type_frozen(dst_tid, some_variant, 0)
                    let payload_c = self.c_type(payload_tid, 0)
                    out = out ++ "        if (__with_n > 0) " ++ cc_lbrace() ++ " " ++ payload_c ++ " __with_v = " ++ self.zero_value_text(payload_tid) ++ "; memcpy(&__with_v, with_vec_get_ptr_es(" ++ recv_ptr ++ ", __with_n - 1, " ++ pop_es ++ "), sizeof(__with_v)); with_vec_remove_es(" ++ recv_ptr ++ ", __with_n - 1, " ++ pop_es ++ "); " ++ dst ++ " = " ++ self.payload_enum_literal(dst_tid, some_variant, "__with_v") ++ "; " ++ cc_rbrace() ++ "\n"
                    out = out ++ "        else " ++ cc_lbrace() ++ " " ++ dst ++ " = " ++ self.payload_enum_literal(dst_tid, none_variant, "") ++ "; " ++ cc_rbrace() ++ "\n"
                else:
                    // Pointer-niche Option: zero is None and the payload itself
                    // is Some. Keep this fallback representation-preserving.
                    out = out ++ "        memset(&(" ++ dst ++ "), 0, sizeof(" ++ dst ++ "));\n"
                    out = out ++ "        if (__with_n > 0) " ++ cc_lbrace() ++ " memcpy(&(" ++ dst ++ "), with_vec_get_ptr_es(" ++ recv_ptr ++ ", __with_n - 1, " ++ pop_es ++ "), sizeof(" ++ dst ++ ")); with_vec_remove_es(" ++ recv_ptr ++ ", __with_n - 1, " ++ pop_es ++ "); " ++ cc_rbrace() ++ "\n"
            else:
                out = out ++ "        if (__with_n > 0) " ++ cc_lbrace() ++ " with_vec_remove_es(" ++ recv_ptr ++ ", __with_n - 1, " ++ pop_es ++ "); " ++ cc_rbrace() ++ "\n"
            out = out ++ "    " ++ cc_rbrace() ++ "\n"
            out = out ++ f"    goto bb{next_bb};"
            return out

        ""

    mut fn emit_builtin_map_call_term(body: &MirBody, kind: CcBuiltin, args_id: i32, dest_place: i32, next_bb: i32, argc: i32, ret_tid: i32, has_ret: i32) -> str:
        if kind == CcBuiltin.MAP_NEW:
            var out = ""
            if has_ret != 0:
                let dst_tid = self.call_dest_expected_tid(body, dest_place)
                var key_tid = self.hashmap_key_tid(dst_tid)
                if key_tid == 0 or self.is_void_tid(key_tid) != 0:
                    key_tid = self.sema.ty_i64 as i32
                var val_tid = self.hashmap_value_tid(dst_tid)
                if val_tid == 0 or self.is_void_tid(val_tid) != 0:
                    val_tid = self.sema.ty_i64 as i32
                let key_ty = self.c_type(key_tid, 0)
                let val_ty = self.c_type(val_tid, 0)
                out = out ++ "    " ++ self.place_text(body, dest_place) ++ " = (int64_t)(intptr_t)with_hashmap_new_keyed(sizeof(" ++ key_ty ++ "), sizeof(" ++ val_ty ++ "), " ++ self.map_key_args_text(key_tid) ++ ");\n"
            else:
                out = out ++ "    (void)0;\n"
            out = out ++ f"    goto bb{next_bb};"
            return out

        if kind == CcBuiltin.MAP_INSERT:
            if argc < 2:
                self.fail("map.insert expects a key argument")
                return "    abort();"
            let recv = self.map_recv_text(body, args_id)
            let key_operand = self.call_arg_operand(body, args_id, 1)
            let key_text = self.operand_text(body, key_operand)
            let key_tid = self.map_call_key_tid(body, args_id, key_operand)
            // One-arg form is HashSet.insert(key): the value is a present
            // marker, mirroring the LLVM backend's set branch.
            var val_text = "1"
            var val_tid = self.sema.ty_i64 as i32
            if argc >= 3:
                let val_operand = self.call_arg_operand(body, args_id, 2)
                val_text = self.operand_text(body, val_operand)
                val_tid = self.operand_tid(body, val_operand)
                if val_tid == 0 or self.is_void_tid(val_tid) != 0:
                    val_tid = self.sema.ty_i64 as i32
            let key_ty = self.c_type(key_tid, 0)
            let val_ty = self.c_type(val_tid, 0)
            let is_str_key = if self.sema.get_type_kind(self.sema.resolve_alias(key_tid as TypeId)) == TypeKind.TY_STR: "1" else: "0"
            // No lazy creation here: like the LLVM backend, insert loads the
            // handle MAP_NEW produced. Lazily creating wrote through const
            // receivers and silently accepted handles LLVM would crash on.
            var out = "    " ++ cc_lbrace() ++ " " ++ key_ty ++ " __with_k = " ++ key_text ++ "; " ++ val_ty ++ " __with_v = " ++ val_text ++ ";"
            let map_tid = self.recv_value_tid(body, args_id)
            out = out ++ self.owned_map_insert_text("(void*)(intptr_t)(" ++ recv ++ ")", is_str_key, key_tid, self.hashmap_value_tid(map_tid)) ++ " " ++ cc_rbrace() ++ "\n"
            out = out ++ f"    goto bb{next_bb};"
            return out

        if kind == CcBuiltin.MAP_CONTAINS:
            if argc < 2:
                self.fail("map.contains expects two arguments")
                return "    abort();"
            let recv = self.map_recv_text(body, args_id)
            let key_operand = self.call_arg_operand(body, args_id, 1)
            let key_text = self.operand_text(body, key_operand)
            let key_tid = self.map_call_key_tid(body, args_id, key_operand)
            let key_ty = self.c_type(key_tid, 0)
            let is_str_key = if self.sema.get_type_kind(self.sema.resolve_alias(key_tid as TypeId)) == TypeKind.TY_STR: "1" else: "0"
            var out = "    " ++ cc_lbrace() ++ " " ++ key_ty ++ " __with_k = " ++ key_text ++ "; "
            if has_ret != 0:
                out = out ++ self.place_text(body, dest_place) ++ " = "
            out = out ++ "(((" ++ recv ++ ") != 0) && (with_hashmap_contains((void*)(intptr_t)(" ++ recv ++ "), &__with_k, " ++ is_str_key ++ ") != 0)); " ++ cc_rbrace() ++ "\n"
            out = out ++ f"    goto bb{next_bb};"
            return out

        if cc_builtin_is_map_len(kind):
            if argc < 1:
                self.fail("map.len expects one argument")
                return "    abort();"
            let recv = self.map_recv_text(body, args_id)
            let raw = "(((" ++ recv ++ ") != 0) ? with_hashmap_len((void*)(intptr_t)(" ++ recv ++ ")) : 0)"
            var out = self.emit_len_result(body, dest_place, raw, kind, has_ret)
            out = out ++ f"    goto bb{next_bb};"
            return out

        if kind == CcBuiltin.MAP_REMOVE:
            if argc < 2:
                self.fail("map.remove expects two arguments")
                return "    abort();"
            let recv = self.map_recv_text(body, args_id)
            let owner = self.call_first_arg_owner_text(body, args_id)
            let recv_is_hashmap = if owner == "HashMap": 1 else: 0
            let key_operand = self.call_arg_operand(body, args_id, 1)
            let key_text = self.operand_text(body, key_operand)
            let key_tid = self.map_call_key_tid(body, args_id, key_operand)
            let key_ty = self.c_type(key_tid, 0)
            let is_str_key = if self.sema.get_type_kind(self.sema.resolve_alias(key_tid as TypeId)) == TypeKind.TY_STR: "1" else: "0"
            var out = f"    {cc_lbrace()} {key_ty} __with_k = {key_text}; "
            // #1189: removal transfers the stored key out too; one that owns
            // memory is dropped here (the probe is the caller's, D110).
            let stored_key = self.hashmap_key_tid(self.recv_value_tid(body, args_id))
            let key_glue = self.glue_needed(stored_key)
            var key_drop = ""
            if key_glue:
                out = out ++ self.c_type(stored_key, 0) ++ " __with_sk = " ++ self.zero_value_text(stored_key) ++ "; "
                key_drop = " " ++ self.drop_call_text("__with_sk", stored_key, true)
            let remove_call = if key_glue: "with_hashmap_remove_entry((void*)(intptr_t)(" ++ recv ++ "), &__with_k, &__with_sk, " else: "with_hashmap_remove((void*)(intptr_t)(" ++ recv ++ "), &__with_k, "
            let remove_tail = if key_glue: ")" else: ", " ++ is_str_key ++ ")"
            if recv_is_hashmap != 0:
                let dst = self.place_text(body, dest_place)
                if self.type_is_payload_enum(ret_tid) == 0:
                    self.fail("HashMap.remove Option result requires a payload enum")
                    return "    abort();"
                let some_variant = self.payload_enum_single_payload_variant(ret_tid)
                let none_variant = self.payload_enum_single_unit_variant(ret_tid)
                if some_variant < 0 or none_variant < 0:
                    self.fail("HashMap.remove Option result requires one payload variant and one unit variant")
                    return "    abort();"
                let payload_tid = self.sema.type_reflection_variant_payload_type_frozen(ret_tid, some_variant, 0)
                let payload_c = self.c_type(payload_tid, 0)
                out = out ++ payload_c ++ " __with_v = " ++ self.zero_value_text(payload_tid) ++ ";"
                out = out ++ " if ((" ++ recv ++ ") != 0 && " ++ remove_call ++ "&__with_v" ++ remove_tail ++ " != 0) "
                out = out ++ cc_lbrace() ++ " " ++ dst ++ " = " ++ self.payload_enum_literal(ret_tid, some_variant, "__with_v") ++ "; " ++ cc_rbrace()
                out = out ++ " else " ++ cc_lbrace() ++ " " ++ dst ++ " = " ++ self.payload_enum_literal(ret_tid, none_variant, "") ++ "; " ++ cc_rbrace() ++ key_drop ++ " " ++ cc_rbrace() ++ "\n"
            else:
                if has_ret != 0:
                    out = out ++ self.place_text(body, dest_place) ++ " = "
                out = out ++ "(((" ++ recv ++ ") != 0) && (" ++ remove_call ++ "(void*)0" ++ remove_tail ++ " != 0));" ++ key_drop ++ " " ++ cc_rbrace() ++ "\n"
            out = out ++ f"    goto bb{next_bb};"
            return out

        if kind == CcBuiltin.MAP_GET:
            if argc < 2:
                self.fail("map.get expects two arguments")
                return "    abort();"
            let recv = self.map_recv_text(body, args_id)
            let key_operand = self.call_arg_operand(body, args_id, 1)
            let key_text = self.operand_text(body, key_operand)
            let key_tid = self.map_call_key_tid(body, args_id, key_operand)
            let key_ty = self.c_type(key_tid, 0)
            let is_str_key = if self.sema.get_type_kind(self.sema.resolve_alias(key_tid as TypeId)) == TypeKind.TY_STR: "1" else: "0"
            let dst = self.place_text(body, dest_place)
            let dst_tid = ret_tid
            if self.type_is_payload_enum(dst_tid) != 0:
                let some_variant = self.payload_enum_single_payload_variant(dst_tid)
                let none_variant = self.payload_enum_single_unit_variant(dst_tid)
                if some_variant < 0 or none_variant < 0:
                    self.fail("Map.get Option result requires one payload variant and one unit variant")
                    return "    abort();"
                let payload_tid = self.sema.type_reflection_variant_payload_type_frozen(dst_tid, some_variant, 0)
                var out = "    " ++ cc_lbrace() ++ " " ++ key_ty ++ " __with_k = " ++ key_text ++ "; void* __with_p = ((" ++ recv ++ ") != 0) ? with_hashmap_get_ptr((void*)(intptr_t)(" ++ recv ++ "), &__with_k, " ++ is_str_key ++ ") : (void*)0;"
                out = out ++ " if (__with_p != (void*)0) "
                let payload_view = self.ref_from_slot_ptr_text("__with_p", payload_tid)
                out = out ++ cc_lbrace() ++ " " ++ dst ++ " = " ++ self.payload_enum_literal(dst_tid, some_variant, payload_view) ++ "; " ++ cc_rbrace()
                out = out ++ " else " ++ cc_lbrace() ++ " " ++ dst ++ " = " ++ self.payload_enum_literal(dst_tid, none_variant, "") ++ "; " ++ cc_rbrace()
                out = out ++ " " ++ cc_rbrace() ++ "\n"
                out = out ++ f"    goto bb{next_bb};"
                return out
            // D22: niche-lowered Option[&V] is the nullable pointer itself.
            // Contextual Copy, when requested, must already be explicit in MIR;
            // emit-C must not infer it from V or the destination spelling.
            var out = "    " ++ cc_lbrace() ++ " " ++ key_ty ++ " __with_k = " ++ key_text ++ "; void* __with_p = ((" ++ recv ++ ") != 0) ? with_hashmap_get_ptr((void*)(intptr_t)(" ++ recv ++ "), &__with_k, " ++ is_str_key ++ ") : (void*)0;"
            out = out ++ " memcpy(&(" ++ dst ++ "), &__with_p, sizeof(__with_p) < sizeof(" ++ dst ++ ") ? sizeof(__with_p) : sizeof(" ++ dst ++ ")); " ++ cc_rbrace() ++ "\n"
            out = out ++ f"    goto bb{next_bb};"
            return out

        ""

    mut fn emit_builtin_option_call_term(body: &MirBody, kind: CcBuiltin, args_id: i32, dest_place: i32, next_bb: i32, argc: i32, ret_tid: i32, has_ret: i32) -> str:
        if kind == CcBuiltin.OPT_IS_SOME:
            if argc < 1:
                self.fail("Option.is_some expects one argument")
                return "    abort();"
            let opt_operand = self.call_arg_operand(body, args_id, 0)
            let opt_text = self.operand_text(body, opt_operand)
            let opt_tid = self.operand_tid(body, opt_operand)
            var test_text = "((" ++ opt_text ++ ") != 0)"
            if self.type_is_payload_enum(opt_tid) != 0:
                let some_variant = self.payload_enum_single_payload_variant(opt_tid)
                if some_variant < 0:
                    self.fail("Option.is_some expects an enum with one payload-bearing variant")
                    return "    abort();"
                let tag = self.sema.type_reflection_variant_discriminant(opt_tid, some_variant)
                test_text = "(" ++ self.enum_tag_text(opt_tid, opt_text) ++ " == " ++ f"{tag}" ++ ")"
            var out = ""
            if has_ret != 0:
                out = out ++ "    " ++ self.place_text(body, dest_place) ++ " = " ++ test_text ++ ";\n"
            else:
                out = out ++ "    (void)" ++ test_text ++ ";\n"
            out = out ++ f"    goto bb{next_bb};"
            return out

        if kind == CcBuiltin.OPT_UNWRAP or kind == CcBuiltin.OPT_EXPECT:
            let is_expect = kind == CcBuiltin.OPT_EXPECT
            let expected_argc = if is_expect: 3 else: 2
            if argc < expected_argc:
                self.fail(if is_expect: "Option.expect expects receiver, message, and location" else: "Option.unwrap expects receiver and location")
                return "    abort();"
            let opt_operand = self.call_arg_operand(body, args_id, 0)
            let opt_text = self.operand_text(body, opt_operand)
            let opt_tid = self.operand_tid(body, opt_operand)
            let loc_text = self.operand_text(body, self.call_arg_operand(body, args_id, argc - 1))
            let user_msg = if is_expect: self.operand_text(body, self.call_arg_operand(body, args_id, 1)) else: "WITH_STR_LIT(\"\")"
            let dst = self.place_text(body, dest_place)
            let opt_resolved = self.sema.resolve_alias(opt_tid as TypeId)
            var carrier_tid = opt_tid
            var borrowed_carrier = false
            if self.sema.get_type_kind(opt_resolved) == TypeKind.TY_REF and self.sema.get_type_d1(opt_resolved) == 0:
                let carrier_candidate = self.sema.resolve_alias(self.sema.get_type_d0(opt_resolved) as TypeId)
                if self.sema.get_type_kind(carrier_candidate) == TypeKind.TY_GENERIC_INST:
                    let carrier_base = self.sema.get_generic_inst_base(carrier_candidate as i32)
                    if carrier_base == self.sema.syms.option or carrier_base == self.sema.syms.result:
                        carrier_tid = carrier_candidate as i32
                        borrowed_carrier = true
            if self.type_is_payload_enum(carrier_tid) != 0:
                let carrier_resolved = self.sema.resolve_alias(carrier_tid as TypeId)
                let carrier_text = if borrowed_carrier: "(*(" ++ opt_text ++ "))" else: opt_text
                let is_result = self.sema.get_type_kind(carrier_resolved) == TypeKind.TY_GENERIC_INST and self.sema.get_generic_inst_base(carrier_resolved as i32) == self.sema.syms.result
                let ok_variant = if is_result: self.payload_enum_named_variant(carrier_tid, self.sema.syms.ok) else: self.payload_enum_named_variant(carrier_tid, self.sema.syms.some)
                let payload_variant = if ok_variant >= 0: ok_variant else: self.payload_enum_single_payload_variant(carrier_tid)
                if payload_variant < 0:
                    self.fail("Option.unwrap/expect expects an enum with a payload-bearing success variant")
                    return "    abort();"
                let ok_tag = self.sema.type_reflection_variant_discriminant(carrier_tid, payload_variant)
                var panic_msg = if is_expect: "with_str_concat_ref(" ++ user_msg ++ ", WITH_STR_LIT(\": None\"))" else: "WITH_STR_LIT(\"called unwrap on None\")"
                if is_result:
                    let err_variant = self.payload_enum_named_variant(carrier_tid, self.sema.syms.err)
                    if err_variant < 0:
                        self.fail("Result.unwrap/expect expects an Err variant")
                        return "    abort();"
                    let err_payload_count = self.sema.type_reflection_variant_payload_count(carrier_tid, err_variant)
                    let err_tid = if err_payload_count > 0: self.sema.type_reflection_variant_payload_type_frozen(carrier_tid, err_variant, 0) else: 0
                    // D61: the error's `:?` form when it has one — the LLVM
                    // backend's gen_unwrap_err_message builds the same text.
                    if err_payload_count > 0 and self.debug_form_available(err_tid):
                        let err_debug = self.debug_format_expr(err_tid, carrier_text ++ self.enum_payload_member(carrier_tid, err_variant), "Result.unwrap/expect")
                        let prefix = if is_expect: user_msg else: "WITH_STR_LIT(\"called unwrap on Err\")"
                        panic_msg = "with_str_concat_ref(with_str_concat_ref(" ++ prefix ++ ", WITH_STR_LIT(\": \")), " ++ err_debug ++ ")"
                    else:
                        panic_msg = if is_expect: user_msg else: "WITH_STR_LIT(\"called unwrap on Err\")"
                var out = "    if (" ++ self.enum_tag_text(carrier_tid, carrier_text) ++ " != " ++ f"{ok_tag}" ++ ") with_panic(" ++ panic_msg ++ ", " ++ loc_text ++ ", 0);\n"
                let payload_text = carrier_text ++ self.enum_payload_member(carrier_tid, payload_variant)
                if has_ret != 0:
                    if borrowed_carrier:
                        let payload_tid = self.sema.type_reflection_variant_payload_type_frozen(carrier_tid, payload_variant, 0)
                        let payload_resolved = self.sema.resolve_alias(payload_tid as TypeId)
                        if self.sema.get_type_kind(payload_resolved) == TypeKind.TY_REF:
                            out = out ++ "    " ++ dst ++ " = " ++ payload_text ++ ";\n"
                        else:
                            out = out ++ "    " ++ dst ++ " = &(" ++ payload_text ++ ");\n"
                    else:
                        out = out ++ "    " ++ dst ++ " = " ++ payload_text ++ ";\n"
                else:
                    out = out ++ "    (void)" ++ payload_text ++ ";\n"
                out = out ++ f"    goto bb{next_bb};"
                return out
            if self.type_is_raw_pointer_tid(opt_tid):
                let panic_msg2 = if is_expect: "with_str_concat_ref(" ++ user_msg ++ ", WITH_STR_LIT(\": None\"))" else: "WITH_STR_LIT(\"called unwrap on None\")"
                var out2 = "    if ((" ++ opt_text ++ ") == NULL) with_panic(" ++ panic_msg2 ++ ", " ++ loc_text ++ ", 0);\n"
                if has_ret != 0:
                    out2 = out2 ++ "    " ++ dst ++ " = " ++ opt_text ++ ";\n"
                else:
                    out2 = out2 ++ "    (void)" ++ opt_text ++ ";\n"
                out2 = out2 ++ f"    goto bb{next_bb};"
                return out2
            // Option unwrap: value = encoded - 1. Use memcpy to handle with_str/with_vec destinations.
            let panic_msg3 = if is_expect: "with_str_concat_ref(" ++ user_msg ++ ", WITH_STR_LIT(\": None\"))" else: "WITH_STR_LIT(\"called unwrap on None\")"
            var out = "    if ((" ++ opt_text ++ ") == 0) with_panic(" ++ panic_msg3 ++ ", " ++ loc_text ++ ", 0);\n"
            if has_ret != 0:
                out = out ++ "    " ++ cc_lbrace() ++ " int64_t __uw = ((" ++ opt_text ++ ") - 1); memcpy(&(" ++ dst ++ "), &__uw, sizeof(" ++ dst ++ ") < sizeof(__uw) ? sizeof(" ++ dst ++ ") : sizeof(__uw)); " ++ cc_rbrace() ++ "\n"
            else:
                out = out ++ "    (void)((" ++ opt_text ++ ") - 1);\n"
            out = out ++ f"    goto bb{next_bb};"
            return out

        ""

    mut fn emit_builtin_atomic_call_term(body: &MirBody, kind: CcBuiltin, args_id: i32, dest_place: i32, next_bb: i32, argc: i32, ret_tid: i32, has_ret: i32) -> str:
        if kind == CcBuiltin.ATOMIC_LOAD:
            if argc < 2:
                self.fail("Atomic.load expects two arguments")
                return "    abort();"
            let recv_ptr = self.atomic_recv_ptr_text(body, args_id)
            let order = self.atomic_order_text(self.operand_text(body, self.call_arg_operand(body, args_id, 1)))
            var out = ""
            if has_ret != 0:
                out = out ++ "    " ++ self.place_text(body, dest_place) ++ " = __atomic_load_n(&((" ++ recv_ptr ++ ")->val), " ++ order ++ ");\n"
            else:
                out = out ++ "    (void)__atomic_load_n(&((" ++ recv_ptr ++ ")->val), " ++ order ++ ");\n"
            out = out ++ f"    goto bb{next_bb};"
            return out

        if kind == CcBuiltin.ATOMIC_STORE:
            if argc < 3:
                self.fail("Atomic.store expects three arguments")
                return "    abort();"
            let recv_ptr = self.atomic_recv_ptr_text(body, args_id)
            let val = self.operand_text(body, self.call_arg_operand(body, args_id, 1))
            let order = self.atomic_order_text(self.operand_text(body, self.call_arg_operand(body, args_id, 2)))
            var out = "    __atomic_store_n(&((" ++ recv_ptr ++ ")->val), " ++ val ++ ", " ++ order ++ ");\n"
            out = out ++ f"    goto bb{next_bb};"
            return out

        if kind == CcBuiltin.ATOMIC_SWAP:
            if argc < 3:
                self.fail("Atomic.swap expects three arguments")
                return "    abort();"
            let recv_ptr = self.atomic_recv_ptr_text(body, args_id)
            let val = self.operand_text(body, self.call_arg_operand(body, args_id, 1))
            let order = self.atomic_order_text(self.operand_text(body, self.call_arg_operand(body, args_id, 2)))
            var out = ""
            if has_ret != 0:
                out = out ++ "    " ++ self.place_text(body, dest_place) ++ " = __atomic_exchange_n(&((" ++ recv_ptr ++ ")->val), " ++ val ++ ", " ++ order ++ ");\n"
            else:
                out = out ++ "    (void)__atomic_exchange_n(&((" ++ recv_ptr ++ ")->val), " ++ val ++ ", " ++ order ++ ");\n"
            out = out ++ f"    goto bb{next_bb};"
            return out

        if kind == CcBuiltin.ATOMIC_FETCH_ADD or kind == CcBuiltin.ATOMIC_FETCH_SUB or kind == CcBuiltin.ATOMIC_FETCH_AND or kind == CcBuiltin.ATOMIC_FETCH_OR or kind == CcBuiltin.ATOMIC_FETCH_XOR:
            if argc < 3:
                self.fail("Atomic.fetch_* expects three arguments")
                return "    abort();"
            let recv_ptr = self.atomic_recv_ptr_text(body, args_id)
            let val = self.operand_text(body, self.call_arg_operand(body, args_id, 1))
            let order = self.atomic_order_text(self.operand_text(body, self.call_arg_operand(body, args_id, 2)))
            let op =
                if kind == CcBuiltin.ATOMIC_FETCH_ADD: "__atomic_fetch_add"
                else if kind == CcBuiltin.ATOMIC_FETCH_SUB: "__atomic_fetch_sub"
                else if kind == CcBuiltin.ATOMIC_FETCH_AND: "__atomic_fetch_and"
                else if kind == CcBuiltin.ATOMIC_FETCH_OR: "__atomic_fetch_or"
                else: "__atomic_fetch_xor"
            var out = ""
            if has_ret != 0:
                out = out ++ "    " ++ self.place_text(body, dest_place) ++ " = " ++ op ++ "(&((" ++ recv_ptr ++ ")->val), " ++ val ++ ", " ++ order ++ ");\n"
            else:
                out = out ++ "    (void)" ++ op ++ "(&((" ++ recv_ptr ++ ")->val), " ++ val ++ ", " ++ order ++ ");\n"
            out = out ++ f"    goto bb{next_bb};"
            return out

        if kind == CcBuiltin.ATOMIC_FETCH_MIN or kind == CcBuiltin.ATOMIC_FETCH_MAX:
            if argc < 3:
                self.fail("Atomic.fetch_min/fetch_max expects three arguments")
                return "    abort();"
            let recv_ptr = self.atomic_recv_ptr_text(body, args_id)
            let val = self.operand_text(body, self.call_arg_operand(body, args_id, 1))
            let order = self.atomic_order_text(self.operand_text(body, self.call_arg_operand(body, args_id, 2)))
            let fail_order = "(" ++ order ++ " == __ATOMIC_RELEASE ? __ATOMIC_RELAXED : (" ++ order ++ " == __ATOMIC_ACQ_REL ? __ATOMIC_ACQUIRE : " ++ order ++ "))"
            let tmp = f"__with_atomic_{args_id}"
            let cmp = if kind == CcBuiltin.ATOMIC_FETCH_MIN: "<" else: ">"
            var out = "    __typeof__(((" ++ recv_ptr ++ ")->val)) " ++ tmp ++ "_old = __atomic_load_n(&((" ++ recv_ptr ++ ")->val), " ++ order ++ ");\n"
            out = out ++ "    for (;;) " ++ cc_lbrace() ++ "\n"
            out = out ++ "        __typeof__(" ++ tmp ++ "_old) " ++ tmp ++ "_desired = ((" ++ val ++ ") " ++ cmp ++ " " ++ tmp ++ "_old) ? (" ++ val ++ ") : " ++ tmp ++ "_old;\n"
            out = out ++ "        if (" ++ tmp ++ "_desired == " ++ tmp ++ "_old || __atomic_compare_exchange_n(&((" ++ recv_ptr ++ ")->val), &" ++ tmp ++ "_old, " ++ tmp ++ "_desired, 0, " ++ order ++ ", " ++ fail_order ++ ")) break;\n"
            out = out ++ "    " ++ cc_rbrace() ++ "\n"
            if has_ret != 0:
                out = out ++ "    " ++ self.place_text(body, dest_place) ++ " = " ++ tmp ++ "_old;\n"
            else:
                out = out ++ "    (void)" ++ tmp ++ "_old;\n"
            out = out ++ f"    goto bb{next_bb};"
            return out

        if kind == CcBuiltin.ATOMIC_CAS or kind == CcBuiltin.ATOMIC_CAS_WEAK:
            if argc < 5:
                self.fail("Atomic.compare_exchange expects five arguments")
                return "    abort();"
            let recv_ptr = self.atomic_recv_ptr_text(body, args_id)
            let expected = self.operand_text(body, self.call_arg_operand(body, args_id, 1))
            let desired = self.operand_text(body, self.call_arg_operand(body, args_id, 2))
            let success_order = self.atomic_order_text(self.operand_text(body, self.call_arg_operand(body, args_id, 3)))
            let failure_order = self.atomic_order_text(self.operand_text(body, self.call_arg_operand(body, args_id, 4)))
            let ret_ty = self.place_local_tid(body, dest_place)
            let ok_variant = self.payload_enum_named_variant(ret_ty, self.sema.syms.ok)
            let err_variant = self.payload_enum_named_variant(ret_ty, self.sema.syms.err)
            if ok_variant < 0 or err_variant < 0:
                self.fail("Atomic.compare_exchange requires Result[T, T] destination")
                return "    abort();"
            let tmp = f"__with_atomic_cas_{args_id}"
            let weak = if kind == CcBuiltin.ATOMIC_CAS_WEAK: "1" else: "0"
            var out = "    __typeof__(((" ++ recv_ptr ++ ")->val)) " ++ tmp ++ "_expected = " ++ expected ++ ";\n"
            out = out ++ "    int " ++ tmp ++ "_ok = __atomic_compare_exchange_n(&((" ++ recv_ptr ++ ")->val), &" ++ tmp ++ "_expected, " ++ desired ++ ", " ++ weak ++ ", " ++ success_order ++ ", " ++ failure_order ++ ");\n"
            if has_ret != 0:
                out = out ++ "    " ++ self.place_text(body, dest_place) ++ " = " ++ tmp ++ "_ok ? " ++ self.payload_enum_literal(ret_ty, ok_variant, tmp ++ "_expected") ++ " : " ++ self.payload_enum_literal(ret_ty, err_variant, tmp ++ "_expected") ++ ";\n"
            else:
                out = out ++ "    (void)" ++ tmp ++ "_ok;\n"
            out = out ++ f"    goto bb{next_bb};"
            return out

        if kind == CcBuiltin.ATOMIC_FENCE:
            if argc < 1:
                self.fail("fence expects one argument")
                return "    abort();"
            let order = self.atomic_order_text(self.operand_text(body, self.call_arg_operand(body, args_id, 0)))
            var out = "    __atomic_thread_fence(" ++ order ++ ");\n"
            out = out ++ f"    goto bb{next_bb};"
            return out

        if kind == CcBuiltin.FIBER_IS_CANCELLED or kind == CcBuiltin.FIBER_WAIT_CANCELLED or kind == CcBuiltin.FIBER_SET_CANCELLED_RETURN or kind == CcBuiltin.FIBER_WAS_CANCELLED_RETURN:
            var call = if kind == CcBuiltin.FIBER_IS_CANCELLED: "with_fiber_is_cancelled()"
                else if kind == CcBuiltin.FIBER_WAIT_CANCELLED: "with_fiber_wait_cancelled()"
                else if kind == CcBuiltin.FIBER_SET_CANCELLED_RETURN: "with_fiber_set_cancelled_return()"
                else: ""
            if kind == CcBuiltin.FIBER_WAS_CANCELLED_RETURN:
                if argc < 1:
                    self.fail("was_cancelled expects the task's fiber id")
                    return "    abort();"
                call = "with_fiber_was_cancelled_return(" ++ self.operand_text(body, self.call_arg_operand(body, args_id, 0)) ++ ")"
            var out = if has_ret != 0 and kind != CcBuiltin.FIBER_SET_CANCELLED_RETURN: "    " ++ self.place_text(body, dest_place) ++ " = " ++ call ++ ";\n" else: "    " ++ call ++ ";\n"
            out = out ++ f"    goto bb{next_bb};"
            return out

        ""

    mut fn emit_builtin_string_call_term(body: &MirBody, kind: CcBuiltin, args_id: i32, dest_place: i32, next_bb: i32, argc: i32, ret_tid: i32, has_ret: i32) -> str:
        if cc_builtin_is_str_len(kind):
            if argc < 1:
                self.fail("str.len expects one argument")
                return "    abort();"
            let recv = self.operand_text(body, self.call_arg_operand(body, args_id, 0))
            var out = self.emit_len_result(body, dest_place, "((" ++ recv ++ ").len)", kind, has_ret)
            out = out ++ f"    goto bb{next_bb};"
            return out

        if kind == CcBuiltin.STR_BYTE_AT:
            if argc < 2:
                self.fail("str.byte_at expects two arguments")
                return "    abort();"
            let recv = self.operand_text(body, self.call_arg_operand(body, args_id, 0))
            let idx = self.operand_text(body, self.call_arg_operand(body, args_id, 1))
            var out = ""
            if has_ret != 0:
                out = out ++ "    " ++ self.place_text(body, dest_place) ++ " = with_str_byte_at_ref(" ++ recv ++ ", (int64_t)(" ++ idx ++ "));\n"
            else:
                out = out ++ "    (void)with_str_byte_at_ref(" ++ recv ++ ", (int64_t)(" ++ idx ++ "));\n"
            out = out ++ f"    goto bb{next_bb};"
            return out

        if kind == CcBuiltin.STR_SLICE:
            if argc < 3:
                self.fail("str.slice expects three arguments")
                return "    abort();"
            let recv = self.operand_text(body, self.call_arg_operand(body, args_id, 0))
            let start = self.operand_text(body, self.call_arg_operand(body, args_id, 1))
            let end_ = self.operand_text(body, self.call_arg_operand(body, args_id, 2))
            var out = ""
            if has_ret != 0:
                out = out ++ "    " ++ self.place_text(body, dest_place) ++ " = with_str_slice_ref(" ++ recv ++ ", (int64_t)(" ++ start ++ "), (int64_t)(" ++ end_ ++ "));\n"
            else:
                out = out ++ "    (void)with_str_slice_ref(" ++ recv ++ ", (int64_t)(" ++ start ++ "), (int64_t)(" ++ end_ ++ "));\n"
            out = out ++ f"    goto bb{next_bb};"
            return out

        if kind == CcBuiltin.STR_CONTAINS:
            if argc < 2:
                self.fail("str.contains expects two arguments")
                return "    abort();"
            let recv = self.operand_text(body, self.call_arg_operand(body, args_id, 0))
            let needle = self.operand_text(body, self.call_arg_operand(body, args_id, 1))
            var out = ""
            if has_ret != 0:
                out = out ++ "    " ++ self.place_text(body, dest_place) ++ " = with_str_contains_ref(" ++ recv ++ ", " ++ needle ++ ");\n"
            else:
                out = out ++ "    (void)with_str_contains_ref(" ++ recv ++ ", " ++ needle ++ ");\n"
            out = out ++ f"    goto bb{next_bb};"
            return out

        if kind == CcBuiltin.STR_CONTAINS_CHAR:
            if argc < 2:
                self.fail("char-in-str membership expects two arguments")
                return "    abort();"
            let recv = self.operand_text(body, self.call_arg_operand(body, args_id, 0))
            let ch = self.operand_text(body, self.call_arg_operand(body, args_id, 1))
            var out = ""
            if has_ret != 0:
                out = out ++ "    " ++ self.place_text(body, dest_place) ++ " = with_str_contains_char_ref(" ++ recv ++ ", (int32_t)(" ++ ch ++ "));\n"
            else:
                out = out ++ "    (void)with_str_contains_char_ref(" ++ recv ++ ", (int32_t)(" ++ ch ++ "));\n"
            out = out ++ f"    goto bb{next_bb};"
            return out

        if kind == CcBuiltin.STR_STARTS_WITH:
            if argc < 2:
                self.fail("str.starts_with expects two arguments")
                return "    abort();"
            let recv = self.operand_text(body, self.call_arg_operand(body, args_id, 0))
            let prefix = self.operand_text(body, self.call_arg_operand(body, args_id, 1))
            var out = ""
            if has_ret != 0:
                out = out ++ "    " ++ self.place_text(body, dest_place) ++ " = with_str_starts_with_ref(" ++ recv ++ ", " ++ prefix ++ ");\n"
            else:
                out = out ++ "    (void)with_str_starts_with_ref(" ++ recv ++ ", " ++ prefix ++ ");\n"
            out = out ++ f"    goto bb{next_bb};"
            return out

        if kind == CcBuiltin.STR_ENDS_WITH:
            if argc < 2:
                self.fail("str.ends_with expects two arguments")
                return "    abort();"
            let recv = self.operand_text(body, self.call_arg_operand(body, args_id, 0))
            let suffix = self.operand_text(body, self.call_arg_operand(body, args_id, 1))
            var out = ""
            if has_ret != 0:
                out = out ++ "    " ++ self.place_text(body, dest_place) ++ " = with_str_ends_with_ref(" ++ recv ++ ", " ++ suffix ++ ");\n"
            else:
                out = out ++ "    (void)with_str_ends_with_ref(" ++ recv ++ ", " ++ suffix ++ ");\n"
            out = out ++ f"    goto bb{next_bb};"
            return out

        if kind == CcBuiltin.STR_FIND:
            if argc < 2:
                self.fail("str.find expects two arguments")
                return "    abort();"
            let recv = self.operand_text(body, self.call_arg_operand(body, args_id, 0))
            let needle = self.operand_text(body, self.call_arg_operand(body, args_id, 1))
            var out = ""
            if has_ret != 0:
                out = out ++ "    " ++ self.place_text(body, dest_place) ++ " = with_str_index_of_ref(" ++ recv ++ ", " ++ needle ++ ");\n"
            else:
                out = out ++ "    (void)with_str_index_of_ref(" ++ recv ++ ", " ++ needle ++ ");\n"
            out = out ++ f"    goto bb{next_bb};"
            return out

        if kind == CcBuiltin.STR_INDEX_OF:
            if argc < 2:
                self.fail("str.index_of expects two arguments")
                return "    abort();"
            let recv = self.operand_text(body, self.call_arg_operand(body, args_id, 0))
            let needle = self.operand_text(body, self.call_arg_operand(body, args_id, 1))
            var out = ""
            if has_ret != 0:
                out = out ++ "    " ++ self.place_text(body, dest_place) ++ " = with_str_index_of_ref(" ++ recv ++ ", " ++ needle ++ ");\n"
            else:
                out = out ++ "    (void)with_str_index_of_ref(" ++ recv ++ ", " ++ needle ++ ");\n"
            out = out ++ f"    goto bb{next_bb};"
            return out

        if kind == CcBuiltin.STR_SPLIT:
            if argc < 2:
                self.fail("str.split expects two arguments")
                return "    abort();"
            let recv = self.operand_text(body, self.call_arg_operand(body, args_id, 0))
            let delim = self.operand_text(body, self.call_arg_operand(body, args_id, 1))
            var out = ""
            if has_ret != 0:
                out = out ++ "    with_str_split_vec_ref(&(" ++ self.place_text(body, dest_place) ++ "), " ++ recv ++ ", " ++ delim ++ ");\n"
            else:
                out = out ++ "    " ++ cc_lbrace() ++ " with_vec __with_tmp_split; with_str_split_vec_ref(&__with_tmp_split, " ++ recv ++ ", " ++ delim ++ "); " ++ cc_rbrace() ++ "\n"
            out = out ++ f"    goto bb{next_bb};"
            return out

        if kind == CcBuiltin.STR_TO_UPPER:
            if argc < 1:
                self.fail("str.to_upper expects one argument")
                return "    abort();"
            let recv = self.operand_text(body, self.call_arg_operand(body, args_id, 0))
            var out = ""
            if has_ret != 0:
                out = out ++ "    " ++ self.place_text(body, dest_place) ++ " = with_str_to_upper_ref(" ++ recv ++ ");\n"
            else:
                out = out ++ "    (void)with_str_to_upper_ref(" ++ recv ++ ");\n"
            out = out ++ f"    goto bb{next_bb};"
            return out

        if kind == CcBuiltin.STR_TO_LOWER:
            if argc < 1:
                self.fail("str.to_lower expects one argument")
                return "    abort();"
            let recv = self.operand_text(body, self.call_arg_operand(body, args_id, 0))
            var out = ""
            if has_ret != 0:
                out = out ++ "    " ++ self.place_text(body, dest_place) ++ " = with_str_to_lower_ref(" ++ recv ++ ");\n"
            else:
                out = out ++ "    (void)with_str_to_lower_ref(" ++ recv ++ ");\n"
            out = out ++ f"    goto bb{next_bb};"
            return out

        if kind == CcBuiltin.STR_REPLACE:
            if argc < 3:
                self.fail("str.replace expects three arguments")
                return "    abort();"
            let recv = self.operand_text(body, self.call_arg_operand(body, args_id, 0))
            let old_s = self.operand_text(body, self.call_arg_operand(body, args_id, 1))
            let new_s = self.operand_text(body, self.call_arg_operand(body, args_id, 2))
            var out = ""
            if has_ret != 0:
                out = out ++ "    " ++ self.place_text(body, dest_place) ++ " = with_str_replace_ref(" ++ recv ++ ", " ++ old_s ++ ", " ++ new_s ++ ");\n"
            else:
                out = out ++ "    (void)with_str_replace_ref(" ++ recv ++ ", " ++ old_s ++ ", " ++ new_s ++ ");\n"
            out = out ++ f"    goto bb{next_bb};"
            return out

        if kind == CcBuiltin.STR_REPEAT:
            if argc < 2:
                self.fail("str.repeat expects two arguments")
                return "    abort();"
            let recv = self.operand_text(body, self.call_arg_operand(body, args_id, 0))
            let n = self.operand_text(body, self.call_arg_operand(body, args_id, 1))
            var out = ""
            if has_ret != 0:
                out = out ++ "    " ++ self.place_text(body, dest_place) ++ " = with_str_repeat_ref(" ++ recv ++ ", (int64_t)(" ++ n ++ "));\n"
            else:
                out = out ++ "    (void)with_str_repeat_ref(" ++ recv ++ ", (int64_t)(" ++ n ++ "));\n"
            out = out ++ f"    goto bb{next_bb};"
            return out

        ""

    mut fn emit_builtin_option_string_call_term(body: &MirBody, kind: CcBuiltin, args_id: i32, dest_place: i32, next_bb: i32, argc: i32, ret_tid: i32, has_ret: i32) -> str:
        var out = self.emit_builtin_option_call_term(body, kind, args_id, dest_place, next_bb, argc, ret_tid, has_ret)
        if out.len() > 0:
            return out
        out = self.emit_builtin_atomic_call_term(body, kind, args_id, dest_place, next_bb, argc, ret_tid, has_ret)
        if out.len() > 0:
            return out
        out = self.emit_builtin_string_call_term(body, kind, args_id, dest_place, next_bb, argc, ret_tid, has_ret)
        if out.len() > 0:
            return out
        ""

    // #1810: the `&T` of a runtime slot's address. A thin reference is the
    // address; a `&str` view is `{ptr, len}` read out of the slot.
    mut fn ref_from_slot_ptr_text(slot_ptr: &str, ref_tid: i32) -> str:
        if self.sema.type_layout_is_str_view(ref_tid):
            return "(*(const with_str*)(" ++ slot_ptr ++ "))"
        "((" ++ self.c_type(ref_tid, 0) ++ ")" ++ slot_ptr ++ ")"

    // D44 map traversal (`for (k, v) in map`, MirLower.lower_for_hashmap)
    // walks the table's slots: MAP_CAPACITY bounds the walk, an unoccupied
    // slot is skipped, and an occupied one is read where it lives — a view
    // destination gets the slot's address, a Copy value destination is
    // loaded through it. Nothing non-Copy is duplicated (§2.3). The same
    // runtime accessors as the LLVM backend (#1434).
    mut fn map_slot_walk_term(body: &MirBody, args_id: i32, dest_place: i32, next_bb: i32, argc: i32, has_ret: i32) -> str:
        let intrinsic = body.call_intrinsic(args_id)
        let map_ptr = "(uint8_t*)(intptr_t)(" ++ self.map_recv_text(body, args_id) ++ ")"
        var value = ""
        var slot_guard = ""
        if intrinsic == MirIntrinsic.MAP_CAPACITY:
            value = "with_hashmap_capacity(" ++ map_ptr ++ ")"
        else:
            if argc < 2:
                self.fail("emit-c: a map slot access expects the map and a slot index")
                return "    abort();"
            let slot = "(int64_t)(" ++ self.operand_text(body, self.call_arg_operand(body, args_id, 1)) ++ ")"
            // D44: a consuming traversal moves the entry into its (K, V)
            // destination; the runtime marks it dead without a drop.
            if intrinsic == MirIntrinsic.MAP_TAKE_AT:
                if has_ret == 0:
                    self.fail("emit-c: a map entry is taken into a destination")
                    return "    abort();"
                let entry = self.place_text(body, dest_place)
                // D100: a dead slot writes nothing; no uninitialized entry.
                return "    if (!with_hashmap_take_at(" ++ map_ptr ++ ", " ++ slot ++ ", (void*)&(" ++ entry ++ ").field0, (void*)&(" ++ entry ++ ").field1)) with_panic(WITH_STR_LIT(\"map slot holds no entry: slot_take moved from a removed or out-of-range slot\"), WITH_STR_LIT(\"\"), 0);\n" ++ f"    goto bb{next_bb};"
            if intrinsic == MirIntrinsic.MAP_SLOT_OCCUPIED:
                value = "with_hashmap_slot_occupied(" ++ map_ptr ++ ", " ++ slot ++ ")"
            else:
                let at_fn = if intrinsic == MirIntrinsic.MAP_KEY_AT: "with_hashmap_key_ptr_at" else: "with_hashmap_value_ptr_at"
                let at = at_fn ++ "(" ++ map_ptr ++ ", " ++ slot ++ ")"
                let dest_tid = self.place_tid_no_infer(body, dest_place)
                if dest_tid == 0 or self.is_void_tid(dest_tid) != 0:
                    self.fail("emit-c: a map slot's key or value has no destination type")
                    return "    abort();"
                let dest_is_view = self.sema.get_type_kind(self.sema.resolve_alias(dest_tid)) == TypeKind.TY_REF
                value = if dest_is_view: self.ref_from_slot_ptr_text(at, dest_tid) else: "(*(" ++ self.c_type(dest_tid, 0) ++ "*)" ++ at ++ ")"
                // D100: no unchecked helpers; a dead slot has nothing to read.
                slot_guard = "    if (!with_hashmap_slot_occupied(" ++ map_ptr ++ ", " ++ slot ++ ")) with_panic(WITH_STR_LIT(\"map slot holds no entry: slot_key/slot_value read a removed or out-of-range slot\"), WITH_STR_LIT(\"\"), 0);\n"
        // The guard leads the read (it was overwritten here, so a dead
        // slot was read with no panic).
        var out = slot_guard.clone()
        if has_ret != 0:
            let dst = self.place_text(body, dest_place)
            out = out ++ "    " ++ dst ++ " = " ++ value ++ ";\n"
            // D111: a key or value read out by value is one more holder.
            let read_tid = self.place_sema_tid(body, dest_place)
            if self.sema.get_type_kind(self.sema.resolve_alias(read_tid as TypeId)) != TypeKind.TY_REF and self.glue_needed(read_tid):
                out = out ++ "    " ++ self.copy_call_text(dst, read_tid) ++ "\n"
        else:
            out = out ++ "    (void)" ++ value ++ ";\n"
        out ++ f"    goto bb{next_bb};"

    mut fn emit_builtin_list_extra_call_term(body: &MirBody, kind: CcBuiltin, args_id: i32, dest_place: i32, next_bb: i32, argc: i32, ret_tid: i32, has_ret: i32) -> str:
        if kind == CcBuiltin.MAP_CLEAR:
            if argc < 1:
                self.fail("map.clear expects one argument")
                return "    abort();"
            let recv = self.map_recv_text(body, args_id)
            // The table is type-erased: the live entries drop through the
            // receiver's type before clear resets occupancy.
            let map_tid = self.recv_value_tid(body, args_id)
            let entries = self.map_entries_glue_text(map_tid, false)
            var out = "    " ++ cc_lbrace() ++ " uint8_t* __h = (uint8_t*)(intptr_t)(" ++ recv ++ "); if (__h != NULL) " ++ cc_lbrace() ++ " " ++ entries ++ "with_hashmap_clear(__h); " ++ cc_rbrace() ++ " " ++ cc_rbrace() ++ "\n"
            out = out ++ f"    goto bb{next_bb};"
            return out

        if kind == CcBuiltin.MAP_INCREMENT or kind == CcBuiltin.MAP_DECREMENT:
            if argc < 2:
                self.fail("map increment/decrement expects two arguments")
                return "    abort();"
            let recv = self.map_recv_text(body, args_id)
            let key_operand = self.call_arg_operand(body, args_id, 1)
            let key_text = self.operand_text(body, key_operand)
            let key_tid = self.map_call_key_tid(body, args_id, key_operand)
            let key_ty = self.c_type(key_tid, 0)
            let is_str_key = if self.sema.get_type_kind(self.sema.resolve_alias(key_tid as TypeId)) == TypeKind.TY_STR: "1" else: "0"
            let fn_name = if kind == CcBuiltin.MAP_INCREMENT: "with_hashmap_increment" else: "with_hashmap_decrement"
            var out = "    " ++ cc_lbrace() ++ " " ++ key_ty ++ " __with_k = " ++ key_text ++ "; " ++ fn_name ++ "((void*)(intptr_t)(" ++ recv ++ "), &__with_k, " ++ is_str_key ++ "); " ++ cc_rbrace() ++ "\n"
            out = out ++ f"    goto bb{next_bb};"
            return out

        if kind == CcBuiltin.MAP_SLOT_WALK:
            return self.map_slot_walk_term(body, args_id, dest_place, next_bb, argc, has_ret)

        if kind == CcBuiltin.MAP_UPDATE:
            self.fail("emit-c: HashMap.update requires closure lowering")
            var out = "    abort();\n"
            out = out ++ f"    goto bb{next_bb};"
            return out

        if kind == CcBuiltin.OPT_IS_NONE:
            if argc < 1:
                self.fail("Option.is_none expects one argument")
                return "    abort();"
            let opt_operand = self.call_arg_operand(body, args_id, 0)
            let opt_text = self.operand_text(body, opt_operand)
            let opt_tid = self.operand_tid(body, opt_operand)
            var test_text = "((" ++ opt_text ++ ") == 0)"
            if self.type_is_payload_enum(opt_tid) != 0:
                let some_variant = self.payload_enum_single_payload_variant(opt_tid)
                if some_variant < 0:
                    self.fail("Option.is_none expects an enum with one payload-bearing variant")
                    return "    abort();"
                let tag = self.sema.type_reflection_variant_discriminant(opt_tid, some_variant)
                test_text = "(" ++ self.enum_tag_text(opt_tid, opt_text) ++ " != " ++ f"{tag}" ++ ")"
            var out = ""
            if has_ret != 0:
                out = out ++ "    " ++ self.place_text(body, dest_place) ++ " = " ++ test_text ++ ";\n"
            else:
                out = out ++ "    (void)" ++ test_text ++ ";\n"
            out = out ++ f"    goto bb{next_bb};"
            return out


        if kind == CcBuiltin.LIST_CONTAINS:
            if argc < 2:
                self.fail("vec.contains expects two arguments")
                return "    abort();"
            let recv_ptr = self.list_recv_ptr_text(body, args_id)
            let elem_operand = self.call_arg_operand(body, args_id, 1)
            let elem_text = self.operand_text(body, elem_operand)
            var elem_tid = self.operand_tid(body, elem_operand)
            if elem_tid == 0 or self.is_void_tid(elem_tid) != 0:
                elem_tid = self.sema.ty_i64 as i32
            // Each element is compared by its type's `==` (§11.7): a str by
            // its text, an aggregate part by part. By its bytes, a str
            // compared pointers, so `["--emit-c"].contains(arg)` was false
            // for an `arg` spelled the same.
            let list_elem = self.list_element_tid(self.recv_value_tid(body, args_id))
            let cmp_tid = if list_elem > 0: list_elem else: elem_tid
            let cmp_c = self.c_type(cmp_tid, 0)
            let needle_tid = self.operand_sema_tid(body, elem_operand)
            let needle_c = self.c_type(if needle_tid > 0: needle_tid else: elem_tid, 0)
            let needle_is_ref = needle_tid > 0 and self.sema.get_type_kind(self.sema.resolve_alias(needle_tid as TypeId)) == TypeKind.TY_REF and not self.sema.type_layout_is_str_view(self.sema.resolve_alias(needle_tid as TypeId) as i32)
            let needle_lv = if needle_is_ref: "(*__with_needle)" else: "__with_needle"
            let equal = self.key_eq_text("__with_cur", needle_lv, cmp_tid)
            let dst = self.place_text(body, dest_place)
            var out = "    " ++ cc_lbrace() ++ " int64_t __with_found = 0; int64_t __with_ci; int64_t __with_cn = with_vec_len(" ++ recv_ptr ++ "); " ++ needle_c ++ " __with_needle = " ++ elem_text ++ ";"
            out = out ++ " for (__with_ci = 0; __with_ci < __with_cn; __with_ci++) " ++ cc_lbrace()
            out = out ++ " " ++ cmp_c ++ " __with_cur; memcpy(&__with_cur, with_vec_get_ptr_es(" ++ recv_ptr ++ ", __with_ci, sizeof(" ++ cmp_c ++ ")), sizeof(" ++ cmp_c ++ "));"
            out = out ++ " if (" ++ equal ++ ") " ++ cc_lbrace() ++ " __with_found = 1; break; " ++ cc_rbrace()
            out = out ++ " " ++ cc_rbrace()
            if has_ret != 0:
                out = out ++ " " ++ dst ++ " = __with_found;"
            out = out ++ " " ++ cc_rbrace() ++ "\n"
            out = out ++ f"    goto bb{next_bb};"
            return out

        if kind == CcBuiltin.LIST_JOIN:
            if argc < 2:
                self.fail("vec.join expects two arguments")
                return "    abort();"
            let recv_ptr = self.list_recv_ptr_text(body, args_id)
            let sep_op = self.call_arg_operand(body, args_id, 1)
            // The separator is a `&str` view: the `{ptr, len}` value itself
            // (#1810; with_runtime.h `with_str sep`), never its address.
            let sep = self.operand_text(body, sep_op)
            var out = ""
            if has_ret != 0:
                out = out ++ "    " ++ self.place_text(body, dest_place) ++ " = with_vec_str_join(" ++ recv_ptr ++ ", " ++ sep ++ ");\n"
            else:
                out = out ++ "    (void)with_vec_str_join(" ++ recv_ptr ++ ", " ++ sep ++ ");\n"
            out = out ++ f"    goto bb{next_bb};"
            return out

        if cc_builtin_is_arr_len(kind):
            if argc < 1:
                self.fail("arr.len expects one argument")
                return "    abort();"
            let recv_operand = self.call_arg_operand(body, args_id, 0)
            let recv = self.operand_text(body, recv_operand)
            let recv_tid = self.sema.resolve_alias(self.operand_tid(body, recv_operand) as TypeId)
            let raw = if self.sema.get_type_kind(recv_tid) == TypeKind.TY_SLICE:
                "((" ++ recv ++ ").len)"
            else:
                "(int64_t)(sizeof(" ++ recv ++ ") / sizeof((" ++ recv ++ ")[0]))"
            var out = self.emit_len_result(body, dest_place, raw, kind, has_ret)
            out = out ++ f"    goto bb{next_bb};"
            return out

        if kind == CcBuiltin.LIST_WITH_CAPACITY:
            var out = ""
            if has_ret != 0:
                let elem_size = self.list_new_elem_size_text(body, dest_place)
                let cap_operand = if argc > 0: self.call_arg_operand(body, args_id, 0) else: -1
                let cap_text = if cap_operand >= 0: self.operand_text(body, cap_operand) else: "0"
                out = out ++ "    with_vec_new_with_capacity_out(&(" ++ self.place_text(body, dest_place) ++ "), " ++ elem_size ++ ", (int64_t)(" ++ cap_text ++ "));\n"
            else:
                out = out ++ "    (void)0;\n"
            out = out ++ f"    goto bb{next_bb};"
            return out

        ""

    // `dst = val.rotate_left(n)` (or right) at the value's own width W: the
    // count is taken modulo W, a count of 0 leaves the value, and no shift
    // is ever by W (undefined in C). The LLVM backend's llvm.fshl/fshr and
    // comptime_rotate_bits compute the same bits (#1006). The old text was
    // 32-bit only and shifted by 32 for a count of 0.
    mut fn rotate_text(val_tid: i32, dst: &str, val: &str, n: &str, left: bool) -> str:
        let resolved = self.sema.resolve_alias(val_tid as TypeId)
        if self.sema.get_type_kind(resolved) != TypeKind.TY_INT:
            self.fail("rotate on a non-integer type " ++ self.sema.type_name(val_tid))
            return "abort();"
        let width = self.sema.get_type_d0(resolved)
        let unsigned_ty = if width == 8: "uint8_t" else if width == 16: "uint16_t" else if width == 32: "uint32_t" else if width == 64: "uint64_t" else if width == 128: "unsigned __int128" else: ""
        if unsigned_ty.len() == 0:
            self.fail(f"emit-c has no rotate for {width}-bit integers")
            return "abort();"
        let first = if left: "<<" else: ">>"
        let second = if left: ">>" else: "<<"
        var out = cc_lbrace() ++ " " ++ unsigned_ty ++ " __with_v = (" ++ unsigned_ty ++ ")(" ++ val ++ "); unsigned __with_n = (unsigned)((uint64_t)(" ++ n ++ f") & {width - 1}u);"
        out = out ++ " " ++ dst ++ " = (" ++ self.c_type(val_tid, 0) ++ ")(__with_n == 0 ? __with_v : (" ++ unsigned_ty ++ ")((__with_v " ++ first ++ " __with_n) | (__with_v " ++ second ++ f" ({width}u - __with_n)))); " ++ cc_rbrace()
        out

    mut fn emit_builtin_numeric_call_term(body: &MirBody, kind: CcBuiltin, args_id: i32, dest_place: i32, next_bb: i32, argc: i32, ret_tid: i32, has_ret: i32) -> str:
        if kind == CcBuiltin.ROTATE_LEFT or kind == CcBuiltin.ROTATE_RIGHT:
            let left = kind == CcBuiltin.ROTATE_LEFT
            if argc < 2:
                self.fail(if left: "rotate_left expects two arguments" else: "rotate_right expects two arguments")
                return "    abort();"
            var out = ""
            if has_ret != 0:
                let val_operand = self.call_arg_operand(body, args_id, 0)
                let val_tid = self.operand_tid(body, val_operand)
                let dst = self.place_text(body, dest_place)
                let val = self.operand_text(body, val_operand)
                let n = self.operand_text(body, self.call_arg_operand(body, args_id, 1))
                out = out ++ "    " ++ self.rotate_text(val_tid, dst, val, n, left) ++ "\n"
            else:
                out = out ++ "    (void)0;\n"
            out = out ++ f"    goto bb{next_bb};"
            return out

        if kind == CcBuiltin.INT_SWAP_BYTES:
            if argc < 1:
                self.fail("int_swap_bytes expects one argument")
                return "    abort();"
            let val = self.operand_text(body, self.call_arg_operand(body, args_id, 0))
            var out = ""
            if has_ret != 0:
                let dst = self.place_text(body, dest_place)
                out = out ++ "    " ++ dst ++ " = (int32_t)__builtin_bswap32((uint32_t)(" ++ val ++ "));\n"
            else:
                out = out ++ "    (void)__builtin_bswap32((uint32_t)(" ++ val ++ "));\n"
            out = out ++ f"    goto bb{next_bb};"
            return out

        if kind == CcBuiltin.POPCOUNT:
            if argc < 1:
                self.fail("popcount expects one argument")
                return "    abort();"
            let pc_val = self.operand_text(body, self.call_arg_operand(body, args_id, 0))
            var out = ""
            if has_ret != 0:
                let dst = self.place_text(body, dest_place)
                out = out ++ "    " ++ dst ++ " = (int32_t)__builtin_popcount((unsigned int)(" ++ pc_val ++ "));\n"
            else:
                out = out ++ "    (void)__builtin_popcount((unsigned int)(" ++ pc_val ++ "));\n"
            out = out ++ f"    goto bb{next_bb};"
            return out

        if kind == CcBuiltin.CLZ:
            if argc < 1:
                self.fail("clz expects one argument")
                return "    abort();"
            let clz_val = self.operand_text(body, self.call_arg_operand(body, args_id, 0))
            var out = ""
            if has_ret != 0:
                let dst = self.place_text(body, dest_place)
                out = out ++ "    " ++ dst ++ " = (" ++ clz_val ++ ") == 0 ? 32 : (int32_t)__builtin_clz((unsigned int)(" ++ clz_val ++ "));\n"
            else:
                out = out ++ "    (void)0;\n"
            out = out ++ f"    goto bb{next_bb};"
            return out

        if kind == CcBuiltin.CTZ:
            if argc < 1:
                self.fail("ctz expects one argument")
                return "    abort();"
            let ctz_val = self.operand_text(body, self.call_arg_operand(body, args_id, 0))
            var out = ""
            if has_ret != 0:
                let dst = self.place_text(body, dest_place)
                out = out ++ "    " ++ dst ++ " = (" ++ ctz_val ++ ") == 0 ? 32 : (int32_t)__builtin_ctz((unsigned int)(" ++ ctz_val ++ "));\n"
            else:
                out = out ++ "    (void)0;\n"
            out = out ++ f"    goto bb{next_bb};"
            return out

        if kind == CcBuiltin.BITREVERSE:
            if argc < 1:
                self.fail("bitreverse expects one argument")
                return "    abort();"
            let brv_val = self.operand_text(body, self.call_arg_operand(body, args_id, 0))
            var out = ""
            if has_ret != 0:
                let dst = self.place_text(body, dest_place)
                out = out ++ "    " ++ dst ++ " = (int32_t)__builtin_bitreverse32((uint32_t)(" ++ brv_val ++ "));\n"
            else:
                out = out ++ "    (void)__builtin_bitreverse32((uint32_t)(" ++ brv_val ++ "));\n"
            out = out ++ f"    goto bb{next_bb};"
            return out

        if kind == CcBuiltin.MIN:
            if argc < 2:
                self.fail("min expects two arguments")
                return "    abort();"
            let mna = self.operand_text(body, self.call_arg_operand(body, args_id, 0))
            let mnb = self.operand_text(body, self.call_arg_operand(body, args_id, 1))
            var out = ""
            if has_ret != 0:
                let dst = self.place_text(body, dest_place)
                out = out ++ "    " ++ dst ++ " = (" ++ mna ++ ") < (" ++ mnb ++ ") ? (" ++ mna ++ ") : (" ++ mnb ++ ");\n"
            out = out ++ f"    goto bb{next_bb};"
            return out

        if kind == CcBuiltin.MAX:
            if argc < 2:
                self.fail("max expects two arguments")
                return "    abort();"
            let mxa = self.operand_text(body, self.call_arg_operand(body, args_id, 0))
            let mxb = self.operand_text(body, self.call_arg_operand(body, args_id, 1))
            var out = ""
            if has_ret != 0:
                let dst = self.place_text(body, dest_place)
                out = out ++ "    " ++ dst ++ " = (" ++ mxa ++ ") > (" ++ mxb ++ ") ? (" ++ mxa ++ ") : (" ++ mxb ++ ");\n"
            out = out ++ f"    goto bb{next_bb};"
            return out

        if kind == CcBuiltin.ABS:
            if argc < 1:
                self.fail("abs expects one argument")
                return "    abort();"
            let abv = self.operand_text(body, self.call_arg_operand(body, args_id, 0))
            var out = ""
            if has_ret != 0:
                let dst = self.place_text(body, dest_place)
                out = out ++ "    " ++ dst ++ " = (" ++ abv ++ ") < 0 ? -(" ++ abv ++ ") : (" ++ abv ++ ");\n"
            out = out ++ f"    goto bb{next_bb};"
            return out

        if kind == CcBuiltin.FMA:
            if argc < 3:
                self.fail("mul_add expects three arguments")
                return "    abort();"
            let fa = self.operand_text(body, self.call_arg_operand(body, args_id, 0))
            let fb = self.operand_text(body, self.call_arg_operand(body, args_id, 1))
            let fc = self.operand_text(body, self.call_arg_operand(body, args_id, 2))
            var out = ""
            if has_ret != 0:
                let dst = self.place_text(body, dest_place)
                out = out ++ "    " ++ dst ++ " = fma((" ++ fa ++ "), (" ++ fb ++ "), (" ++ fc ++ "));\n"
            out = out ++ f"    goto bb{next_bb};"
            return out

        if kind == CcBuiltin.MATH_FN:
            // math.h is always included; emit the width-correct C call
            // (`cos` for double, `cosf` for float) from the MathBuiltins row.
            let mf_id = body.call_math_fn_id(args_id)
            let mf_arity = math_fn_arity(mf_id)
            let mf_nm = math_fn_name(mf_id)
            if argc < mf_arity:
                self.fail(f"{mf_nm} expects {mf_arity} argument(s)")
                return "    abort();"
            var mf_sym = math_fn_libm(mf_id)
            if self.operand_tid(body, self.call_arg_operand(body, args_id, 0)) == self.sema.ty_f32 as i32:
                mf_sym = mf_sym ++ "f"
            var mf_call = mf_sym ++ "((" ++ self.operand_text(body, self.call_arg_operand(body, args_id, 0)) ++ ")"
            if mf_arity == 2:
                mf_call = mf_call ++ ", (" ++ self.operand_text(body, self.call_arg_operand(body, args_id, 1)) ++ ")"
            mf_call = mf_call ++ ")"
            var out = ""
            if has_ret != 0:
                out = out ++ "    " ++ self.place_text(body, dest_place) ++ " = " ++ mf_call ++ ";\n"
            else:
                out = out ++ "    (void)" ++ mf_call ++ ";\n"
            out = out ++ f"    goto bb{next_bb};"
            return out

        ""

    mut fn emit_builtin_format_call_term(body: &MirBody, kind: CcBuiltin, args_id: i32, dest_place: i32, next_bb: i32, argc: i32, ret_tid: i32, has_ret: i32) -> str:
        if kind == CcBuiltin.FMT_BUF_NEW:
            var out = ""
            if has_ret != 0:
                out = out ++ "    " ++ self.place_text(body, dest_place) ++ " = with_fmt_buf_new();\n"
            else:
                out = out ++ "    (void)with_fmt_buf_new();\n"
            out = out ++ f"    goto bb{next_bb};"
            return out

        if kind == CcBuiltin.FMT_BUF_WRITE_STR:
            if argc < 2:
                self.fail("fmt_buf_write_str expects two arguments")
                return "    abort();"
            let buf = self.operand_text(body, self.call_arg_operand(body, args_id, 0))
            let text = self.operand_text(body, self.call_arg_operand(body, args_id, 1))
            var out = "    with_fmt_buf_write_str_ref((uint8_t*)(" ++ buf ++ "), " ++ text ++ ");\n"
            out = out ++ f"    goto bb{next_bb};"
            return out

        if kind == CcBuiltin.FMT_BUF_WRITE_STR_REF:
            if argc < 2:
                self.fail("fmt_buf_write_str_ref expects two arguments")
                return "    abort();"
            let buf = self.operand_text(body, self.call_arg_operand(body, args_id, 0))
            let text = self.operand_text(body, self.call_arg_operand(body, args_id, 1))
            var out = "    with_fmt_buf_write_str_ref((uint8_t*)(" ++ buf ++ "), " ++ text ++ ");\n"
            out = out ++ f"    goto bb{next_bb};"
            return out

        // D63: `f.clone()` of a callable value. A plain function or an
        // inline-captured closure is its pair; an owning cell's clone runs
        // the cell's clone fn, which the C backend does not model, so it
        // stops there (the LLVM backend panics the same way for a cell with
        // no clone fn).
        if kind == CcBuiltin.CLOSURE_CLONE:
            if argc < 1:
                self.fail("closure_clone expects one argument")
                return "    abort();"
            let text = self.operand_text(body, self.call_arg_operand(body, args_id, 0))
            var out = "    if ((((intptr_t)(" ++ text ++ ").ctx) & 3) == 2) { abort(); } /* emit-c: an owning closure's clone is not modeled */\n"
            if has_ret != 0:
                out = out ++ "    " ++ self.place_text(body, dest_place) ++ " = " ++ text ++ ";\n"
            out = out ++ f"    goto bb{next_bb};"
            return out

        if kind == CcBuiltin.STR_CLONE_REF:
            if argc < 1:
                self.fail("str_clone_ref expects one argument")
                return "    abort();"
            let text = self.operand_text(body, self.call_arg_operand(body, args_id, 0))
            var out = ""
            if has_ret != 0:
                out = out ++ "    " ++ self.place_text(body, dest_place) ++ " = with_str_clone_ref(" ++ text ++ ");\n"
            else:
                out = out ++ "    (void)with_str_clone_ref(" ++ text ++ ");\n"
            out = out ++ f"    goto bb{next_bb};"
            return out

        if kind == CcBuiltin.FMT_BUF_WRITE_FMT:
            if argc < 6:
                self.fail("fmt_buf_write_fmt expects six arguments")
                return "    abort();"
            let buf = self.operand_text(body, self.call_arg_operand(body, args_id, 0))
            let val_operand = self.call_arg_operand(body, args_id, 1)
            let val = self.operand_text(body, val_operand)
            let flags = self.operand_text(body, self.call_arg_operand(body, args_id, 2))
            let width = self.operand_text(body, self.call_arg_operand(body, args_id, 3))
            let precision = self.operand_text(body, self.call_arg_operand(body, args_id, 4))
            let val_tid = self.operand_tid(body, val_operand)
            let resolved = self.sema.resolve_alias(val_tid as TypeId)
            let tk = self.fmt_value_kind(resolved as i32)
            var out = ""
            if tk == TypeKind.TY_FLOAT:
                out = out ++ "    with_fmt_buf_write_f64_spec((uint8_t*)(" ++ buf ++ "), (double)(" ++ val ++ "), (int64_t)(" ++ flags ++ "), (int32_t)(" ++ width ++ "), (int32_t)(" ++ precision ++ "), (int32_t)(((" ++ flags ++ ") & 255)));\n"
            else if tk == TypeKind.TY_STR:
                out = out ++ "    with_fmt_buf_write_str_spec_ref((uint8_t*)(" ++ buf ++ "), " ++ val ++ ", (int64_t)(" ++ flags ++ "), (int32_t)(" ++ width ++ "), (int32_t)(" ++ precision ++ "));\n"
            else:
                let spec_fn = if self.int_spec_is_128(resolved as i32): "with_fmt_buf_write_int128_spec" else: "with_fmt_buf_write_i64_spec"
                out = out ++ "    " ++ spec_fn ++ "((uint8_t*)(" ++ buf ++ "), " ++ self.int_spec_value_args(resolved as i32, val) ++ ", (int64_t)(" ++ self.int_spec_flags_text(resolved as i32, flags) ++ "), (int32_t)(" ++ width ++ "), (int32_t)(" ++ precision ++ "), (int32_t)(((" ++ flags ++ ") & 255)));\n"
            out = out ++ f"    goto bb{next_bb};"
            return out

        if kind == CcBuiltin.FMT_BUF_FINISH:
            if argc < 1:
                self.fail("fmt_buf_finish expects one argument")
                return "    abort();"
            let buf = self.operand_text(body, self.call_arg_operand(body, args_id, 0))
            var out = ""
            if has_ret != 0:
                out = out ++ "    " ++ self.place_text(body, dest_place) ++ " = with_fmt_buf_finish((uint8_t*)(" ++ buf ++ "));\n"
            else:
                out = out ++ "    (void)with_fmt_buf_finish((uint8_t*)(" ++ buf ++ "));\n"
            out = out ++ f"    goto bb{next_bb};"
            return out

        if kind == CcBuiltin.FMT_TO_STR:
            if argc < 1:
                self.fail("fmt.to_str expects one argument")
                return "    abort();"
            let val_operand = self.call_arg_operand(body, args_id, 0)
            let val_text = self.operand_text(body, val_operand)
            var val_tid = self.operand_tid(body, val_operand)
            if val_tid == 0 or self.is_void_tid(val_tid) != 0:
                val_tid = self.sema.ty_i64 as i32
            let resolved = self.sema.resolve_alias(val_tid as TypeId)
            let tk = self.fmt_value_kind(resolved as i32)
            // A payload enum — a declared one or a generic instance such as
            // Option[&str] — formats its variant and payload, as
            // display_format_expr does for an enum payload.
            if (tk == TypeKind.TY_ENUM or tk == TypeKind.TY_GENERIC_INST) and self.type_is_payload_enum(resolved as i32) != 0:
                let fmt_expr = self.payload_enum_format_expr(resolved as i32, val_text, "fmt.to_str")
                var out_enum = ""
                if has_ret != 0:
                    out_enum = out_enum ++ "    " ++ self.place_text(body, dest_place) ++ " = " ++ fmt_expr ++ ";\n"
                else:
                    out_enum = out_enum ++ "    (void)(" ++ fmt_expr ++ ");\n"
                out_enum = out_enum ++ f"    goto bb{next_bb};"
                return out_enum
            var fmt_call = ""
            if tk == TypeKind.TY_INT:
                fmt_call = self.debug_int_format_expr(resolved as i32, val_text)
            else:
                let fmt_fn = if tk == TypeKind.TY_STR: "with_fmt_str_ref"
                    else if tk == TypeKind.TY_BOOL: "with_fmt_bool"
                    else if tk == TypeKind.TY_FLOAT: "with_fmt_f64"
                    else: "with_fmt_i64"
                let cast_prefix = if tk == TypeKind.TY_FLOAT: "(double)("
                    else if tk == TypeKind.TY_BOOL: "(int32_t)("
                    else if tk == TypeKind.TY_STR: "("
                    else: "(int64_t)("
                fmt_call = fmt_fn ++ "(" ++ cast_prefix ++ val_text ++ "))"
            var out = ""
            if has_ret != 0:
                out = out ++ "    " ++ self.place_text(body, dest_place) ++ " = " ++ fmt_call ++ ";\n"
            else:
                out = out ++ "    (void)" ++ fmt_call ++ ";\n"
            out = out ++ f"    goto bb{next_bb};"
            return out

        if kind == CcBuiltin.FMT_DEBUG_STR:
            if argc < 1:
                self.fail("fmt.debug_str expects one argument")
                return "    abort();"
            let val_text = self.operand_text(body, self.call_arg_operand(body, args_id, 0))
            var out = ""
            if has_ret != 0:
                out = out ++ "    " ++ self.place_text(body, dest_place) ++ " = with_fmt_str_debug_ref(" ++ val_text ++ ");\n"
            else:
                out = out ++ "    (void)with_fmt_str_debug_ref(" ++ val_text ++ ");\n"
            out = out ++ f"    goto bb{next_bb};"
            return out

        if kind == CcBuiltin.FMT_DEBUG:
            if argc < 1:
                self.fail("fmt.debug expects one argument")
                return "    abort();"
            let val_operand = self.call_arg_operand(body, args_id, 0)
            let val_text = self.operand_text(body, val_operand)
            var val_tid = self.operand_tid(body, val_operand)
            if val_tid == 0 or self.is_void_tid(val_tid) != 0:
                val_tid = self.sema.ty_i64 as i32
            // D61: MirLower sends only the inline rows (numbers, bool, str,
            // raw pointers) here; debug_format_expr formats them exactly as
            // the LLVM backend does.
            let fmt_expr = self.debug_format_expr(val_tid, val_text, "fmt.debug")
            var out = ""
            if has_ret != 0:
                out = out ++ "    " ++ self.place_text(body, dest_place) ++ " = " ++ fmt_expr ++ ";\n"
            else:
                out = out ++ "    (void)(" ++ fmt_expr ++ ");\n"
            out = out ++ f"    goto bb{next_bb};"
            return out

        if kind == CcBuiltin.FMT_SPEC:
            // args: value, flags(i64), width(i32), precision(i32), sema_type_id
            if argc < 5:
                self.fail("fmt.spec expects five arguments")
                return "    abort();"
            let val_operand = self.call_arg_operand(body, args_id, 0)
            let val_text = self.operand_text(body, val_operand)
            let flags_text = self.operand_text(body, self.call_arg_operand(body, args_id, 1))
            let width_text = self.operand_text(body, self.call_arg_operand(body, args_id, 2))
            let prec_text = self.operand_text(body, self.call_arg_operand(body, args_id, 3))
            var val_tid = self.operand_tid(body, val_operand)
            if val_tid == 0 or self.is_void_tid(val_tid) != 0:
                val_tid = self.sema.ty_i64 as i32
            let resolved = self.sema.resolve_alias(val_tid as TypeId)
            let tk = self.fmt_value_kind(resolved as i32)
            var out = ""
            if has_ret != 0:
                let dst = self.place_text(body, dest_place)
                let mode_text = "(((" ++ flags_text ++ ") & 255))"
                if tk == TypeKind.TY_FLOAT:
                    out = out ++ "    " ++ dst ++ " = with_fmt_f64_spec((double)(" ++ val_text ++ "), (int64_t)(" ++ flags_text ++ "), (int32_t)(" ++ width_text ++ "), (int32_t)(" ++ prec_text ++ "), (int32_t)(" ++ mode_text ++ "));\n"
                else if tk == TypeKind.TY_STR:
                    out = out ++ "    " ++ dst ++ " = with_fmt_str_spec_ref(" ++ val_text ++ ", (int64_t)(" ++ flags_text ++ "), (int32_t)(" ++ width_text ++ "), (int32_t)(" ++ prec_text ++ "));\n"
                else:
                    let spec_fn = if self.int_spec_is_128(resolved as i32): "with_fmt_int128_spec" else: "with_fmt_int_spec"
                    out = out ++ "    " ++ dst ++ " = " ++ spec_fn ++ "(" ++ self.int_spec_value_args(resolved as i32, val_text) ++ ", (int64_t)(" ++ self.int_spec_flags_text(resolved as i32, flags_text) ++ "), (int32_t)(" ++ width_text ++ "), (int32_t)(" ++ prec_text ++ "), (int32_t)(" ++ mode_text ++ "));\n"
            else:
                out = out ++ "    (void)0;\n"
            out = out ++ f"    goto bb{next_bb};"
            return out

        ""

    mut fn emit_builtin_dyn_unsupported_call_term(body: &MirBody, kind: CcBuiltin, args_id: i32, dest_place: i32, next_bb: i32, argc: i32, ret_tid: i32, has_ret: i32) -> str:
        if kind == CcBuiltin.DYN_VTABLE_CMP:
            // Dynamic trait vtable comparison
            if argc < 2:
                self.fail("dyn_vtable_cmp expects two arguments")
                return "    abort();"
            let obj_text = self.operand_text(body, self.call_arg_operand(body, args_id, 0))
            let vtable_text = self.operand_text(body, self.call_arg_operand(body, args_id, 1))
            var out = ""
            if has_ret != 0:
                out = out ++ "    " ++ self.place_text(body, dest_place) ++ " = ((" ++ obj_text ++ ").vtable == (void*)(" ++ vtable_text ++ "));\n"
            else:
                out = out ++ "    (void)0;\n"
            out = out ++ f"    goto bb{next_bb};"
            return out

        if kind == CcBuiltin.DYN_DOWNCAST:
            self.fail("emit-c does not support dynamic trait downcast")
            return "\n"

        if kind == CcBuiltin.OPT_FILTER:
            self.fail("emit-c does not support opt.filter (requires closure support)")
            return "\n"

        ""

    // The spelling of a `sizeof[T]` type argument, for diagnostics.
    fn type_arg_text(type_node: i32) -> str:
        let kind = self.ast.kind(type_node)
        if kind == NodeKind.NK_IDENT or kind == NodeKind.NK_TYPE_NAMED:
            return cc_intern_resolve(self.intern, self.ast.get_data0(type_node))
        // `sizeof[PullCore[G]]` parses as an index expression, which the
        // type renderer does not spell.
        if kind == NodeKind.NK_INDEX:
            var text = self.type_arg_text(self.ast.get_data0(type_node)) ++ "[" ++ self.type_arg_text(self.ast.get_data1(type_node))
            if self.ast.get_data2(type_node) != 0:
                text = text ++ ", " ++ self.type_arg_text(self.ast.get_data2(type_node))
            return text ++ "]"
        render_type_expr(self.ast, self.intern, type_node as NodeId)

    // The named function whose module and substitution a body runs under:
    // itself, or for a closure body the function it sits in, through any
    // enclosing closures (#1766).
    fn body_owner_sym(fn_sym: i32) -> i32:
        var owner = fn_sym
        while self.closure_index_by_sym.contains(owner):
            owner = self.closure_parents[self.closure_index_by_sym.get(owner).unwrap()]
        owner

    fn generic_call_type_arg_node(body: &MirBody, args_id: i32) -> i32:
        let call_node = body.call_ast_node(args_id)
        if call_node <= 0 or call_node >= self.ast.node_count() or self.ast.kind(call_node) != NodeKind.NK_CALL:
            return 0
        let callee = self.ast.get_data0(call_node)
        let callee_kind = self.ast.kind(callee)
        if callee_kind == NodeKind.NK_TYPE_GENERIC:
            let start = self.ast.get_data1(callee)
            let count = self.ast.get_data2(callee)
            if count != 1:
                return 0
            return self.ast.get_extra(start)
        if callee_kind == NodeKind.NK_INDEX:
            return self.ast.get_data1(callee)
        0

    mut fn emit_builtin_generic_call_term(body: &MirBody, callee_operand: i32, args_id: i32, dest_place: i32, next_bb: i32) -> str:
        let callee_sym = self.call_callee_fn_sym(body, callee_operand)
        let name = cc_base_name(cc_intern_resolve(self.intern, callee_sym))
        if name == "transmute":
            if self.call_arg_count(body, args_id) != 1:
                self.fail("transmute expects one argument")
                return "\n"
            let src = self.operand_text(body, self.call_arg_operand(body, args_id, 0))
            let dst = self.place_text(body, dest_place)
            var out = "    " ++ cc_lbrace() ++ " __typeof__(" ++ src ++ ") __with_transmute_src = " ++ src ++ "; "
            out = out ++ "_Static_assert(sizeof(" ++ dst ++ ") == sizeof(__with_transmute_src), \"transmute size mismatch\"); "
            out = out ++ "memcpy(&(" ++ dst ++ "), &__with_transmute_src, sizeof(" ++ dst ++ ")); " ++ cc_rbrace() ++ "\n"
            out = out ++ f"    goto bb{next_bb};"
            return out

        if name == "sizeof" or name == "size_of" or name == "alignof" or name == "align_of":
            let type_node = self.generic_call_type_arg_node(body, args_id)
            if type_node == 0:
                self.fail("emit-c could not recover the type argument for " ++ name)
                return "\n"
            let target_tid = self.sema.type_level_arg_in_body(self.body_owner_sym(body.fn_sym), type_node)
            if target_tid == 0:
                self.fail("emit-c could not resolve the type argument '" ++ self.type_arg_text(type_node) ++ "' of " ++ name ++ " in '" ++ cc_intern_resolve(self.intern, body.fn_sym) ++ "' (resolved from module '" ++ self.sema.current_module_path ++ "')")
                return "\n"
            let type_text = self.c_decl(target_tid, "")
            let op = if name == "sizeof" or name == "size_of": "sizeof" else: "_Alignof"
            let dst = self.place_text(body, dest_place)
            let dst_tid = self.place_tid(body, dest_place)
            let dst_ty = self.c_type(dst_tid, 0)
            var out = "    " ++ dst ++ " = (" ++ dst_ty ++ ")" ++ op ++ "(" ++ type_text ++ ");\n"
            out = out ++ f"    goto bb{next_bb};"
            return out

        // D109: TypeLayout's offset, which every emitted struct is
        // static-asserted to match (layout_static_asserts).
        if name == "offsetof" or name == "offset_of":
            let call_node = body.call_ast_node(args_id)
            let type_node = self.generic_call_type_arg_node(body, args_id)
            let target_tid = self.sema.offsetof_owner_in_body(self.body_owner_sym(body.fn_sym), call_node, type_node)
            let field_index = self.sema.offsetof_field_indices.get(call_node) ?? -1
            let offset = self.sema.layout_field_offset_cache.get(sema_pair_key(self.sema.resolve_alias(target_tid as TypeId) as i32, field_index))
            if target_tid <= 0 or field_index < 0 or offset.is_none():
                self.fail("emit-c has no TypeLayout offset for offsetof in '" ++ cc_intern_resolve(self.intern, body.fn_sym) ++ "'")
                return "\n"
            let dst = self.place_text(body, dest_place)
            let dst_tid = self.place_tid(body, dest_place)
            let dst_ty = self.c_type(dst_tid, 0)
            var out = "    " ++ dst ++ " = (" ++ dst_ty ++ ")" ++ f"{offset.unwrap()}" ++ ";\n"
            out = out ++ f"    goto bb{next_bb};"
            return out

        let intrinsic = body.call_intrinsic(args_id)
        if intrinsic == MirIntrinsic.COLLECTION_LITERAL or intrinsic == MirIntrinsic.MAP_LITERAL:
            return self.emit_collection_literal_term(body, intrinsic, args_id, dest_place, next_bb)

        // `Atomic.new(v)`: the cell `{ val }` emit_struct_type_defs declares
        // (#985 made std.random's state one, in a global's initializer).
        let new_tid = if name == "new" and dest_place >= 0: self.place_sema_tid(body, dest_place) else: 0
        if new_tid != 0 and self.generic_inst_base_name(new_tid) == "Atomic" and self.call_arg_count(body, args_id) == 1:
            let value = self.operand_text(body, self.call_arg_operand(body, args_id, 0))
            let dst = self.place_text(body, dest_place)
            let cell_c = self.c_type(new_tid, 0)
            return "    " ++ dst ++ " = (" ++ cell_c ++ ")" ++ cc_lbrace() ++ " .val = " ++ value ++ " " ++ cc_rbrace() ++ ";\n" ++ f"    goto bb{next_bb};"

        self.fail("emit-c does not support generic intrinsic " ++ if name.len() > 0: name else: "<unknown>")
        "\n"

    // `[a, b]` into a List or HashSet and `[k: v]` into a HashMap (MirLower's
    // COLLECTION_LITERAL / MAP_LITERAL): the collection built empty and each
    // element pushed or inserted in order, as the LLVM backend's
    // mir_emit_collection_literal_intrinsic_call and this backend's own
    // VEC_PUSH / MAP_NEW / MAP_INSERT do (#2017).
    mut fn emit_collection_literal_term(body: &MirBody, intrinsic: MirIntrinsic, args_id: i32, dest_place: i32, next_bb: i32) -> str:
        let dst_tid = self.place_tid(body, dest_place)
        let resolved = self.sema.resolve_alias(dst_tid as TypeId) as i32
        let base = self.generic_inst_base_name(resolved)
        let argc = self.call_arg_count(body, args_id)
        let dst = self.place_text(body, dest_place)
        var out = "    " ++ cc_lbrace()
        if intrinsic == MirIntrinsic.COLLECTION_LITERAL and base == "List":
            let elem_tid = self.sema.get_generic_inst_arg(resolved, 0)
            let elem_ty = self.c_type(elem_tid, 0)
            out = out ++ " " ++ self.c_type(dst_tid, 0) ++ " __with_lit; with_vec_new_out((uint8_t*)&__with_lit, sizeof(" ++ elem_ty ++ "));"
            for i in 0..argc:
                let elem_text = self.collection_literal_elem_text(body, args_id, i, elem_tid)
                out = out ++ " " ++ cc_lbrace() ++ " " ++ elem_ty ++ " __with_e = " ++ elem_text ++ "; with_vec_push_es(&__with_lit, &__with_e, sizeof(" ++ elem_ty ++ ")); " ++ cc_rbrace()
            out = out ++ " " ++ dst ++ " = __with_lit; " ++ cc_rbrace() ++ "\n"
            return out ++ f"    goto bb{next_bb};"
        let is_set = intrinsic == MirIntrinsic.COLLECTION_LITERAL and base == "HashSet"
        if not is_set and not (intrinsic == MirIntrinsic.MAP_LITERAL and base == "HashMap"):
            self.fail("emit-c has no collection literal for " ++ self.sema.type_name(dst_tid))
            return "\n"
        let key_tid = self.hashmap_key_tid(resolved)
        // A set's value is a present marker sized as MAP_NEW sizes it.
        let val_tid = if is_set: self.sema.ty_i64 as i32 else: self.hashmap_value_tid(resolved)
        let key_ty = self.c_type(key_tid, 0)
        let val_ty = self.c_type(val_tid, 0)
        let is_str_key = if self.sema.get_type_kind(self.sema.resolve_alias(key_tid as TypeId)) == TypeKind.TY_STR: "1" else: "0"
        out = out ++ " void* __with_h = with_hashmap_new_keyed(sizeof(" ++ key_ty ++ "), sizeof(" ++ val_ty ++ "), " ++ self.map_key_args_text(key_tid) ++ ");"
        let entry_count = if is_set: argc else: argc / 2
        for i in 0..entry_count:
            let key_idx = if is_set: i else: i * 2
            let key_text = self.collection_literal_elem_text(body, args_id, key_idx, key_tid)
            let val_text = if is_set: "1" else: self.collection_literal_elem_text(body, args_id, key_idx + 1, val_tid)
            let insert = self.owned_map_insert_text("__with_h", is_str_key, key_tid, if is_set: 0 else: val_tid)
            out = out ++ " " ++ cc_lbrace() ++ " " ++ key_ty ++ " __with_k = " ++ key_text ++ "; " ++ val_ty ++ " __with_v = " ++ val_text ++ ";" ++ insert ++ " " ++ cc_rbrace()
        out = out ++ " " ++ dst ++ " = (int64_t)(intptr_t)__with_h; " ++ cc_rbrace() ++ "\n"
        out ++ f"    goto bb{next_bb};"

    mut fn collection_literal_elem_text(body: &MirBody, args_id: i32, index: i32, elem_tid: i32) -> str:
        let operand = self.call_arg_operand(body, args_id, index)
        if self.fn_tid_is_fat(elem_tid) != 0:
            let fn_sym = self.operand_ck_fn_sym(body, operand)
            if fn_sym != 0:
                return self.fat_fn_literal(fn_sym, self.sema.resolve_alias(elem_tid as TypeId) as i32)
        self.operand_text(body, operand)

    mut fn emit_builtin_numeric_format_call_term(body: &MirBody, kind: CcBuiltin, args_id: i32, dest_place: i32, next_bb: i32, argc: i32, ret_tid: i32, has_ret: i32) -> str:
        var out = self.emit_builtin_numeric_call_term(body, kind, args_id, dest_place, next_bb, argc, ret_tid, has_ret)
        if out.len() > 0:
            return out
        out = self.emit_builtin_format_call_term(body, kind, args_id, dest_place, next_bb, argc, ret_tid, has_ret)
        if out.len() > 0:
            return out
        out = self.emit_builtin_dyn_unsupported_call_term(body, kind, args_id, dest_place, next_bb, argc, ret_tid, has_ret)
        if out.len() > 0:
            return out
        ""

    // D75 (§16.2b.5): <stdarg.h> is C's own lowering of a variadic
    // definition. The list is the binding's storage — va_start's
    // destination, va_arg's and va_end's receiver — and va_start names the
    // last named parameter, `_N` in emit_fn_decl's prototype.
    mut fn emit_c_variadic_call_term(body: &MirBody, kind: CcBuiltin, args_id: i32, dest_place: i32, next_bb: i32) -> str:
        if kind == CcBuiltin.VA_START:
            let sig_idx = self.body_sig_index(body.fn_sym)
            let named = if sig_idx >= 0: self.sema.sig_get_param_count(sig_idx) else: 0
            if named == 0:
                self.fail("emit-c: va_start() in a variadic definition with no named parameter, which C before C23 cannot express")
                return "    abort();"
            return "    va_start(" ++ self.place_text(body, dest_place) ++ f", _{named});\n    goto bb{next_bb};"
        let list = self.operand_text(body, self.call_arg_operand(body, args_id, 0))
        if kind == CcBuiltin.VA_END:
            return "    va_end(" ++ list ++ f");\n    goto bb{next_bb};"
        let arg_tid = self.place_local_tid(body, dest_place)
        "    " ++ self.place_text(body, dest_place) ++ " = va_arg(" ++ list ++ ", " ++ self.c_type(arg_tid, 0) ++ f");\n    goto bb{next_bb};"

    mut fn emit_builtin_call_term(body: &MirBody, bb: i32, callee_operand: i32, args_id: i32, dest_place: i32, next_bb: i32) -> str:
        if body.call_requires_contract(args_id):
            return ""
        // Read intrinsic marker from MIR instead of name-heuristic inference.
        let mir_intrinsic = body.call_intrinsic(args_id)
        var kind = cc_builtin_from_mir_intrinsic(mir_intrinsic)
        // Fall back to legacy heuristic for MIR produced without markers.
        if kind == CcBuiltin.NONE:
            kind = self.call_builtin_kind(body, callee_operand, args_id, dest_place)
        if kind == CcBuiltin.NONE:
            return ""
        let _ = bb
        let argc = self.call_arg_count(body, args_id)
        let ret_tid = self.call_builtin_ret_tid(body, callee_operand, args_id, dest_place)
        let has_ret: i32 = if self.is_void_tid(ret_tid) == 0: 1 else: 0
        if kind == CcBuiltin.VA_START or kind == CcBuiltin.VA_ARG or kind == CcBuiltin.VA_END:
            return self.emit_c_variadic_call_term(body, kind, args_id, dest_place, next_bb)

        // LLVM-only-by-design intrinsic families (#301). The C backend exists only to
        // self-bootstrap the compiler (see with-bootstrap-runbook.md, "Scope of the C
        // backend"); the compiler uses none of these internally, and user programs are
        // always compiled through LLVM. These loud failures are intentional and
        // permanent — reaching parity is NOT a goal. If the compiler ever starts using
        // one of these, `make emit-c-fixpoint` fails loudly and points here. Keep the
        // loud fail; never add a silent fallback to make --emit-c pass.
        var out = self.emit_builtin_list_core_call_term(body, kind, args_id, dest_place, next_bb, argc, ret_tid, has_ret)
        if out.len() > 0:
            return out
        out = self.emit_builtin_map_call_term(body, kind, args_id, dest_place, next_bb, argc, ret_tid, has_ret)
        if out.len() > 0:
            return out
        out = self.emit_builtin_option_string_call_term(body, kind, args_id, dest_place, next_bb, argc, ret_tid, has_ret)
        if out.len() > 0:
            return out
        if kind == CcBuiltin.GENERIC_CALL:
            return self.emit_builtin_generic_call_term(body, callee_operand, args_id, dest_place, next_bb)
        out = self.emit_builtin_list_extra_call_term(body, kind, args_id, dest_place, next_bb, argc, ret_tid, has_ret)
        if out.len() > 0:
            return out
        out = self.emit_builtin_numeric_format_call_term(body, kind, args_id, dest_place, next_bb, argc, ret_tid, has_ret)
        if out.len() > 0:
            return out
        ""

    fn field_place_matches(body: &MirBody, place_id: i32, struct_tid: i32, field_sym: i32) -> i32:
        if place_id < 0 or place_id >= body.place_locals.len():
            return 0
        let count = body.place_proj_counts[place_id]
        if count != 1:
            return 0
        let start = body.place_proj_starts[place_id]
        if body.proj_kinds[start] != ProjKind.PK_FIELD:
            return 0
        if body.proj_d0[start] != field_sym:
            return 0
        let lid = body.place_locals[place_id]
        if lid < 0 or lid >= body.local_type_ids.len():
            return 0
        let base_tid = self.local_declared_tid(body, lid)
        if self.is_void_tid(base_tid) != 0:
            return 0
        let base_resolved = self.sema.resolve_alias(base_tid)
        let want_resolved = self.sema.resolve_alias(struct_tid)
        if self.sema.get_type_kind(base_resolved) != TypeKind.TY_STRUCT:
            return 0
        if self.sema.get_type_kind(want_resolved) != TypeKind.TY_STRUCT:
            return 0
        let base_name = self.sema.get_type_d0(base_resolved)
        let want_name = self.sema.get_type_d0(want_resolved)
        if base_name == want_name:
            return 1
        if base_name != 0 and want_name != 0 and cc_intern_resolve(self.intern, base_name) == cc_intern_resolve(self.intern, want_name):
            return 1
        0

    mut fn rvalue_infer_tid(body: &MirBody, rval_id: i32) -> i32:
        if rval_id < 0 or rval_id >= body.rval_kinds.len():
            return 0
        let no_infer = if self.in_field_cache_build != 0: 1 else: 0
        let rk = body.rval_kinds[rval_id]
        let d0 = body.rval_d0[rval_id]
        let d1 = body.rval_d1[rval_id]
        let d2 = body.rval_d2[rval_id]
        if rk == RvalueKind.RK_USE:
            if no_infer != 0:
                return self.operand_tid_no_infer(body, d0)
            return self.operand_tid(body, d0)
        if rk == RvalueKind.RK_ARRAY_FILL:
            if no_infer != 0:
                return self.operand_tid_no_infer(body, d0)
            return self.operand_tid(body, d0)
        if rk == RvalueKind.RK_BIN_OP:
            if d0 == BinaryOp.OP_EQ or d0 == BinaryOp.OP_NEQ or d0 == BinaryOp.OP_LT or d0 == BinaryOp.OP_GT or d0 == BinaryOp.OP_LTE or d0 == BinaryOp.OP_GTE or d0 == BinaryOp.OP_AND or d0 == BinaryOp.OP_OR:
                return self.sema.ty_bool as i32
            if d0 == BinaryOp.OP_CONCAT:
                return self.sema.ty_str as i32
            let lt = if no_infer != 0: self.operand_tid_no_infer(body, d1) else: self.operand_tid(body, d1)
            if lt != 0 and self.is_void_tid(lt) == 0:
                return lt
            if no_infer != 0:
                return self.operand_tid_no_infer(body, d2)
            return self.operand_tid(body, d2)
        if rk == RvalueKind.RK_STR_CONCAT_N:
            return self.sema.ty_str as i32
        if rk == RvalueKind.RK_UN_OP:
            if d0 == UnaryOp.UOP_NOT:
                return self.sema.ty_bool as i32
            if no_infer != 0:
                return self.operand_tid_no_infer(body, d1)
            return self.operand_tid(body, d1)
        if rk == RvalueKind.RK_CAST:
            return d1
        if rk == RvalueKind.RK_AGGREGATE:
            if d1 < 0 or d1 >= body.agg_field_starts.len():
                return 0
            let start = body.agg_field_starts[d1]
            let count = body.agg_field_counts[d1]
            if count <= 0:
                return 0
            let first = body.agg_field_operands[start]
            if no_infer != 0:
                return self.operand_tid_no_infer(body, first)
            return self.operand_tid(body, first)
        if rk == RvalueKind.RK_LEN:
            return self.sema.ty_i64 as i32
        if rk == RvalueKind.RK_DISCRIMINANT:
            return self.sema.ty_i32 as i32
        0

    mut fn record_field_tid_from_place(body: &MirBody, place_id: i32, tid: i32):
        if place_id < 0 or place_id >= body.place_locals.len():
            return
        if tid == 0:
            return
        let count = body.place_proj_counts[place_id]
        if count != 1:
            return
        let start = body.place_proj_starts[place_id]
        if body.proj_kinds[start] != ProjKind.PK_FIELD:
            return
        let field_sym = body.proj_d0[start]
        let lid = body.place_locals[place_id]
        if lid < 0 or lid >= body.local_type_ids.len():
            return
        var base_tid = self.local_effective_tid(body, lid)
        if self.is_void_tid(base_tid) != 0:
            base_tid = self.local_declared_tid(body, lid)
        let base_resolved = self.sema.resolve_alias(base_tid)
        if self.sema.get_type_kind(base_resolved) != TypeKind.TY_STRUCT:
            return
        self.field_cache_record(base_resolved, field_sym, tid)

    fn place_is_single_field(body: &MirBody, place_id: i32) -> i32:
        let _ = self
        if place_id < 0 or place_id >= body.place_locals.len():
            return 0
        if body.place_proj_counts[place_id] != 1:
            return 0
        let start = body.place_proj_starts[place_id]
        if body.proj_kinds[start] != ProjKind.PK_FIELD:
            return 0
        1

    mut fn build_field_cache_from_usage():
        if self.field_cache_ready != 0:
            return
        self.field_cache_ready = 1
        self.in_field_cache_build = 1

        for bi in 0..self.mir_mod.bodies.len():
            if self.check_interrupted() != 0:
                self.in_field_cache_build = 0
                return
            let body = self.mir_body_at(bi as i64)
            for bb in 0..body.block_count():
                if self.check_interrupted() != 0:
                    self.in_field_cache_build = 0
                    return
                if body.term_kind(bb) != TermKind.TK_CALL:
                    continue
                let callee_operand = body.term_data0(bb)
                let args_id = body.term_data1(bb)
                let dest_place = body.term_data2(bb)
                let recv_place = self.call_first_arg_place_id(body, args_id)
                let recv_is_field = if recv_place >= 0: self.place_is_single_field(body, recv_place) else: 0
                let dest_is_field = self.place_is_single_field(body, dest_place)
                if recv_is_field == 0 and dest_is_field == 0:
                    continue

                let callee_sym = self.call_callee_fn_sym(body, callee_operand)
                let hint = self.callee_field_hint(callee_sym)
                if hint == CcCalleeHint.NONE:
                    continue

                if recv_is_field != 0:
                    if hint == CcCalleeHint.LIST_RECV:
                        self.record_field_tid_from_place(body, recv_place, CC_PSEUDO_TID_LIST)
                        continue
                    if hint == CcCalleeHint.MAP_RECV:
                        self.record_field_tid_from_place(body, recv_place, self.sema.ty_i64)
                        continue
                    if hint == CcCalleeHint.OPT_RECV:
                        self.record_field_tid_from_place(body, recv_place, self.sema.ty_i64)
                        continue

                if dest_is_field != 0:
                    if hint == CcCalleeHint.MAP_NEW:
                        self.record_field_tid_from_place(body, dest_place, self.sema.ty_i64)
                        continue
                    if hint == CcCalleeHint.LIST_NEW:
                        self.record_field_tid_from_place(body, dest_place, CC_PSEUDO_TID_LIST)
                        continue
                    if hint == CcCalleeHint.OPT_NEW:
                        self.record_field_tid_from_place(body, dest_place, self.sema.ty_i64)
                        continue
        self.in_field_cache_build = 0

    mut fn infer_struct_field_tid_from_usage(struct_tid: i32, field_sym: i32) -> i32:
        let resolved_struct = self.sema.resolve_alias(struct_tid)
        if resolved_struct == 0:
            return 0
        if self.sema.get_type_kind(resolved_struct) != TypeKind.TY_STRUCT:
            return 0
        let cached = self.field_cache_lookup(resolved_struct, field_sym)
        if cached != -1234567:
            return cached

        self.build_field_cache_from_usage()
        let hinted = self.field_cache_lookup(resolved_struct, field_sym)
        if hinted != -1234567:
            return hinted

        var inferred: i32 = 0
        for bi in 0..self.mir_mod.bodies.len():
            if self.check_interrupted() != 0:
                return 0
            let body = self.mir_body_at(bi as i64)

            for bb in 0..body.block_count():
                if self.check_interrupted() != 0:
                    return 0

                if body.term_kind(bb) == TermKind.TK_CALL:
                    let callee_operand = body.term_data0(bb)
                    let args_id = body.term_data1(bb)
                    let dest_place = body.term_data2(bb)

                    var sig_idx: i32 = -1
                    if callee_operand >= 0 and callee_operand < body.operand_kinds.len():
                        if body.operand_kinds[callee_operand] == OperandKind.OK_CONSTANT:
                            let const_id = body.operand_d0[callee_operand]
                            if const_id >= 0 and const_id < body.const_kinds.len():
                                if body.const_kinds[const_id] == ConstKind.CK_FN:
                                    let fn_sym = body.const_d0[const_id]
                                    if fn_sym != 0:
                                        sig_idx = self.sig_index_for_sym(fn_sym)

                    if sig_idx >= 0:
                        let argc = self.call_arg_count(body, args_id)
                        let param_count = self.sema.sig_get_param_count(sig_idx)
                        for ai in 0..argc:
                            if ai >= param_count:
                                break
                            let arg_operand = self.call_arg_operand(body, args_id, ai)
                            if arg_operand < 0 or arg_operand >= body.operand_kinds.len():
                                continue
                            let ok = body.operand_kinds[arg_operand]
                            if ok != OperandKind.OK_COPY and ok != OperandKind.OK_MOVE:
                                continue
                            let arg_place = body.operand_d0[arg_operand]
                            if self.field_place_matches(body, arg_place, resolved_struct, field_sym) == 0:
                                continue
                            let p_tid = self.sema.sig_param_type(sig_idx, ai)
                            inferred = self.prefer_inferred_tid(inferred, p_tid)

                        if self.field_place_matches(body, dest_place, resolved_struct, field_sym) != 0:
                            let ret_tid = self.c_sig_return_type(sig_idx)
                            inferred = self.prefer_inferred_tid(inferred, ret_tid)

                let start = body.bb_stmt_starts[bb]
                let count = body.bb_stmt_counts[bb]
                for si in 0..count:
                    let stmt_id = start + si
                    if body.stmt_kinds[stmt_id] != StmtKind.Assign:
                        continue
                    let dst_place = body.stmt_d0[stmt_id]
                    let rval_id = body.stmt_d1[stmt_id]

                    if self.field_place_matches(body, dst_place, resolved_struct, field_sym) != 0:
                        var rv_tid: i32 = 0
                        if rval_id >= 0 and rval_id < body.rval_kinds.len():
                            let rk = body.rval_kinds[rval_id]
                            let rd0 = body.rval_d0[rval_id]
                            let rd1 = body.rval_d1[rval_id]
                            if rk == RvalueKind.RK_USE:
                                if rd0 >= 0 and rd0 < body.operand_kinds.len():
                                    let ok = body.operand_kinds[rd0]
                                    let od = body.operand_d0[rd0]
                                    if ok == OperandKind.OK_COPY or ok == OperandKind.OK_MOVE:
                                        let src_local = self.place_local_id(body, od)
                                        if src_local >= 0 and self.place_is_direct_local(body, od, src_local) != 0:
                                            rv_tid = self.local_declared_tid(body, src_local)
                                    else if ok == OperandKind.OK_CONSTANT:
                                        if od >= 0 and od < body.const_types.len():
                                            rv_tid = body.const_types[od]
                            else if rk == RvalueKind.RK_BIN_OP:
                                if rd0 == BinaryOp.OP_EQ or rd0 == BinaryOp.OP_NEQ or rd0 == BinaryOp.OP_LT or rd0 == BinaryOp.OP_GT or rd0 == BinaryOp.OP_LTE or rd0 == BinaryOp.OP_GTE or rd0 == BinaryOp.OP_AND or rd0 == BinaryOp.OP_OR:
                                    rv_tid = self.sema.ty_bool as i32
                                else if rd0 == BinaryOp.OP_CONCAT:
                                    rv_tid = self.sema.ty_str as i32
                            else if rk == RvalueKind.RK_STR_CONCAT_N:
                                rv_tid = self.sema.ty_str as i32
                            else if rk == RvalueKind.RK_UN_OP:
                                if rd0 == UnaryOp.UOP_NOT:
                                    rv_tid = self.sema.ty_bool as i32
                            else if rk == RvalueKind.RK_CAST:
                                rv_tid = rd1
                            else if rk == RvalueKind.RK_LEN:
                                rv_tid = self.sema.ty_i64 as i32
                            else if rk == RvalueKind.RK_DISCRIMINANT:
                                rv_tid = self.sema.ty_i32 as i32
                        inferred = self.prefer_inferred_tid(inferred, rv_tid)

                    if rval_id < 0 or rval_id >= body.rval_kinds.len():
                        continue
                    if body.rval_kinds[rval_id] != RvalueKind.RK_USE:
                        continue
                    let src_operand = body.rval_d0[rval_id]
                    if src_operand < 0 or src_operand >= body.operand_kinds.len():
                        continue
                    let src_ok = body.operand_kinds[src_operand]
                    if src_ok != OperandKind.OK_COPY and src_ok != OperandKind.OK_MOVE:
                        continue
                    let src_place = body.operand_d0[src_operand]
                    if self.field_place_matches(body, src_place, resolved_struct, field_sym) == 0:
                        continue
                    let dst_local = self.place_local_id(body, dst_place)
                    if dst_local < 0:
                        continue
                    if self.place_is_direct_local(body, dst_place, dst_local) == 0:
                        continue
                    let dst_tid = self.local_declared_tid(body, dst_local)
                    inferred = self.prefer_inferred_tid(inferred, dst_tid)

        self.field_cache_store(resolved_struct, field_sym, inferred)
        inferred

    mut fn effective_field_tid(struct_tid: i32, field_sym: i32, raw_field_tid: i32) -> i32:
        let resolved = self.sema.resolve_alias(raw_field_tid as TypeId) as i32
        if resolved != 0 and self.is_void_tid(resolved) == 0 and self.sema.get_type_kind(resolved as TypeId) != TypeKind.TY_ERR:
            return resolved
        if self.in_field_cache_build != 0:
            if resolved != 0:
                return resolved
            return raw_field_tid
        let owner_tid = self.sema.resolve_alias(struct_tid as TypeId) as i32
        if owner_tid != 0 and self.sema.get_type_kind(owner_tid as TypeId) == TypeKind.TY_STRUCT:
            var cached = self.field_cache_lookup(owner_tid, field_sym)
            if cached == -1234567:
                self.build_field_cache_from_usage()
                cached = self.field_cache_lookup(owner_tid, field_sym)
            if cached != -1234567 and cached != 0 and self.is_void_tid(cached) == 0:
                let cached_resolved = self.sema.resolve_alias(cached as TypeId) as i32
                if cached_resolved != 0 and self.sema.get_type_kind(cached_resolved as TypeId) != TypeKind.TY_ERR:
                    return cached_resolved
                return cached
            let owner_name = cc_intern_resolve(self.intern, self.sema.get_type_d0(owner_tid as TypeId))
            let field_name = cc_intern_resolve(self.intern, field_sym)
            if owner_name == "Parser":
                if field_name == "intern" or field_sym == 144:
                    let intern_tid = self.named_struct_tid("InternPool")
                    if intern_tid != 0:
                        return intern_tid
                if field_name == "diags" or field_name == "diagnostics" or field_sym == 145:
                    let diags_tid = self.named_struct_tid("DiagnosticList")
                    if diags_tid != 0:
                        return diags_tid
            if owner_name == "Compilation":
                if field_name == "driver" or field_sym == 213:
                    let driver_tid = self.named_struct_tid("Driver")
                    if driver_tid != 0:
                        return driver_tid
            if owner_name == "ResolveState":
                if field_name == "pool":
                    let pool_tid = self.named_struct_tid("InternPool")
                    if pool_tid != 0:
                        return pool_tid
                if field_name == "diags" or field_name == "diagnostics":
                    let diags_tid = self.named_struct_tid("DiagnosticList")
                    if diags_tid != 0:
                        return diags_tid
                if field_name == "result":
                    let result_tid = self.named_struct_tid("ResolveResult")
                    if result_tid != 0:
                        return result_tid
                if field_name == "root_source_dir":
                    return self.sema.ty_str as i32
                if field_name == "module_paths" or field_name == "module_dirs" or field_name == "module_file_ids" or field_name == "module_decl_counts" or field_name == "module_import_starts" or field_name == "module_import_counts" or field_name == "module_scope_ids" or field_name == "module_processed":
                    return CC_PSEUDO_TID_LIST
                if field_name == "module_map" or field_name == "link_lib_set" or field_name == "binding_map":
                    return self.sema.ty_i64 as i32
        raw_field_tid

    fn is_unit_rvalue(body: &MirBody, rval_id: i32) -> i32:
        let _ = self
        if rval_id < 0 or rval_id >= body.rval_kinds.len():
            return 0
        if body.rval_kinds[rval_id] != RvalueKind.RK_USE:
            return 0
        let op = body.rval_d0[rval_id]
        if op < 0 or op >= body.operand_kinds.len():
            return 0
        if body.operand_kinds[op] != OperandKind.OK_CONSTANT:
            return 0
        let const_id = body.operand_d0[op]
        if const_id < 0 or const_id >= body.const_kinds.len():
            return 0
        let ck = body.const_kinds[const_id]
        if ck == ConstKind.CK_UNIT or ck == ConstKind.CK_ZERO_SIZED:
            return 1
        0

    fn rvalue_direct_local_id(body: &MirBody, rval_id: i32) -> i32:
        let _ = self
        if rval_id < 0 or rval_id >= body.rval_kinds.len():
            return -1
        if body.rval_kinds[rval_id] != RvalueKind.RK_USE:
            return -1
        let op = body.rval_d0[rval_id]
        if op < 0 or op >= body.operand_kinds.len():
            return -1
        let ok = body.operand_kinds[op]
        if ok != OperandKind.OK_COPY and ok != OperandKind.OK_MOVE:
            return -1
        let place_id = body.operand_d0[op]
        if place_id < 0 or place_id >= body.place_locals.len():
            return -1
        let local_id = body.place_locals[place_id]
        if local_id < 0:
            return -1
        if body.place_proj_counts[place_id] != 0:
            return -1
        local_id

    fn local_has_assignment(body: &MirBody, local_id: i32) -> i32:
        if local_id < 0:
            return 0
        for bb in 0..body.block_count():
            let start = body.bb_stmt_starts[bb]
            let count = body.bb_stmt_counts[bb]
            for si in 0..count:
                let stmt_id = start + si
                if body.stmt_kinds[stmt_id] != StmtKind.Assign:
                    continue
                let dst_place = body.stmt_d0[stmt_id]
                if self.place_is_direct_local(body, dst_place, local_id) != 0:
                    return 1
            if body.term_kind(bb) == TermKind.TK_CALL:
                let dest_place = body.term_data2(bb)
                if self.place_is_direct_local(body, dest_place, local_id) != 0:
                    return 1
        0

    mut fn zero_value_text(tid: i32) -> str:
        // MIR can retain the backend's pseudo List type for compiler-created
        // carrier/reset locals. It has the same C representation as List[T].
        if tid == CC_PSEUDO_TID_LIST:
            return "(with_vec)" ++ cc_lbrace() ++ "0" ++ cc_rbrace()
        let resolved = self.sema.resolve_alias(tid)
        let tk = self.sema.get_type_kind(resolved)
        if tk == TypeKind.TY_BOOL:
            return "false"
        if tk == TypeKind.TY_FLOAT:
            return "0.0"
        // A `&str` view is a with_str value (#1810).
        if self.sema.type_layout_is_str_view(resolved as i32):
            return "(with_str)" ++ cc_lbrace() ++ "0" ++ cc_rbrace()
        if tk == TypeKind.TY_PTR or tk == TypeKind.TY_REF:
            return "NULL"
        if tk == TypeKind.TY_GENERIC_INST and self.generic_inst_base_name(resolved as i32) == "List":
            return "(with_vec)" ++ cc_lbrace() ++ "0" ++ cc_rbrace()
        if tk == TypeKind.TY_GENERIC_INST and (self.generic_inst_needs_struct_def(resolved as i32) != 0 or self.generic_inst_is_declared_struct(resolved as i32)):
            return "(" ++ self.c_type(resolved, 0) ++ ")" ++ cc_lbrace() ++ "0" ++ cc_rbrace()
        if tk == TypeKind.TY_STR or tk == TypeKind.TY_STRUCT or tk == TypeKind.TY_TUPLE or tk == TypeKind.TY_FN or self.type_is_payload_enum(resolved as i32) != 0:
            return "(" ++ self.c_type(resolved, 0) ++ ")" ++ cc_lbrace() ++ "0" ++ cc_rbrace()
        "0"

    mut fn line_directive(body: &MirBody, stmt_id: i32) -> str:
        if self.line_file_id < 0 or self.line_file_path.len() == 0:
            return ""
        if stmt_id < 0 or stmt_id >= body.stmt_spans.len():
            return ""
        let span = body.stmt_spans[stmt_id]
        if span <= 0:
            return ""
        let line = self.sema.source_location_for_file_id(self.line_file_id, span).line + 1
        if line == self.last_line_directive:
            return ""
        self.last_line_directive = line
        f"#line {line} \"{cc_line_directive_path(self.line_file_path)}\"\n"

    // Point the #line directives at the file this body's declaration came
    // from: the root for file 0, else the name Sema recorded for that file.
    mut fn enter_line_file(fn_sym: i32):
        self.last_line_directive = 0
        let fn_node = self.sema.fn_symbol_decl_node(fn_sym)
        if fn_node == 0:
            self.line_file_id = -1
            self.line_file_path = ""
            return
        self.line_file_id = self.sema.ast.file(fn_node) as i32
        self.line_file_path = self.source_path.clone()
        for si in 0..self.sema.source_text_file_ids.len():
            if self.sema.source_text_file_ids[si] == self.line_file_id:
                self.line_file_path = self.sema.source_text_names[si].clone()

    mut fn emit_stmt_line(body: &MirBody, stmt_id: i32) -> str:
        if stmt_id < 0 or stmt_id >= body.stmt_kinds.len():
            self.fail(f"invalid statement id {stmt_id}")
            return "    /* invalid statement */"
        let sk = body.stmt_kinds[stmt_id]
        let d0 = body.stmt_d0[stmt_id]
        let d1 = body.stmt_d1[stmt_id]
        if sk == StmtKind.Assign:
            let dst_local = self.place_local_id(body, d0)
            if self.place_is_direct_local(body, d0, dst_local) != 0 and self.local_has_value_use(body, dst_local) == 0:
                if d1 >= 0 and d1 < body.rval_kinds.len() and body.rval_kinds[d1] == RvalueKind.RK_AGGREGATE:
                    return "    /* dead aggregate temp */"
            let dst_place = self.place_text(body, d0)
            let dst_tid = self.place_tid(body, d0)
            let dst_resolved = self.sema.resolve_alias(dst_tid)
            let dst_tk = self.sema.get_type_kind(dst_resolved)
            // §2.5.1: the reset-on-move blank is all-zero bytes, padding
            // included: the drop guard reads every byte (#983).
            if self.rvalue_is_zero_const(body, d1):
                let zero_addr = if dst_tk == TypeKind.TY_ARRAY: dst_place else: "&(" ++ dst_place ++ ")"
                return "    memset(" ++ zero_addr ++ ", 0, sizeof(" ++ dst_place ++ "));"
            // `&raw const s` of a str is the address of its header: a raw
            // pointer, never the `&str` view a shared reference is (#1810).
            if dst_tk == TypeKind.TY_PTR and d1 >= 0 and d1 < body.rval_kinds.len() and body.rval_kinds[d1] == RvalueKind.RK_REF:
                let target = self.place_text(body, body.rval_d1[d1])
                return "    " ++ dst_place ++ " = (" ++ self.c_type(dst_tid, 0) ++ ")(&" ++ target ++ ");"
            if dst_tk == TypeKind.TY_FN:
                let fat_sym = self.rvalue_ck_fn_sym(body, d1)
                if fat_sym != 0:
                    return "    " ++ dst_place ++ " = " ++ self.fat_fn_literal(fat_sym, dst_resolved as i32) ++ ";"
            if self.is_unit_rvalue(body, d1) != 0:
                if dst_tk == TypeKind.TY_ARRAY:
                    return "    memset(" ++ dst_place ++ ", 0, sizeof(" ++ dst_place ++ "));"
                return "    " ++ dst_place ++ " = " ++ self.zero_value_text(dst_tid) ++ ";"
            if dst_tk == TypeKind.TY_ARRAY and d1 >= 0 and d1 < body.rval_kinds.len() and body.rval_kinds[d1] == RvalueKind.RK_ARRAY_FILL:
                let fill_op = body.rval_d0[d1]
                let fill_count = body.rval_d1[d1]
                let fill_text = self.operand_text(body, fill_op)
                return "    " ++ cc_lbrace() ++ " __typeof__(" ++ dst_place ++ "[0]) __with_fill = " ++ fill_text ++ "; for (int64_t __with_i = 0; __with_i < " ++ f"{fill_count}" ++ "; __with_i++) " ++ cc_lbrace() ++ " " ++ dst_place ++ "[__with_i] = __with_fill; " ++ cc_rbrace() ++ " " ++ cc_rbrace()
            let rval = self.rvalue_text(body, d1)
            let dst_c_type_for_assign = self.c_type(dst_tid, 0)
            let rval_looks_address = cc_rval_looks_address(rval)
            if rval_looks_address != 0 and rval != "0" and rval != "0LL" and rval != "NULL":
                if cc_str_contains(dst_c_type_for_assign, "*") != 0:
                    return "    " ++ dst_place ++ " = (" ++ dst_c_type_for_assign ++ ")" ++ rval ++ ";"
                if dst_c_type_for_assign == "int64_t":
                    return "    " ++ dst_place ++ " = (int64_t)(intptr_t)" ++ rval ++ ";"
                if dst_c_type_for_assign == "uint64_t":
                    return "    " ++ dst_place ++ " = (uint64_t)(uintptr_t)" ++ rval ++ ";"
            // Array assignment: use memcpy/memset (C arrays are not assignable)
            if dst_tk == TypeKind.TY_ARRAY:
                if rval == "0" or rval == "0LL":
                    return "    memset(" ++ dst_place ++ ", 0, sizeof(" ++ dst_place ++ "));"
                let nested = self.aggregate_nested_array_assignment(body, d1, dst_tid, dst_place)
                if nested.len() > 0:
                    return nested
                let arr_init = self.aggregate_array_initializer(body, d1)
                if arr_init.len() > 0:
                    return "    " ++ cc_lbrace() ++ " " ++ self.c_decl(dst_tid, "__with_arr_tmp") ++ " = " ++ arr_init ++ "; memcpy(" ++ dst_place ++ ", __with_arr_tmp, sizeof(" ++ dst_place ++ ")); " ++ cc_rbrace()
                let rv_tid = self.rvalue_tid(body, d1)
                let rv_resolved = if rv_tid != 0: self.sema.resolve_alias(rv_tid) else: 0
                let rv_tk = if rv_resolved != 0: self.sema.get_type_kind(rv_resolved) else: 0
                if rv_tk == TypeKind.TY_ARRAY:
                    return "    memcpy(" ++ dst_place ++ ", " ++ rval ++ ", sizeof(" ++ dst_place ++ "));"
                // Scalar to array: write scalar bytes into array via temp
                return "    " ++ cc_lbrace() ++ " __typeof__(" ++ rval ++ ") __tmp = " ++ rval ++ "; memcpy(" ++ dst_place ++ ", &__tmp, sizeof(" ++ dst_place ++ ") < sizeof(__tmp) ? sizeof(" ++ dst_place ++ ") : sizeof(__tmp)); " ++ cc_rbrace()
            let array_field_struct_assign = self.aggregate_struct_assignment_with_array_fields(body, d1, dst_tid, dst_place)
            if array_field_struct_assign.len() > 0:
                return array_field_struct_assign
            let agg_literal = self.aggregate_compound_literal(body, d1, dst_tid)
            if agg_literal.len() > 0:
                return "    " ++ dst_place ++ " = " ++ agg_literal ++ ";"
            if self.type_is_payload_enum(dst_tid) != 0:
                let rv_tid_for_payload = self.rvalue_tid(body, d1)
                let variant_index = self.payload_enum_variant_for_payload_tid(dst_tid, rv_tid_for_payload)
                if variant_index >= 0:
                    return "    " ++ dst_place ++ " = " ++ self.payload_enum_literal(dst_tid, variant_index, rval) ++ ";"
            // List zero-init: c_type returns "with_vec" for TY_GENERIC_INST(List)
            if (rval == "0" or rval == "0LL") and self.c_type(dst_tid, 0) == "with_vec":
                return "    " ++ dst_place ++ " = (with_vec)" ++ cc_lbrace() ++ "0" ++ cc_rbrace() ++ ";"
            // If destination is struct/str/vec and rvalue looks like a scalar, wrap it
            let dst_c_type = self.c_type(dst_tid, 0)
            let dst_is_distinct = self.type_is_distinct(dst_tid)
            let dst_is_compound = (dst_tk == TypeKind.TY_STRUCT and dst_is_distinct == 0) or dst_tk == TypeKind.TY_TUPLE or dst_tk == TypeKind.TY_STR or dst_tid == CC_PSEUDO_TID_LIST or dst_resolved == CC_PSEUDO_TID_LIST or dst_c_type == "with_str" or dst_c_type == "with_vec"
            if dst_is_compound:
                if rval == "0" or rval == "0LL":
                    return "    " ++ dst_place ++ " = " ++ self.zero_value_text(dst_tid) ++ ";"
                // If the rvalue type doesn't match the struct destination, wrap
                let rv_tid = self.rvalue_tid(body, d1)
                let rv_resolved = if rv_tid != 0: self.sema.resolve_alias(rv_tid) else: 0
                let rv_tk = if rv_resolved != 0: self.sema.get_type_kind(rv_resolved) else: 0
                var needs_wrap = rv_tk == TypeKind.TY_INT or rv_tk == TypeKind.TY_BOOL or rv_tk == TypeKind.TY_ENUM
                if not needs_wrap and rv_resolved != 0 and rv_resolved != dst_resolved:
                    // Check C type strings before assuming incompatibility — pseudo List and
                    // real List[T] have different sema type kinds but the same C type.
                    let dst_c = self.c_type(dst_tid, 0)
                    let rv_c = self.c_type(rv_tid, 0)
                    if dst_c != rv_c:
                        needs_wrap = true
                // If rvalue type is unknown but the rvalue text looks like a simple scalar, wrap it
                if not needs_wrap and rv_tid == 0:
                    let rv_looks_scalar = rval.len() > 0 and rval[0] != 40 and rval[0] != 123
                    if rv_looks_scalar and rval != self.zero_value_text(dst_tid):
                        needs_wrap = true
                if needs_wrap:
                    let src_local = self.rvalue_direct_local_id(body, d1)
                    if src_local >= 0 and self.local_has_assignment(body, src_local) == 0:
                        return "    " ++ dst_place ++ " = " ++ self.zero_value_text(dst_tid) ++ ";"
                    let dst_c = self.c_type(dst_tid, 0)
                    if dst_c == "with_str" or dst_c == "with_vec":
                        return self.storage_copy_assignment(dst_place, rval)
                    if dst_tk == TypeKind.TY_STRUCT:
                        return "    " ++ dst_place ++ " = " ++ self.zero_value_text(dst_tid) ++ ";"
                    return "    " ++ dst_place ++ " = (" ++ dst_c ++ ")" ++ cc_lbrace() ++ rval ++ cc_rbrace() ++ ";"
            let rv_tid_for_copy = self.rvalue_tid(body, d1)
            if rv_tid_for_copy != 0 and dst_tid != 0:
                let dst_c_for_copy = self.c_type(dst_tid, 0)
                let rv_c_for_copy = self.c_type(rv_tid_for_copy, 0)
                let dst_resolved_for_copy = self.sema.resolve_alias(dst_tid)
                let dst_kind_for_copy = self.sema.get_type_kind(dst_resolved_for_copy)
                let dst_is_str_view_for_copy = self.sema.type_layout_is_str_view(dst_resolved_for_copy as i32)
                if (dst_kind_for_copy == TypeKind.TY_PTR or dst_kind_for_copy == TypeKind.TY_REF) and not dst_is_str_view_for_copy:
                    if rval.len() >= 2 and rval[0] == 40 and rval[1] == 38:
                        return "    " ++ dst_place ++ " = (" ++ dst_c_for_copy ++ ")" ++ rval ++ ";"
                if dst_kind_for_copy == TypeKind.TY_REF and not dst_is_str_view_for_copy:
                    // #785: a str CONSTANT assigned to a &str-typed local (an
                    // if-join over literals) renders as a with_str VALUE; the
                    // pointer local takes the array-compound-literal address.
                    let dst_pointee_for_copy = self.sema.resolve_alias(self.sema.get_type_d0(dst_resolved_for_copy) as TypeId)
                    if self.sema.get_type_kind(dst_pointee_for_copy) == TypeKind.TY_STR and self.rvalue_is_str_const_use(body, d1) != 0:
                        return "    " ++ dst_place ++ " = ((with_str[]){ " ++ rval ++ " });"
                if dst_c_for_copy != rv_c_for_copy:
                    let dst_scalar = self.is_scalar_like_tid(dst_tid)
                    let rv_scalar = self.is_scalar_like_tid(rv_tid_for_copy)
                    if dst_scalar == 0 or rv_scalar == 0:
                        return self.storage_copy_assignment(dst_place, rval)
            return "    " ++ dst_place ++ " = " ++ rval ++ ";"
        if sk == StmtKind.StorageLive:
            return f"    /* StorageLive(_{d0}); */"
        if sk == StmtKind.StorageDead:
            return f"    /* StorageDead(_{d0}); */"
        if sk == StmtKind.Drop:
            return self.drop_place_text(body, d0)
        if sk == StmtKind.Nop:
            return "    /* nop */"
        self.fail(f"unsupported statement kind {sk}")
        "    /* unsupported statement */"

    mut fn emit_switch_term(body: &MirBody, d0: i32, d1: i32, d2: i32) -> str:
        let cond = self.operand_text(body, d0)
        if d1 < 0 or d1 >= body.switch_table_starts.len():
            self.fail(f"invalid switch table id {d1}")
            if d2 != 0:
                return f"    goto bb{d2};"
            return "    abort();"

        let start = body.switch_table_starts[d1]
        let count = body.switch_table_counts[d1]
        // A switch with no arms (D69's exit-code switch after a generator
        // loop whose body neither breaks nor returns) is its default alone.
        if count == 0:
            if d2 != 0:
                return f"    (void)({cond});\n    goto bb{d2};"
            return f"    (void)({cond});\n    abort();"
        var out = ""
        for i in 0..count:
            let val: i64 = body.switch_table_vals[(start + i)]
            let tgt = body.switch_table_targets[(start + i)]
            let head = if i == 0: "if" else: "else if"
            out = out ++ "    " ++ head ++ f" ({cond} == {val}) " ++ cc_lbrace() ++ "\n"
            out = out ++ f"        goto bb{tgt};\n"
            out = out ++ "    " ++ cc_rbrace() ++ "\n"
        out = out ++ "    else " ++ cc_lbrace() ++ "\n"
        if d2 != 0:
            out = out ++ f"        goto bb{d2};\n"
        else:
            out = out ++ "        abort();\n"
        out = out ++ "    " ++ cc_rbrace()
        out

    // The Unit constant MirLower gives a call that is all intrinsic
    // (`unit_operand`): no function is named.
    fn operand_is_unit_placeholder(body: &MirBody, operand_id: i32) -> bool:
        if operand_id < 0 or operand_id >= body.operand_kinds.len() or body.operand_kinds[operand_id] != OperandKind.OK_CONSTANT:
            return false
        let c: i32 = body.operand_d0[operand_id]
        c >= 0 and c < body.const_kinds.len() and body.const_kinds[c] == ConstKind.CK_UNIT and body.const_types[c] == self.sema.ty_void as i32

    mut fn emit_term(body: &MirBody, bb: i32) -> str:
        let tk = body.term_kind(bb)
        let d0 = body.term_data0(bb)
        let d1 = body.term_data1(bb)
        let d2 = body.term_data2(bb)
        let d3 = body.term_data3(bb)
        if tk == TermKind.TK_GOTO:
            return f"    goto bb{d0};"
        if tk == TermKind.TK_RETURN:
            if self.global_init_target(body.fn_sym) != 0:
                return self.global_init_return_text(body.fn_sym)
            let sig_idx = self.body_sig_index(body.fn_sym)
            let ret_tid = if sig_idx >= 0: self.c_sig_return_type(sig_idx) else:
                if body.local_type_ids.len() > 0: body.local_type_ids[0] else: self.sema.ty_void
            if self.is_void_tid(ret_tid) != 0:
                return "    return;"
            if self.returns_array(ret_tid):
                return "    memcpy(__with_ret, _0, sizeof(_0));\n    return;"
            return "    return _0;"
        if tk == TermKind.TK_UNREACHABLE:
            return "    with_panic(WITH_STR_LIT(\"reached unreachable code\"), WITH_STR_LIT(\"\"), 0);\n    abort();"
        if tk == TermKind.TK_SWITCH_INT:
            return self.emit_switch_term(body, d0, d1, d2)
        if tk == TermKind.TK_CALL:
            let builtin_term = self.emit_builtin_call_term(body, bb, d0, d1, d2, d3)
            if builtin_term.len() > 0:
                return builtin_term
            // #2073: an intrinsic call's callee operand is the Unit
            // placeholder; the intrinsic tag is the whole call. With no C
            // lowering for the tag there is nothing to call — resolving the
            // placeholder named an unrelated function (`StringBuilder.new`
            // for the #1985 cancelled-return check).
            if self.operand_is_unit_placeholder(body, d0):
                let tag = body.call_intrinsic(d1) as i32
                self.fail(f"C backend has no lowering for MIR intrinsic #{tag} called in `{self.sema.pool_resolve(body.fn_sym)}`")
                return "    abort();"
            let callee = self.resolve_call_callee_text(body, bb, d0, d1, d2)
            let ret_tid = self.call_return_tid(body, bb, d0, d1, d2)
            if callee == "/*unresolved_call*/" or callee == "/*ambiguous_call*/" or callee == "/*ambiguous_method*/":
                let _ = ret_tid
                return "    abort();"
            self.call_lends = List.new()
            var args = if self.callee_is_str_builtin_ref != 0: self.builtin_method_ref_args_text(body, d1) else: self.call_args_text(body, d1, d0)
            // #1817 (array_out_param): the leading arguments in the one
            // order every signature declares them — the fat pair's context
            // first, then the destination array (it decays to the callee's
            // out-pointer), then the With arguments.
            let fat_callee_place = self.indirect_callee_place_id(body, d0, d1)
            var lead = if fat_callee_place >= 0: self.place_text(body, fat_callee_place) ++ ".ctx" else: ""
            if self.returns_array(ret_tid):
                let dest = self.place_text(body, d2)
                lead = if lead.len() > 0: lead ++ ", " ++ dest else: dest
            if lead.len() > 0:
                args = if args.len() > 0: lead ++ ", " ++ args else: lead
            var call_line = ""
            if self.is_void_tid(ret_tid) != 0 or self.returns_array(ret_tid):
                call_line = callee ++ "(" ++ args ++ ");"
            else:
                call_line = self.place_text(body, d2) ++ " = " ++ callee ++ "(" ++ args ++ ");"
            var out = ""
            if self.call_lends.len() == 0:
                out = "    " ++ call_line ++ "\n"
            else:
                // D47: the lent C strings live for the call, then go back.
                out = "    " ++ cc_lbrace()
                for li in 0..self.call_lends.len():
                    out = out ++ f" uint8_t* __with_lend{li} = " ++ self.call_lends[li] ++ ";"
                out = out ++ " " ++ call_line
                for li in 0..self.call_lends.len():
                    out = out ++ f" with_cstr_release(__with_lend{li});"
                out = out ++ " " ++ cc_rbrace() ++ "\n"
            out = out ++ f"    goto bb{d3};"
            return out
        if tk == TermKind.TK_DROP_AND_GOTO:
            return self.drop_place_text(body, d0) ++ f"\n    goto bb{d1};"
        self.fail(f"unsupported terminator kind {tk}")
        "    abort();"

// mut.md Rev 8 §5.1 — accumulator state for struct-type collection.
// Bundling out + seen_names into a single CollectStructTypes value lets the
// recursive walk be a method with `mut self: Self` instead of taking two
// separate `&mut` accumulators.
type CollectStructTypes {
    out: List[i32],
    seen_names: HashMap[i32, i32],
    seen_c_names: HashMap[str, i32],
}

fn CollectStructTypes.new -> CollectStructTypes:
    CollectStructTypes { out: List.new(), seen_names: HashMap.new(), seen_c_names: HashMap.new() }

type CollectFnTypes {
    out: List[i32],
    seen_names: HashMap[i32, i32],
    seen_types: HashMap[i32, i32],
}

fn CollectFnTypes.new -> CollectFnTypes:
    CollectFnTypes { out: List.new(), seen_names: HashMap.new(), seen_types: HashMap.new() }

impl CCodegen:
    mut fn collect_struct_types_from_tid(acc: CollectStructTypes, tid: i32) -> CollectStructTypes:
        let resolved = self.sema.resolve_alias(tid)
        if resolved == 0:
            return acc
        let tk = self.sema.get_type_kind(resolved)
        // A nullable-pointer Option has no record of its own (#2036): its
        // payload's types are what it needs.
        if self.option_is_nullable_pointer(resolved as i32):
            return self.collect_struct_types_from_tid(move acc, self.sema.get_generic_inst_arg(resolved as i32, 0))
        if tk == TypeKind.TY_STRUCT or self.type_is_payload_enum(resolved as i32) != 0:
            let cname = self.struct_c_name(resolved as i32)
            if not acc.seen_names.contains(resolved as i32) and not acc.seen_c_names.contains(cname):
                acc.seen_names.insert(resolved as i32, 1)
                acc.seen_c_names.insert(cname, 1)
                acc.out.push(resolved as i32)
            if self.type_is_payload_enum(resolved as i32) != 0:
                var payload_acc = acc
                let variant_count = self.sema.type_reflection_variant_count(resolved as i32)
                for vi in 0..variant_count:
                    let payload_count = self.sema.type_reflection_variant_payload_count(resolved as i32, vi)
                    for pi in 0..payload_count:
                        let payload_tid = self.sema.type_reflection_variant_payload_type_frozen(resolved as i32, vi, pi)
                        payload_acc = self.collect_struct_types_from_tid(move payload_acc, payload_tid)
                return payload_acc
            return acc
        if tk == TypeKind.TY_TUPLE:
            let cname = self.struct_c_name(resolved as i32)
            if not acc.seen_names.contains(resolved as i32) and not acc.seen_c_names.contains(cname):
                acc.seen_names.insert(resolved as i32, 1)
                acc.seen_c_names.insert(cname, 1)
                acc.out.push(resolved as i32)
            var tuple_acc = acc
            let start = self.sema.get_type_d0(resolved)
            let count = self.sema.get_type_d1(resolved)
            for ti in 0..count:
                tuple_acc = self.collect_struct_types_from_tid(move tuple_acc, self.sema.type_extra[(start + ti)])
            return tuple_acc
        if tk == TypeKind.TY_GENERIC_INST:
            let base_name = self.generic_inst_base_name(resolved as i32)
            if self.generic_inst_needs_struct_def(resolved as i32) != 0:
                if not acc.seen_names.contains(resolved as i32):
                    acc.seen_names.insert(resolved as i32, 1)
                    acc.out.push(resolved as i32)
                var generic_acc = acc
                let field_tids = self.synthetic_generic_struct_field_tids(resolved as i32)
                for fi in 0..field_tids.len():
                    generic_acc = self.collect_struct_types_from_tid(move generic_acc, field_tids[fi])
                return generic_acc
            if base_name == "List" or base_name == "HashMap" or base_name == "HashSet":
                // The container itself is the runtime's with_vec/with_map,
                // but emitted code names the element (and key) type in
                // casts and sizeof, so its declaration is owed exactly as
                // for a fixed array's element (a struct reached only as a
                // List element was otherwise undeclared in the C).
                var elem_acc = acc
                let arg_count = self.sema.get_generic_inst_arg_count(resolved as i32)
                for ai in 0..arg_count:
                    elem_acc = self.collect_struct_types_from_tid(elem_acc, self.sema.get_generic_inst_arg(resolved as i32, ai))
                return elem_acc
            if self.generic_inst_is_declared_struct(resolved as i32):
                let cname = self.struct_c_name(resolved as i32)
                if acc.seen_names.contains(resolved as i32) or acc.seen_c_names.contains(cname):
                    return acc
                acc.seen_names.insert(resolved as i32, 1)
                acc.seen_c_names.insert(cname, 1)
                acc.out.push(resolved as i32)
                var inst_acc = acc
                for fi in 0..self.sema.type_reflection_field_count(resolved as i32):
                    inst_acc = self.collect_struct_types_from_tid(move inst_acc, self.sema.type_reflection_field_type_frozen(resolved as i32, fi))
                return inst_acc
        if tk == TypeKind.TY_SLICE:
            let cname = self.struct_c_name(resolved as i32)
            if not acc.seen_names.contains(resolved as i32) and not acc.seen_c_names.contains(cname):
                acc.seen_names.insert(resolved as i32, 1)
                acc.seen_c_names.insert(cname, 1)
                acc.out.push(resolved as i32)
            return self.collect_struct_types_from_tid(move acc, self.sema.get_type_d0(resolved))
        if tk == TypeKind.TY_PTR or tk == TypeKind.TY_REF or tk == TypeKind.TY_ARRAY:
            let inner_tid = self.sema.get_type_d0(resolved)
            return self.collect_struct_types_from_tid(move acc, inner_tid)
        let box_pointee = self.std_box_pointee_tid(resolved as i32)
        if box_pointee != 0:
            return self.collect_struct_types_from_tid(move acc, box_pointee)
        acc

    fn synthetic_generic_struct_field_tids(tid: i32) -> List[i32]:
        let fields: List[i32] = List.new()
        let resolved = self.sema.resolve_alias(tid as TypeId) as i32
        if self.sema.get_type_kind(resolved as TypeId) != TypeKind.TY_GENERIC_INST:
            return fields
        let base_name = self.generic_inst_base_name(resolved)
        if base_name == "HashMapEntry":
            if self.sema.get_generic_inst_arg_count(resolved) > 0:
                fields.push(self.sema.get_generic_inst_arg(resolved, 0))
        else if base_name == "Atomic":
            if self.sema.get_generic_inst_arg_count(resolved) > 0:
                fields.push(self.sema.get_generic_inst_arg(resolved, 0))
        fields

    mut fn collect_fn_types_from_tid(acc: CollectFnTypes, tid: i32) -> CollectFnTypes:
        var cur = acc
        let resolved = self.sema.resolve_alias(tid)
        if resolved == 0:
            return cur
        if cur.seen_types.contains(resolved as i32):
            return cur
        cur.seen_types.insert(resolved as i32, 1)
        let tk = self.sema.get_type_kind(resolved)
        if tk == TypeKind.TY_FN or tk == TypeKind.TY_EXTERN_FN:
            if not cur.seen_names.contains(resolved as i32):
                cur.seen_names.insert(resolved as i32, 1)
                cur.out.push(resolved as i32)
            let ret_tid = self.sema.get_type_d2(resolved)
            cur = self.collect_fn_types_from_tid(move cur, ret_tid)
            let start = self.sema.get_type_d0(resolved)
            let count = self.sema.get_type_d1(resolved)
            for pi in 0..count:
                cur = self.collect_fn_types_from_tid(move cur, self.sema.type_extra[(start + pi)])
            return cur
        if tk == TypeKind.TY_PTR or tk == TypeKind.TY_REF or tk == TypeKind.TY_ARRAY or tk == TypeKind.TY_SLICE:
            return self.collect_fn_types_from_tid(move cur, self.sema.get_type_d0(resolved))
        if tk == TypeKind.TY_GENERIC_INST:
            let arg_count = self.sema.get_generic_inst_arg_count(resolved as i32)
            for ai in 0..arg_count:
                cur = self.collect_fn_types_from_tid(move cur, self.sema.get_generic_inst_arg(resolved as i32, ai))
            return cur
        if tk == TypeKind.TY_STRUCT:
            let start = self.sema.get_type_d1(resolved)
            let count = self.sema.get_type_d2(resolved)
            for fi in 0..count:
                let raw_field_tid: i32 = self.sema.type_extra[(start + fi * 3 + 1)]
                cur = self.collect_fn_types_from_tid(move cur, raw_field_tid)
            return cur
        if tk == TypeKind.TY_TUPLE:
            let start = self.sema.get_type_d0(resolved)
            let count = self.sema.get_type_d1(resolved)
            for ti in 0..count:
                cur = self.collect_fn_types_from_tid(move cur, self.sema.type_extra[(start + ti)])
            return cur
        if self.type_is_payload_enum(resolved as i32) != 0:
            let variant_count = self.sema.type_reflection_variant_count(resolved as i32)
            for vi in 0..variant_count:
                let payload_count = self.sema.type_reflection_variant_payload_count(resolved as i32, vi)
                for pi in 0..payload_count:
                    cur = self.collect_fn_types_from_tid(move cur, self.sema.type_reflection_variant_payload_type_frozen(resolved as i32, vi, pi))
            return cur
        cur

    mut fn collect_used_fn_types() -> List[i32]:
        var acc = CollectFnTypes.new()
        for bi in 0..self.mir_mod.bodies.len():
            if self.check_interrupted() != 0:
                return move acc.out
            let body = self.mir_body_at(bi as i64)
            for li in 0..body.local_type_ids.len():
                acc = self.collect_fn_types_from_tid(move acc, body.local_type_ids[li])
            let sig_idx = self.body_sig_index(body.fn_sym)
            if sig_idx >= 0:
                acc = self.collect_fn_types_from_tid(move acc, self.c_sig_return_type(sig_idx))
                let param_count = self.sema.sig_get_param_count(sig_idx)
                for pi in 0..param_count:
                    acc = self.collect_fn_types_from_tid(move acc, self.sema.sig_param_type(sig_idx, pi))
        return move acc.out

    mut fn collect_used_struct_types() -> List[i32]:
        var acc = CollectStructTypes.new()
        if self.collect_cstr_literal_texts().len() > 0:
            acc = self.collect_struct_types_from_tid(move acc, self.sema.ty_cstr as i32)

        for bi in 0..self.mir_mod.bodies.len():
            if self.check_interrupted() != 0:
                return move acc.out
            let body = self.mir_body_at(bi as i64)
            for bb in 0..body.block_count():
                if self.check_interrupted() != 0:
                    return move acc.out
                if body.term_kind(bb) != TermKind.TK_CALL:
                    continue
                let args_id = body.term_data1(bb)
                let call_intr = body.call_intrinsic(args_id)
                if call_intr == MirIntrinsic.GENERIC_CALL:
                    // sizeof[T]()/alignof[T]() may name a type no local ever
                    // carries; the emitted C sizeof needs its definition.
                    // Resolved as the body's emission will resolve it: from
                    // the owning function's module, under the instance's
                    // substitution (#1766).
                    let ga_type_node = self.generic_call_type_arg_node(body, args_id)
                    if ga_type_node != 0:
                        let ga_owner = self.body_owner_sym(body.fn_sym)
                        let saved_module = move self.sema.current_module_path
                        let ga_path = self.sema.fn_body_source_path(ga_owner)
                        self.sema.current_module_path = if ga_path.len() > 0: ga_path else: with_str_clone_ref(saved_module)
                        let ga_tid = self.sema.type_level_arg_in_body(ga_owner, ga_type_node)
                        self.sema.current_module_path = saved_module
                        if ga_tid != 0:
                            acc = self.collect_struct_types_from_tid(move acc, ga_tid)
                    continue
                if call_intr != MirIntrinsic.MAP_GET:
                    continue
                let recv_operand = self.call_arg_operand(body, args_id, 0)
                let recv_tid = self.operand_tid_no_infer(body, recv_operand)
                let value_tid = self.hashmap_value_tid(recv_tid)
                if value_tid != 0 and self.is_void_tid(value_tid) == 0:
                    let opt_tid = self.option_ref_tid_for_payload(value_tid)
                    acc = self.collect_struct_types_from_tid(move acc, opt_tid)
                let dst_tid = self.place_local_tid(body, body.term_data2(bb))
                if dst_tid != 0 and self.is_void_tid(dst_tid) == 0 and self.is_scalar_like_tid(dst_tid) == 0:
                    let dst_opt_tid = self.option_ref_tid_for_payload(dst_tid)
                    acc = self.collect_struct_types_from_tid(move acc, dst_opt_tid)
            for li in 0..body.local_type_ids.len():
                if self.check_interrupted() != 0:
                    return move acc.out
                let tid = self.local_struct_collection_tid(body, li as i32)
                acc = self.collect_struct_types_from_tid(move acc, tid)
            let sig_idx = self.body_sig_index(body.fn_sym)
            if sig_idx >= 0:
                let ret_tid = self.c_sig_return_type(sig_idx)
                acc = self.collect_struct_types_from_tid(move acc, ret_tid)
                let param_count = self.sema.sig_get_param_count(sig_idx)
                for pi in 0..param_count:
                    let p_tid = self.sema.sig_param_type(sig_idx, pi)
                    acc = self.collect_struct_types_from_tid(move acc, p_tid)
        // A struct a function type names only through a pointer (an engine's
        // `fn(*mut m_string_s) -> i32` callback field, the pointee opaque)
        // needs its forward typedef before the fn typedefs: collected as a
        // signature's parameters are.
        let fn_tids = self.collect_used_fn_types()
        for fi in 0..fn_tids.len():
            let ftid = self.sema.resolve_alias(fn_tids[fi] as TypeId)
            let fkind = self.sema.get_type_kind(ftid)
            if fkind != TypeKind.TY_FN and fkind != TypeKind.TY_EXTERN_FN: continue
            acc = self.collect_struct_types_from_tid(move acc, self.sema.get_type_d2(ftid))
            let pstart = self.sema.get_type_d0(ftid)
            for pi in 0..self.sema.get_type_d1(ftid):
                acc = self.collect_struct_types_from_tid(move acc, self.sema.type_extra[(pstart + pi)])

        var i = 0
        while i < acc.out.len():
            if self.check_interrupted() != 0:
                return move acc.out
            let tid: i32 = acc.out[i]
            i = i + 1
            let resolved = self.sema.resolve_alias(tid as TypeId) as i32
            let tk = self.sema.get_type_kind(resolved as TypeId)
            if tk == TypeKind.TY_GENERIC_INST and self.generic_inst_needs_struct_def(resolved) != 0:
                let field_tids = self.synthetic_generic_struct_field_tids(resolved)
                for fi in 0..field_tids.len():
                    if self.check_interrupted() != 0:
                        return move acc.out
                    acc = self.collect_struct_types_from_tid(move acc, field_tids[fi])
                continue
            if self.type_is_payload_enum(resolved) != 0:
                let variant_count = self.sema.type_reflection_variant_count(resolved)
                for vi in 0..variant_count:
                    let payload_count = self.sema.type_reflection_variant_payload_count(resolved, vi)
                    for pi in 0..payload_count:
                        if self.check_interrupted() != 0:
                            return move acc.out
                        acc = self.collect_struct_types_from_tid(move acc, self.sema.type_reflection_variant_payload_type_frozen(resolved, vi, pi))
                continue
            if tk == TypeKind.TY_TUPLE:
                let start = self.sema.get_type_d0(resolved as TypeId)
                let count = self.sema.get_type_d1(resolved as TypeId)
                for ti in 0..count:
                    if self.check_interrupted() != 0:
                        return move acc.out
                    acc = self.collect_struct_types_from_tid(move acc, self.sema.type_extra[(start + ti)])
                continue
            if tk != TypeKind.TY_STRUCT:
                continue
            let start = self.sema.get_type_d1(resolved as TypeId)
            let count = self.sema.get_type_d2(resolved as TypeId)
            for fi in 0..count:
                if self.check_interrupted() != 0:
                    return move acc.out
                let raw_field_tid: i32 = self.sema.type_extra[(start + fi * 3 + 1)]
                acc = self.collect_struct_types_from_tid(move acc, raw_field_tid)

        return move acc.out

    mut fn emit_fn_type_defs() -> str:
        let fn_tids = self.collect_used_fn_types()
        var out = ""
        // Structurally equal fn types share one C name (#1766): one typedef.
        var seen_names: HashMap[str, i32] = HashMap.new()
        for i in 0..fn_tids.len():
            if self.check_interrupted() != 0:
                return ""
            let tid = self.sema.resolve_alias(fn_tids[i] as TypeId)
            let tid_kind = self.sema.get_type_kind(tid)
            if tid_kind != TypeKind.TY_FN and tid_kind != TypeKind.TY_EXTERN_FN:
                continue
            let c_name = self.fn_type_c_name(tid as i32)
            if seen_names.contains(c_name):
                continue
            seen_names.insert(c_name.clone(), 1)
            let ret_tid = self.sema.get_type_d2(tid)
            let start = self.sema.get_type_d0(tid)
            let count = self.sema.get_type_d1(tid)
            if tid_kind == TypeKind.TY_FN:
                // Fat fn value: {fn_ptr, ctx} matching native's closure
                // convention — fn_ptr always takes the context first, then
                // (#1817) an array return's out-pointer.
                var fat_params = "void*" ++ self.array_out_param(ret_tid, false, true)
                for pi in 0..count:
                    fat_params = fat_params ++ ", " ++ self.c_type(self.sema.type_extra[(start + pi)], 0)
                let member = self.return_decl(ret_tid, "(*fn_ptr)(" ++ fat_params ++ ")")
                out = out ++ "typedef struct " ++ cc_lbrace() ++ " " ++ member ++ "; void* ctx; " ++ cc_rbrace() ++ " " ++ self.fn_type_c_name(tid as i32) ++ ";\n"
                continue
            if self.returns_array(ret_tid):
                // A C function pointer is a foreign ABI surface: C has no
                // function returning an array, so no C type spells this.
                self.fail("emit-c: an extern \"C\" fn pointer type returning an array is impossible in C (a C function cannot return an array, and a foreign pointer type carries no out-pointer convention)")
                return ""
            var params = ""
            let variadic = self.sema.fn_type_is_variadic(tid as i32)
            if count == 0:
                params = if variadic: "..." else: "void"
            else:
                for pi in 0..count:
                    if pi > 0:
                        params = params ++ ", "
                    params = params ++ self.c_type(self.sema.type_extra[(start + pi)], 0)
                // #1832: a C variadic function pointer.
                if variadic:
                    params = params ++ ", ..."
            out = out ++ "typedef " ++ self.return_decl(ret_tid, "(*" ++ self.fn_type_c_name(tid as i32) ++ ")(" ++ params ++ ")") ++ ";\n"
        if out.len() > 0:
            out = out ++ "\n"
        out

    mut fn emit_struct_type_defs() -> str:
        let struct_tids = self.collect_used_struct_types()
        if self.had_error != 0:
            return ""
        if struct_tids.len() == 0:
            return self.emit_fn_type_defs()

        let ordered: List[i32] = List.new()
        let emitted_names: HashMap[i32, i32] = HashMap.new()
        while ordered.len() < struct_tids.len():
            if self.check_interrupted() != 0:
                return ""
            var progressed = 0
            for i in 0..struct_tids.len():
                if self.check_interrupted() != 0:
                    return ""
                let resolved = self.sema.resolve_alias(struct_tids[i] as TypeId) as i32
                if emitted_names.contains(resolved):
                    continue
                let resolved_kind = self.sema.get_type_kind(resolved as TypeId)
                let start = self.sema.get_type_d1(resolved as TypeId)
                let count = self.sema.get_type_d2(resolved as TypeId)
                var ready = 1
                if self.generic_inst_needs_struct_def(resolved) != 0:
                    let base_name = self.generic_inst_base_name(resolved)
                    if base_name == "HashMapEntry":
                        let key_tid = self.sema.resolve_alias(self.sema.get_generic_inst_arg(resolved, 0) as TypeId)
                        if self.tid_is_c_struct_value(key_tid as i32) and key_tid != resolved and not emitted_names.contains(key_tid as i32):
                            ready = 0
                    if base_name == "Atomic":
                        let value_tid = self.sema.resolve_alias(self.sema.get_generic_inst_arg(resolved, 0) as TypeId)
                        if self.tid_is_c_struct_value(value_tid as i32) and value_tid != resolved and not emitted_names.contains(value_tid as i32):
                            ready = 0
                else if self.type_is_payload_enum(resolved) != 0:
                    let variant_count = self.sema.type_reflection_variant_count(resolved)
                    for vi in 0..variant_count:
                        let payload_count = self.sema.type_reflection_variant_payload_count(resolved, vi)
                        for pi in 0..payload_count:
                            let field_tid = self.sema.resolve_alias(self.sema.type_reflection_variant_payload_type_frozen(resolved, vi, pi) as TypeId)
                            if not self.tid_is_c_struct_value(field_tid as i32):
                                continue
                            if field_tid != resolved and not emitted_names.contains(field_tid as i32):
                                ready = 0
                                break
                        if ready == 0:
                            break
                else if resolved_kind == TypeKind.TY_TUPLE:
                    let tuple_start = self.sema.get_type_d0(resolved as TypeId)
                    let tuple_count = self.sema.get_type_d1(resolved as TypeId)
                    for ti in 0..tuple_count:
                        if self.check_interrupted() != 0:
                            return ""
                        let field_tid = self.sema.resolve_alias(self.sema.type_extra[(tuple_start + ti)] as TypeId)
                        if not self.tid_is_c_struct_value(field_tid as i32):
                            continue
                        if field_tid != resolved and not emitted_names.contains(field_tid as i32):
                            ready = 0
                            break
                else if self.generic_inst_is_declared_struct(resolved):
                    for fi in 0..self.sema.type_reflection_field_count(resolved):
                        let field_tid = self.sema.resolve_alias(self.sema.type_reflection_field_type_frozen(resolved, fi) as TypeId)
                        if not self.tid_is_c_struct_value(field_tid as i32):
                            continue
                        if field_tid != resolved and not emitted_names.contains(field_tid as i32):
                            ready = 0
                            break
                else:
                    for fi in 0..count:
                        if self.check_interrupted() != 0:
                            return ""
                        let field_sym: i32 = self.sema.type_extra[(start + fi * 3)]
                        let raw_field_tid: i32 = self.sema.type_extra[(start + fi * 3 + 1)]
                        let field_tid = self.c_value_member_struct_tid(self.effective_field_tid(resolved, field_sym, raw_field_tid))
                        if field_tid == 0:
                            continue
                        if field_tid != resolved and not emitted_names.contains(field_tid):
                            ready = 0
                            break
                if ready == 0:
                    continue
                ordered.push(resolved)
                emitted_names.insert(resolved, 1)
                progressed = 1
            if progressed == 0:
                for i in 0..struct_tids.len():
                    if self.check_interrupted() != 0:
                        return ""
                    let resolved = self.sema.resolve_alias(struct_tids[i] as TypeId) as i32
                    if emitted_names.contains(resolved):
                        continue
                    ordered.push(resolved)
                    emitted_names.insert(resolved, 1)

        var out = ""
        for i in 0..ordered.len():
            if self.check_interrupted() != 0:
                return ""
            let tid = ordered[i]
            let resolved = self.sema.resolve_alias(tid)
            if self.sema.get_type_kind(resolved) == TypeKind.TY_SLICE:
                let name = self.struct_c_name(tid)
                out = out ++ "typedef struct " ++ name ++ " " ++ name ++ ";\n"
                continue
            if self.sema.get_type_kind(resolved) == TypeKind.TY_TUPLE:
                let name = self.struct_c_name(tid)
                out = out ++ "typedef struct " ++ name ++ " " ++ name ++ ";\n"
                continue
            let name_sym = self.sema.get_type_d0(resolved)
            let count = self.sema.get_type_d2(resolved)
            if self.sema.get_type_kind(resolved) == TypeKind.TY_STRUCT and count == 1 and self.sema.distinct_type_names.contains(name_sym):
                continue  // distinct types get their typedef in the definition pass
            let name = self.struct_c_name(tid)
            out = out ++ "typedef " ++ self.record_keyword(tid) ++ " " ++ name ++ " " ++ name ++ ";\n"
        out = out ++ "\n"
        out = out ++ self.emit_fn_type_defs()

        for i in 0..ordered.len():
            if self.check_interrupted() != 0:
                return ""
            let tid = ordered[i]
            let resolved = self.sema.resolve_alias(tid)
            let name = self.struct_c_name(resolved)
            if self.sema.get_type_kind(resolved) == TypeKind.TY_SLICE:
                let elem_tid = self.sema.get_type_d0(resolved)
                out = out ++ "struct " ++ name ++ " " ++ cc_lbrace() ++ "\n"
                out = out ++ "    " ++ self.c_type(elem_tid, 0) ++ "* ptr;\n"
                out = out ++ "    int64_t len;\n"
                out = out ++ cc_rbrace() ++ ";\n\n"
                continue
            if self.sema.get_type_kind(resolved) == TypeKind.TY_TUPLE:
                let start = self.sema.get_type_d0(resolved)
                let count = self.sema.get_type_d1(resolved)
                out = out ++ "struct " ++ name ++ " " ++ cc_lbrace() ++ "\n"
                var elem_names: List[str] = List.new()
                for ti in 0..count:
                    if self.check_interrupted() != 0:
                        return ""
                    let elem_tid: i32 = self.sema.type_extra[(start + ti)]
                    out = out ++ "    " ++ self.c_decl(elem_tid, f"field{ti}") ++ ";\n"
                    elem_names.push(f"field{ti}")
                out = out ++ cc_rbrace() ++ ";\n"
                out = out ++ self.layout_static_asserts(resolved, name, &elem_names) ++ "\n"
                continue
            let generic_base_name = self.generic_inst_base_name(resolved as i32)
            if self.sema.is_opaque_value_type(resolved as i32) != 0:
                continue
            if generic_base_name == "ListSlot":
                out = out ++ "struct " ++ name ++ " " ++ cc_lbrace() ++ "\n"
                out = out ++ "    int64_t data_ptr;\n"
                out = out ++ "    int64_t index;\n"
                out = out ++ cc_rbrace() ++ ";\n\n"
                continue
            if self.option_is_nullable_pointer(resolved as i32):
                continue
            if self.type_is_payload_enum(resolved as i32) != 0:
                out = out ++ "struct " ++ name ++ " " ++ cc_lbrace() ++ "\n"
                out = out ++ "    int32_t tag;\n"
                var has_payload = 0
                let variant_count = self.sema.type_reflection_variant_count(resolved as i32)
                for vi in 0..variant_count:
                    if self.sema.type_reflection_variant_payload_count(resolved as i32, vi) > 0:
                        has_payload = 1
                if has_payload != 0:
                    out = out ++ "    union " ++ cc_lbrace() ++ "\n"
                    for vi in 0..variant_count:
                        let payload_count = self.sema.type_reflection_variant_payload_count(resolved as i32, vi)
                        if payload_count == 0:
                            continue
                        if payload_count == 1:
                            let payload_tid = self.sema.type_reflection_variant_payload_type_frozen(resolved as i32, vi, 0)
                            out = out ++ "        " ++ self.c_decl(payload_tid, self.payload_enum_variant_field(vi)) ++ ";\n"
                            continue
                        // Several payload fields are a struct of them in
                        // declaration order (with-abi.md §2, TypeLayout's
                        // TY_ENUM rule), C's own struct placement (#2017).
                        out = out ++ "        struct " ++ cc_lbrace() ++ "\n"
                        for pi in 0..payload_count:
                            let field_tid = self.sema.type_reflection_variant_payload_type_frozen(resolved as i32, vi, pi)
                            out = out ++ "            " ++ self.c_decl(field_tid, cc_payload_struct_field(pi)) ++ ";\n"
                        out = out ++ "        " ++ cc_rbrace() ++ " " ++ self.payload_enum_variant_field(vi) ++ ";\n"
                    out = out ++ "    " ++ cc_rbrace() ++ ";\n"
                out = out ++ cc_rbrace() ++ ";\n\n"
                continue
            if generic_base_name == "ListIterPlace":
                out = out ++ "struct " ++ name ++ " " ++ cc_lbrace() ++ "\n"
                out = out ++ "    int64_t data_ptr;\n"
                out = out ++ "    int64_t len;\n"
                out = out ++ "    int64_t idx;\n"
                out = out ++ cc_rbrace() ++ ";\n\n"
                continue
            if generic_base_name == "HashMapEntry":
                let key_tid = self.sema.get_generic_inst_arg(resolved as i32, 0)
                out = out ++ "struct " ++ name ++ " " ++ cc_lbrace() ++ "\n"
                out = out ++ "    int64_t map_ptr;\n"
                out = out ++ "    " ++ self.c_decl(key_tid, "key") ++ ";\n"
                out = out ++ cc_rbrace() ++ ";\n\n"
                continue
            if generic_base_name == "Atomic":
                let value_tid = self.sema.get_generic_inst_arg(resolved as i32, 0)
                out = out ++ "struct " ++ name ++ " " ++ cc_lbrace() ++ "\n"
                out = out ++ "    " ++ self.c_decl(value_tid, "val") ++ ";\n"
                out = out ++ cc_rbrace() ++ ";\n\n"
                continue
            if self.generic_inst_is_declared_struct(resolved as i32):
                out = out ++ self.record_keyword(resolved as i32) ++ " " ++ name ++ " " ++ cc_lbrace() ++ "\n"
                var field_names: List[str] = List.new()
                for fi in 0..self.sema.type_reflection_field_count(resolved as i32):
                    let field_name = cc_member(cc_intern_resolve(self.intern, self.sema.type_reflection_field_name(resolved as i32, fi)))
                    out = out ++ "    " ++ self.c_decl(self.sema.type_reflection_field_type_frozen(resolved as i32, fi), field_name) ++ ";\n"
                    field_names.push(field_name)
                // D72 (§2.5.1): the template's hidden liveness byte.
                if self.sema.struct_liveness_byte_frozen_tid(self.sema.get_type_d0(resolved), resolved as i32) != 0:
                    out = out ++ "    uint8_t __with_live;\n"
                out = out ++ cc_rbrace() ++ ";\n"
                out = out ++ self.layout_static_asserts(resolved as i32, name, &field_names) ++ "\n"
                continue
            let start = self.sema.get_type_d1(resolved)
            let count = self.sema.get_type_d2(resolved)
            // Distinct types (single-field wrapper) → emit as typedef to underlying C type
            let name_sym = self.sema.get_type_d0(resolved)
            if count == 1 and self.sema.distinct_type_names.contains(name_sym):
                let raw_field_tid: i32 = self.sema.type_extra[(start + 1)]
                let field_sym: i32 = self.sema.type_extra[start]
                let field_tid = self.effective_field_tid(resolved, field_sym, raw_field_tid)
                out = out ++ "typedef " ++ self.c_decl(field_tid, name) ++ ";\n\n"
                continue
            out = out ++ self.record_keyword(resolved as i32) ++ " " ++ name ++ " " ++ cc_lbrace() ++ "\n"
            var field_names: List[str] = List.new()
            for fi in 0..count:
                if self.check_interrupted() != 0:
                    return ""
                let field_sym: i32 = self.sema.type_extra[(start + fi * 3)]
                let raw_field_tid: i32 = self.sema.type_extra[(start + fi * 3 + 1)]
                let field_tid = self.effective_field_tid(resolved, field_sym, raw_field_tid)
                let field_name = cc_member(cc_intern_resolve(self.intern, field_sym))
                // §16.4 `@[align(N)]`: the field's declared alignment, the
                // one TypeLayout places it at (#2022).
                let align_slot = start + count * 3 + fi
                let declared_align = if align_slot < self.sema.type_extra.len(): self.sema.type_extra[align_slot] else: 0
                let align_text = if declared_align > 0: f"_Alignas({declared_align}) " else: ""
                out = out ++ "    " ++ align_text ++ self.c_decl(field_tid, field_name) ++ ";\n"
                field_names.push(field_name)
            // D72 (§2.5.1): the hidden liveness byte after the last field.
            if self.sema.struct_liveness_byte_frozen_tid(name_sym, resolved) != 0:
                out = out ++ "    uint8_t __with_live;\n"
            out = out ++ cc_rbrace() ++ ";\n"
            out = out ++ self.layout_static_asserts(resolved, name, &field_names) ++ "\n"
        out

    // `union` for a §16.4 union type (all fields at offset 0, TypeLayout's
    // union rule), else `struct`. A union emitted as a struct laid its
    // members end to end: pcre2's class_bits_storage was 64 bytes where the
    // model says 32, moving every later field of compile_block_8 (#2022).
    fn record_keyword(tid: i32) -> str:
        let resolved = self.sema.resolve_alias(tid as TypeId)
        let tk = self.sema.get_type_kind(resolved)
        let name_sym = if tk == TypeKind.TY_STRUCT or tk == TypeKind.TY_GENERIC_INST: self.sema.get_type_d0(resolved) else: 0
        if name_sym != 0 and self.sema.type_layout_struct_sub_kind(name_sym) == TypeDeclKind.Union: "union" else: "struct"

    // #2022: the C compiler proves an emitted record is TypeLayout's model
    // (with-abi.md §2): its size, its alignment and each field's offset. A
    // difference is a C compile error naming the type, never a program that
    // silently reads its fields elsewhere than the LLVM backend does. A
    // fact the model never registered is not asserted.
    fn layout_static_asserts(tid: i32, c_type: &str, field_names: &List[str]) -> str:
        let label = cc_escape_c_string(self.sema.type_name(tid))
        var out = ""
        let size_opt = self.sema.layout_size_cache.get(tid)
        if size_opt.is_some():
            out = out ++ f"_Static_assert(sizeof({c_type}) == {size_opt.unwrap()}, \"emit-c: " ++ label ++ f" is not TypeLayout's {size_opt.unwrap()} bytes\");\n"
        let align_opt = self.sema.layout_align_cache.get(tid)
        if align_opt.is_some():
            out = out ++ f"_Static_assert(_Alignof({c_type}) == {align_opt.unwrap()}, \"emit-c: " ++ label ++ f" is not TypeLayout's {align_opt.unwrap()}-byte alignment\");\n"
        for fi in 0..field_names.len():
            let offset_opt = self.sema.layout_field_offset_cache.get(sema_pair_key(tid, fi as i32))
            if offset_opt.is_some():
                out = out ++ f"_Static_assert(offsetof({c_type}, " ++ field_names[fi] ++ f") == {offset_opt.unwrap()}, \"emit-c: " ++ label ++ "." ++ field_names[fi] ++ f" is not at TypeLayout's offset {offset_opt.unwrap()}\");\n"
        out

    mut fn global_var_definition(decl: NodeId) -> str:
        let sym = self.ast.get_data0(decl)
        let tid = self.global_decl_tid(decl)
        if tid == 0:
            return ""
        let name = self.global_c_name(sym)
        var init = self.global_init_text(self.ast.get_data1(decl), tid, self.decl_source_text(decl))
        if init.len() == 0:
            // Storage only: the entry wrapper stores the initializer's value.
            var started = false
            for i in 0..self.global_init_syms.len():
                if self.global_init_syms[i] == sym:
                    started = true
            if not started:
                self.fail(f"emit-c: global '{cc_intern_resolve(self.intern, sym)}' has an initializer with no C constant form and no startup initializer")
                return ""
            init = self.global_zero_text(tid)
        "static " ++ self.c_decl(tid, name) ++ " = " ++ init ++ ";\n"

    // #1484: a global whose initializer has no C constant form (a shift, an
    // array or variant literal, a call) runs before `main`, in declaration
    // order (§9.1c), as the LLVM backend's __with_init_const_* helpers do.
    // MirBuilder lowers the initializer into a body of its own that joins the
    // module, so its types, callees, globals and literals are collected with
    // every other body's; the emitter writes it as a static function and the
    // entry wrapper stores its result. A global reached only from another
    // global's initializer is found by the next round.
    mut fn prepare_global_init_bodies():
        let prepared: HashMap[i32, i32] = HashMap.new()
        var grew = true
        while grew:
            grew = false
            let used_globals = self.collect_referenced_global_syms()
            for di in 0..self.ast.decl_count():
                if self.check_interrupted() != 0 or self.had_error != 0:
                    return
                if self.sema.decl_is_lazy_skipped(di):
                    continue
                let decl = self.ast.get_decl(di)
                if self.ast.kind(decl) != NodeKind.NK_LET_DECL:
                    continue
                let sym = self.ast.get_data0(decl)
                if prepared.contains(sym) or (self.ast.get_data2(decl) % 2 == 0 and not used_globals.contains(sym)):
                    continue
                prepared.insert(sym, 1)
                let tid = self.global_decl_tid(decl)
                let value = self.ast.get_data1(decl)
                if tid == 0 or self.global_init_text(value, tid, self.decl_source_text(decl)).len() > 0:
                    continue
                let init_sym = self.intern.intern("__with_init_global_" ++ cc_sanitize_ident(cc_intern_resolve(self.intern, sym)) ++ f"__{sym}")
                let saved_module = with_str_clone_ref(self.sema.current_module_path)
                self.sema.current_module_path = self.decl_source_path(decl)
                let body = self.lower_global_init_body(init_sym, value, tid)
                self.sema.current_module_path = saved_module
                let invalid = validate_use_after_kill(&body, &self.intern)
                if invalid.len() > 0:
                    self.fail(f"emit-c: the initializer of global '{cc_intern_resolve(self.intern, sym)}' lowered to invalid MIR: {invalid}")
                    return
                self.body_fn_map.insert(init_sym, 1)
                self.mir_mod.body_index_by_fn_sym.insert(init_sym, self.mir_mod.bodies.len() as i32)
                self.mir_mod.body_fn_syms.push(init_sym)
                self.mir_mod.bodies.push(body)
                self.global_init_syms.push(sym)
                self.global_init_decl_indices.push(di)
                self.global_init_fn_syms.push(init_sym)
                grew = true

    // The initializer as the body of `fn init_sym() -> tid`, lowered exactly
    // as Codegen.emit_module_runtime_init_fn lowers it for the LLVM backend.
    fn lower_global_init_body(init_sym: i32, value: i32, tid: i32) -> MirBody:
        var b = MirBuilder.init(self.sema, self.ast, self.intern, init_sym)
        b.body.local_type_ids[0] = tid
        b.push_scope()
        b.expected_type = tid
        let result = b.lower_expr(value)
        let ret_place = b.place_for_local(0)
        b.assign_operand_to_place(ret_place, result, self.ast.get_end(value))
        b.pop_scope_inline()
        b.terminate(TermKind.TK_RETURN, 0, 0, 0, 0)
        move b.body

    // Whether a global's initializer only computes its value: no call (a
    // panic is a call) but a list literal's construction (MIR's
    // COLLECTION_LITERAL into a List: it allocates and moves its elements,
    // which earlier statements made), no drop that runs a user Drop impl
    // (Sema's type_carries_user_drop; any other drop frees memory), no write
    // to a global. Skipping such a body when nothing reads its global is
    // unobservable. A set's or map's literal hashes its keys, which may run
    // user code.
    mut fn init_body_is_pure(body: &MirBody) -> bool:
        for bb in 0..body.block_count():
            let kind = body.term_kind(bb)
            if kind == TermKind.TK_CALL and not self.call_is_list_literal(body, body.term_data1(bb), body.term_data2(bb)): return false
            if kind == TermKind.TK_DROP_AND_GOTO and self.drop_runs_user_code(body, body.term_data0(bb)): return false
            let start = body.bb_stmt_starts[bb]
            for si in 0..body.bb_stmt_counts[bb]:
                let stmt_id = start + si
                if body.stmt_kinds[stmt_id] == StmtKind.Drop and self.drop_runs_user_code(body, body.stmt_d0[stmt_id]): return false
                if body.stmt_kinds[stmt_id] != StmtKind.Assign: continue
                if self.local_global_sym(body, self.place_local_id(body, body.stmt_d0[stmt_id])) != 0: return false
        true

    mut fn call_is_list_literal(body: &MirBody, args_id: i32, dest_place: i32) -> bool:
        if body.call_intrinsic(args_id) != MirIntrinsic.COLLECTION_LITERAL: return false
        self.generic_inst_base_name(self.sema.resolve_alias(self.place_tid(body, dest_place) as TypeId) as i32) == "List"

    // Whether dropping `place` runs a user Drop impl.
    mut fn drop_runs_user_code(body: &MirBody, place: i32) -> bool:
        let local = self.place_local_id(body, place)
        if local < 0 or local >= body.local_type_ids.len(): return true
        self.sema.type_carries_user_drop(body.local_type_ids[local]) != 0

    // The global an initializer body stores into, or 0 for any other body.
    fn global_init_target(fn_sym: i32) -> i32:
        for i in 0..self.global_init_fn_syms.len():
            if self.global_init_fn_syms[i] == fn_sym:
                return self.global_init_syms[i]
        0

    // An initializer body is `static void f(void)` and its return stores the
    // value into the global: C returns no arrays, and the value moves into
    // its storage byte for byte either way.
    fn global_init_return_text(fn_sym: i32) -> str:
        let g = self.global_c_name(self.global_init_target(fn_sym))
        "    memcpy(&" ++ g ++ ", &_0, sizeof(" ++ g ++ "));\n    return;"

    // The entry wrapper's calls, in declaration order (§9.1c).
    fn global_init_calls_text(skipped: &List[i32]) -> str:
        var out = ""
        for di in 0..self.ast.decl_count():
            for i in 0..self.global_init_decl_indices.len():
                if self.global_init_decl_indices[i] == di and not skipped.contains(self.global_init_fn_syms[i]):
                    out = out ++ "    " ++ self.fn_c_name(self.global_init_fn_syms[i]) ++ "();\n"
        out

    mut fn collect_referenced_global_syms() -> HashMap[i32, i32]:
        let used = HashMap[i32, i32].new()
        for bi in 0..self.mir_mod.bodies.len():
            if self.check_interrupted() != 0:
                return used
            let body = &self.mir_mod.bodies[bi]
            for li in 0..body.local_names.len():
                let sym = self.local_global_sym(body, li as i32)
                if sym != 0:
                    used.insert(sym, 1)
        used

    mut fn collect_referenced_fn_syms() -> HashMap[i32, i32]:
        let used = HashMap[i32, i32].new()
        for bi in 0..self.mir_mod.bodies.len():
            if self.check_interrupted() != 0:
                return used
            let body = &self.mir_mod.bodies[bi]
            for oi in 0..body.operand_kinds.len():
                if body.operand_kinds[oi] != OperandKind.OK_CONSTANT:
                    continue
                let const_id = body.operand_d0[oi]
                if const_id < 0 or const_id >= body.const_kinds.len():
                    continue
                if body.const_kinds[const_id] != ConstKind.CK_FN:
                    continue
                let fn_sym = body.const_d0[const_id]
                if fn_sym != 0:
                    used.insert(fn_sym, 1)
        used

    // Each global's definition and its C name ("" for an extern
    // declaration, always written): emit_module writes the ones the emitted
    // C names.
    mut fn global_var_defs() -> List[CGlobalDef]:
        var out: List[CGlobalDef] = List.new()
        let used_globals = self.collect_referenced_global_syms()
        if self.had_error != 0:
            return out
        for di in 0..self.ast.decl_count():
            if self.check_interrupted() != 0:
                return out
            if self.sema.decl_is_lazy_skipped(di):
                continue
            let decl = self.ast.get_decl(di)
            let kind = self.ast.kind(decl)
            if kind == NodeKind.NK_LET_DECL:
                let sym = self.ast.get_data0(decl)
                let flags = self.ast.get_data2(decl)
                if flags % 2 == 0 and not used_globals.contains(sym):
                    continue
                out.push(CGlobalDef { sym, name: self.global_c_name(sym), text: self.global_var_definition(decl) })
                continue
            if kind == NodeKind.NK_EXTERN_VAR:
                let sym = self.ast.get_data0(decl)
                let tid = self.global_decl_tid(decl)
                if tid == 0:
                    continue
                // stdio's globals are <stdio.h>'s (`FILE *__stdoutp`); a
                // `void*` redeclaration is a conflicting type, and the
                // emitted reads convert implicitly.
                if ci_libc_symbol_allowed_as(cc_intern_resolve(self.intern, sym), CI_LIBC_KIND_VAR):
                    continue
                out.push(CGlobalDef { sym, name: "", text: "extern " ++ self.c_decl(tid, self.global_c_name(sym)) ++ ";\n" })
        out

    mut fn emit_extern_fn_decl(decl: NodeId) -> str:
        let fn_sym = self.ast.get_data0(decl)
        let sig_idx = self.sig_index_for_sym(fn_sym)
        if sig_idx < 0:
            self.fail(f"emit-c: missing signature for extern fn {cc_intern_resolve(self.intern, fn_sym)}")
            return ""
        var params = ""
        let param_count = self.sema.sig_get_param_count(sig_idx)
        for i in 0..param_count:
            if i > 0:
                params = params ++ ", "
            let p_tid = self.sema.sig_param_type(sig_idx, i)
            if self.fn_param_is_c_pointer(fn_sym, i) != 0:
                params = params ++ self.c_type(p_tid, 0) ++ f"* _{i + 1}"
            else:
                params = params ++ self.c_decl(p_tid, f"_{i + 1}")
        // #1831: an unprototyped declaration stays unprototyped, so the C
        // compiler passes each call's promoted arguments with the
        // fixed-argument convention. (A C23 compiler reads `()` as `(void)`
        // and refuses a call with arguments — loud, never a wrong ABI.)
        if self.sema.sig_is_unprototyped(sig_idx):
            params = ""
        else if self.sema.sig_is_variadic(sig_idx) != 0:
            if param_count > 0:
                params = params ++ ", ..."
            else:
                params = "..."
        else:
            if param_count == 0:
                params = "void"
        let ret_tid = self.c_sig_return_type(sig_idx)
        let name = self.extern_sym_c_name(fn_sym) ++ "(" ++ params ++ ")"
        if self.type_is_pointer_to_array(ret_tid):
            return "extern " ++ self.c_decl(ret_tid, name) ++ ";\n"
        "extern " ++ self.c_type(ret_tid, 1) ++ " " ++ name ++ ";\n"

    // The with_* names the fixed block (emit_module_prelude's `extern …`
    // lines below) declares with their C spellings. The fiber entry points
    // are named one by one: the block declares five, and a `with_fiber_`
    // prefix here left every other fiber extern (std.task's coroutine calls
    // for g.pull()) with no prototype at all.
    // #2180 (§11.7, D96): how the runtime map hashes and compares a key,
    // as with_hashmap_new_keyed's last three arguments: 0, by its bytes (an
    // integer, a bool, a raw pointer); 1, as a `str`; 2, by the functions
    // generated for its type (key_hash_fn_name, key_eq_fn_name).
    mut fn map_key_args_text(key_tid: i32) -> str:
        let resolved = self.sema.resolve_alias(key_tid as TypeId) as i32
        let tk = self.sema.get_type_kind(resolved as TypeId)
        if tk == TypeKind.TY_STR or self.sema.type_layout_is_str_view(resolved): return "1, 0, 0"
        if tk == TypeKind.TY_INT or tk == TypeKind.TY_BOOL or tk == TypeKind.TY_PTR: return "0, 0, 0"
        let hash_fn = self.key_hash_fn_name(resolved)
        let eq_fn = self.key_eq_fn_name(resolved)
        "2, " ++ hash_fn ++ ", " ++ eq_fn

    fn prelude_block_declares(name: &str) -> bool:
        cc_str_starts_with(name, "with_str_") != 0 or cc_str_starts_with(name, "with_fmt_") != 0 or
        name == "with_fiber_in_fiber" or name == "with_fiber_await" or name == "with_fiber_cleanup_await" or
        name == "with_fiber_cancel" or name == "with_fiber_panic_capture" or cc_str_starts_with(name, "with_println_") != 0 or
        name == "with_alloc" or name == "with_alloc_aligned" or name == "with_free" or name == "with_memcpy" or name == "with_memmove" or
        name == "with_memset" or name == "with_memcmp" or name == "with_hashmap_get_ptr" or
        name == "with_hashmap_capacity" or name == "with_hashmap_slot_occupied" or
        name == "with_hashmap_key_ptr_at" or name == "with_hashmap_value_ptr_at" or name == "with_hashmap_take_at" or
        name == "with_clock_nanos" or name == "with_nanosleep" or name == "with_sysinfo_os" or
        name == "with_sysinfo_arch" or name == "with_sysinfo_hostname" or name == "with_eprint" or
        name == "with_write" or name == "with_ewrite" or name == "with_panic" or name == "with_bool_to_str" or
        name == "with_i64_to_str" or name == "with_runtime_configure_fibers" or name == "with_str"

    fn should_emit_extern_fn_decl(fn_sym: i32, referenced: &HashMap[i32, i32]) -> i32:
        if not referenced.contains(fn_sym):
            return 0
        let linked = self.extern_link_name(fn_sym)
        let name = if linked.len() > 0: linked else: self.canonical_extern_name(cc_intern_resolve(self.intern, fn_sym))
        // A with_* runtime function the fixed block below declares (the str,
        // fmt, memory and fiber entry points) is not redeclared; every other
        // with_* prototype comes from the With extern declaration itself, so
        // the emitted C never trusts runtime/with_runtime.h for a signature
        // the runtime has since changed (#1038: the fs/exec wrappers took
        // `&str` in 7d8d085e while the header still said `with_str`).
        if self.prelude_block_declares(name):
            return 0
        if cc_str_starts_with(name, "wl_") != 0:
            return 0
        if self.extern_declared_by_included_headers(name):
            return 0
        1

    // The header's spelling of a `c_char` pointer chain two or more deep,
    // "" for any other type. `c_char` is the target's i8 or u8 (D155),
    // which c_type spells int8_t or uint8_t where a header says `char`: C
    // converts `int8_t *` to `char *` with a warning, but `int8_t **` to
    // `char **` is an incompatible pointer type, an error under clang 22
    // on windows-gnu (#2769: strtoll's endptr in migrated mlib code).
    mut fn header_char_pointer_type(p_tid: i32) -> str:
        var depth = 0
        var cur = self.sema.resolve_alias(p_tid as TypeId)
        while self.sema.get_type_kind(cur) == TypeKind.TY_PTR:
            depth = depth + 1
            cur = self.sema.resolve_alias(self.sema.get_type_d0(cur) as TypeId)
        if depth < 2 or cur != self.sema.resolve_alias(self.sema.ty_c_char):
            return ""
        self.c_type(p_tid, 0).replace(self.c_type(self.sema.ty_c_char as i32, 0), "char")

    // A name the included libc headers declare is theirs: a With
    // spelling (`*const i8` for `char*`) never redeclares it. The
    // migrator's libc knowledge is the list.
    fn extern_declared_by_included_headers(name: &str) -> bool:
        if ci_libc_symbol_allowed_as(name, CI_LIBC_KIND_FN) or ci_libc_simple_rename(name).len() > 0 or ci_migrate_preamble_name_is_modeled_libc(name):
            return true
        if name == "malloc" or name == "free":
            return true
        // Runtime entry points with_runtime.h declares (in the runtime's
        // own signatures, rt_core.w): a second, emitted extern conflicted.
        if name == "with_arg_at" or name == "with_vec_get_ptr_es":
            return true
        if name == "mkstemp" or name == "strtod" or name == "realpath" or name == "getenv":
            return true
        if name == "strlen" or name == "strcmp" or name == "strncmp" or name == "memchr":
            return true
        if name == "strcpy" or name == "strncpy" or name == "strstr" or name == "strerror":
            return true
        if name == "strtol" or name == "strtoul":
            return true
        if name == "isalpha" or name == "isdigit" or name == "isalnum" or name == "isspace":
            return true
        if name == "isupper" or name == "islower" or name == "isxdigit" or name == "isprint":
            return true
        if name == "isgraph" or name == "ispunct" or name == "iscntrl" or name == "tolower" or name == "toupper":
            return true
        if name == "sqrt" or name == "pow" or name == "floor" or name == "ceil" or name == "round":
            return true
        if name == "sin" or name == "cos" or name == "tan" or name == "log" or name == "log10":
            return true
        if name == "exp" or name == "fabs" or name == "fmod" or name == "asin" or name == "acos":
            return true
        if name == "atan" or name == "atan2":
            return true
        if name == "fprintf" or name == "printf" or name == "snprintf" or name == "sprintf":
            return true
        if name == "fopen" or name == "fclose" or name == "fflush" or name == "fileno":
            return true
        if name == "fgets" or name == "fgetc" or name == "fputc" or name == "fputs" or name == "putc":
            return true
        if name == "feof" or name == "fread" or name == "fwrite":
            return true
        if name == "setlocale" or name == "exit" or name == "clock" or name == "time" or name == "isatty":
            return true
        if name == "getrlimit" or name == "setrlimit":
            return true
        if name == "rename" or name == "unlink" or name == "write" or name == "read" or name == "close":
            return true
        if name == "open" or name == "__open" or name == "gethostname" or name == "mkdir" or name == "rmdir":
            return true
        if name == "chmod" or name == "access" or name == "symlink":
            return true
        if name == "setenv" or name == "execv" or name == "execvp" or name == "chdir":
            return true
        false

    mut fn emit_extern_fn_decls() -> str:
        var out = ""
        let referenced = self.collect_referenced_fn_syms()
        for di in 0..self.ast.decl_count():
            if self.check_interrupted() != 0:
                return ""
            if self.sema.decl_is_lazy_skipped(di):
                continue
            let decl = self.ast.get_decl(di)
            // A runtime function the unit knows through the runtime's
            // interface (D30 step 3: std imports `rt.*`; the declaration has
            // an interface body) is a prototype here, as the `extern fn` it
            // replaced was: the C runtime defines it.
            let interface_fn = self.ast.kind(decl) == NodeKind.NK_FN_DECL and self.ast.fn_decl_body_is_interface(decl)
            if self.ast.kind(decl) != NodeKind.NK_EXTERN_FN and not interface_fn:
                continue
            if self.should_emit_extern_fn_decl(self.ast.get_data0(decl), referenced) == 0:
                continue
            out = out ++ self.emit_extern_fn_decl(decl)
        if out.len() > 0:
            out = out ++ "\n"
        out

    mut fn emit_fn_decl(body: &MirBody) -> str:
        let fn_sym = body.fn_sym
        let fn_name = self.fn_c_name(fn_sym)
        if self.global_init_target(fn_sym) != 0:
            return "static void " ++ fn_name ++ "(void)"
        let sig_idx = self.body_sig_index(fn_sym)
        let ret_tid = if sig_idx >= 0: self.c_sig_return_type(sig_idx) else:
            if body.local_type_ids.len() > 0: body.local_type_ids[0] else: self.sema.ty_void
        var params = ""
        let param_count = if sig_idx >= 0: self.sema.sig_get_param_count(sig_idx) else: 0
        for i in 0..param_count:
            if i > 0:
                params = params ++ ", "
            let p_tid = self.sema.sig_param_type(sig_idx, i)
            if self.fn_param_is_c_pointer(fn_sym, i) != 0:
                params = params ++ self.c_type(p_tid, 0) ++ f"* _{i + 1}"
            else:
                params = params ++ self.c_decl(p_tid, f"_{i + 1}")
        // D75 (§16.2b.5): a `...` definition is a C variadic function.
        if sig_idx >= 0 and self.sema.sig_is_variadic(sig_idx) != 0:
            if param_count == 0:
                self.fail(f"emit-c: variadic definition {fn_name} has no named parameter, which C before C23 cannot express")
            params = params ++ ", ..."
        // #1775/#1817 (array_out_param): a named function's out-pointer
        // leads; there is no context before it.
        let out_param = self.array_out_param(ret_tid, true, false)
        if out_param.len() > 0:
            params = if params.len() > 0: out_param ++ ", " ++ params else: out_param
        let decl = self.return_decl(ret_tid, fn_name ++ "(" ++ params ++ ")")
        // A function under its mangled name is the program's own: nothing
        // outside this translation unit can name it, so it is `static`, and
        // clang neither generates nor optimizes one nothing calls. Every
        // emitted program carries the whole standard library (pcre2
        // included, about 24 MB of C), and with external linkage each was
        // compiled in full at -O1. An export name or a public runtime-ABI
        // name (cc_is_public_abi_name) keeps external linkage.
        if self.fn_c_name_is_internal(fn_sym): "static " ++ decl else: decl

    mut fn prepare_c_type_instantiations():
        for i in 0..self.mir_mod.bodies.len():
            if self.check_interrupted() != 0:
                return
            let body = self.mir_body_at(i as i64)
            for bb in 0..body.block_count():
                if body.term_kind(bb) != TermKind.TK_CALL:
                    continue
                let args_id = body.term_data1(bb)
                if body.call_intrinsic(args_id) != MirIntrinsic.MAP_GET:
                    continue
                let recv_operand = self.call_arg_operand(body, args_id, 0)
                let recv_tid = self.operand_tid_no_infer(body, recv_operand)
                let value_tid = self.hashmap_value_tid(recv_tid)
                if value_tid != 0 and self.is_void_tid(value_tid) == 0:
                    let _ = self.option_ref_tid_for_payload(value_tid)
                let dest_place = body.term_data2(bb)
                let dst_tid = self.place_local_tid(body, dest_place)
                if dst_tid != 0 and self.is_void_tid(dst_tid) == 0 and self.is_scalar_like_tid(dst_tid) == 0:
                    let _ = self.option_ref_tid_for_payload(dst_tid)

    mut fn local_receives_ref(body: &MirBody, local_id: i32) -> bool:
        self.local_ref_target_tid(body, local_id) != 0

    // Index `body`'s direct assignments by destination local, once per body.
    mut fn ensure_assign_index(body: &MirBody):
        if self.assign_index_sym == body.fn_sym and self.assign_index_len == body.stmt_kinds.len(): return
        let n = body.local_count()
        var starts = cc_zero_i32_list(n + 1)
        for bb in 0..body.block_count():
            let start = body.bb_stmt_starts[bb]
            for si in 0..body.bb_stmt_counts[bb]:
                let local = cc_direct_assign_local(body, start + si)
                if local >= 0: starts[local + 1] += 1
        for k in 0..n: starts[k + 1] += starts[k]
        var fill = starts.clone()
        var stmts = cc_zero_i32_list(starts[n])
        for bb in 0..body.block_count():
            let start = body.bb_stmt_starts[bb]
            for si in 0..body.bb_stmt_counts[bb]:
                let local = cc_direct_assign_local(body, start + si)
                if local < 0: continue
                stmts[fill[local]] = start + si
                fill[local] += 1
        self.assign_starts = starts
        self.assign_stmts = stmts
        self.assign_index_sym = body.fn_sym
        self.assign_index_len = body.stmt_kinds.len()

    mut fn local_ref_target_tid(body: &MirBody, local_id: i32) -> i32:
        if local_id < 0:
            return 0
        let cache_key = cc_body_local_cache_key(body.fn_sym, local_id)
        let cached = self.local_ref_target_cache.get(cache_key)
        if cached.is_some():
            let value = cached.unwrap()
            if value < 0:
                return 0
            return value
        self.local_ref_target_cache.insert(cache_key, -1)
        var out: i32 = 0
        // Only this local's own assignments: a scan of every statement per
        // local was quadratic in the body (2026-10-14: 63% of emitting a
        // one-line program's C, every program carrying all of std).
        self.ensure_assign_index(body)
        if local_id >= body.local_count(): return 0
        for ai in self.assign_starts[local_id]..self.assign_starts[local_id + 1]:
            let stmt_id = self.assign_stmts[ai]
            let rval_id = body.stmt_d1[stmt_id]
            if rval_id < 0 or rval_id >= body.rval_kinds.len():
                continue
            let rk = body.rval_kinds[rval_id]
            var src_place: i32 = -1
            if rk == RvalueKind.RK_REF:
                // A `&str` view is the str's {ptr, len}, not a pointer
                // to the place it was read from (#1810).
                if self.ref_rvalue_is_str_view(body, rval_id):
                    continue
                src_place = body.rval_d1[rval_id]
            else if rk == RvalueKind.RK_ADDR_OF:
                src_place = body.rval_d0[rval_id]
            else if rk == RvalueKind.RK_USE:
                let src_operand = body.rval_d0[rval_id]
                if src_operand < 0 or src_operand >= body.operand_kinds.len():
                    continue
                let ok = body.operand_kinds[src_operand]
                if ok != OperandKind.OK_COPY and ok != OperandKind.OK_MOVE:
                    continue
                let copied_place = body.operand_d0[src_operand]
                let copied_local = self.place_local_id(body, copied_place)
                if copied_local == local_id:
                    continue
                if self.place_is_direct_local(body, copied_place, copied_local) == 0:
                    continue
                let copied_tid = self.local_ref_target_tid(body, copied_local)
                if copied_tid == 0 or self.is_void_tid(copied_tid) != 0:
                    continue
                if out == 0:
                    out = copied_tid
                else if self.strict_type_match(out, copied_tid) == 0:
                    self.local_ref_target_cache.insert(cache_key, -1)
                    return 0
                continue
            else:
                continue
            let src_tid = self.place_ref_target_tid(body, src_place)
            if src_tid == 0 or self.is_void_tid(src_tid) != 0:
                continue
            if out == 0:
                out = src_tid
            else if self.strict_type_match(out, src_tid) == 0:
                self.local_ref_target_cache.insert(cache_key, -1)
                return 0
        if out == 0:
            self.local_ref_target_cache.insert(cache_key, -1)
        else:
            self.local_ref_target_cache.insert(cache_key, out)
        out

    mut fn local_receives_arith(body: &MirBody, local_id: i32) -> bool:
        for bb in 0..body.block_count():
            // Check statements
            let start = body.bb_stmt_starts[bb]
            let count = body.bb_stmt_counts[bb]
            for si in 0..count:
                let stmt_id = start + si
                if body.stmt_kinds[stmt_id] != StmtKind.Assign:
                    continue
                let dst_place = body.stmt_d0[stmt_id]
                if self.place_is_direct_local(body, dst_place, local_id) == 0:
                    continue
                let rval_id = body.stmt_d1[stmt_id]
                if rval_id < 0 or rval_id >= body.rval_kinds.len():
                    continue
                let rk = body.rval_kinds[rval_id]
                if rk == RvalueKind.RK_BIN_OP:
                    let op = body.rval_d0[rval_id]
                    if op != BinaryOp.OP_CONCAT:
                        return true
            // Check terminators: if this local is the dest of a map-get call, it's int64
            let tk = body.term_kind(bb)
            if tk == TermKind.TK_CALL:
                let dest_place = body.term_data2(bb)
                if self.place_is_direct_local(body, dest_place, local_id) != 0:
                    let callee_op = body.term_data0(bb)
                    let args_id = body.term_data1(bb)
                    let kind = self.call_builtin_kind(body, callee_op, args_id, dest_place)
                    if kind == CcBuiltin.MAP_GET or kind == CcBuiltin.MAP_CONTAINS or kind == CcBuiltin.MAP_LEN:
                        if kind == CcBuiltin.MAP_GET:
                            let ret_tid = self.call_return_tid(body, bb, callee_op, args_id, dest_place)
                            if self.type_is_payload_enum(ret_tid) != 0:
                                continue
                        return true
        false

    fn operand_is_int_const(body: &MirBody, operand_id: i32, value: i64) -> bool:
        let _ = self
        if operand_id < 0 or operand_id >= body.operand_kinds.len():
            return false
        if body.operand_kinds[operand_id] != OperandKind.OK_CONSTANT:
            return false
        let const_id = body.operand_d0[operand_id]
        if const_id < 0 or const_id >= body.const_kinds.len():
            return false
        let ck = body.const_kinds[const_id]
        if ck != ConstKind.CK_INT and ck != ConstKind.CK_INT_EXACT:
            return false
        mir_const_int_value(body, const_id) == value

    mut fn local_originates_from_map_get_depth(body: &MirBody, local_id: i32, depth: i32) -> bool:
        if local_id < 0 or depth > 8:
            return false
        for bb in 0..body.block_count():
            if body.term_kind(bb) == TermKind.TK_CALL:
                let dest_place = body.term_data2(bb)
                if self.place_is_direct_local(body, dest_place, local_id) != 0:
                    let callee_op = body.term_data0(bb)
                    let args_id = body.term_data1(bb)
                    let intrinsic_kind = cc_builtin_from_mir_intrinsic(body.call_intrinsic(args_id))
                    let kind = if intrinsic_kind != CcBuiltin.NONE:
                        intrinsic_kind
                    else:
                        self.call_builtin_kind(body, callee_op, args_id, dest_place)
                    if kind == CcBuiltin.MAP_GET:
                        return true
            let start = body.bb_stmt_starts[bb]
            let count = body.bb_stmt_counts[bb]
            for si in 0..count:
                let stmt_id = start + si
                if body.stmt_kinds[stmt_id] != StmtKind.Assign:
                    continue
                let dst_place = body.stmt_d0[stmt_id]
                if self.place_is_direct_local(body, dst_place, local_id) == 0:
                    continue
                let src_local = self.rvalue_direct_local_id(body, body.stmt_d1[stmt_id])
                if src_local >= 0 and src_local != local_id and self.local_originates_from_map_get_depth(body, src_local, depth + 1):
                    return true
        false

    mut fn local_originates_from_map_get(body: &MirBody, local_id: i32) -> bool:
        self.local_originates_from_map_get_depth(body, local_id, 0)

    mut fn local_used_as_list_receiver(body: &MirBody, local_id: i32) -> bool:
        if local_id < 0:
            return false
        for bb in 0..body.block_count():
            if body.term_kind(bb) != TermKind.TK_CALL:
                continue
            let callee_op = body.term_data0(bb)
            let args_id = body.term_data1(bb)
            let dest_place = body.term_data2(bb)
            var kind = cc_builtin_from_mir_intrinsic(body.call_intrinsic(args_id))
            if kind == CcBuiltin.NONE:
                kind = self.call_builtin_kind(body, callee_op, args_id, dest_place)
            if not cc_builtin_uses_list_receiver(kind):
                continue
            let recv_place = self.call_first_arg_place_id(body, args_id)
            if self.place_is_direct_local(body, recv_place, local_id) != 0:
                return true
        false

    mut fn local_used_as_option_receiver(body: &MirBody, local_id: i32) -> bool:
        if local_id < 0:
            return false
        for bb in 0..body.block_count():
            if body.term_kind(bb) != TermKind.TK_CALL:
                continue
            let callee_op = body.term_data0(bb)
            let args_id = body.term_data1(bb)
            let dest_place = body.term_data2(bb)
            var kind = cc_builtin_from_mir_intrinsic(body.call_intrinsic(args_id))
            if kind == CcBuiltin.NONE:
                kind = self.call_builtin_kind(body, callee_op, args_id, dest_place)
            if not cc_builtin_uses_option_receiver(kind):
                continue
            let recv_place = self.call_first_arg_place_id(body, args_id)
            if self.place_is_direct_local(body, recv_place, local_id) != 0:
                return true
        false

fn cc_mark_local_repr(flags_in: List[i32], local_id: i32, mark: i32) -> List[i32]:
    var flags = flags_in
    if local_id < 0 or local_id >= flags.len():
        return flags
    let existing = flags[local_id]
    if mark == 2 or existing == 0:
        let slot_index = local_id as i64
        with flags.slot(slot_index) as mut slot:
            slot.set(mark)
    flags

impl CCodegen:
    mut fn encoded_option_local_flags(body: &MirBody) -> List[i32]:
        var flags: List[i32] = List.new()
        for _i in 0..body.local_count():
            flags.push(0)

        for bb in 0..body.block_count():
            if body.term_kind(bb) == TermKind.TK_CALL:
                let callee_op = body.term_data0(bb)
                let args_id = body.term_data1(bb)
                let dest_place = body.term_data2(bb)
                var kind = cc_builtin_from_mir_intrinsic(body.call_intrinsic(args_id))
                if kind == CcBuiltin.NONE:
                    kind = self.call_builtin_kind(body, callee_op, args_id, dest_place)
                let recv_place = self.call_first_arg_place_id(body, args_id)
                let recv_local = self.place_local_id(body, recv_place)
                if self.place_is_direct_local(body, recv_place, recv_local) != 0:
                    if cc_builtin_uses_list_receiver(kind):
                        flags = cc_mark_local_repr(move flags, recv_local, 2)
                    else if cc_builtin_uses_option_receiver(kind):
                        flags = cc_mark_local_repr(move flags, recv_local, 1)

            let start = body.bb_stmt_starts[bb]
            let count = body.bb_stmt_counts[bb]
            for si in 0..count:
                let stmt_id = start + si
                if body.stmt_kinds[stmt_id] != StmtKind.Assign:
                    continue
                let rval_id = body.stmt_d1[stmt_id]
                if rval_id < 0 or rval_id >= body.rval_kinds.len():
                    continue
                if body.rval_kinds[rval_id] != RvalueKind.RK_BIN_OP:
                    continue
                let op = body.rval_d0[rval_id]
                if op != BinaryOp.OP_SUB and op != BinaryOp.OP_NEQ and op != BinaryOp.OP_EQ:
                    continue
                let lhs = body.rval_d1[rval_id]
                let rhs = body.rval_d2[rval_id]
                if op == BinaryOp.OP_SUB and self.operand_is_int_const(body, rhs, 1):
                    flags = cc_mark_local_repr(move flags, self.operand_direct_local_id(body, lhs), 1)
                else if op == BinaryOp.OP_NEQ or op == BinaryOp.OP_EQ:
                    if self.operand_is_int_const(body, rhs, 0):
                        flags = cc_mark_local_repr(move flags, self.operand_direct_local_id(body, lhs), 1)
                    if self.operand_is_int_const(body, lhs, 0):
                        flags = cc_mark_local_repr(move flags, self.operand_direct_local_id(body, rhs), 1)
        flags

    mut fn local_used_as_encoded_option(body: &MirBody, local_id: i32) -> bool:
        if local_id < 0:
            return false
        if self.local_used_as_list_receiver(body, local_id):
            return false
        if self.local_used_as_option_receiver(body, local_id):
            return true
        for bb in 0..body.block_count():
            let start = body.bb_stmt_starts[bb]
            let count = body.bb_stmt_counts[bb]
            for si in 0..count:
                let stmt_id = start + si
                if body.stmt_kinds[stmt_id] != StmtKind.Assign:
                    continue
                let rval_id = body.stmt_d1[stmt_id]
                if rval_id < 0 or rval_id >= body.rval_kinds.len():
                    continue
                let rk = body.rval_kinds[rval_id]
                if rk != RvalueKind.RK_BIN_OP:
                    continue
                let op = body.rval_d0[rval_id]
                if op != BinaryOp.OP_SUB and op != BinaryOp.OP_NEQ and op != BinaryOp.OP_EQ:
                    continue
                let lhs = body.rval_d1[rval_id]
                let rhs = body.rval_d2[rval_id]
                if op == BinaryOp.OP_SUB and self.operand_uses_local(body, lhs, local_id) != 0 and self.operand_is_int_const(body, rhs, 1):
                    return true
                if (op == BinaryOp.OP_NEQ or op == BinaryOp.OP_EQ) and self.operand_uses_local(body, lhs, local_id) != 0 and self.operand_is_int_const(body, rhs, 0):
                    return true
                if (op == BinaryOp.OP_NEQ or op == BinaryOp.OP_EQ) and self.operand_uses_local(body, rhs, local_id) != 0 and self.operand_is_int_const(body, lhs, 0):
                    return true
        false

    // ── #1766: closures ────────────────────────────────────────────────
    //
    // The retained MIR body is the closure's whole contract (D65: Sema
    // decided the captures, MirLower their sources): locals 1..captures are
    // its captures, the rest of its parameters follow, `_0` its result. The
    // C lowering is the LLVM backend's (CodegenDispatch.gen_closure):
    //   static R __with_closure_N(void* ctx, params...)
    // and the value is the fat pair {fn, ctx} of the fn type, whose
    // context word's low two bits say what it holds (D63):
    //   00  a `struct __with_env_N` of pointers to the creating frame's
    //       slots (a non-move closure captures by place, §12.4), or null;
    //   01  a `move` closure's environment inline in the upper 62 bits
    //       (every capture Copy, at most 7 bytes);
    //   10  a `struct __with_cell_N` {drop_fn, clone_fn, env} the value
    //       owns on the heap (a `move` closure otherwise).
    // A call through the pair is callee.fn_ptr(callee.ctx, args...), as
    // for a named function's thunk (fat_fn_literal).

    // Locals 1..count are a body's parameters: the signature's for a named
    // function, the retained MIR's (captures, then parameters) for a closure.
    fn body_param_count(body: &MirBody) -> i32:
        if body.anonymous_type != 0:
            return body.n_params
        let sig_idx = self.body_sig_index(body.fn_sym)
        if sig_idx >= 0: self.sema.sig_get_param_count(sig_idx) else: 0

    fn closure_fn_name(idx: i32) -> str:
        let _ = self
        f"__with_closure_{idx}"

    fn closure_env_struct(idx: i32) -> str:
        let _ = self
        f"struct __with_env_{idx}"

    fn closure_cell_struct(idx: i32) -> str:
        let _ = self
        f"struct __with_cell_{idx}"

    fn closure_body_at(idx: i32) -> &MirBody:
        self.mir_body_at(self.mir_mod.find_body(self.closure_syms[idx]) as i64)

    // "path:line" of an AST node, for a diagnostic that names a construct.
    fn node_site_text(node: i32) -> str:
        let file_id = self.sema.ast.file(node as NodeId) as i32
        var path = self.source_path.clone()
        for si in 0..self.sema.source_text_file_ids.len():
            if self.sema.source_text_file_ids[si] == file_id:
                path = self.sema.source_text_names[si].clone()
        let line = self.sema.source_location_for_file_id(file_id, self.ast.get_start(node)).line + 1
        f"{path}:{line}"

    // Register every CK_CLOSURE constant of the module, in body then
    // constant order, so closure numbering is deterministic, and decide
    // each one's environment kind from the facts Sema recorded on its node.
    mut fn register_closures():
        for bi in 0..self.mir_mod.bodies.len():
            let body = self.mir_body_at(bi as i64)
            for ci in 0..body.const_kinds.len():
                if body.const_kinds[ci] != ConstKind.CK_CLOSURE:
                    continue
                let sym = body.const_d1[ci]
                if self.closure_index_by_sym.contains(sym):
                    continue
                let node = body.const_d0[ci]
                let site = self.node_site_text(node) ++ " in " ++ cc_intern_resolve(self.intern, body.fn_sym)
                let body_idx = self.mir_mod.find_body(sym)
                if body_idx < 0:
                    self.fail(f"emit-c: the closure at {site} has no retained MIR body")
                    return
                let closure_body = self.mir_body_at(body_idx as i64)
                let kind = self.sema.get_type_kind(self.sema.resolve_alias(closure_body.anonymous_type))
                if kind == TypeKind.TY_EXTERN_FN:
                    self.fail(f"emit-c does not support a closure used as a C function pointer ({site})")
                    return
                if kind != TypeKind.TY_FN:
                    self.fail(f"emit-c: the closure at {site} has a non-callable type")
                    return
                let env_kind = self.closure_env_kind_for(closure_body, node)
                self.closure_index_by_sym.insert(sym, self.closure_syms.len() as i32)
                self.closure_syms.push(sym)
                self.closure_parents.push(body.fn_sym)
                self.closure_nodes.push(node)
                self.closure_in_loop.push(body.const_d2[ci])
                self.closure_env_kinds.push(env_kind)

    // §12.4 / D62: a non-move closure captures every value by place, Copy
    // or not; `move ||` owns its environment — inline in the context word
    // when every capture is Copy and the environment fits, else a heap
    // cell. The C struct layout is computed the way C lays it out.
    mut fn closure_env_kind_for(body: &MirBody, node: i32) -> i32:
        let count = body.anonymous_capture_count
        if count == 0:
            return CC_CLOSURE_ENV_NONE
        // Sema's capture record decides (D62, D65), not the spelling.
        if not self.sema.closure_env_owned(node):
            return CC_CLOSURE_ENV_BY_PLACE
        var offset: i64 = 0
        var max_align: i64 = 1
        for ci in 0..count:
            let tid = body.local_type_ids[ci + 1]
            if self.sema.is_copy_frozen(tid as TypeId) == 0:
                return CC_CLOSURE_ENV_CELL
            let align = self.sema.type_layout_align_of_frozen(tid)
            let size = self.sema.type_layout_size_of_frozen(tid)
            if align > max_align: max_align = align
            offset = (offset + align - 1) / align * align + size
        let env_size = (offset + max_align - 1) / max_align * max_align
        if env_size <= 7: CC_CLOSURE_ENV_INLINE else: CC_CLOSURE_ENV_CELL

    // A capture by place or in an owned cell is a local holding a pointer
    // to its value (the LLVM backend's indirect local): it reads as (*_N).
    fn local_is_indirect_capture(body: &MirBody, local_id: i32) -> bool:
        if body.anonymous_type == 0 or local_id < 1 or local_id > body.anonymous_capture_count:
            return false
        if not self.closure_index_by_sym.contains(body.fn_sym):
            return false
        let kind: i32 = self.closure_env_kinds[self.closure_index_by_sym.get(body.fn_sym).unwrap()]
        kind == CC_CLOSURE_ENV_BY_PLACE or kind == CC_CLOSURE_ENV_CELL

    // The owned cell is clonable when every capture is Copy or a str
    // (CodegenDispatch.gen_closure_env_clone_fn); otherwise clone_fn is null.
    fn closure_cell_clonable(idx: i32) -> bool:
        let body = self.closure_body_at(idx)
        for ci in 0..body.anonymous_capture_count:
            let tid = body.local_type_ids[ci + 1]
            if self.sema.is_copy_frozen(tid as TypeId) == 0 and self.sema.get_type_kind(self.sema.resolve_alias(tid)) != TypeKind.TY_STR:
                return false
        true

    mut fn closure_fn_sig(idx: i32) -> str:
        let body = self.closure_body_at(idx)
        let ret_tid = body.local_type_ids[0]
        // #1817: the array out-pointer after the context, as the fat
        // typedef declares it; TK_RETURN copies `_0` into it.
        var params = "void* __with_ctx" ++ self.array_out_param(ret_tid, true, true)
        for pi in body.anonymous_capture_count..body.n_params:
            let li = pi + 1
            params = params ++ ", " ++ self.c_decl(body.local_type_ids[li], f"_{li}")
        self.return_decl(ret_tid, self.closure_fn_name(idx) ++ "(" ++ params ++ ")")

    // Every closure's environment struct, owned-cell struct and glue, and
    // prototype: before any body, since a body creates or runs them.
    mut fn emit_closure_decls() -> str:
        var out = ""
        var any_inline = false
        for idx in 0..self.closure_syms.len() as i32:
            if self.check_interrupted() != 0:
                return ""
            let body = self.closure_body_at(idx)
            let kind: i32 = self.closure_env_kinds[idx]
            let count = body.anonymous_capture_count
            let env = self.closure_env_struct(idx)
            let name = self.closure_fn_name(idx)
            if kind != CC_CLOSURE_ENV_NONE:
                out = out ++ env ++ " " ++ cc_lbrace()
                for ci in 0..count:
                    let tid = body.local_type_ids[ci + 1]
                    let field = f"c{ci}"
                    let decl = if kind == CC_CLOSURE_ENV_BY_PLACE: self.c_decl(tid, "(*" ++ field ++ ")") else: self.c_decl(tid, field)
                    out = out ++ " " ++ decl ++ ";"
                out = out ++ " " ++ cc_rbrace() ++ ";\n"
            if kind == CC_CLOSURE_ENV_INLINE:
                any_inline = true
            if kind == CC_CLOSURE_ENV_CELL:
                let cell = self.closure_cell_struct(idx)
                out = out ++ cell ++ " " ++ cc_lbrace() ++ " void (*drop_fn)(void*); void* (*clone_fn)(void*); " ++ env ++ " env; " ++ cc_rbrace() ++ ";\n"
                // The cell's drop drops every capture that needs it (guarded:
                // a consuming body blanks the slot it moved out of), then
                // frees the cell (gen_closure_env_drop_fn).
                var drops = ""
                for ci in 0..count:
                    let call = self.drop_call_text(f"c->env.c{ci}", body.local_type_ids[ci + 1], true)
                    if call.len() > 0:
                        drops = drops ++ " " ++ call
                out = out ++ "static void " ++ name ++ "_drop(void* cell) " ++ cc_lbrace() ++ " " ++ cell ++ "* c = (" ++ cell ++ "*)cell; (void)c;" ++ drops ++ " with_free(cell); " ++ cc_rbrace() ++ "\n"
                if self.closure_cell_clonable(idx):
                    out = out ++ "static void* " ++ name ++ "_clone(void* old) " ++ cc_lbrace() ++ " " ++ cell ++ "* c = (" ++ cell ++ "*)with_alloc_aligned((int64_t)sizeof(" ++ cell ++ "), (int64_t)_Alignof(" ++ cell ++ ")); memcpy(c, old, sizeof(" ++ cell ++ "));"
                    // D111: the clone is one more holder of every capture.
                    for ci in 0..count:
                        let call = self.copy_call_text(f"c->env.c{ci}", body.local_type_ids[ci + 1])
                        if call.len() > 0:
                            out = out ++ " " ++ call
                    out = out ++ " return c; " ++ cc_rbrace() ++ "\n"
            out = out ++ "static " ++ self.closure_fn_sig(idx) ++ ";\n"
        if any_inline:
            out = "static inline void* __with_closure_inline_ctx(const void* env, size_t n) " ++ cc_lbrace() ++ " uint64_t w = 0; memcpy(&w, env, n); return (void*)(uintptr_t)((w << 2) | 1u); " ++ cc_rbrace() ++ "\n" ++ out
        if out.len() > 0:
            out = out ++ "\n"
        out

    // A creating body's frame storage for each by-place environment it
    // builds outside a loop; inside a loop the site allocates per creation
    // (#1471), and an owned environment lives in the word or on the heap.
    fn closure_env_locals_text(body: &MirBody) -> str:
        var out = ""
        for idx in 0..self.closure_syms.len():
            if self.closure_parents[idx] != body.fn_sym:
                continue
            if self.closure_env_kinds[idx] != CC_CLOSURE_ENV_BY_PLACE or self.closure_in_loop[idx] != 0:
                continue
            out = out ++ "    " ++ self.closure_env_struct(idx as i32) ++ f" __with_env_{idx}_s __attribute__((unused));\n"
        out

    // The pair for a CK_CLOSURE constant of `body`: a GNU statement
    // expression that builds the environment from the creating body's
    // locals (the capture sources MirLower resolved) and yields the pair.
    mut fn closure_value_text(body: &MirBody, const_id: i32) -> str:
        let sym = body.const_d1[const_id]
        if not self.closure_index_by_sym.contains(sym):
            self.fail(f"emit-c: closure at node {body.const_d0[const_id]} of {cc_intern_resolve(self.intern, body.fn_sym)} was not registered")
            return "0"
        let idx: i32 = self.closure_index_by_sym.get(sym).unwrap()
        let closure_body = self.closure_body_at(idx)
        let pair_ty = self.fn_type_c_name(body.const_types[const_id])
        let fn_name = self.closure_fn_name(idx)
        let kind: i32 = self.closure_env_kinds[idx]
        let count = closure_body.anonymous_capture_count
        if kind == CC_CLOSURE_ENV_NONE:
            return "((" ++ pair_ty ++ ")" ++ cc_lbrace() ++ " " ++ fn_name ++ ", 0 " ++ cc_rbrace() ++ ")"
        let env = self.closure_env_struct(idx)
        var out = "(" ++ cc_lbrace()
        if kind == CC_CLOSURE_ENV_BY_PLACE:
            if self.closure_in_loop[idx] != 0:
                out = out ++ " " ++ env ++ "* __with_env = (" ++ env ++ "*)__builtin_alloca(sizeof(" ++ env ++ "));"
            else:
                out = out ++ " " ++ env ++ f"* __with_env = &__with_env_{idx}_s;"
            for ci in 0..count:
                let src = self.local_base_text(body, closure_body.anonymous_capture_sources[ci])
                out = out ++ f" __with_env->c{ci} = (__typeof__(__with_env->c{ci}))&(" ++ src ++ ");"
            return out ++ " (" ++ pair_ty ++ ")" ++ cc_lbrace() ++ " " ++ fn_name ++ ", (void*)__with_env " ++ cc_rbrace() ++ "; " ++ cc_rbrace() ++ ")"
        if kind == CC_CLOSURE_ENV_INLINE:
            out = out ++ " " ++ env ++ " __with_env;"
            for ci in 0..count:
                let src = self.local_base_text(body, closure_body.anonymous_capture_sources[ci])
                out = out ++ f" memcpy(&__with_env.c{ci}, &(" ++ src ++ f"), sizeof(__with_env.c{ci}));"
            return out ++ " (" ++ pair_ty ++ ")" ++ cc_lbrace() ++ " " ++ fn_name ++ ", __with_closure_inline_ctx(&__with_env, sizeof(__with_env)) " ++ cc_rbrace() ++ "; " ++ cc_rbrace() ++ ")"
        let cell = self.closure_cell_struct(idx)
        out = out ++ " " ++ cell ++ "* __with_cell = (" ++ cell ++ "*)with_alloc_aligned((int64_t)sizeof(" ++ cell ++ "), (int64_t)_Alignof(" ++ cell ++ "));"
        out = out ++ " __with_cell->drop_fn = " ++ fn_name ++ "_drop;"
        out = out ++ " __with_cell->clone_fn = " ++ (if self.closure_cell_clonable(idx): fn_name ++ "_clone;" else: "0;")
        for ci in 0..count:
            let src = self.local_base_text(body, closure_body.anonymous_capture_sources[ci])
            out = out ++ f" memcpy(&__with_cell->env.c{ci}, &(" ++ src ++ f"), sizeof(__with_cell->env.c{ci}));"
            // D63 / §2.5: `move ||` transfers ownership — the outer binding
            // is reset so its own drop frees nothing (MirLower marks it moved).
            if self.sema.type_needs_drop_frozen(closure_body.local_type_ids[ci + 1]) != 0:
                out = out ++ " memset(&(" ++ src ++ "), 0, sizeof(" ++ src ++ "));"
        out ++ " (" ++ pair_ty ++ ")" ++ cc_lbrace() ++ " " ++ fn_name ++ ", (void*)((uintptr_t)__with_cell | 2u) " ++ cc_rbrace() ++ "; " ++ cc_rbrace() ++ ")"

    // Closure N's static C function: the context decoded into its capture
    // locals, then the body like any other.
    mut fn emit_closure_body(idx: i32) -> str:
        let body = self.closure_body_at(idx)
        // Line directives, frozen name resolution and the instance
        // substitution follow the named function the closure sits in,
        // through any enclosing closures.
        let parent = self.body_owner_sym(self.closure_parents[idx])
        self.enter_line_file(parent)
        let decl_path = self.sema.fn_body_source_path(parent)
        if decl_path.len() > 0:
            self.sema.current_module_path = decl_path
        let kind: i32 = self.closure_env_kinds[idx]
        let count = body.anonymous_capture_count
        let env = self.closure_env_struct(idx)
        var prologue = ""
        if kind == CC_CLOSURE_ENV_NONE:
            prologue = "    (void)__with_ctx;\n"
        else if kind == CC_CLOSURE_ENV_BY_PLACE:
            prologue = "    " ++ env ++ "* __with_env = (" ++ env ++ "*)__with_ctx;\n"
            for ci in 0..count:
                let li = ci + 1
                prologue = prologue ++ "    " ++ self.c_decl(body.local_type_ids[li], f"(*_{li})") ++ f" __attribute__((unused)) = __with_env->c{ci};\n"
        else if kind == CC_CLOSURE_ENV_INLINE:
            prologue = "    uint64_t __with_env_word = ((uint64_t)(uintptr_t)__with_ctx) >> 2;\n"
            prologue = prologue ++ "    " ++ env ++ "* __with_env = (" ++ env ++ "*)&__with_env_word;\n"
            for ci in 0..count:
                let li = ci + 1
                prologue = prologue ++ "    " ++ self.c_decl(body.local_type_ids[li], f"_{li}") ++ " __attribute__((unused));\n"
                prologue = prologue ++ f"    memcpy(&_{li}, &__with_env->c{ci}, sizeof(_{li}));\n"
        else:
            // The cell's slot IS the local: reads, writes and a consuming
            // body's reset all land in the cell.
            prologue = "    " ++ env ++ "* __with_env = &((" ++ self.closure_cell_struct(idx) ++ "*)((uintptr_t)__with_ctx - 2u))->env;\n"
            for ci in 0..count:
                let li = ci + 1
                prologue = prologue ++ "    " ++ self.c_decl(body.local_type_ids[li], f"(*_{li})") ++ f" __attribute__((unused)) = &__with_env->c{ci};\n"
        let sig = "static " ++ self.closure_fn_sig(idx)
        self.emit_body_text(body, sig, body.n_params, prologue)

    mut fn emit_fn_body(body: &MirBody) -> str:
        if self.check_interrupted() != 0:
            return ""
        // A closure's retained body is emitted by emit_closure_body, after
        // every named body (#1766).
        if body.anonymous_type != 0:
            return ""
        let fn_sym = body.fn_sym
        let sig_idx = self.body_sig_index(fn_sym)
        let init_global = self.global_init_target(fn_sym)
        if sig_idx < 0 and init_global == 0:
            return ""
        self.enter_line_file(fn_sym)
        // Frozen name resolution (a `sizeof[T]` type argument through
        // resolve_type_level_arg_expr_frozen) judges visibility from
        // sema.current_module_path. Point it at the DECLARING module, as
        // Codegen.enter_decl does for the LLVM backend (#705). Left at the
        // root, std.engines.pcre2.pcre2_study's find_minlength (compiled in-unit under
        // --emit-c) resolved `sizeof[pcre2_real_code_8]` as if the user had
        // written it, and an engine corpus type is invisible to user code
        // (#1362): the emitter failed before any LLVM-only refusal fired.
        let decl_path = if init_global != 0: self.decl_source_path(self.global_decl_node(init_global)) else: self.sema.fn_body_source_path(fn_sym)
        if decl_path.len() > 0:
            self.sema.current_module_path = decl_path
        let fn_sig = self.emit_fn_decl(body)
        let param_count = if sig_idx >= 0: self.sema.sig_get_param_count(sig_idx) else: 0
        // A specialization's type-level builtin arguments (`sizeof[PullCore[G]]`,
        // #1766) are Sema's recorded facts (type_level_arg_in_body, #1983).
        let was_ok = self.had_error == 0
        let text = self.emit_body_text(body, fn_sig, param_count, "")
        // A refusal names the function it stopped in (#2017: a bare
        // "payload downcast for unit enum variant 1" over the whole compiler).
        if was_ok and self.had_error != 0:
            self.err_msg = "in " ++ self.fn_c_name(fn_sym) ++ ": " ++ self.err_msg
        text

    // The C function over a MIR body: `fn_sig {`, `prologue` (a closure's
    // capture locals, #1766), the declaration of every local past the
    // `param_count` parameters, then each basic block under its label.
    mut fn emit_body_text(body: &MirBody, fn_sig: &str, param_count: i32, prologue: &str) -> str:
        let fn_sym = body.fn_sym
        let sig_idx = if body.anonymous_type != 0: -1 else: self.body_sig_index(fn_sym)
        let out = COut.new()
        out.write(fn_sig ++ " " ++ cc_lbrace() ++ "\n")
        out.write(prologue)
        out.write(self.closure_env_locals_text(body))
        let call_override_locals: List[i32] = List.new()
        let call_override_tids: List[i32] = List.new()
        for bb in 0..body.block_count():
            if self.check_interrupted() != 0:
                return ""
            if body.term_kind(bb) != TermKind.TK_CALL:
                continue
            let callee_operand = body.term_data0(bb)
            let args_id = body.term_data1(bb)
            let dest_place = body.term_data2(bb)
            let local_id = self.place_local_id(body, dest_place)
            if local_id < 0:
                continue
            if self.place_is_direct_local(body, dest_place, local_id) == 0:
                continue
            let declared_tid = self.local_declared_tid(body, local_id)
            let declared_resolved = self.sema.resolve_alias(declared_tid)
            let declared_kind = self.sema.get_type_kind(declared_resolved)
            var needs_override = 0
            if self.is_void_tid(declared_tid) != 0 or declared_resolved == 0 or declared_kind == TypeKind.TY_ERR:
                needs_override = 1
            if declared_kind == TypeKind.TY_GENERIC_INST:
                needs_override = 1
            let intrinsic_kind = cc_builtin_from_mir_intrinsic(body.call_intrinsic(args_id))
            let call_kind = if intrinsic_kind != CcBuiltin.NONE:
                intrinsic_kind
            else:
                self.call_builtin_kind(body, callee_operand, args_id, dest_place)
            if call_kind == CcBuiltin.MAP_GET:
                needs_override = 1
            if call_kind == CcBuiltin.FMT_BUF_NEW:
                needs_override = 1
            if needs_override == 0:
                continue
            var ret_tid: i32 = 0
            if call_kind == CcBuiltin.MAP_GET:
                ret_tid = self.call_builtin_ret_tid(body, callee_operand, args_id, dest_place)
            else if intrinsic_kind != CcBuiltin.NONE:
                ret_tid = self.call_builtin_ret_tid(body, callee_operand, args_id, dest_place)
            else:
                ret_tid = self.call_return_tid(body, bb, callee_operand, args_id, dest_place)
            if ret_tid == 0 or self.is_void_tid(ret_tid) != 0:
                continue
            var seen = 0
            for oi in 0..call_override_locals.len():
                if call_override_locals[oi] == local_id:
                    seen = 1
                    break
            if seen != 0:
                continue
            call_override_locals.push(local_id)
            call_override_tids.push(ret_tid)
        let encoded_option_locals = self.encoded_option_local_flags(body)
        let downcast_option_tids = self.body_downcast_option_tids(body)
        let copied_payload_enum_tids = self.body_copied_payload_enum_tids(body, downcast_option_tids)
        let ref_target_tids = self.body_ref_target_tids(body)
        for li in 0..body.local_count():
            if self.check_interrupted() != 0:
                return ""
            if li >= 1 and li <= param_count:
                continue
            if self.local_global_sym(body, li) != 0:
                continue
            let declared_tid = if li == 0 and sig_idx >= 0: self.c_sig_return_type(sig_idx) else:
                if li < body.local_type_ids.len(): body.local_type_ids[li] else: self.sema.ty_i32
            var use_tid = declared_tid
            let declared_resolved = self.sema.resolve_alias(declared_tid)
            let declared_kind = self.sema.get_type_kind(declared_resolved)
            if self.is_void_tid(declared_tid) == 0 and declared_resolved != 0 and declared_kind != TypeKind.TY_ERR:
                for oi in 0..call_override_locals.len():
                    if call_override_locals[oi] != li:
                        continue
                    let override_tid = call_override_tids[oi]
                    let declared_kind_for_override = self.sema.get_type_kind(self.sema.resolve_alias(declared_tid))
                    let override_kind = self.sema.get_type_kind(self.sema.resolve_alias(override_tid))
                    if declared_kind_for_override != override_kind or self.strict_type_match(declared_tid, override_tid) == 0:
                        use_tid = override_tid
                    break
            let downcast_opt_tid = cc_list_tid_at(downcast_option_tids, li)
            if downcast_opt_tid != 0 and self.is_void_tid(downcast_opt_tid) == 0:
                use_tid = downcast_opt_tid
            let copied_payload_enum_tid = cc_list_tid_at(copied_payload_enum_tids, li)
            if copied_payload_enum_tid != 0 and self.is_void_tid(copied_payload_enum_tid) == 0:
                use_tid = copied_payload_enum_tid
            let use_resolved_before_infer = self.sema.resolve_alias(use_tid)
            let use_kind_before_infer = self.sema.get_type_kind(use_resolved_before_infer)
            var should_infer_local = 0
            if self.is_void_tid(use_tid) != 0 or use_resolved_before_infer == 0 or use_kind_before_infer == TypeKind.TY_ERR:
                should_infer_local = 1
            if use_kind_before_infer == TypeKind.TY_GENERIC_INST and self.type_is_payload_enum(use_tid) == 0:
                should_infer_local = 1
            if should_infer_local != 0:
                let inferred_tid = self.infer_local_tid(body, li)
                if inferred_tid != 0 and self.is_void_tid(inferred_tid) == 0:
                    let inferred_kind = self.sema.get_type_kind(self.sema.resolve_alias(inferred_tid))
                    if self.is_void_tid(use_tid) != 0 or use_kind_before_infer != inferred_kind or self.strict_type_match(use_tid, inferred_tid) == 0:
                        use_tid = inferred_tid
            self.local_effective_cache.insert(cc_body_local_cache_key(body.fn_sym, li), use_tid)
            let use_resolved = self.sema.resolve_alias(use_tid)
            let use_kind = self.sema.get_type_kind(use_resolved)
            var local_ty = if li == 0 and self.is_void_tid(use_tid) != 0: "int32_t" else: self.c_type(use_tid, 0)
            // If this local is assigned from RK_REF/RK_ADDR_OF, declare as pointer
            let ref_target_tid = cc_list_tid_at(ref_target_tids, li)
            if ref_target_tid != 0 and use_kind != TypeKind.TY_PTR and use_kind != TypeKind.TY_REF:
                local_ty = self.c_type(ref_target_tid, 0)
                let use_kind_for_ref = self.sema.get_type_kind(self.sema.resolve_alias(ref_target_tid))
                if use_kind_for_ref == TypeKind.TY_ARRAY:
                    local_ty = "void*"
                else if use_kind_for_ref == TypeKind.TY_PTR or use_kind_for_ref == TypeKind.TY_REF:
                    local_ty = "void*"
                else if use_kind_for_ref != TypeKind.TY_PTR and use_kind_for_ref != TypeKind.TY_REF:
                    let base_ty = local_ty
                    if base_ty == "void":
                        local_ty = "uint8_t*"
                    else:
                        local_ty = base_ty ++ "*"
            // If declared as compound type but receives arithmetic result, force int64_t
            let is_compound_local = local_ty == "with_str" or local_ty == "with_vec"
            if is_compound_local and self.local_receives_arith(body, li):
                local_ty = "int64_t"
            if is_compound_local and li < encoded_option_locals.len() and encoded_option_locals[li] == 1:
                local_ty = "int64_t"
            // Array types need C's declarator syntax, including nested dimensions.
            if use_kind == TypeKind.TY_ARRAY:
                out.write("    " ++ self.c_decl(use_tid, f"_{li}") ++ " __attribute__((unused)) = " ++ cc_lbrace() ++ "0" ++ cc_rbrace() ++ ";\n")
            else if self.type_is_pointer_to_array(use_tid):
                out.write("    " ++ self.c_decl(use_tid, f"_{li}") ++ " __attribute__((unused)) = " ++ cc_lbrace() ++ "0" ++ cc_rbrace() ++ ";\n")
            else:
                out.write("    " ++ local_ty ++ f" _{li} __attribute__((unused)) = " ++ cc_lbrace() ++ "0" ++ cc_rbrace() ++ ";\n")
        if body.block_count() == 0:
            self.fail("function has no basic blocks: " ++ cc_intern_resolve(self.intern, fn_sym))
            out.write("    abort();\n")
            out.write(cc_rbrace() ++ "\n")
            return out.finish()
        out.write("    goto bb0;\n")
        for bb in 0..body.block_count():
            if self.check_interrupted() != 0:
                return ""
            out.write(f"bb{bb}:\n")
            let start = body.bb_stmt_starts[bb]
            let count = body.bb_stmt_counts[bb]
            for si in 0..count:
                if self.check_interrupted() != 0:
                    return ""
                out.write(self.line_directive(body, start + si))
                self.begin_holds()
                let stmt_text = self.emit_stmt_line(body, start + si)
                self.hold_active = false
                out.write(self.with_holds(stmt_text))
                out.write("\n")
            self.begin_holds()
            let term_text = self.emit_term(body, bb)
            self.hold_active = false
            out.write(self.with_holds(term_text))
            out.write("\n")
        // #982: a successor past the body's blocks is invalid MIR. Empty stub
        // labels made control fall off the function's end; they were emitted
        // for "references" that read a call's destination place (its d2) as
        // a block number.
        for bb in 0..body.block_count():
            for target in mir_term_successors(body, bb):
                if target >= body.block_count():
                    self.fail(f"bb{bb}'s terminator names bb{target}, past the body's {body.block_count()} blocks")
                    return ""
        out.write(cc_rbrace() ++ "\n")
        out.finish()

    fn find_main_sym() -> i32:
        for i in 0..self.mir_mod.body_fn_syms.len():
            let sym = self.mir_mod.body_fn_syms[i]
            if cc_intern_resolve(self.intern, sym) == "main":
                return sym
        0

    fn uses_async_runtime() -> bool:
        for i in 0..self.mir_mod.body_fn_syms.len():
            let sym = self.mir_mod.body_fn_syms[i]
            if self.sema.task_fns.contains(sym):
                return true
        false

    fn emit_runtime_fiber_config_call() -> str:
        if not self.uses_async_runtime():
            return ""
        let stack_size = self.sema.runtime_fiber_stack_size
        let pool_size = self.sema.runtime_fiber_pool_size
        let worker_count = self.sema.runtime_fiber_worker_count
        if stack_size <= 0 and pool_size <= 0 and worker_count <= 0:
            return ""
        "    if (with_runtime_configure_fibers(" ++ with_i64_to_str(stack_size) ++ "LL, " ++ with_i64_to_str(pool_size as i64) ++ ", " ++ with_i64_to_str(worker_count as i64) ++ ") != 0) {\n" ++
        "        with_panic(WITH_STR_LIT(\"runtime fiber configuration cannot change after fibers exist\"), WITH_STR_LIT(\"\"), 0);\n" ++
        "    }\n"

    mut fn emit_main_wrapper(skipped_inits: &List[i32]) -> str:
        let main_sym = self.find_main_sym()
        if main_sym == 0:
            // A unit without `main` has no entry to run its startup
            // initializers from; its globals would read zero (#1484).
            if self.global_init_syms.len() > 0:
                self.fail(f"emit-c: global '{cc_intern_resolve(self.intern, self.global_init_syms[0])}' is initialized at startup, and this unit has no `main` to run it before")
            return ""
        let main_name = self.fn_c_name(main_sym)
        let sig_idx = self.sema.get_sig(main_sym)
        let ret_tid = if sig_idx >= 0: self.c_sig_return_type(sig_idx) else: self.sema.ty_void
        var out = "int main(int argc, char** argv) " ++ cc_lbrace() ++ "\n"
        out = out ++ "    with_runtime_set_argv(argc, argv);\n"
        out = out ++ self.emit_runtime_fiber_config_call()
        out = out ++ "    with_runtime_init();\n"
        out = out ++ self.global_init_calls_text(skipped_inits)
        if self.is_void_tid(ret_tid) != 0:
            out = out ++ "    " ++ main_name ++ "();\n"
            out = out ++ "    with_runtime_shutdown();\n"
            out = out ++ "    return 0;\n"
        else:
            out = out ++ "    int __with_exit_code = (int)(" ++ main_name ++ "());\n"
            out = out ++ "    with_runtime_shutdown();\n"
            out = out ++ "    return __with_exit_code;\n"
        out = out ++ cc_rbrace() ++ "\n"
        out

    mut fn emit_module() -> str:
        if self.check_interrupted() != 0:
            return ""
        let out = COut.new()
        out.write("/* Generated by with --emit-c (conservative MIR subset). */\n")
        out.write("#include <stdint.h>\n")
        out.write("#include <stdbool.h>\n")
        out.write("#include <stdarg.h>\n")
        out.write("#include <math.h>\n")
        out.write("#include <stdlib.h>\n")
        out.write("#include <string.h>\n")
        out.write("#include <ctype.h>\n")
        out.write("#include <fcntl.h>\n")
        out.write("#include <locale.h>\n")
        out.write("#include <stdio.h>\n")
        out.write("#include \"undef_stdio_macros.h\"\n")
        out.write("#include <time.h>\n")
        out.write("#include <unistd.h>\n")
        out.write("#include <sys/resource.h>\n")
        out.write("#include <sys/stat.h>\n")
        out.write("#include \"with_runtime.h\"\n\n")
        out.write(cc_emit_checked_arith_helpers())
        out.write(cc_emit_str_range_view_helper())
        // Extra declarations for functions used by emitted C but not in with_runtime.h
        out.write("/* Extra runtime declarations */\n")
        out.write("#define fmt_buf_new with_fmt_buf_new\n")
        out.write("#define fmt_buf_finish with_fmt_buf_finish\n")
        out.write("extern uint8_t* with_fmt_buf_new(void);\n")
        out.write("extern void with_fmt_buf_write_str_ref(uint8_t*, with_str);\n")
        out.write("extern with_str with_str_clone_ref(with_str);\n")
        out.write("extern void with_fmt_buf_write_i64_spec(uint8_t*, int64_t, int32_t, int64_t, int32_t, int32_t, int32_t);\n")
        out.write("extern void with_fmt_buf_write_int128_spec(uint8_t*, uint64_t, uint64_t, int32_t, int64_t, int32_t, int32_t, int32_t);\n")
        out.write("extern void with_fmt_buf_write_f64_spec(uint8_t*, double, int64_t, int32_t, int32_t, int32_t);\n")
        out.write("extern void with_fmt_buf_write_str_spec_ref(uint8_t*, with_str, int64_t, int32_t, int32_t);\n")
        out.write("extern with_str with_fmt_buf_finish(uint8_t*);\n")
        if self.module_exports_c_name("with_alloc") == 0:
            out.write("extern void* with_alloc(int64_t);\n")
        if self.module_exports_c_name("with_alloc_aligned") == 0:
            out.write("extern void* with_alloc_aligned(int64_t, int64_t);\n")
        if self.module_exports_c_name("with_free") == 0:
            out.write("extern void with_free(void*);\n")
        if self.module_exports_c_name("with_memcpy") == 0:
            out.write("extern void* with_memcpy(void*, const void*, int64_t);\n")
        if self.module_exports_c_name("with_memset") == 0:
            out.write("extern void* with_memset(void*, int32_t, int64_t);\n")
        if self.module_exports_c_name("with_memmove") == 0:
            out.write("extern void* with_memmove(void*, const void*, int64_t);\n")
        if self.module_exports_c_name("with_memcmp") == 0:
            out.write("extern int32_t with_memcmp(const void*, const void*, int64_t);\n")
        out.write("extern void* with_hashmap_get_ptr(void*, const void*, int64_t);\n")
        // D44 map traversal's slot walk (#1434); rt_core's own signatures.
        out.write("extern int64_t with_hashmap_capacity(uint8_t*);\n")
        out.write("extern int32_t with_hashmap_slot_occupied(uint8_t*, int64_t);\n")
        out.write("extern uint8_t* with_hashmap_key_ptr_at(uint8_t*, int64_t);\n")
        out.write("extern uint8_t* with_hashmap_value_ptr_at(uint8_t*, int64_t);\n")
        out.write("extern int32_t with_hashmap_take_at(uint8_t*, int64_t, void*, void*);\n")
        out.write("extern int64_t with_clock_nanos(void);\n")
        out.write("extern int32_t with_nanosleep(int64_t);\n")
        out.write("extern with_str with_sysinfo_os(void);\n")
        out.write("extern with_str with_sysinfo_arch(void);\n")
        out.write("extern with_str with_sysinfo_hostname(void);\n")
        // §16.3c, D47: a str lent to a `const char *` parameter.
        out.write("extern uint8_t* with_cstr_lend(with_str);\n")
        out.write("extern void with_cstr_release(uint8_t*);\n")
        // #983: the drop and copy glue's runtime (rt_core, channel_runtime).
        out.write("extern void with_str_free(with_str*);\n")
        out.write("extern void with_str_retain(const with_str*);\n")
        out.write("extern with_str with_str_own_view(with_str);\n")
        out.write("extern int64_t with_slotmap_capacity(uint8_t*);\n")
        out.write("extern int32_t with_slotmap_slot_occupied(uint8_t*, int64_t);\n")
        out.write("extern uint8_t* with_slotmap_value_ptr_at(uint8_t*, int64_t);\n")
        out.write("extern void with_slotmap_free(uint8_t*);\n")
        out.write("extern int32_t with_hashmap_remove_entry(void*, const void*, void*, void*);\n")
        out.write("extern void with_hasher_init(uint8_t*);\n")
        out.write("extern void with_hasher_write(uint8_t*, const uint8_t*, int64_t);\n")
        out.write("extern void with_hasher_write_str(uint8_t*, with_str);\n")
        out.write("extern int64_t with_hasher_finish(uint8_t*);\n")
        out.write("extern void with_channel_release_sender(int64_t);\n")
        out.write("extern void with_channel_release_receiver(int64_t);\n")
        // §2.5.1: the reset-on-move sentinel is all-zero storage.
        out.write("static inline int __with_is_zero(const void* p, size_t n) " ++ cc_lbrace() ++ " const unsigned char* b = (const unsigned char*)p; for (size_t i = 0; i < n; i++) if (b[i] != 0) return 0; return 1; " ++ cc_rbrace() ++ "\n\n")
        out.write("#ifdef WITH_BOOTSTRAP_TYPES_H\n")
        out.write("extern with_str with_str_concat_ref(with_str, with_str);\n")
        out.write("extern with_str with_str_concat_n(const with_str*, int64_t);\n")
        out.write("extern with_str with_str_concat_n_move_first(const with_str*, int64_t);\n")
        out.write("extern int32_t with_str_cmp_ref(with_str, with_str);\n")
        out.write("extern int64_t with_str_len(with_str);\n")
        out.write("extern int32_t with_str_byte_at_ref(with_str, int64_t);\n")
        out.write("extern int32_t with_str_contains_char_ref(with_str, int32_t);\n")
        out.write("extern with_str with_str_from_cstr(const uint8_t*);\n")
        out.write("extern with_str with_str_from_bytes(const uint8_t*, int64_t);\n")
        out.write("extern with_str with_i64_to_str(int64_t);\n")
        out.write("extern with_str with_fmt_u32(uint32_t);\n")
        out.write("extern with_str with_fmt_u64(uint64_t);\n")
        out.write("extern with_str with_bool_to_str(int32_t);\n")
        out.write("extern void with_println_str(with_str);\n")
        out.write("extern void with_println_i32(int32_t);\n")
        out.write("extern void with_println_i64(int64_t);\n")
        out.write("extern void with_eprint(with_str);\n")
        out.write("extern void with_write(with_str);\n")
        out.write("extern void with_println_bool(int32_t);\n")
        out.write("extern void with_ewrite(with_str);\n")
        out.write("extern void with_panic(with_str, with_str, int32_t);\n")
        out.write("extern int32_t with_runtime_configure_fibers(int64_t, int32_t, int32_t);\n")
        out.write("extern int32_t with_fiber_in_fiber(void);\n")
        out.write("extern void with_fiber_await(int32_t);\n")
        out.write("extern void with_fiber_cleanup_await(int32_t);\n")
        out.write("extern int32_t with_fiber_cancel(int32_t);\n")
        out.write("#endif\n")
        out.write("extern void with_fiber_panic_capture(const uint8_t*, int32_t);\n")
        out.write("\n")

        self.prepare_extern_link_names()
        self.prepare_global_init_bodies()
        if self.had_error != 0:
            return ""
        self.register_closures()
        if self.had_error != 0:
            return ""
        self.prepare_c_type_instantiations()
        if self.had_error != 0:
            return ""
        let struct_defs = self.emit_struct_type_defs()
        if self.had_error != 0:
            return ""
        let cstr_defs = self.emit_cstr_literal_defs()
        if self.had_error != 0:
            return ""
        let global_defs = self.global_var_defs()
        if self.had_error != 0:
            return ""
        let extern_decls = self.emit_extern_fn_decls()
        if self.had_error != 0:
            return ""

        // Forward declarations for all lowered functions; only the reached
        // ones are written (below).
        var decls: List[str] = List.new()
        for i in 0..self.mir_mod.bodies.len():
            if self.check_interrupted() != 0:
                return ""
            let body = self.mir_body_at(i as i64)
            decls.push(if self.body_sig_index(body.fn_sym) < 0: "" else: self.emit_fn_decl(body))

        // #1766: every closure's environment struct, owned-cell glue and
        // prototype, before any body that creates or runs one.
        let closure_decls = self.emit_closure_decls()
        if self.had_error != 0:
            return ""

        // A body is emitted only when C text already emitted names it: the
        // functions with external names (exports, the public runtime ABI),
        // the startup wrapper, closures, globals and fn-value thunks are the
        // roots. A program carries the whole standard library (pcre2
        // included, through the prelude's std.regex) and used to emit all of
        // it: 24 MB of C for `print("hi")`, about 17 MB of it the regex
        // engine. Whatever the C names is emitted, so nothing a program
        // reaches can go missing; reached bodies emit in declaration order.
        // A global's initializer that only computes its value (no call, no
        // drop, no write to another global) is reached through the global;
        // any other runs at startup whatever reads it. pcre2's Unicode tables
        // are such initializers, 6 MB of C (3.6 MB in one function).
        let main_sym = self.find_main_sym()
        var init_of_global: HashMap[i32, i32] = HashMap.new()
        let body_count = self.mir_mod.bodies.len()
        var reach = CReach.new(body_count + global_defs.len())
        for gi in 0..global_defs.len():
            if global_defs[gi].name.len() == 0 or self.emit_all: reach.mark((body_count + gi) as i32) else: reach.name(global_defs[gi].name, (body_count + gi) as i32)
        for i in 0..self.mir_mod.bodies.len():
            let fn_sym = self.mir_body_at(i as i64).fn_sym
            let init_global = self.global_init_target(fn_sym)
            if init_global != 0:
                let init_body = self.mir_body_at(i as i64)
                if not self.emit_all and self.init_body_is_pure(init_body): init_of_global.insert(init_global, i as i32) else: reach.mark(i as i32)
                continue
            if decls[i].len() == 0: continue
            if self.emit_all or fn_sym == main_sym or not self.fn_c_name_is_internal(fn_sym): reach.mark(i as i32) else: reach.name(self.fn_c_name(fn_sym), i as i32)
        reach.scan(struct_defs)
        reach.scan(closure_decls)
        var closure_texts: List[str] = List.new()
        for ci in 0..self.closure_syms.len():
            if self.check_interrupted() != 0:
                return ""
            closure_texts.push(self.emit_closure_body(ci as i32))
            reach.scan(closure_texts[ci])
        var body_texts: List[str] = List.new()
        for _ in 0..self.mir_mod.bodies.len(): body_texts.push("")
        var thunk_defs = ""
        // #983: glue names the Drop impls it calls; bodies make more glue.
        var glue_scanned: isize = 0
        var grew = true
        while grew:
            grew = false
            for i in 0..self.mir_mod.bodies.len():
                if not reach.take(i as i32): continue
                if self.check_interrupted() != 0:
                    return ""
                let body = self.mir_body_at(i as i64)
                body_texts[i] = self.emit_fn_body(body)
                reach.scan(body_texts[i])
                grew = true
            for gi in 0..global_defs.len():
                if not reach.take((body_count + gi) as i32): continue
                reach.scan(global_defs[gi].text)
                let init: i32 = init_of_global.get(global_defs[gi].sym) ?? -1
                if init >= 0: reach.mark(init)
                grew = true
            // Emitting bodies discovers the fat fn-value thunks, which name
            // their targets.
            thunk_defs = self.emit_fat_thunk_defs()
            reach.scan(thunk_defs)
            while glue_scanned < self.glue_defs.len():
                reach.scan(self.glue_defs[glue_scanned])
                glue_scanned += 1
            if reach.pending(): grew = true
        if self.had_error != 0:
            return ""
        var skipped_inits: List[i32] = List.new()
        for i in 0..body_count:
            let fn_sym = self.mir_body_at(i as i64).fn_sym
            if self.global_init_target(fn_sym) != 0 and not reach.emitted(i as i32): skipped_inits.push(fn_sym)
        let main_wrapper = self.emit_main_wrapper(skipped_inits)
        if self.had_error != 0:
            return ""

        out.write(struct_defs)
        out.write(cstr_defs)
        var any_global = false
        for gi in 0..global_defs.len():
            if not reach.emitted((body_count + gi) as i32): continue
            out.write(global_defs[gi].text)
            any_global = true
        if any_global:
            out.write("\n")
        out.write(extern_decls)
        var any_decl = false
        for i in 0..self.mir_mod.bodies.len():
            if not reach.emitted(i as i32) or decls[i].len() == 0: continue
            out.write(decls[i])
            out.write(";\n")
            any_decl = true
        if any_decl:
            out.write("\n")
        for proto in self.glue_protos: out.write(proto)
        out.write(closure_decls)
        // The thunks' static definitions precede the bodies (every reached
        // function already has its prototype above).
        out.write(thunk_defs)
        for def in self.glue_defs: out.write(def)
        for i in 0..self.mir_mod.bodies.len():
            if not reach.emitted(i as i32): continue
            out.write(body_texts[i])
            out.write("\n")
        for ci in 0..closure_texts.len():
            out.write(closure_texts[ci])
            out.write("\n")

        // C entrypoint wrapper for With `main`.
        out.write(main_wrapper)
        out.finish()

// ── Ownership: drop glue, copy glue and operand holds (#983) ─────────
//
// The C backend runs the destructors and takes the holds the LLVM backend
// does (CodegenDispatch: mir_emit_drop_ptr_for_sema_type,
// mir_emit_copy_glue_ptr, mir_eval_operand), shape for shape. Each type's
// drop and copy is one static C function, `__with_drop_<tid>(T*)` and
// `__with_copy_<tid>(T*)`, declared before every body so a type recursive
// through its own collection calls its declaration (#1557's class). A
// member's drop is guarded by the reset-on-move sentinel (§2.5.1, #697):
// all-zero storage owns nothing, so it is skipped.
impl CCodegen:
    fn glue_needed(tid: i32) -> bool:
        tid > 0 and tid != CC_PSEUDO_TID_LIST and self.sema.type_needs_drop_frozen(tid) != 0

    // The type a place holds: MIR's (Sema's), the one its drop is decided by.
    mut fn place_sema_tid(body: &MirBody, place_id: i32) -> i32:
        let local = body.place_locals[place_id]
        if body.place_proj_counts[place_id] == 0 and local >= 0 and local < body.local_type_ids.len() and body.local_type_ids[local] > 0:
            return body.local_type_ids[local]
        if place_id < body.place_sema_types.len() and body.place_sema_types[place_id] > 0:
            return body.place_sema_types[place_id]
        self.place_tid(body, place_id)

    // The type MIR gives an operand: its place's, or its constant's.
    mut fn operand_sema_tid(body: &MirBody, operand_id: i32) -> i32:
        let ok = body.operand_kinds[operand_id]
        if ok == OperandKind.OK_COPY or ok == OperandKind.OK_MOVE:
            return self.place_sema_tid(body, body.operand_d0[operand_id])
        if ok == OperandKind.OK_CONSTANT:
            return body.const_types[body.operand_d0[operand_id]]
        0

    // `drop(place)`: the place's glue, guarded when the move analysis saw
    // its local moved (§2.5.2: a local never moved never holds the
    // sentinel, and a live value that happens to be all zero still drops).
    mut fn drop_place_text(body: &MirBody, place_id: i32) -> str:
        let tid = self.place_sema_tid(body, place_id)
        if tid == CC_PSEUDO_TID_LIST or (tid == 0 and self.place_tid(body, place_id) == CC_PSEUDO_TID_LIST):
            self.fail(f"emit-c: drop of a List whose element type MIR does not name (place {place_id} of " ++ cc_intern_resolve(self.intern, body.fn_sym) ++ ")")
            return "    abort();"
        if not self.glue_needed(tid):
            return ""
        let guarded = body.local_ever_moved(body.place_locals[place_id])
        let lv = self.place_text(body, place_id)
        "    " ++ self.drop_call_text(lv, tid, guarded)

    // A call of `tid`'s drop glue on the lvalue `lv`.
    mut fn drop_call_text(lv: &str, tid: i32, guarded: bool) -> str:
        if not self.glue_needed(tid):
            return ""
        let name = self.ensure_drop_glue(tid)
        if name.len() == 0:
            return ""
        let call = name ++ "(" ++ self.glue_arg(lv, tid) ++ ");"
        if guarded: "if (!__with_is_zero(&(" ++ lv ++ "), sizeof(" ++ lv ++ "))) " ++ call else: call

    // The glue's argument: the value's address, or an array's first element.
    fn glue_arg(lv: &str, tid: i32) -> str:
        if self.sema.get_type_kind(self.sema.resolve_alias(tid as TypeId)) == TypeKind.TY_ARRAY: "(" ++ lv ++ ")" else: "&(" ++ lv ++ ")"

    mut fn glue_param_c_type(resolved: i32) -> str:
        if self.sema.get_type_kind(resolved as TypeId) == TypeKind.TY_ARRAY:
            return self.c_type(self.sema.get_type_d0(resolved as TypeId), 0)
        self.c_type(resolved, 0)

    // Seed-bound: the name observed, so the caller's `name` is not the
    // insert's last-use take (the tail StorageDead fix in this stack); the
    // next seed pin inserts it in place.
    mut fn mark_glue_done(name: &str):
        self.glue_done.insert(name, 1)

    // Declares `name` for `resolved` and builds its body once.
    mut fn ensure_glue(kind: &str, resolved: i32) -> str:
        let name = f"__with_{kind}_{resolved}"
        if self.glue_done.contains(name):
            return name
        self.mark_glue_done(name)
        let sig = "static void " ++ name ++ "(" ++ self.glue_param_c_type(resolved) ++ "* p)"
        self.glue_protos.push(sig ++ ";\n")
        let lv = if self.sema.get_type_kind(resolved as TypeId) == TypeKind.TY_ARRAY: "p" else: "(*p)"
        let text = if kind == "drop": self.drop_glue_body(lv, resolved) else: self.copy_glue_body(lv, resolved)
        self.glue_defs.push(sig ++ " " ++ cc_lbrace() ++ "\n" ++ text ++ cc_rbrace() ++ "\n")
        name

    mut fn ensure_drop_glue(tid: i32) -> str:
        self.ensure_glue("drop", self.sema.resolve_alias(tid as TypeId) as i32)

    // The statements dropping the value at `lv` of type `resolved`, in the
    // order the LLVM backend drops it.
    mut fn drop_glue_body(lv: &str, resolved: i32) -> str:
        let tk = self.sema.get_type_kind(resolved as TypeId)
        // §4.5 (D75): a distinct type has its underlying type's destructor.
        if tk == TypeKind.TY_STRUCT and self.sema.distinct_type_names.contains(self.sema.get_type_d0(resolved as TypeId)):
            return "    " ++ self.drop_call_text(lv, self.sema.type_extra[(self.sema.get_type_d1(resolved as TypeId) + 1)], false) ++ "\n"
        if tk == TypeKind.TY_TUPLE:
            var out = ""
            var i = self.sema.get_type_d1(resolved as TypeId) - 1
            while i >= 0:
                out = out ++ "    " ++ self.drop_call_text(lv ++ f".field{i}", self.tuple_field_tid(resolved, i), true) ++ "\n"
                i = i - 1
            return out
        if tk == TypeKind.TY_ARRAY:
            let elem = self.sema.get_type_d0(resolved as TypeId)
            let n = self.sema.get_type_d1(resolved as TypeId)
            return f"    for (int64_t __i = {n} - 1; __i >= 0; __i--) " ++ cc_lbrace() ++ " " ++ self.drop_call_text(lv ++ "[__i]", elem, true) ++ " " ++ cc_rbrace() ++ "\n"
        if tk == TypeKind.TY_STR:
            return "    with_str_free(&(" ++ lv ++ "));\n"
        // D63: a callable value owns its environment when its context word
        // is tagged as a heap cell (tag 2); the cell's own drop fn frees it.
        if tk == TypeKind.TY_FN:
            return "    " ++ cc_lbrace() ++ " uintptr_t __b = (uintptr_t)(" ++ lv ++ ").ctx; if ((__b & 3u) == 2u) " ++ cc_lbrace() ++ " void* __cell = (void*)(__b - 2u); (*(void (**)(void*))__cell)(__cell); (" ++ lv ++ ").ctx = 0; " ++ cc_rbrace() ++ " " ++ cc_rbrace() ++ "\n"
        if tk == TypeKind.TY_GENERIC_INST:
            let generic = self.drop_generic_inst_body(lv, resolved)
            if generic.len() > 0:
                return generic
        // with-abi §3: a nullable-pointer Option is its payload; null is None.
        if self.option_is_nullable_pointer(resolved):
            var payload: i32 = 0
            for vi in 0..self.sema.type_reflection_variant_count(resolved):
                if self.sema.type_reflection_variant_payload_count(resolved, vi) > 0:
                    payload = self.sema.type_reflection_variant_payload_type_frozen(resolved, vi, 0)
            return "    if ((" ++ lv ++ ") != 0) " ++ cc_lbrace() ++ " " ++ self.drop_call_text(lv, payload, false) ++ " " ++ cc_rbrace() ++ "\n"
        var out = ""
        let has_drop = self.sema.type_has_drop_impl(resolved) != 0
        if has_drop:
            let fn_name = self.user_drop_fn_name(resolved)
            if fn_name.len() == 0:
                return "    abort();\n"
            out = out ++ "    " ++ fn_name ++ "(&(" ++ lv ++ "));\n"
        let variants = if self.type_is_payload_enum(resolved) != 0: self.sema.type_reflection_variant_count(resolved) else: 0
        if variants == 0:
            return out ++ self.drop_struct_fields_text(lv, resolved)
        // #693: an enum's payload cleanup belongs to the variant switch; an
        // explicit drop owns it entirely.
        if has_drop:
            return out
        out = out ++ "    switch ((" ++ lv ++ ").tag) " ++ cc_lbrace() ++ "\n"
        for vi in 0..variants:
            var case_text = ""
            for pi in 0..self.sema.type_reflection_variant_payload_count(resolved, vi):
                let ptid = self.sema.type_reflection_variant_payload_type_frozen(resolved, vi, pi)
                case_text = case_text ++ " " ++ self.drop_call_text(lv ++ self.payload_enum_field_path(resolved, vi, pi), ptid, true)
            if case_text.len() > 0:
                out = out ++ f"    case {self.sema.type_reflection_variant_discriminant(resolved, vi)}:" ++ case_text ++ " break;\n"
        out ++ "    default: break;\n    " ++ cc_rbrace() ++ "\n"

    // A struct's fields in reverse, each guarded, minus those the type's
    // Drop body consumed (drop_consumed_field).
    mut fn drop_struct_fields_text(lv: &str, resolved: i32) -> str:
        let names = self.glue_field_names(resolved)
        let tids = self.glue_field_tids(resolved)
        let syms = self.glue_field_syms(resolved)
        let owner = self.sema.get_type_d0(resolved as TypeId)
        var out = ""
        var fi = names.len() - 1
        while fi >= 0:
            if owner == 0 or self.sema.drop_consumed_field(owner, syms[fi]) == 0:
                let call = self.drop_call_text(lv ++ "." ++ names[fi], tids[fi], true)
                if call.len() > 0:
                    out = out ++ "    " ++ call ++ "\n"
            fi = fi - 1
        out

    // A struct's C members, as emit_struct_type_defs declares them.
    fn glue_field_syms(resolved: i32) -> List[i32]:
        var out: List[i32] = List.new()
        if self.sema.get_type_kind(resolved as TypeId) == TypeKind.TY_STRUCT:
            let start = self.sema.get_type_d1(resolved as TypeId)
            for fi in 0..self.sema.get_type_d2(resolved as TypeId):
                out.push(self.sema.type_extra[(start + fi * 3)])
            return out
        if self.generic_inst_is_declared_struct(resolved):
            for fi in 0..self.sema.type_reflection_field_count(resolved):
                out.push(self.sema.type_reflection_field_name(resolved, fi))
        out

    fn glue_field_names(resolved: i32) -> List[str]:
        var out: List[str] = List.new()
        for sym in self.glue_field_syms(resolved):
            out.push(cc_member(cc_intern_resolve(self.intern, sym)))
        out

    mut fn glue_field_tids(resolved: i32) -> List[i32]:
        var out: List[i32] = List.new()
        if self.sema.get_type_kind(resolved as TypeId) == TypeKind.TY_STRUCT:
            let start = self.sema.get_type_d1(resolved as TypeId)
            for fi in 0..self.sema.get_type_d2(resolved as TypeId):
                out.push(self.effective_field_tid(resolved, self.sema.type_extra[(start + fi * 3)], self.sema.type_extra[(start + fi * 3 + 1)]))
            return out
        if self.generic_inst_is_declared_struct(resolved):
            for fi in 0..self.sema.type_reflection_field_count(resolved):
                out.push(self.sema.type_reflection_field_type_frozen(resolved, fi))
        out

    // The compiler-backed generic instances: Box, Rc/Arc, List, HashMap,
    // HashSet, SlotMap and the channel endpoints. "" for any other.
    mut fn drop_generic_inst_body(lv: &str, resolved: i32) -> str:
        let base = self.sema.get_generic_inst_base(resolved)
        let box_pointee = self.std_box_pointee_tid(resolved)
        if box_pointee != 0:
            if self.sema.get_type_kind(self.sema.resolve_alias(box_pointee as TypeId)) == TypeKind.TY_TRAIT_OBJ:
                self.fail("emit-c: dropping a Box[dyn " ++ self.sema.type_name(box_pointee) ++ "] needs the trait's vtable drop slot, which the C backend does not lower (#1847)")
                return "    abort();\n"
            // #697/§2.5.1: a reset-on-move Box is null.
            return "    if ((" ++ lv ++ ") != NULL) " ++ cc_lbrace() ++ " " ++ self.drop_call_text("(*(" ++ lv ++ "))", box_pointee, true) ++ " with_free((void*)(" ++ lv ++ ")); " ++ cc_rbrace() ++ "\n"
        if self.sema.type_symbol_is_std_rc_owner(base) != 0:
            // RcControl {strong, value}: the last holder drops the payload
            // and frees both cells; Arc counts atomically.
            let payload = self.sema.get_generic_inst_arg(resolved, 0)
            let payload_c = self.c_type(payload, 0)
            let dec = if cc_intern_resolve(self.intern, base) == "Arc": "__atomic_sub_fetch((int64_t*)__c, 1, __ATOMIC_ACQ_REL) == 0" else: "--(*(int64_t*)__c) == 0"
            return "    " ++ cc_lbrace() ++ " uint8_t* __c = (uint8_t*)(" ++ lv ++ ").ptr; if (__c != NULL && " ++ dec ++ ") " ++ cc_lbrace() ++ " " ++ payload_c ++ "* __v = *(" ++ payload_c ++ "**)(__c + 8); " ++ self.drop_call_text("(*__v)", payload, false) ++ " with_free((void*)__v); with_free((void*)__c); " ++ cc_rbrace() ++ " " ++ cc_rbrace() ++ "\n"
        if base == self.sema.syms.list:
            let elem = self.sema.get_generic_inst_arg(resolved, 0)
            let elem_c = self.c_type(elem, 0)
            let es = "(int64_t)sizeof(" ++ elem_c ++ ")"
            var elems = ""
            if self.glue_needed(elem):
                elems = "for (int64_t __i = 0; __i < (" ++ lv ++ ").len; __i++) " ++ cc_lbrace() ++ " " ++ self.drop_call_text("((" ++ elem_c ++ "*)(" ++ lv ++ ").ptr)[__i]", elem, true) ++ " " ++ cc_rbrace() ++ " "
            // D120: only the buffer's last holder drops the elements and frees it.
            return "    if (with_vec_release_last(&(" ++ lv ++ "), " ++ es ++ ")) " ++ cc_lbrace() ++ " " ++ elems ++ "with_vec_free_buffer_at((" ++ lv ++ ").ptr, (" ++ lv ++ ").cap, " ++ es ++ ", (" ++ lv ++ ").start); (" ++ lv ++ ") = (with_vec)" ++ cc_lbrace() ++ "0" ++ cc_rbrace() ++ "; " ++ cc_rbrace() ++ "\n"
        if base == self.sema.syms.hashmap or base == self.sema.syms.hashset:
            let entries = self.map_entries_glue_text(resolved, false)
            return "    " ++ cc_lbrace() ++ " uint8_t* __h = (uint8_t*)(intptr_t)(" ++ lv ++ "); if (__h != NULL && with_hashmap_release_last(__h)) " ++ cc_lbrace() ++ " " ++ entries ++ "with_hashmap_free(__h); " ++ cc_rbrace() ++ " (" ++ lv ++ ") = 0; " ++ cc_rbrace() ++ "\n"
        if base == self.sema.syms.slotmap:
            let elem = self.sema.get_generic_inst_arg(resolved, 0)
            let elem_c = self.c_type(elem, 0)
            var elems = ""
            if self.glue_needed(elem):
                elems = "int64_t __cap = with_slotmap_capacity(__h); for (int64_t __i = 0; __i < __cap; __i++) " ++ cc_lbrace() ++ " if (!with_slotmap_slot_occupied(__h, __i)) continue; " ++ self.drop_call_text("(*(" ++ elem_c ++ "*)with_slotmap_value_ptr_at(__h, __i))", elem, true) ++ " " ++ cc_rbrace() ++ " "
            return "    " ++ cc_lbrace() ++ " uint8_t* __h = (uint8_t*)(" ++ lv ++ ").ptr; if (__h != NULL) " ++ cc_lbrace() ++ " " ++ elems ++ "with_slotmap_free(__h); " ++ cc_rbrace() ++ " " ++ cc_rbrace() ++ "\n"
        let base_name = cc_intern_resolve(self.intern, base)
        if base_name == "Sender":
            return "    with_channel_release_sender((" ++ lv ++ ").handle);\n"
        if base_name == "Receiver":
            return "    with_channel_release_receiver((" ++ lv ++ ").handle);\n"
        ""

    // The glue over a map's live entries, in a block holding its table as
    // `__h`: each key's and value's drop, or (copy) each one's copy glue
    // after make-unique copied the table.
    mut fn map_entries_glue_text(resolved: i32, copying: bool) -> str:
        let key = self.hashmap_key_tid(resolved)
        let value = self.hashmap_value_tid(resolved)
        let key_glue = self.glue_needed(key)
        let value_glue = self.glue_needed(value)
        if not key_glue and not value_glue:
            return ""
        var each = ""
        if key_glue:
            let key_lv = "(*(" ++ self.c_type(key, 0) ++ "*)with_hashmap_key_ptr_at(__h, __i))"
            each = each ++ " " ++ (if copying: self.copy_call_text(key_lv, key) else: self.drop_call_text(key_lv, key, true))
        if value_glue:
            let value_lv = "(*(" ++ self.c_type(value, 0) ++ "*)with_hashmap_value_ptr_at(__h, __i))"
            each = each ++ " " ++ (if copying: self.copy_call_text(value_lv, value) else: self.drop_call_text(value_lv, value, true))
        "int64_t __cap = with_hashmap_capacity(__h); for (int64_t __i = 0; __i < __cap; __i++) " ++ cc_lbrace() ++ " if (!with_hashmap_slot_occupied(__h, __i)) continue;" ++ each ++ " " ++ cc_rbrace() ++ " "

    // The C function a type's `impl Drop` lowered to: a generic instance's
    // specialization (Sema's concrete_drop_mono_syms), else the body Sema
    // registers as the owner's `drop` (drop_owner_for_fn_symbol).
    mut fn user_drop_fn_name(resolved: i32) -> str:
        var sym: i32 = self.sema.concrete_drop_mono_syms.get(resolved) ?? 0
        if sym == 0:
            if not self.drop_receivers_ready:
                self.drop_receivers_ready = true
                for i in 0..self.mir_mod.body_fn_syms.len():
                    let fn_sym = self.mir_mod.body_fn_syms[i]
                    let owner = self.sema.drop_owner_for_fn_symbol(fn_sym)
                    if owner != 0 and not self.drop_body_by_owner.contains(owner):
                        self.drop_body_by_owner.insert(owner, fn_sym)
            sym = self.drop_body_by_owner.get(self.sema.get_type_d0(resolved as TypeId)) ?? 0
        let body_sym = self.canonical_body_sym(sym)
        if body_sym == 0:
            self.fail("emit-c: the Drop impl of " ++ self.sema.type_name(resolved) ++ " has no lowered body to call")
            return ""
        self.fn_c_name(body_sym)

    // A `Drop.drop` receiver is the value in its owner's storage (FnAbi
    // owned_place): the body and the glue's field cleanup after it read one
    // place, so a field the body moves out is blanked where the glue looks.
    fn param_is_drop_receiver(fn_sym: i32, param_idx: i32) -> bool:
        if param_idx != 0:
            return false
        if self.sema.drop_owner_for_fn_symbol(fn_sym) != 0:
            return true
        for entry in self.sema.concrete_drop_mono_syms:
            if entry.1 == fn_sym:
                return true
        false

    // ── copy glue (D111, D120) ──

    mut fn copy_call_text(lv: &str, tid: i32) -> str:
        if not self.glue_needed(tid):
            return ""
        let resolved = self.sema.resolve_alias(tid as TypeId) as i32
        if self.sema.get_type_kind(resolved as TypeId) == TypeKind.TY_STR:
            return "with_str_retain(&(" ++ lv ++ "));"
        self.ensure_glue("copy", resolved) ++ "(" ++ self.glue_arg(lv, resolved) ++ ");"

    mut fn copy_glue_body(lv: &str, resolved: i32) -> str:
        let tk = self.sema.get_type_kind(resolved as TypeId)
        if tk == TypeKind.TY_STRUCT and self.sema.distinct_type_names.contains(self.sema.get_type_d0(resolved as TypeId)):
            return "    " ++ self.copy_call_text(lv, self.sema.type_extra[(self.sema.get_type_d1(resolved as TypeId) + 1)]) ++ "\n"
        if tk == TypeKind.TY_STR:
            return "    with_str_retain(&(" ++ lv ++ "));\n"
        if tk == TypeKind.TY_TUPLE:
            var out = ""
            for i in 0..self.sema.get_type_d1(resolved as TypeId):
                out = out ++ "    " ++ self.copy_call_text(lv ++ f".field{i}", self.tuple_field_tid(resolved, i)) ++ "\n"
            return out
        if tk == TypeKind.TY_ARRAY:
            let elem = self.sema.get_type_d0(resolved as TypeId)
            return f"    for (int64_t __i = 0; __i < {self.sema.get_type_d1(resolved as TypeId)}; __i++) " ++ cc_lbrace() ++ " " ++ self.copy_call_text(lv ++ "[__i]", elem) ++ " " ++ cc_rbrace() ++ "\n"
        if tk == TypeKind.TY_GENERIC_INST:
            let base = self.sema.get_generic_inst_base(resolved)
            // D120 stage 2: a HashMap or HashSet of values shares its table.
            if base == self.sema.syms.hashmap or base == self.sema.syms.hashset:
                return "    if ((" ++ lv ++ ") != 0) with_hashmap_retain((uint8_t*)(intptr_t)(" ++ lv ++ "));\n"
            // D120: a List of values shares its buffer.
            if base == self.sema.syms.list:
                return "    with_vec_retain(&(" ++ lv ++ "), (int64_t)sizeof(" ++ self.c_type(self.sema.get_generic_inst_arg(resolved, 0), 0) ++ "));\n"
        if self.type_is_payload_enum(resolved) != 0 and not self.option_is_nullable_pointer(resolved):
            var out = "    switch ((" ++ lv ++ ").tag) " ++ cc_lbrace() ++ "\n"
            for vi in 0..self.sema.type_reflection_variant_count(resolved):
                var case_text = ""
                for pi in 0..self.sema.type_reflection_variant_payload_count(resolved, vi):
                    let ptid = self.sema.type_reflection_variant_payload_type_frozen(resolved, vi, pi)
                    case_text = case_text ++ " " ++ self.copy_call_text(lv ++ self.payload_enum_field_path(resolved, vi, pi), ptid)
                if case_text.len() > 0:
                    out = out ++ f"    case {self.sema.type_reflection_variant_discriminant(resolved, vi)}:" ++ case_text ++ " break;\n"
            return out ++ "    default: break;\n    " ++ cc_rbrace() ++ "\n"
        if tk == TypeKind.TY_STRUCT or self.generic_inst_is_declared_struct(resolved):
            let names = self.glue_field_names(resolved)
            let tids = self.glue_field_tids(resolved)
            var out = ""
            for fi in 0..names.len():
                let call = self.copy_call_text(lv ++ "." ++ names[fi], tids[fi])
                if call.len() > 0:
                    out = out ++ "    " ++ call ++ "\n"
            return out
        self.fail("emit-c: no copy glue for Copy type " ++ self.sema.type_name(resolved) ++ " (D111)")
        "    abort();\n"

    // D120: after make-unique copied a shared buffer, each element with copy
    // glue is one more holder of what it shares.
    mut fn list_make_unique_text(recv_ptr: &str, elem: i32) -> str:
        let elem_c = self.c_type(elem, 0)
        let es = "(int64_t)sizeof(" ++ elem_c ++ ")"
        if not self.glue_needed(elem):
            return "    (void)with_vec_make_unique_bits(" ++ recv_ptr ++ ", " ++ es ++ ");\n"
        "    if (with_vec_make_unique_bits(" ++ recv_ptr ++ ", " ++ es ++ ")) " ++ cc_lbrace() ++ " with_vec* __l = " ++ recv_ptr ++ "; for (int64_t __i = 0; __i < __l->len; __i++) " ++ cc_lbrace() ++ " " ++ self.copy_call_text("((" ++ elem_c ++ "*)__l->ptr)[__i]", elem) ++ " " ++ cc_rbrace() ++ " " ++ cc_rbrace() ++ "\n"

    mut fn map_make_unique_text(recv: &str, map_tid: i32) -> str:
        let entries = self.map_entries_glue_text(self.sema.resolve_alias(map_tid as TypeId) as i32, true)
        if entries.len() == 0:
            return "    (void)with_hashmap_make_unique((void**)&(" ++ recv ++ "));\n"
        "    if (with_hashmap_make_unique((void**)&(" ++ recv ++ "))) " ++ cc_lbrace() ++ " uint8_t* __h = (uint8_t*)(intptr_t)(" ++ recv ++ "); " ++ entries ++ cc_rbrace() ++ "\n"

    // An insert of `__with_k`/`__with_v` into `handle`: ordinary insert and
    // literals transfer the same owners; a duplicate keeps the stored key,
    // drops the unused incoming one and replaces the value, dropping the old
    // (mir_emit_owned_map_insert). `value_tid` is 0 for a set.
    mut fn owned_map_insert_text(handle: &str, is_str_key: &str, key_tid: i32, value_tid: i32) -> str:
        let insert = " with_hashmap_insert(" ++ handle ++ ", &__with_k, &__with_v, " ++ is_str_key ++ ");"
        let key_glue = self.glue_needed(key_tid)
        let value_glue = value_tid != 0 and self.glue_needed(value_tid)
        if not key_glue and not value_glue:
            return insert
        var replace = ""
        if value_glue:
            let value_c = self.c_type(value_tid, 0)
            replace = replace ++ " " ++ self.drop_call_text("(*(" ++ value_c ++ "*)__with_old)", value_tid, true)
        if value_tid != 0:
            replace = replace ++ " memcpy(__with_old, &__with_v, sizeof(__with_v));"
        if key_glue:
            replace = replace ++ " " ++ self.drop_call_text("__with_k", key_tid, true)
        " void* __with_old = with_hashmap_get_ptr(" ++ handle ++ ", &__with_k, " ++ is_str_key ++ "); if (__with_old != NULL) " ++ cc_lbrace() ++ replace ++ " " ++ cc_rbrace() ++ " else" ++ insert

    // ── operand holds (D111) ──

    // An operand MIR recorded a hold for, as the consumer reads it: a
    // retained copy takes a hold on what the source carries; a taken copy
    // hands the value over and blanks the source, so the source's drop
    // releases nothing. The work lands before the statement (hold_pre), once
    // however often the statement's text names the operand.
    mut fn held_operand_text(body: &MirBody, operand_id: i32, place_id: i32, hold: i32, text: &str) -> str:
        let done = self.hold_texts.get(operand_id)
        if done.is_some():
            return done.unwrap()
        let tid = self.place_sema_tid(body, place_id)
        var out: str = text
        if hold == MIR_HOLD_TAKE:
            out = f"__with_take{self.hold_counter}"
            self.hold_counter = self.hold_counter + 1
            if self.sema.get_type_kind(self.sema.resolve_alias(tid as TypeId)) == TypeKind.TY_ARRAY:
                self.hold_pre = self.hold_pre ++ " __typeof__(" ++ text ++ ") " ++ out ++ "; memcpy(" ++ out ++ ", " ++ text ++ ", sizeof(" ++ out ++ "));"
            else:
                self.hold_pre = self.hold_pre ++ " __typeof__(" ++ text ++ ") " ++ out ++ " = " ++ text ++ ";"
            self.hold_pre = self.hold_pre ++ " memset(&(" ++ text ++ "), 0, sizeof(" ++ text ++ "));"
        else if tid == self.sema.ty_str as i32 and body.place_proj_counts[place_id] > 0 and body.proj_kinds[(body.place_proj_starts[place_id] + body.place_proj_counts[place_id] - 1)] == ProjKind.PK_DEREF:
            // #2307: a str read through a view owns its bytes: shared when
            // the view starts an owned buffer, copied otherwise.
            out = f"__with_own{self.hold_counter}"
            self.hold_counter = self.hold_counter + 1
            self.hold_pre = self.hold_pre ++ " with_str " ++ out ++ " = with_str_own_view(" ++ text ++ ");"
        else:
            self.hold_pre = self.hold_pre ++ " " ++ self.copy_call_text(text, tid)
        self.hold_texts.insert(operand_id, out)
        // Seed-bound: the stored copy, not `out`. Every seed through the
        // 2026-10-25 one lowers a tail `out` after `insert(…, out)` as a
        // read of the blank the insert's last-use take left (the tail
        // StorageDead fix in this stack); the next seed pin returns `out`.
        self.hold_texts.get(operand_id).unwrap()

    // A statement or terminator's text with its holds in front of it.
    mut fn with_holds(text: &str) -> str:
        if self.hold_pre.len() == 0:
            return text
        "    " ++ cc_lbrace() ++ self.hold_pre ++ "\n" ++ text ++ "\n    " ++ cc_rbrace()

    // `RK_USE` of a `CK_ZERO_SIZED` constant: the reset-on-move blank.
    fn rvalue_is_zero_const(body: &MirBody, rval_id: i32) -> bool:
        if rval_id < 0 or rval_id >= body.rval_kinds.len() or body.rval_kinds[rval_id] != RvalueKind.RK_USE:
            return false
        let op = body.rval_d0[rval_id]
        if op < 0 or op >= body.operand_kinds.len() or body.operand_kinds[op] != OperandKind.OK_CONSTANT:
            return false
        let cid = body.operand_d0[op]
        cid >= 0 and cid < body.const_kinds.len() and body.const_kinds[cid] == ConstKind.CK_ZERO_SIZED

    mut fn begin_holds():
        self.hold_active = true
        self.hold_pre = ""
        self.hold_texts = HashMap.new()

// ── Map keys (§11.7, D96, #2180) ─────────────────────────────────────
//
// A key that is not its bytes (a tuple, a struct, an enum with payloads, a
// List, a str inside any of them) is hashed and compared by functions
// generated for its type, part by part in the order the LLVM backend's
// mir_emit_hash_ptrs and mir_emit_eq_ptrs walk it, so equal keys hash
// alike. A key with its own `Eq` or a key projection is refused here, not
// compared by its parts.
impl CCodegen:
    // A type whose parts the walks visit; any other is compared and hashed
    // by its bytes (an integer, a float, a bool, a pointer, a plain enum, an
    // opaque runtime handle).
    fn key_type_has_walk(resolved: i32) -> bool:
        let tk = self.sema.get_type_kind(resolved as TypeId)
        if tk == TypeKind.TY_TUPLE or tk == TypeKind.TY_ARRAY:
            return true
        // §4.5: a distinct type is its underlying type in C (a typedef).
        if tk == TypeKind.TY_STRUCT and self.sema.distinct_type_names.contains(self.sema.get_type_d0(resolved as TypeId)):
            return self.key_type_has_walk(self.sema.resolve_alias(self.sema.type_extra[(self.sema.get_type_d1(resolved as TypeId) + 1)] as TypeId) as i32)
        if tk == TypeKind.TY_STRUCT:
            return true
        if self.type_is_payload_enum(resolved) != 0:
            return true
        if tk == TypeKind.TY_GENERIC_INST:
            return self.sema.get_generic_inst_base(resolved) == self.sema.syms.list or self.std_box_pointee_tid(resolved) != 0 or self.generic_inst_is_declared_struct(resolved)
        false

    mut fn key_refuse_projection(resolved: i32) -> bool:
        if self.sema.concrete_key_sigs.contains(resolved):
            self.fail("emit-c: a map key of type " ++ self.sema.type_name(resolved) ++ " hashes and compares by its key projection, which the C backend does not call yet (#2180)")
            return true
        false

    // A type with an `eq` of its own (derived or written) compares by it:
    // its specialization (Sema's concrete_eq_mono_syms), each argument
    // passed as its C prototype takes it.
    mut fn concrete_eq_call_text(la: &str, lb: &str, resolved: i32) -> str:
        let mono: i32 = self.sema.concrete_eq_mono_syms.get(resolved) ?? 0
        let body_sym = self.canonical_body_sym(mono)
        if body_sym == 0:
            self.fail("emit-c: the eq of map key type " ++ self.sema.type_name(resolved) ++ " has no lowered body to call (#2180)")
            return "0"
        let sig = self.sig_index_for_sym(body_sym)
        var args = ""
        for i in 0..2:
            let lv = if i == 0: la else: lb
            let p_tid = if sig >= 0: self.sema.sig_param_type(sig, i) else: 0
            let by_ref = self.fn_param_is_c_pointer(body_sym, i) != 0 or (p_tid > 0 and self.sema.get_type_kind(self.sema.resolve_alias(p_tid as TypeId)) == TypeKind.TY_REF)
            if i > 0: args = args ++ ", "
            args = args ++ (if by_ref: "&(" ++ lv ++ ")" else: lv)
        "(" ++ self.fn_c_name(body_sym) ++ "(" ++ args ++ ") != 0)"

    // Statements feeding the value at `lv` (of `tid`) to the hasher `st`.
    mut fn key_hash_text(lv: &str, tid: i32, st: &str) -> str:
        let resolved = self.sema.resolve_alias(tid as TypeId) as i32
        if self.key_refuse_projection(resolved):
            return ""
        let tk = self.sema.get_type_kind(resolved as TypeId)
        if tk == TypeKind.TY_STR or self.sema.type_layout_is_str_view(resolved):
            return " with_hasher_write_str(" ++ st ++ ", " ++ lv ++ ");"
        if tk == TypeKind.TY_REF:
            return self.key_hash_text("(*" ++ lv ++ ")", self.sema.get_type_d0(resolved as TypeId), st)
        if self.key_type_has_walk(resolved):
            let name = self.ensure_key_walk("hash", resolved)
            return " " ++ name ++ "(" ++ self.glue_arg(lv, resolved) ++ ", " ++ st ++ ");"
        " with_hasher_write(" ++ st ++ ", (const uint8_t*)&(" ++ lv ++ "), (int64_t)sizeof(" ++ lv ++ "));"

    // An expression: whether the values at `la` and `lb` (of `tid`) are equal.
    mut fn key_eq_text(la: &str, lb: &str, tid: i32) -> str:
        let resolved = self.sema.resolve_alias(tid as TypeId) as i32
        if self.key_refuse_projection(resolved):
            return "0"
        if self.sema.concrete_eq_sigs.contains(resolved):
            return self.concrete_eq_call_text(la, lb, resolved)
        let tk = self.sema.get_type_kind(resolved as TypeId)
        if tk == TypeKind.TY_STR or self.sema.type_layout_is_str_view(resolved):
            return "with_str_eq_ref(" ++ la ++ ", " ++ lb ++ ")"
        if tk == TypeKind.TY_REF:
            return self.key_eq_text("(*" ++ la ++ ")", "(*" ++ lb ++ ")", self.sema.get_type_d0(resolved as TypeId))
        if self.key_type_has_walk(resolved):
            let name = self.ensure_key_walk("eq", resolved)
            return name ++ "(" ++ self.glue_arg(la, resolved) ++ ", " ++ self.glue_arg(lb, resolved) ++ ")"
        if tk == TypeKind.TY_INT or tk == TypeKind.TY_BOOL or tk == TypeKind.TY_FLOAT or tk == TypeKind.TY_PTR or tk == TypeKind.TY_ENUM:
            return "((" ++ la ++ ") == (" ++ lb ++ "))"
        "(memcmp(&(" ++ la ++ "), &(" ++ lb ++ "), sizeof(" ++ la ++ ")) == 0)"

    // `__with_keyhash_<t>(p, st)` / `__with_keyeq_<t>(a, b)`: one aggregate
    // type's walk, declared before its body so a recursive type calls it.
    mut fn ensure_key_walk(kind: &str, resolved: i32) -> str:
        let name = f"__with_keywalk_{kind}_{resolved}"
        if self.glue_done.contains(name):
            return name
        self.mark_glue_done(name)
        let param_c = self.glue_param_c_type(resolved)
        let is_array = self.sema.get_type_kind(resolved as TypeId) == TypeKind.TY_ARRAY
        if kind == "hash":
            let sig = "static void " ++ name ++ "(" ++ param_c ++ "* p, uint8_t* st)"
            self.glue_protos.push(sig ++ ";\n")
            let body = self.key_hash_walk_text(if is_array: "p" else: "(*p)", resolved)
            self.glue_defs.push(sig ++ " " ++ cc_lbrace() ++ body ++ " " ++ cc_rbrace() ++ "\n")
        else:
            let sig = "static int32_t " ++ name ++ "(" ++ param_c ++ "* a, " ++ param_c ++ "* b)"
            self.glue_protos.push(sig ++ ";\n")
            let body = self.key_eq_walk_text(if is_array: "a" else: "(*a)", if is_array: "b" else: "(*b)", resolved)
            self.glue_defs.push(sig ++ " " ++ cc_lbrace() ++ body ++ " return 1; " ++ cc_rbrace() ++ "\n")
        name

    mut fn key_hash_walk_text(lv: &str, resolved: i32) -> str:
        let tk = self.sema.get_type_kind(resolved as TypeId)
        if tk == TypeKind.TY_TUPLE:
            var out = ""
            for i in 0..self.sema.get_type_d1(resolved as TypeId):
                out = out ++ self.key_hash_text(lv ++ f".field{i}", self.tuple_field_tid(resolved, i), "st")
            return out
        if tk == TypeKind.TY_ARRAY:
            let n = self.sema.get_type_d1(resolved as TypeId)
            return f" for (int64_t __i = 0; __i < {n}; __i++) " ++ cc_lbrace() ++ self.key_hash_text(lv ++ "[__i]", self.sema.get_type_d0(resolved as TypeId), "st") ++ " " ++ cc_rbrace()
        if tk == TypeKind.TY_GENERIC_INST and self.sema.get_generic_inst_base(resolved) == self.sema.syms.list:
            let elem = self.sema.get_generic_inst_arg(resolved, 0)
            let elem_c = self.c_type(elem, 0)
            let each = self.key_hash_text("((" ++ elem_c ++ "*)(" ++ lv ++ ").ptr)[__i]", elem, "st")
            return " with_hasher_write(st, (const uint8_t*)&(" ++ lv ++ ").len, 8); for (int64_t __i = 0; __i < (" ++ lv ++ ").len; __i++) " ++ cc_lbrace() ++ each ++ " " ++ cc_rbrace()
        let box_pointee = self.std_box_pointee_tid(resolved)
        if box_pointee != 0:
            if self.sema.get_type_kind(self.sema.resolve_alias(box_pointee as TypeId)) == TypeKind.TY_TRAIT_OBJ:
                return " with_hasher_write(st, (const uint8_t*)&(" ++ lv ++ "), (int64_t)sizeof(" ++ lv ++ "));"
            return self.key_hash_text("(*(" ++ lv ++ "))", box_pointee, "st")
        if self.type_is_payload_enum(resolved) != 0:
            if self.option_is_nullable_pointer(resolved):
                var payload: i32 = 0
                for vi in 0..self.sema.type_reflection_variant_count(resolved):
                    if self.sema.type_reflection_variant_payload_count(resolved, vi) == 1:
                        payload = self.sema.type_reflection_variant_payload_type_frozen(resolved, vi, 0)
                return " " ++ cc_lbrace() ++ " uint8_t __some = (" ++ lv ++ ") != 0; with_hasher_write(st, &__some, 1); if (__some) " ++ cc_lbrace() ++ self.key_hash_text(lv, payload, "st") ++ " " ++ cc_rbrace() ++ " " ++ cc_rbrace()
            var out = " with_hasher_write(st, (const uint8_t*)&(" ++ lv ++ ").tag, (int64_t)sizeof((" ++ lv ++ ").tag)); switch ((" ++ lv ++ ").tag) " ++ cc_lbrace()
            for vi in 0..self.sema.type_reflection_variant_count(resolved):
                let pc = self.sema.type_reflection_variant_payload_count(resolved, vi)
                if pc == 0:
                    continue
                out = out ++ f" case {self.sema.type_reflection_variant_discriminant(resolved, vi)}:"
                for pi in 0..pc:
                    out = out ++ self.key_hash_text(lv ++ self.payload_enum_field_path(resolved, vi, pi), self.sema.type_reflection_variant_payload_type_frozen(resolved, vi, pi), "st")
                out = out ++ " break;"
            return out ++ " default: break; " ++ cc_rbrace()
        if tk == TypeKind.TY_STRUCT and self.sema.distinct_type_names.contains(self.sema.get_type_d0(resolved as TypeId)):
            return self.key_hash_text(lv, self.sema.type_extra[(self.sema.get_type_d1(resolved as TypeId) + 1)], "st")
        let names = self.glue_field_names(resolved)
        let tids = self.glue_field_tids(resolved)
        var out = ""
        for fi in 0..names.len():
            out = out ++ self.key_hash_text(lv ++ "." ++ names[fi], tids[fi], "st")
        out

    mut fn key_eq_walk_text(la: &str, lb: &str, resolved: i32) -> str:
        let tk = self.sema.get_type_kind(resolved as TypeId)
        if tk == TypeKind.TY_TUPLE:
            var out = ""
            for i in 0..self.sema.get_type_d1(resolved as TypeId):
                let tid = self.tuple_field_tid(resolved, i)
                out = out ++ " if (!" ++ self.key_eq_text(la ++ f".field{i}", lb ++ f".field{i}", tid) ++ ") return 0;"
            return out
        if tk == TypeKind.TY_ARRAY:
            let n = self.sema.get_type_d1(resolved as TypeId)
            let elem = self.sema.get_type_d0(resolved as TypeId)
            return f" for (int64_t __i = 0; __i < {n}; __i++) " ++ cc_lbrace() ++ " if (!" ++ self.key_eq_text(la ++ "[__i]", lb ++ "[__i]", elem) ++ ") return 0; " ++ cc_rbrace()
        if tk == TypeKind.TY_GENERIC_INST and self.sema.get_generic_inst_base(resolved) == self.sema.syms.list:
            let elem = self.sema.get_generic_inst_arg(resolved, 0)
            let elem_c = self.c_type(elem, 0)
            let each = self.key_eq_text("((" ++ elem_c ++ "*)(" ++ la ++ ").ptr)[__i]", "((" ++ elem_c ++ "*)(" ++ lb ++ ").ptr)[__i]", elem)
            return " if ((" ++ la ++ ").len != (" ++ lb ++ ").len) return 0; for (int64_t __i = 0; __i < (" ++ la ++ ").len; __i++) " ++ cc_lbrace() ++ " if (!" ++ each ++ ") return 0; " ++ cc_rbrace()
        let box_pointee = self.std_box_pointee_tid(resolved)
        if box_pointee != 0:
            if self.sema.get_type_kind(self.sema.resolve_alias(box_pointee as TypeId)) == TypeKind.TY_TRAIT_OBJ:
                return " if ((" ++ la ++ ") != (" ++ lb ++ ")) return 0;"
            return " if (!" ++ self.key_eq_text("(*(" ++ la ++ "))", "(*(" ++ lb ++ "))", box_pointee) ++ ") return 0;"
        if self.type_is_payload_enum(resolved) != 0:
            if self.option_is_nullable_pointer(resolved):
                var payload: i32 = 0
                for vi in 0..self.sema.type_reflection_variant_count(resolved):
                    if self.sema.type_reflection_variant_payload_count(resolved, vi) == 1:
                        payload = self.sema.type_reflection_variant_payload_type_frozen(resolved, vi, 0)
                return " if (((" ++ la ++ ") == 0) != ((" ++ lb ++ ") == 0)) return 0; if ((" ++ la ++ ") != 0 && !" ++ self.key_eq_text(la, lb, payload) ++ ") return 0;"
            var out = " if ((" ++ la ++ ").tag != (" ++ lb ++ ").tag) return 0; switch ((" ++ la ++ ").tag) " ++ cc_lbrace()
            for vi in 0..self.sema.type_reflection_variant_count(resolved):
                let pc = self.sema.type_reflection_variant_payload_count(resolved, vi)
                if pc == 0:
                    continue
                out = out ++ f" case {self.sema.type_reflection_variant_discriminant(resolved, vi)}:"
                for pi in 0..pc:
                    let path = self.payload_enum_field_path(resolved, vi, pi)
                    out = out ++ " if (!" ++ self.key_eq_text(la ++ path, lb ++ path, self.sema.type_reflection_variant_payload_type_frozen(resolved, vi, pi)) ++ ") return 0;"
                out = out ++ " break;"
            return out ++ " default: break; " ++ cc_rbrace()
        if tk == TypeKind.TY_STRUCT and self.sema.distinct_type_names.contains(self.sema.get_type_d0(resolved as TypeId)):
            return " if (!" ++ self.key_eq_text(la, lb, self.sema.type_extra[(self.sema.get_type_d1(resolved as TypeId) + 1)]) ++ ") return 0;"
        let names = self.glue_field_names(resolved)
        let tids = self.glue_field_tids(resolved)
        var out = ""
        for fi in 0..names.len():
            out = out ++ " if (!" ++ self.key_eq_text(la ++ "." ++ names[fi], lb ++ "." ++ names[fi], tids[fi]) ++ ") return 0;"
        out

    // `__with_keyhash_<t>(const void*) -> int64_t`, the hash the runtime
    // map calls: a keyed hasher fed the key's parts.
    mut fn key_hash_fn_name(resolved: i32) -> str:
        let name = f"__with_keyhash_{resolved}"
        if self.glue_done.contains(name):
            return name
        self.mark_glue_done(name)
        let sig = "static int64_t " ++ name ++ "(const void* k)"
        self.glue_protos.push(sig ++ ";\n")
        let key_c = self.glue_param_c_type(resolved)
        let lv = if self.sema.get_type_kind(resolved as TypeId) == TypeKind.TY_ARRAY: "((" ++ key_c ++ "*)k)" else: "(*(" ++ key_c ++ "*)k)"
        let feed = self.key_hash_text(lv, resolved, "(uint8_t*)__st")
        self.glue_defs.push(sig ++ " " ++ cc_lbrace() ++ " uint64_t __st[7]; with_hasher_init((uint8_t*)__st);" ++ feed ++ " return with_hasher_finish((uint8_t*)__st); " ++ cc_rbrace() ++ "\n")
        name

    // `__with_keyeq_<t>(const void*, const void*) -> int32_t`.
    mut fn key_eq_fn_name(resolved: i32) -> str:
        let name = f"__with_keyeqfn_{resolved}"
        if self.glue_done.contains(name):
            return name
        self.mark_glue_done(name)
        let sig = "static int32_t " ++ name ++ "(const void* a, const void* b)"
        self.glue_protos.push(sig ++ ";\n")
        let key_c = self.glue_param_c_type(resolved)
        let is_array = self.sema.get_type_kind(resolved as TypeId) == TypeKind.TY_ARRAY
        let la = if is_array: "((" ++ key_c ++ "*)a)" else: "(*(" ++ key_c ++ "*)a)"
        let lb = if is_array: "((" ++ key_c ++ "*)b)" else: "(*(" ++ key_c ++ "*)b)"
        let equal = self.key_eq_text(la, lb, resolved)
        self.glue_defs.push(sig ++ " " ++ cc_lbrace() ++ " return " ++ equal ++ " ? 1 : 0; " ++ cc_rbrace() ++ "\n")
        name
