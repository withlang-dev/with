// CCodegen — conservative MIR → C11 emitter used by `with build --emit-c`.
//
// This backend intentionally supports the same conservative MIR subset that
// LLVM MIR codegen currently accepts directly. When MIR contains unsupported
// constructs, emission fails with a clear error.

use Mir
use Ast
use InternPool
use Sema
use Source
use compiler.EmbeddedStdlib
use Overflow

extern fn with_fs_read_file(path: str) -> str
extern fn with_i64_to_str(n: i64) -> str
extern fn str_from_byte(b: i32) -> str
extern fn with_interrupt_requested() -> i32
extern fn with_fmt_buf_new() -> *mut u8
extern fn with_fmt_buf_write_str(buf: *mut u8, s: str)
extern fn with_fmt_buf_finish(buf: *mut u8) -> str

type COut {
    buf: *mut u8,
}

fn COut.new -> COut:
    COut { buf: with_fmt_buf_new() }

fn COut.write(self: COut, text: str):
    with_fmt_buf_write_str(self.buf, text)

fn COut.finish(self: COut) -> str:
    with_fmt_buf_finish(self.buf)

fn cc_intern_resolve(intern: InternPool, sym: i32) -> str:
    intern.resolve_symbol(sym)


fn cc_lbrace -> str:
    str_from_byte(123)

fn cc_rbrace -> str:
    str_from_byte(125)

let CC_PSEUDO_TID_VEC = 1900001
let CC_PSEUDO_TID_FMT_BUF = 1900002

enum CcPlaceKind: i32:
    UNKNOWN
    VEC
    HASHMAP
    OPTION

// Copy: these C-backend tag enums are lightweight values passed by value,
// cached in HashMaps, and compared throughout codegen.
impl Copy for CcPlaceKind

enum CcBuiltin: i32:
    NONE
    VEC_NEW
    VEC_PUSH
    VEC_GET
    VEC_LEN
    VEC_SET_I32
    VEC_REMOVE
    VEC_CLEAR
    MAP_NEW
    MAP_INSERT
    MAP_GET
    MAP_CONTAINS
    MAP_LEN
    MAP_REMOVE
    OPT_IS_SOME
    OPT_UNWRAP
    VEC_POP
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
    STR_TRIM
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
    VEC_SLOT
    VECSLOT_GET
    VECSLOT_SET
    FMT_BUF_NEW
    FMT_BUF_WRITE_STR
    FMT_BUF_WRITE_FMT
    FMT_BUF_FINISH
    ATOMIC_LOAD
    ATOMIC_STORE
    ATOMIC_SWAP
    VEC_GET_DISJOINT
    DYN_CALL
    SLOTMAP
    MULTI_INDEX
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
    VECRANGE

impl Copy for CcBuiltin

fn cc_builtin_uses_vec_receiver(kind: CcBuiltin) -> bool:
    if kind == CcBuiltin.VEC_PUSH: return true
    if kind == CcBuiltin.VEC_GET: return true
    if kind == CcBuiltin.VEC_LEN: return true
    if kind == CcBuiltin.VEC_LEN32: return true
    if kind == CcBuiltin.VEC_LEN64: return true
    if kind == CcBuiltin.VEC_ULEN32: return true
    if kind == CcBuiltin.VEC_SET_I32: return true
    if kind == CcBuiltin.VEC_REMOVE: return true
    if kind == CcBuiltin.VEC_CLEAR: return true
    if kind == CcBuiltin.VEC_POP: return true
    if kind == CcBuiltin.VEC_ITER: return true
    if kind == CcBuiltin.VEC_MAP: return true
    if kind == CcBuiltin.VEC_FILTER: return true
    if kind == CcBuiltin.VEC_FOLD: return true
    if kind == CcBuiltin.VEC_CONTAINS: return true
    if kind == CcBuiltin.VEC_JOIN: return true
    if kind == CcBuiltin.VEC_SLOT: return true
    if kind == CcBuiltin.VEC_GET_DISJOINT: return true
    false

fn cc_builtin_uses_option_receiver(kind: CcBuiltin) -> bool:
    if kind == CcBuiltin.OPT_IS_SOME: return true
    if kind == CcBuiltin.OPT_IS_NONE: return true
    if kind == CcBuiltin.OPT_UNWRAP: return true
    if kind == CcBuiltin.OPT_FILTER: return true
    false

enum CcCalleeHint: i32:
    NONE
    VEC_RECV
    MAP_RECV
    OPT_RECV
    VEC_NEW
    MAP_NEW
    OPT_NEW

impl Copy for CcCalleeHint

enum CcLenMode: i32:
    USIZE
    I32
    I64
    U32

impl Copy for CcLenMode

fn cc_is_len_method(method: str) -> bool:
    method == "len" or method == "len32" or method == "len64" or method == "ulen32"

fn cc_len_method_builtin(base: CcBuiltin, method: str) -> CcBuiltin:
    if method == "len":
        return base
    if method == "len32":
        if base == CcBuiltin.VEC_LEN: return CcBuiltin.VEC_LEN32
        if base == CcBuiltin.MAP_LEN: return CcBuiltin.MAP_LEN32
        if base == CcBuiltin.STR_LEN: return CcBuiltin.STR_LEN32
        if base == CcBuiltin.ARR_LEN: return CcBuiltin.ARR_LEN32
    if method == "len64":
        if base == CcBuiltin.VEC_LEN: return CcBuiltin.VEC_LEN64
        if base == CcBuiltin.MAP_LEN: return CcBuiltin.MAP_LEN64
        if base == CcBuiltin.STR_LEN: return CcBuiltin.STR_LEN64
        if base == CcBuiltin.ARR_LEN: return CcBuiltin.ARR_LEN64
    if method == "ulen32":
        if base == CcBuiltin.VEC_LEN: return CcBuiltin.VEC_ULEN32
        if base == CcBuiltin.MAP_LEN: return CcBuiltin.MAP_ULEN32
        if base == CcBuiltin.STR_LEN: return CcBuiltin.STR_ULEN32
        if base == CcBuiltin.ARR_LEN: return CcBuiltin.ARR_ULEN32
    CcBuiltin.NONE

fn cc_builtin_len_mode(kind: CcBuiltin) -> CcLenMode:
    if kind == CcBuiltin.VEC_LEN32 or kind == CcBuiltin.MAP_LEN32 or kind == CcBuiltin.STR_LEN32 or kind == CcBuiltin.ARR_LEN32:
        return CcLenMode.I32
    if kind == CcBuiltin.VEC_LEN64 or kind == CcBuiltin.MAP_LEN64 or kind == CcBuiltin.STR_LEN64 or kind == CcBuiltin.ARR_LEN64:
        return CcLenMode.I64
    if kind == CcBuiltin.VEC_ULEN32 or kind == CcBuiltin.MAP_ULEN32 or kind == CcBuiltin.STR_ULEN32 or kind == CcBuiltin.ARR_ULEN32:
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

fn cc_builtin_is_vec_len(kind: CcBuiltin) -> bool:
    kind == CcBuiltin.VEC_LEN or kind == CcBuiltin.VEC_LEN32 or kind == CcBuiltin.VEC_LEN64 or kind == CcBuiltin.VEC_ULEN32

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
    di_source: Source,
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
    active_local_body_fns: Vec[i32],
    active_local_ids: Vec[i32],
    active_method_syms: Vec[i32],
    active_method_args: Vec[i32],
    active_method_dests: Vec[i32],
    active_direct_args: Vec[i32],
    active_direct_dests: Vec[i32],
    call_infer_cache: HashMap[str, i32],
    field_cache_struct_tids: Vec[i32],
    field_cache_syms: Vec[i32],
    field_cache_tids: Vec[i32],
    field_cache_ready: i32,
    in_field_cache_build: i32,
    local_infer_cache: HashMap[i64, i32],
    local_usage_hint_cache: HashMap[i64, i32],
    local_call_ret_cache: HashMap[i64, i32],
    local_copied_payload_cache: HashMap[i64, i32],
    local_downcast_option_cache: HashMap[i64, i32],
    local_effective_cache: HashMap[i64, i32],
    local_ref_target_cache: HashMap[i64, i32],
    local_value_use_cache: HashMap[i64, i32],
    // Stored as raw i32 (the enum's backing repr): the compiler-backed
    // HashMap.get cannot synthesize Option[enum] to match a written return
    // annotation, so the typed enum is reconstructed at the accessor boundary.
    place_kind_cache: HashMap[i64, i32],
    callee_hint_cache: HashMap[i32, i32],
}

fn CCodegen.intern_intern(self: CCodegen, s: str) -> i32:
    self.intern.intern(s)

fn c_emit_module(mir_mod: MirModule, ast: AstPool, intern: InternPool, sema: Sema, source_path: str, source_text: str, overflow_mode: i32) -> CEmitResult:
    var cg = CCodegen {
        mir_mod,
        ast,
        intern,
        sema,
        overflow_mode,
        had_error: 0,
        err_msg: "",
        source_path,
        source_text,
        di_source: Source.from_string(source_path, source_text, 0),
        last_line_directive: 0,
        body_fn_map: HashMap.new(),
        body_fn_name_map: HashMap.new(),
        canonical_body_cache: HashMap.new(),
        fn_pointer_param_cache: HashMap.new(),
        sig_idx_cache: HashMap.new(),
        infer_local_depth: 0,
        active_local_body_fns: Vec.new(),
        active_local_ids: Vec.new(),
        active_method_syms: Vec.new(),
        active_method_args: Vec.new(),
        active_method_dests: Vec.new(),
        active_direct_args: Vec.new(),
        active_direct_dests: Vec.new(),
        call_infer_cache: HashMap.new(),
        field_cache_struct_tids: Vec.new(),
        field_cache_syms: Vec.new(),
        field_cache_tids: Vec.new(),
        field_cache_ready: 0,
        in_field_cache_build: 0,
        local_infer_cache: HashMap.new(),
        local_usage_hint_cache: HashMap.new(),
        local_call_ret_cache: HashMap.new(),
        local_copied_payload_cache: HashMap.new(),
        local_downcast_option_cache: HashMap.new(),
        local_effective_cache: HashMap.new(),
        local_ref_target_cache: HashMap.new(),
        local_value_use_cache: HashMap.new(),
        place_kind_cache: HashMap.new(),
        callee_hint_cache: HashMap.new(),
    }
    for i in 0..mir_mod.body_fn_syms.len() as i32:
        let sym = mir_mod.body_fn_syms.get(i as i64)
        cg.body_fn_map.insert(sym, 1)
    let src = cg.emit_module()
    if cg.had_error != 0:
        return CEmitResult { ok: 0, source: "", err_msg: cg.err_msg }
    CEmitResult { ok: 1, source: src, err_msg: "" }

fn CCodegen.fail(self: CCodegen, msg: str):
    if self.had_error != 0:
        return
    self.had_error = 1
    self.err_msg = msg

fn CCodegen.check_interrupted(self: CCodegen) -> i32:
    if with_interrupt_requested() == 0:
        return 0
    self.fail("interrupted by signal")
    1

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

fn cc_escape_c_string(text: str) -> str:
    var out = StringBuilder.with_capacity(text.len())
    for i in 0..text.len():
        let b = text.byte_at(i as i64)
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
        // Octal escapes for non-ASCII bytes: no hex continuation ambiguity,
        // and handles signed byte_at values (byte > 127 returns negative i32).
        let ub = if b < 0: b + 256 else: b
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

fn cc_decode_with_string_escapes(text: str) -> str:
    var out = StringBuilder.with_capacity(text.len())
    var i = 0
    while i < text.len() as i32:
        let ch = text.byte_at(i as i64)
        if ch == 92 and i + 1 < text.len() as i32:
            i = i + 1
            let esc = text.byte_at(i as i64)
            if esc == 120 and i + 2 < text.len() as i32:
                let hi = cc_hex_digit_value(text.byte_at((i + 1) as i64))
                let lo = cc_hex_digit_value(text.byte_at((i + 2) as i64))
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

fn cc_string_literal_payload(raw: str) -> str:
    if raw.len() >= 5 and raw.byte_at(0) == 1 and raw.byte_at(1) == 114 and raw.byte_at(2) == 97 and raw.byte_at(3) == 119 and raw.byte_at(4) == 1:
        return raw.slice(5, raw.len())
    cc_decode_with_string_escapes(raw)

fn cc_is_raw_string_token_text(text: str) -> i32:
    if text.len() < 3:
        return 0
    if text.byte_at(0) != 114:  // r
        return 0
    var i = 1
    while i < text.len() as i32 and text.byte_at(i as i64) == 35:  // #
        i = i + 1
    let hash_count = i - 1
    if i >= text.len() as i32 or text.byte_at(i as i64) != 34:
        return 0
    let len = text.len() as i32
    if len < i + 2 + hash_count:
        return 0
    let close_quote = len - hash_count - 1
    if close_quote <= i or text.byte_at(close_quote as i64) != 34:
        return 0
    var hi = 0
    while hi < hash_count:
        if text.byte_at((close_quote + 1 + hi) as i64) != 35:
            return 0
        hi = hi + 1
    1

fn cc_is_quoted_string_token_text(text: str, prefix_len: i32) -> i32:
    let len = text.len() as i32
    if len < prefix_len + 2:
        return 0
    if text.byte_at(prefix_len as i64) != 34:
        return 0
    if text.byte_at((len - 1) as i64) != 34:
        return 0
    var i = prefix_len + 1
    while i < len - 1:
        let ch = text.byte_at(i as i64)
        if ch == 10 or ch == 13:
            return 0
        if ch == 34:
            var slash_count = 0
            var j = i - 1
            while j >= prefix_len + 1 and text.byte_at(j as i64) == 92:
                slash_count = slash_count + 1
                j = j - 1
            if slash_count % 2 == 0:
                return 0
        i = i + 1
    1

fn cc_string_token_payload(text: str) -> str:
    if cc_is_raw_string_token_text(text) != 0:
        var i = 1
        while i < text.len() as i32 and text.byte_at(i as i64) == 35:
            i = i + 1
        if i < text.len() as i32 and text.byte_at(i as i64) == 34:
            let content_start = i + 1
            var end_q = text.len() as i32 - 1
            while end_q >= content_start and text.byte_at(end_q as i64) == 35:
                end_q = end_q - 1
            if end_q >= content_start and text.byte_at(end_q as i64) == 34:
                return text.slice(content_start as i64, end_q as i64)
    if cc_is_quoted_string_token_text(text, 0) != 0:
        return cc_decode_with_string_escapes(text.slice(1, text.len() as i64 - 1))
    if text.len() >= 3 and text.byte_at(0) == 102 and cc_is_quoted_string_token_text(text, 1) != 0:
        return cc_decode_with_string_escapes(text.slice(2, text.len() as i64 - 1))
    ""

fn cc_is_string_token_text(text: str) -> i32:
    if cc_is_raw_string_token_text(text) != 0:
        return 1
    if cc_is_quoted_string_token_text(text, 0) != 0:
        return 1
    if text.len() >= 3 and text.byte_at(0) == 102 and cc_is_quoted_string_token_text(text, 1) != 0:
        return 1
    0

fn CCodegen.string_literal_node_payload(self: CCodegen, node: i32) -> str:
    self.string_literal_node_payload_from_source(node, self.source_text)

fn CCodegen.string_literal_node_payload_from_source(self: CCodegen, node: i32, source_text: str) -> str:
    let start = self.ast.get_start(node)
    let end = self.ast.get_end(node)
    if start >= 0 and end > start and end <= source_text.len() as i32:
        let text = source_text.slice(start as i64, end as i64)
        if cc_is_string_token_text(text) != 0:
            return cc_string_token_payload(text)
    cc_string_literal_payload(cc_intern_resolve(self.intern, self.ast.get_data0(node)))

fn cc_sanitize_ident(raw: str) -> str:
    if raw.len() == 0:
        return "sym"
    var out = ""
    for i in 0..raw.len():
        if with_interrupt_requested() != 0:
            return "__with_interrupted"
        let b = raw.byte_at(i as i64)
        if cc_is_ident_char(b) != 0:
            out = out ++ raw.slice(i as i64, (i + 1) as i64)
        else:
            out = out ++ "_"
    if out.len() == 0:
        return "sym"
    let first = out.byte_at(0)
    if cc_is_ident_start(first) == 0:
        return "_" ++ out
    out

fn cc_str_ends_with(text: str, suffix: str) -> i32:
    if suffix.len() == 0:
        return 1
    if text.len() < suffix.len():
        return 0
    let start = text.len() - suffix.len()
    if text.slice(start as i64, text.len() as i64) == suffix:
        return 1
    0

fn cc_str_starts_with(text: str, prefix: str) -> i32:
    if prefix.len() == 0:
        return 1
    if text.len() < prefix.len():
        return 0
    if text.slice(0, prefix.len() as i64) == prefix:
        return 1
    0

fn cc_str_find_last_char(text: str, ch: i32) -> i32:
    var i = text.len() as i32 - 1
    while i >= 0:
        if text.byte_at(i as i64) == ch:
            return i
        i = i - 1
    -1

fn cc_owner_prefix(sym_text: str) -> str:
    let dot = cc_str_find_last_char(sym_text, 46)
    if dot <= 0:
        return ""
    sym_text.slice(0, dot as i64)

fn cc_str_contains_dot(text: str) -> i32:
    for i in 0..text.len() as i32:
        if text.byte_at(i as i64) == 46:
            return 1
    0

fn cc_str_contains(text: str, needle: str) -> i32:
    if needle.len() == 0:
        return 1
    if text.len() < needle.len():
        return 0
    let end = text.len() - needle.len()
    for i in 0..(end + 1):
        if text.slice(i as i64, (i + needle.len()) as i64) == needle:
            return 1
    0

fn cc_rval_looks_address(text: str) -> i32:
    if text.len() >= 2 and text.byte_at(0) == 40 and text.byte_at(1) == 38:
        return 1
    if cc_str_contains(text, "*)") != 0 or cc_str_contains(text, "* const") != 0:
        return 1
    0

fn cc_name_matches(raw: str, wanted: str) -> i32:
    if raw == wanted:
        return 1
    cc_str_ends_with(raw, "." ++ wanted)

fn cc_emit_checked_signed_helpers(c_type: str, suffix: str, min_expr: str) -> str:
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

fn cc_emit_checked_unsigned_helpers(c_type: str, suffix: str) -> str:
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

fn cc_base_name(raw: str) -> str:
    let dot = cc_str_find_last_char(raw, 46)
    if dot < 0:
        return raw
    raw.slice((dot + 1) as i64, raw.len() as i64)

fn cc_is_vec_method_name(name: str) -> i32:
    if name == "new":
        return 1
    if name == "push" or name == "get" or name == "len":
        return 1
    if name == "slot" or name == "set_i32" or name == "remove" or name == "clear" or name == "pop":
        return 1
    0

fn cc_is_hashmap_method_name(name: str) -> i32:
    if name == "insert" or name == "contains" or name == "remove":
        return 1
    if name == "get" or name == "len" or name == "new":
        return 1
    0

fn cc_is_option_method_name(name: str) -> i32:
    if name == "is_some" or name == "unwrap":
        return 1
    0

fn cc_is_public_abi_name(name: str) -> i32:
    if name.starts_with("with_") or name.starts_with("rt_") or name.starts_with("wl_"):
        return 1
    if name.starts_with("migrate_") or name.starts_with("ci_"):
        return 1
    if name == "gethostname" or name == "pthread_self" or name == "mkstemp" or name == "realpath":
        return 1
    if name == "i32_to_str" or name == "i64_to_string" or name == "str_from_byte":
        return 1
    0

fn CCodegen.fn_c_name(self: CCodegen, fn_sym: i32) -> str:
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

fn CCodegen.global_c_name(self: CCodegen, sym: i32) -> str:
    if sym == 0:
        return "__with_global_0"
    let decl = self.global_decl_node(sym)
    if decl != 0 as NodeId and self.ast.kind(decl) == NodeKind.NK_EXTERN_VAR:
        return cc_sanitize_ident(cc_intern_resolve(self.intern, sym))
    "__with_global_" ++ cc_sanitize_ident(cc_intern_resolve(self.intern, sym)) ++ f"__{sym}"

fn CCodegen.extern_sym_c_name(self: CCodegen, fn_sym: i32) -> str:
    if fn_sym == 0:
        return "sym0"
    let raw = cc_intern_resolve(self.intern, fn_sym)
    if raw.len() == 0:
        return "sym0"
    cc_sanitize_ident(self.canonical_extern_name(raw))

fn CCodegen.canonical_extern_name(self: CCodegen, name: str) -> str:
    // c_import can suffix C symbols as "name.<n>" to avoid With-side name
    // collisions. The emitted C must still call the original C symbol.
    var dot_pos = -1
    for i in 0..name.len() as i32:
        if name.byte_at(i as i64) == 46:
            dot_pos = i
    if dot_pos > 0 and dot_pos + 1 < name.len() as i32:
        var all_digits = true
        var j = dot_pos + 1
        while j < name.len() as i32:
            let ch = name.byte_at(j as i64)
            if ch < 48 or ch > 57:
                all_digits = false
                break
            j = j + 1
        if all_digits:
            return name.slice(0, dot_pos as i64)
    name

fn CCodegen.global_decl_node(self: CCodegen, sym: i32) -> NodeId:
    for di in 0..self.ast.decl_count():
        let decl = self.ast.get_decl(di)
        let dk = self.ast.kind(decl)
        if dk != NodeKind.NK_LET_DECL and dk != NodeKind.NK_EXTERN_VAR:
            continue
        if self.ast.get_data0(decl) == sym:
            return decl
    0 as NodeId

fn CCodegen.decl_index_for_node(self: CCodegen, node: NodeId) -> i32:
    for di in 0..self.ast.decl_count():
        if self.ast.get_decl(di) == node:
            return di
    -1

fn CCodegen.decl_source_path(self: CCodegen, decl: NodeId) -> str:
    let di = self.decl_index_for_node(decl)
    if di >= 0 and di < self.sema.decl_source_paths.len() as i32:
        let path = self.sema.decl_source_paths.get(di as i64)
        if path.len() > 0:
            return path
    self.source_path

fn CCodegen.source_text_for_path(self: CCodegen, path: str) -> str:
    if path.len() == 0 or path == self.source_path:
        return self.source_text
    let embedded_rel = embedded_std_rel_path(path)
    if embedded_rel.len() > 0:
        return embedded_std_source(embedded_rel)
    let text = with_fs_read_file(path)
    if text.len() > 0:
        return text
    self.source_text

fn CCodegen.decl_source_text(self: CCodegen, decl: NodeId) -> str:
    self.source_text_for_path(self.decl_source_path(decl))

fn cc_path_with_slashes(path: str) -> str:
    var out = StringBuilder.with_capacity(path.len())
    for i in 0..path.len() as i32:
        let ch = path.byte_at(i as i64)
        if ch == 92:
            out.push_byte(47 as u8)
        else:
            out.push_byte(ch as u8)
    out.to_str()

fn cc_path_find(text: str, needle: str) -> i32:
    if needle.len() == 0 or text.len() < needle.len():
        return -1
    var i = 0
    while i <= text.len() as i32 - needle.len() as i32:
        var j = 0
        var ok = true
        while j < needle.len() as i32:
            if text.byte_at((i + j) as i64) != needle.byte_at(j as i64):
                ok = false
                break
            j = j + 1
        if ok:
            return i
        i = i + 1
    -1

fn cc_line_directive_path(path: str) -> str:
    let p = cc_path_with_slashes(path)
    let anchors: Vec[str] = Vec.new()
    anchors.push("/out/gen/")
    anchors.push("/src/")
    anchors.push("/lib/")
    anchors.push("/rt/")
    anchors.push("/build/")
    anchors.push("/test/")
    anchors.push("/tests/")
    anchors.push("/runtime/")
    for i in 0..anchors.len() as i32:
        let anchor = anchors.get(i as i64)
        let at = cc_path_find(p, anchor)
        if at >= 0:
            return p.slice((at + 1) as i64, p.len())
    p

fn CCodegen.fn_decl_node(self: CCodegen, sym: i32) -> NodeId:
    for di in 0..self.ast.decl_count():
        let decl = self.ast.get_decl(di)
        if self.ast.kind(decl) != NodeKind.NK_FN_DECL:
            continue
        if self.ast.get_data0(decl) == sym:
            return decl
    0 as NodeId

fn CCodegen.fn_decl_is_public(self: CCodegen, sym: i32) -> i32:
    let decl = self.fn_decl_node(sym)
    if decl == 0 as NodeId:
        return 0
    let flags = self.ast.get_data2(decl)
    if (flags / FnFlags.PUB) % 2 == 1:
        return 1
    0

fn CCodegen.fn_callconv_name(self: CCodegen, meta: i32) -> str:
    if meta < 0:
        return ""
    let cc_sym = self.ast.fn_meta_tp_start(meta)
    if cc_sym == 0:
        return ""
    let cc_name = cc_intern_resolve(self.intern, cc_sym)
    if cc_name.len() >= 2 and cc_name.byte_at(0) == 34 and cc_name.byte_at(cc_name.len() - 1) == 34:
        return cc_name.slice(1, cc_name.len() - 1)
    cc_name

fn CCodegen.fn_c_export_name(self: CCodegen, fn_sym: i32) -> str:
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

fn CCodegen.module_exports_c_name(self: CCodegen, name: str) -> i32:
    for di in 0..self.ast.decl_count():
        let decl = self.ast.get_decl(di)
        if self.ast.kind(decl) != NodeKind.NK_FN_DECL:
            continue
        let sym = self.ast.get_data0(decl)
        if self.fn_c_name(sym) == name:
            return 1
    0

fn CCodegen.global_decl_tid(self: CCodegen, decl: NodeId) -> i32:
    let dk = self.ast.kind(decl)
    if dk == NodeKind.NK_EXTERN_VAR:
        let type_node = self.ast.get_data1(decl)
        let tid = self.sema.resolve_type_expr(type_node) as i32
        if tid != 0:
            return tid
        return self.sema.ty_i32 as i32
    if dk != NodeKind.NK_LET_DECL:
        return 0
    let flags = self.ast.get_data2(decl)
    let type_extra_packed = flags / 16
    if type_extra_packed > 0:
        let type_node = self.ast.get_extra(type_extra_packed - 1)
        let tid = self.sema.resolve_type_expr(type_node) as i32
        if tid != 0:
            return tid
    let value = self.ast.get_data1(decl)
    if self.sema.typed_expr_types.contains(value):
        return self.sema.typed_expr_types.get(value).unwrap()
    self.sema.ty_i32 as i32

fn CCodegen.local_global_sym(self: CCodegen, body: MirBody, local_id: i32) -> i32:
    if local_id <= 0 or local_id >= body.local_names.len() as i32:
        return 0
    let sym = body.local_names.get(local_id as i64)
    if sym == 0:
        return 0
    let decl = self.global_decl_node(sym)
    if decl == 0 as NodeId:
        return 0
    sym

fn CCodegen.canonical_body_sym(self: CCodegen, fn_sym: i32) -> i32:
    if fn_sym == 0:
        return 0
    if self.canonical_body_cache.contains(fn_sym):
        return self.canonical_body_cache.get(fn_sym).unwrap()
    var out = 0
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

fn CCodegen.lookup_body_sym_by_name(self: CCodegen, name: str) -> i32:
    if name.len() == 0:
        return 0
    let cached = self.body_fn_name_map.get(name)
    if cached.is_some():
        return cached.unwrap()
    var out = 0
    for i in 0..self.mir_mod.body_fn_syms.len() as i32:
        let sym = self.mir_mod.body_fn_syms.get(i as i64)
        if cc_intern_resolve(self.intern, sym) == name:
            out = sym
            break
    self.body_fn_name_map.insert(name, out)
    out

fn CCodegen.has_body_for_sym(self: CCodegen, fn_sym: i32) -> i32:
    if self.canonical_body_sym(fn_sym) != 0:
        return 1
    0

fn CCodegen.body_sig_index(self: CCodegen, fn_sym: i32) -> i32:
    let direct = self.sema.get_sig(fn_sym)
    if direct >= 0:
        return direct
    self.sig_index_for_sym(fn_sym)

fn CCodegen.fn_param_is_c_pointer(self: CCodegen, fn_sym: i32, param_idx: i32) -> i32:
    let cache_key = cc_body_local_cache_key(fn_sym, param_idx)
    let cached = self.fn_pointer_param_cache.get(cache_key)
    if cached.is_some():
        return cached.unwrap()
    let sig_idx = self.sig_index_for_sym(fn_sym)
    let out = if sig_idx >= 0: self.sema.sig_param_uses_value_ref_abi(sig_idx, param_idx) else: 0
    self.fn_pointer_param_cache.insert(cache_key, out)
    out

fn CCodegen.local_is_c_pointer_param(self: CCodegen, body: MirBody, local_id: i32) -> i32:
    if local_id <= 0:
        return 0
    let sig_idx = self.body_sig_index(body.fn_sym)
    let param_count = if sig_idx >= 0: self.sema.sig_get_param_count(sig_idx) else: body.n_params
    if local_id > param_count:
        return 0
    self.fn_param_is_c_pointer(body.fn_sym, local_id - 1)

fn CCodegen.call_param_expects_c_pointer(self: CCodegen, body: MirBody, callee_operand: i32, param_idx: i32) -> i32:
    let fn_sym = self.call_callee_fn_sym(body, callee_operand)
    self.fn_param_is_c_pointer(fn_sym, param_idx)

fn CCodegen.is_void_tid(self: CCodegen, tid: i32) -> i32:
    if tid == 0:
        return 1
    let resolved = self.sema.resolve_alias(tid)
    if resolved == 0:
        return 0
    if self.sema.get_type_kind(resolved) == TypeKind.TY_VOID:
        return 1
    0

fn CCodegen.struct_c_name(self: CCodegen, tid: i32) -> str:
    if self.check_interrupted() != 0:
        return "with_interrupted"
    let resolved = self.sema.resolve_alias(tid)
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
    out

fn CCodegen.type_is_payload_enum(self: CCodegen, tid: i32) -> i32:
    let base_tid = self.sema.type_reflection_variant_base(tid)
    if base_tid == 0:
        return 0
    let count = self.sema.type_reflection_variant_count(tid)
    for vi in 0..count:
        if self.sema.type_reflection_variant_payload_count(tid, vi) > 0:
            return 1
    0

fn CCodegen.type_is_distinct(self: CCodegen, tid: i32) -> i32:
    let resolved = self.sema.resolve_alias(tid)
    if self.sema.get_type_kind(resolved) != TypeKind.TY_STRUCT:
        return 0
    let name_sym = self.sema.get_type_d0(resolved)
    if name_sym == 0:
        return 0
    if self.sema.distinct_type_names.contains(name_sym):
        return 1
    0

fn CCodegen.type_is_c_void(self: CCodegen, tid: i32) -> i32:
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

fn CCodegen.payload_enum_variant_field(self: CCodegen, variant_index: i32) -> str:
    let _ = self
    f"payload{variant_index}"

fn CCodegen.payload_enum_variant_for_payload_tid(self: CCodegen, enum_tid: i32, payload_tid: i32) -> i32:
    if self.type_is_payload_enum(enum_tid) == 0 or payload_tid == 0:
        return -1
    let variant_count = self.sema.type_reflection_variant_count(enum_tid)
    var found = -1
    for vi in 0..variant_count:
        if self.sema.type_reflection_variant_payload_count(enum_tid, vi) != 1:
            continue
        let candidate = self.sema.type_reflection_variant_payload_type(enum_tid, vi, 0)
        if candidate == 0:
            continue
        if self.strict_type_match(candidate, payload_tid) != 0:
            if found >= 0:
                return -1
            found = vi
    found

fn CCodegen.payload_enum_single_payload_variant(self: CCodegen, enum_tid: i32) -> i32:
    if self.type_is_payload_enum(enum_tid) == 0:
        return -1
    let variant_count = self.sema.type_reflection_variant_count(enum_tid)
    var found = -1
    for vi in 0..variant_count:
        if self.sema.type_reflection_variant_payload_count(enum_tid, vi) <= 0:
            continue
        if found >= 0:
            return -1
        found = vi
    found

fn CCodegen.payload_enum_single_unit_variant(self: CCodegen, enum_tid: i32) -> i32:
    if self.type_is_payload_enum(enum_tid) == 0:
        return -1
    let variant_count = self.sema.type_reflection_variant_count(enum_tid)
    var found = -1
    for vi in 0..variant_count:
        if self.sema.type_reflection_variant_payload_count(enum_tid, vi) != 0:
            continue
        if found >= 0:
            return -1
        found = vi
    found

fn CCodegen.payload_enum_literal(self: CCodegen, enum_tid: i32, variant_index: i32, payload_text: str) -> str:
    let enum_c = self.c_type(enum_tid, 0)
    let tag = self.sema.type_reflection_variant_discriminant(enum_tid, variant_index)
    var out = "(" ++ enum_c ++ ")" ++ cc_lbrace() ++ ".tag = " ++ f"{tag}"
    if payload_text.len() > 0:
        out = out ++ ", ." ++ self.payload_enum_variant_field(variant_index) ++ " = " ++ payload_text
    out ++ cc_rbrace()

fn CCodegen.fn_type_c_name(self: CCodegen, tid: i32) -> str:
    let resolved = self.sema.resolve_alias(tid)
    f"with_fn_{resolved as i32}"

fn CCodegen.storage_copy_assignment(self: CCodegen, dst_place: str, rval: str) -> str:
    let _ = self
    "    " ++ cc_lbrace() ++ " __typeof__(" ++ rval ++ ") __tmp = " ++ rval ++ "; memcpy(&(" ++ dst_place ++ "), &__tmp, sizeof(" ++ dst_place ++ ") < sizeof(__tmp) ? sizeof(" ++ dst_place ++ ") : sizeof(__tmp)); " ++ cc_rbrace()

fn CCodegen.named_struct_tid(self: CCodegen, type_name: str) -> i32:
    let sym = self.intern_intern(type_name)
    if not self.sema.named_types.contains(sym):
        return 0
    let tid = self.sema.named_types.get(sym).unwrap()
    let resolved = self.sema.resolve_alias(tid)
    if self.sema.get_type_kind(resolved) != TypeKind.TY_STRUCT:
        return 0
    resolved as i32

fn CCodegen.struct_field_tid(self: CCodegen, struct_tid: i32, field_sym: i32) -> i32:
    let resolved = self.sema.resolve_alias(struct_tid)
    if self.sema.get_type_kind(resolved) != TypeKind.TY_STRUCT:
        return 0
    let start = self.sema.get_type_d1(resolved)
    let count = self.sema.get_type_d2(resolved)
    for fi in 0..count:
        let f_sym = self.sema.type_extra.get((start + fi * 3) as i64)
        if f_sym == field_sym:
            return self.sema.type_extra.get((start + fi * 3 + 1) as i64)
    0

fn CCodegen.place_tid(self: CCodegen, body: MirBody, place_id: i32) -> i32:
    let lid = self.place_local_id(body, place_id)
    var base_tid = self.local_effective_tid(body, lid)
    if self.is_void_tid(base_tid) != 0:
        base_tid = self.place_local_tid(body, place_id)
    if base_tid == 0:
        return 0
    var tid = base_tid
    if place_id < 0 or place_id >= body.place_locals.len() as i32:
        return tid
    let start = body.place_proj_starts.get(place_id as i64)
    let count = body.place_proj_counts.get(place_id as i64)
    for i in 0..count:
        let pk = body.proj_kinds.get((start + i) as i64)
        let pd = body.proj_d0.get((start + i) as i64)
        let resolved = self.sema.resolve_alias(tid as TypeId)
        let tk = self.sema.get_type_kind(resolved)
        if pk == ProjKind.PK_FIELD:
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
                let ft = self.vec_synthetic_field_tid(resolved as i32, pd)
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
            let vec_elem_tid = self.vec_element_tid(tid)
            let effective_vec_elem_tid = if vec_elem_tid != 0: vec_elem_tid else: self.vec_local_element_tid(body, lid)
            if effective_vec_elem_tid != 0:
                tid = effective_vec_elem_tid
                continue
            return 0
        if pk == ProjKind.PK_DEREF:
            if tk == TypeKind.TY_PTR or tk == TypeKind.TY_REF:
                tid = self.sema.get_type_d0(resolved)
                continue
            return 0
        if pk == ProjKind.PK_DOWNCAST:
            if self.type_is_payload_enum(tid) != 0:
                if self.sema.type_reflection_variant_payload_count(tid, pd) == 1:
                    tid = self.sema.type_reflection_variant_payload_type(tid, pd, 0)
                    continue
                return 0
            return 0
        return 0
    tid

fn CCodegen.place_ref_target_tid(self: CCodegen, body: MirBody, place_id: i32) -> i32:
    let lid = self.place_local_id(body, place_id)
    var base_tid = self.local_effective_tid(body, lid)
    if self.is_void_tid(base_tid) != 0:
        base_tid = self.place_local_tid(body, place_id)
    if base_tid == 0:
        return 0
    var tid = base_tid
    if place_id < 0 or place_id >= body.place_locals.len() as i32:
        return tid
    let start = body.place_proj_starts.get(place_id as i64)
    let count = body.place_proj_counts.get(place_id as i64)
    for i in 0..count:
        let pk = body.proj_kinds.get((start + i) as i64)
        let pd = body.proj_d0.get((start + i) as i64)
        let resolved = self.sema.resolve_alias(tid as TypeId)
        let tk = self.sema.get_type_kind(resolved)
        if pk == ProjKind.PK_FIELD:
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
                let ft = self.vec_synthetic_field_tid(resolved as i32, pd)
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
                    tid = self.sema.ensure_exact_type(TypeKind.TY_PTR, self.sema.ty_i8 as i32, 0, 0) as i32
                    continue
                return 0
            return 0
        if pk == ProjKind.PK_INDEX:
            if tk == TypeKind.TY_STR:
                return self.sema.ensure_exact_type(TypeKind.TY_PTR, self.sema.ty_i8 as i32, 0, 0) as i32
            if tk == TypeKind.TY_ARRAY or tk == TypeKind.TY_SLICE:
                tid = self.sema.get_type_d0(resolved)
                continue
            let vec_elem_tid = self.vec_element_tid(tid)
            let effective_vec_elem_tid = if vec_elem_tid != 0: vec_elem_tid else: self.vec_local_element_tid(body, lid)
            if effective_vec_elem_tid != 0:
                tid = effective_vec_elem_tid
                continue
            return 0
        if pk == ProjKind.PK_DEREF:
            if tk == TypeKind.TY_PTR or tk == TypeKind.TY_REF:
                tid = self.sema.get_type_d0(resolved)
                continue
            return 0
        if pk == ProjKind.PK_DOWNCAST:
            if self.type_is_payload_enum(tid) != 0:
                if self.sema.type_reflection_variant_payload_count(tid, pd) == 1:
                    tid = self.sema.type_reflection_variant_payload_type(tid, pd, 0)
                    continue
                return 0
            return 0
        return 0
    tid

fn CCodegen.place_tid_no_infer(self: CCodegen, body: MirBody, place_id: i32) -> i32:
    let base_tid = self.place_local_tid(body, place_id)
    if base_tid == 0:
        return 0
    var tid = base_tid
    if place_id < 0 or place_id >= body.place_locals.len() as i32:
        return tid
    let start = body.place_proj_starts.get(place_id as i64)
    let count = body.place_proj_counts.get(place_id as i64)
    for i in 0..count:
        let pk = body.proj_kinds.get((start + i) as i64)
        let pd = body.proj_d0.get((start + i) as i64)
        let resolved = self.sema.resolve_alias(tid as TypeId)
        let tk = self.sema.get_type_kind(resolved)
        if pk == ProjKind.PK_FIELD:
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
                let ft = self.vec_synthetic_field_tid(resolved as i32, pd)
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
            let vec_elem_tid = self.vec_element_tid(tid)
            if vec_elem_tid != 0:
                tid = vec_elem_tid
                continue
            return 0
        if pk == ProjKind.PK_DEREF:
            if tk == TypeKind.TY_PTR or tk == TypeKind.TY_REF:
                tid = self.sema.get_type_d0(resolved)
                continue
            return 0
        if pk == ProjKind.PK_DOWNCAST:
            if self.type_is_payload_enum(tid) != 0:
                if self.sema.type_reflection_variant_payload_count(tid, pd) == 1:
                    tid = self.sema.type_reflection_variant_payload_type(tid, pd, 0)
                    continue
                return 0
            return 0
        return 0
    tid

fn CCodegen.type_match(self: CCodegen, expected: i32, actual: i32) -> i32:
    if expected == 0 or actual == 0:
        return 1
    if self.sema.types_compatible(expected, actual) != 0:
        return 1
    if self.sema.types_compatible(actual, expected) != 0:
        return 1
    0

fn CCodegen.strict_type_match(self: CCodegen, expected: i32, actual: i32) -> i32:
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

fn CCodegen.is_scalar_like_tid(self: CCodegen, tid: i32) -> i32:
    let resolved = self.sema.resolve_alias(tid)
    let tk = self.sema.get_type_kind(resolved)
    if tk == TypeKind.TY_INT or tk == TypeKind.TY_BOOL or tk == TypeKind.TY_FLOAT or tk == TypeKind.TY_ENUM:
        return 1
    if self.type_is_distinct(resolved as i32) != 0:
        return 1
    0

fn CCodegen.prefer_inferred_tid(self: CCodegen, current_tid: i32, candidate_tid: i32) -> i32:
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

fn CCodegen.c_type(self: CCodegen, tid: i32, as_return: i32) -> str:
    if tid == CC_PSEUDO_TID_VEC:
        return "with_vec"
    if tid == CC_PSEUDO_TID_FMT_BUF:
        return "uint8_t*"
    let resolved = self.sema.resolve_alias(tid)
    if resolved == CC_PSEUDO_TID_VEC:
        return "with_vec"
    if resolved == CC_PSEUDO_TID_FMT_BUF:
        return "uint8_t*"
    let tk = self.sema.get_type_kind(resolved)
    if tk == TypeKind.TY_VOID:
        if as_return != 0:
            return "void"
        return "int32_t"
    if tk == TypeKind.TY_BOOL:
        return "bool"
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
    if tk == TypeKind.TY_PTR or tk == TypeKind.TY_REF:
        let inner_tid = self.sema.get_type_d0(resolved)
        let inner_resolved = self.sema.resolve_alias(inner_tid)
        let inner_kind = self.sema.get_type_kind(inner_resolved)
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
        // Generic instances: Vec[T] → with_vec, HashMap[K,V] → void* (opaque handle)
        let base_sym = self.sema.get_type_d0(resolved)
        let base_name = cc_intern_resolve(self.intern, base_sym)
        if base_name == "Vec":
            return "with_vec"
        if base_name == "HashMap":
            return "int64_t"  // opaque handle, passed as int64_t to runtime functions
        if base_name == "HashSet":
            return "int64_t"  // opaque handle, same runtime representation as HashMap
        if base_name == "SlotMap":
            return "int64_t"  // opaque handle, LLVM backend owns SlotMap intrinsics
        if self.type_is_payload_enum(resolved as i32) != 0:
            return self.struct_c_name(resolved)
        // Other generic types: treat as opaque struct
        return self.struct_c_name(resolved)
    if tk == TypeKind.TY_ARRAY:
        let elem_tid = self.sema.get_type_d0(resolved)
        return self.c_type(elem_tid, 0) ++ "*"
    if tk == TypeKind.TY_TUPLE:
        return self.struct_c_name(resolved as i32)
    if tk == TypeKind.TY_FN or tk == TypeKind.TY_EXTERN_FN:
        return self.fn_type_c_name(resolved as i32)
    // Conservative fallback
    "int64_t"

fn CCodegen.checked_int_helper_suffix(self: CCodegen, tid: i32) -> str:
    let resolved = self.sema.resolve_alias(tid)
    if self.sema.get_type_kind(resolved) != TypeKind.TY_INT:
        return ""
    let bits = self.sema.get_type_d0(resolved)
    let signed = self.sema.get_type_d1(resolved) != 0
    if bits != 8 and bits != 16 and bits != 32 and bits != 64 and bits != 128:
        return ""
    let prefix = if signed: "i" else: "u"
    prefix ++ f"{bits}"

fn CCodegen.checked_int_bin_op_text(self: CCodegen, op: i32, lhs: str, rhs: str, result_tid: i32) -> str:
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

fn CCodegen.checked_int_neg_text(self: CCodegen, inner: str, result_tid: i32) -> str:
    let suffix = self.checked_int_helper_suffix(result_tid)
    if suffix.len() == 0 or suffix.byte_at(0) != 105:
        self.fail("C backend does not support checked integer negation for this integer type yet")
        return "0"
    let c_ty = self.c_type(result_tid, 0)
    "__with_checked_neg_" ++ suffix ++ "((" ++ c_ty ++ ")(" ++ inner ++ "))"

fn CCodegen.c_decl(self: CCodegen, tid: i32, name: str) -> str:
    let resolved = self.sema.resolve_alias(tid)
    if resolved != 0 and self.sema.get_type_kind(resolved) == TypeKind.TY_ARRAY:
        let elem_tid = self.sema.get_type_d0(resolved)
        let size = self.sema.get_type_d1(resolved)
        return self.c_decl(elem_tid, name ++ f"[{size}]")
    self.c_type(tid, 0) ++ " " ++ name

fn CCodegen.vec_element_tid(self: CCodegen, tid: i32) -> i32:
    let resolved = self.sema.resolve_alias(tid)
    if self.sema.get_type_kind(resolved) != TypeKind.TY_GENERIC_INST:
        return 0
    let base_sym = self.sema.get_generic_inst_base(resolved as i32)
    let base_name = cc_intern_resolve(self.intern, base_sym)
    if base_name != "Vec":
        return 0
    if self.sema.get_generic_inst_arg_count(resolved as i32) <= 0:
        return 0
    self.sema.get_generic_inst_arg(resolved as i32, 0)

fn CCodegen.vec_synthetic_field_tid(self: CCodegen, vec_tid: i32, field_sym: i32) -> i32:
    let resolved = self.sema.resolve_alias(vec_tid as TypeId) as i32
    if self.sema.get_type_kind(resolved as TypeId) != TypeKind.TY_GENERIC_INST:
        return 0
    if self.generic_inst_base_name(resolved) != "Vec":
        return 0
    let field_name = cc_intern_resolve(self.intern, field_sym)
    if field_name == "len" or field_name == "cap" or field_name == "elem_size":
        return self.sema.ty_i64 as i32
    if field_name != "ptr":
        return 0
    let elem_tid = self.vec_element_tid(resolved)
    if elem_tid == 0 or self.is_void_tid(elem_tid) != 0:
        return 0
    let const_ptr = self.sema.find_exact_type(TypeKind.TY_PTR, elem_tid, 0, 0) as i32
    if const_ptr != 0:
        return const_ptr
    let mut_ptr = self.sema.find_exact_type(TypeKind.TY_PTR, elem_tid, 1, 0) as i32
    if mut_ptr != 0:
        return mut_ptr
    self.sema.ensure_exact_type(TypeKind.TY_PTR, elem_tid, 0, 0) as i32

fn CCodegen.vec_new_elem_size_text(self: CCodegen, body: MirBody, dest_place: i32) -> str:
    var vec_tid = self.place_tid_no_infer(body, dest_place)
    var elem_tid = self.vec_element_tid(vec_tid)
    if elem_tid == 0 or self.is_void_tid(elem_tid) != 0:
        vec_tid = self.call_dest_expected_tid(body, dest_place)
        elem_tid = self.vec_element_tid(vec_tid)
    if elem_tid == 0 or self.is_void_tid(elem_tid) != 0:
        let dst_local = self.place_local_id(body, dest_place)
        elem_tid = self.vec_local_element_tid(body, dst_local)
    if elem_tid == 0 or self.is_void_tid(elem_tid) != 0:
        "0"
    else:
        "sizeof(" ++ self.c_type(elem_tid, 0) ++ ")"

fn CCodegen.generic_inst_base_name(self: CCodegen, tid: i32) -> str:
    let resolved = self.sema.resolve_alias(tid)
    if self.sema.get_type_kind(resolved) != TypeKind.TY_GENERIC_INST:
        return ""
    let base_sym = self.sema.get_generic_inst_base(resolved as i32)
    cc_intern_resolve(self.intern, base_sym)

fn CCodegen.generic_inst_needs_struct_def(self: CCodegen, tid: i32) -> i32:
    let base_name = self.generic_inst_base_name(tid)
    if base_name == "VecSlot":
        return 1
    if base_name == "VecIter":
        return 1
    if base_name == "VecIterPlace":
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

fn CCodegen.vecslot_element_tid(self: CCodegen, tid: i32) -> i32:
    let resolved = self.sema.resolve_alias(tid)
    if self.sema.get_type_kind(resolved) != TypeKind.TY_GENERIC_INST:
        return 0
    if self.generic_inst_base_name(resolved as i32) != "VecSlot":
        return 0
    if self.sema.get_generic_inst_arg_count(resolved as i32) <= 0:
        return 0
    self.sema.get_generic_inst_arg(resolved as i32, 0)

fn CCodegen.hashmap_value_tid(self: CCodegen, tid: i32) -> i32:
    let resolved = self.sema.resolve_alias(tid)
    if self.sema.get_type_kind(resolved) != TypeKind.TY_GENERIC_INST:
        return 0
    if self.generic_inst_base_name(resolved as i32) != "HashMap":
        return 0
    if self.sema.get_generic_inst_arg_count(resolved as i32) < 2:
        return 0
    self.sema.get_generic_inst_arg(resolved as i32, 1)

fn CCodegen.hashmap_key_tid(self: CCodegen, tid: i32) -> i32:
    let resolved = self.sema.resolve_alias(tid)
    if self.sema.get_type_kind(resolved) != TypeKind.TY_GENERIC_INST:
        return 0
    if self.generic_inst_base_name(resolved as i32) != "HashMap":
        return 0
    if self.sema.get_generic_inst_arg_count(resolved as i32) < 2:
        return 0
    self.sema.get_generic_inst_arg(resolved as i32, 0)

fn CCodegen.option_tid_for_payload(self: CCodegen, payload_tid: i32) -> i32:
    if payload_tid == 0 or self.is_void_tid(payload_tid) != 0:
        return 0
    let args: Vec[i32] = Vec.new()
    args.push(payload_tid)
    self.sema.ensure_generic_inst_type(self.sema.syms.option, args, 1) as i32

fn CCodegen.call_hashmap_get_option_tid(self: CCodegen, body: MirBody, args_id: i32) -> i32:
    let recv_operand = self.call_arg_operand(body, args_id, 0)
    var value_tid = self.hashmap_value_tid(self.operand_tid(body, recv_operand))
    if value_tid == 0:
        value_tid = self.call_hashmap_value_tid_from_usage(body, args_id)
    self.option_tid_for_payload(value_tid)

fn CCodegen.call_hashmap_value_tid_from_usage(self: CCodegen, body: MirBody, args_id: i32) -> i32:
    let recv_operand = self.call_arg_operand(body, args_id, 0)
    let recv_text = self.operand_text(body, recv_operand)
    if recv_text.len() == 0:
        return 0
    var out = 0
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

fn CCodegen.vec_local_element_tid(self: CCodegen, body: MirBody, local_id: i32) -> i32:
    if local_id < 0:
        return 0
    var out = 0
    for bb in 0..body.block_count():
        let start = body.bb_stmt_starts.get(bb as i64)
        let count = body.bb_stmt_counts.get(bb as i64)
        for si in 0..count:
            let stmt_id = start + si
            if body.stmt_kinds.get(stmt_id as i64) != StmtKind.Assign:
                continue
            let dst_place = body.stmt_d0.get(stmt_id as i64)
            if self.place_is_direct_local(body, dst_place, local_id) == 0:
                continue
            let rval_id = body.stmt_d1.get(stmt_id as i64)
            if rval_id < 0 or rval_id >= body.rval_kinds.len() as i32:
                continue
            if body.rval_kinds.get(rval_id as i64) != RvalueKind.RK_USE:
                continue
            let src_operand = body.rval_d0.get(rval_id as i64)
            if src_operand >= 0 and src_operand < body.operand_kinds.len() as i32:
                let src_ok = body.operand_kinds.get(src_operand as i64)
                if src_ok == OperandKind.OK_COPY or src_ok == OperandKind.OK_MOVE:
                    let src_place = body.operand_d0.get(src_operand as i64)
                    if self.place_is_direct_local(body, src_place, local_id) != 0:
                        continue
            let src_elem_tid = self.vec_element_tid(self.operand_tid(body, src_operand))
            if src_elem_tid == 0 or self.is_void_tid(src_elem_tid) != 0:
                continue
            if out == 0:
                out = src_elem_tid
            else if self.strict_type_match(out, src_elem_tid) == 0:
                return 0
        if body.term_kind(bb) != TermKind.TK_CALL:
            continue
        let args_id = body.term_data1(bb)
        if cc_builtin_from_mir_intrinsic(body.call_intrinsic(args_id)) != CcBuiltin.VEC_PUSH:
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

fn CCodegen.place_local_id(self: CCodegen, body: MirBody, place_id: i32) -> i32:
    if place_id < 0 or place_id >= body.place_locals.len() as i32:
        return 0
    body.place_locals.get(place_id as i64)

fn CCodegen.local_declared_tid(self: CCodegen, body: MirBody, local_id: i32) -> i32:
    if local_id < 0 or local_id >= body.local_type_ids.len() as i32:
        return 0
    let declared = body.local_type_ids.get(local_id as i64)
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

fn CCodegen.local_effective_tid(self: CCodegen, body: MirBody, local_id: i32) -> i32:
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
    let sig_idx = self.body_sig_index(body.fn_sym)
    let param_count = if sig_idx >= 0: self.sema.sig_get_param_count(sig_idx) else: 0
    if local_id <= param_count:
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

fn CCodegen.local_struct_collection_tid(self: CCodegen, body: MirBody, local_id: i32) -> i32:
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

fn CCodegen.local_direct_call_return_tid(self: CCodegen, body: MirBody, local_id: i32) -> i32:
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
    var out = 0
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
        if kind != CcBuiltin.MAP_GET:
            continue
        let ret_tid = self.call_builtin_ret_tid(body, callee_operand, args_id, dest_place)
        if ret_tid == 0 or self.is_void_tid(ret_tid) != 0:
            continue
        if out == 0:
            out = ret_tid
        else if self.strict_type_match(out, ret_tid) == 0:
            out = 0
            break
    self.local_call_ret_cache.insert(cache_key, out)
    out

fn CCodegen.local_copied_payload_enum_tid(self: CCodegen, body: MirBody, local_id: i32) -> i32:
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
    var out = 0
    for bb in 0..body.block_count():
        let start = body.bb_stmt_starts.get(bb as i64)
        let count = body.bb_stmt_counts.get(bb as i64)
        for si in 0..count:
            let stmt_id = start + si
            if body.stmt_kinds.get(stmt_id as i64) != StmtKind.Assign:
                continue
            let dst_place = body.stmt_d0.get(stmt_id as i64)
            if self.place_is_direct_local(body, dst_place, local_id) == 0:
                continue
            let rval_id = body.stmt_d1.get(stmt_id as i64)
            if rval_id < 0 or rval_id >= body.rval_kinds.len() as i32:
                continue
            if body.rval_kinds.get(rval_id as i64) != RvalueKind.RK_USE:
                continue
            let src_operand = body.rval_d0.get(rval_id as i64)
            if src_operand < 0 or src_operand >= body.operand_kinds.len() as i32:
                continue
            let ok = body.operand_kinds.get(src_operand as i64)
            if ok != OperandKind.OK_COPY and ok != OperandKind.OK_MOVE:
                continue
            let src_place = body.operand_d0.get(src_operand as i64)
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

fn CCodegen.place_has_downcast(self: CCodegen, body: MirBody, place_id: i32) -> bool:
    let _ = self
    if place_id < 0 or place_id >= body.place_locals.len() as i32:
        return false
    let start = body.place_proj_starts.get(place_id as i64)
    let count = body.place_proj_counts.get(place_id as i64)
    for i in 0..count:
        if body.proj_kinds.get((start + i) as i64) == ProjKind.PK_DOWNCAST:
            return true
    false

fn CCodegen.local_payload_downcast_option_tid(self: CCodegen, body: MirBody, local_id: i32) -> i32:
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
    var out = 0
    for bb in 0..body.block_count():
        let start = body.bb_stmt_starts.get(bb as i64)
        let count = body.bb_stmt_counts.get(bb as i64)
        for si in 0..count:
            let stmt_id = start + si
            if body.stmt_kinds.get(stmt_id as i64) != StmtKind.Assign:
                continue
            let rval_id = body.stmt_d1.get(stmt_id as i64)
            if rval_id < 0 or rval_id >= body.rval_kinds.len() as i32:
                continue
            if body.rval_kinds.get(rval_id as i64) != RvalueKind.RK_USE:
                continue
            let src_operand = body.rval_d0.get(rval_id as i64)
            if src_operand < 0 or src_operand >= body.operand_kinds.len() as i32:
                continue
            let ok = body.operand_kinds.get(src_operand as i64)
            if ok != OperandKind.OK_COPY and ok != OperandKind.OK_MOVE:
                continue
            let src_place = body.operand_d0.get(src_operand as i64)
            if self.place_local_id(body, src_place) != local_id:
                continue
            if not self.place_has_downcast(body, src_place):
                continue
            let dst_tid = self.place_tid(body, body.stmt_d0.get(stmt_id as i64))
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

fn cc_zero_i32_vec(count: i32) -> Vec[i32]:
    let out: Vec[i32] = Vec.new()
    for i in 0..count:
        out.push(0)
    out

fn cc_vec_tid_at(values: Vec[i32], local_id: i32) -> i32:
    if local_id < 0 or local_id >= values.len() as i32:
        return 0
    let value = values.get(local_id as i64)
    if value < 0:
        return 0
    value

fn CCodegen.record_local_tid(self: CCodegen, values: Vec[i32], local_id: i32, tid: i32):
    if local_id < 0 or local_id >= values.len() as i32:
        return
    if tid == 0 or self.is_void_tid(tid) != 0:
        return
    let current = values.get(local_id as i64)
    if current < 0:
        return
    if current == 0:
        values.set_i32(local_id, tid)
        return
    if self.strict_type_match(current, tid) == 0:
        values.set_i32(local_id, -1)

fn CCodegen.body_downcast_option_tids(self: CCodegen, body: MirBody) -> Vec[i32]:
    let out = cc_zero_i32_vec(body.local_count())
    for bb in 0..body.block_count():
        let start = body.bb_stmt_starts.get(bb as i64)
        let count = body.bb_stmt_counts.get(bb as i64)
        for si in 0..count:
            let stmt_id = start + si
            if body.stmt_kinds.get(stmt_id as i64) != StmtKind.Assign:
                continue
            let rval_id = body.stmt_d1.get(stmt_id as i64)
            if rval_id < 0 or rval_id >= body.rval_kinds.len() as i32:
                continue
            if body.rval_kinds.get(rval_id as i64) != RvalueKind.RK_USE:
                continue
            let src_operand = body.rval_d0.get(rval_id as i64)
            if src_operand < 0 or src_operand >= body.operand_kinds.len() as i32:
                continue
            let ok = body.operand_kinds.get(src_operand as i64)
            if ok != OperandKind.OK_COPY and ok != OperandKind.OK_MOVE:
                continue
            let src_place = body.operand_d0.get(src_operand as i64)
            if not self.place_has_downcast(body, src_place):
                continue
            let src_local = self.place_local_id(body, src_place)
            if src_local < 0:
                continue
            let dst_tid = self.place_tid(body, body.stmt_d0.get(stmt_id as i64))
            let opt_tid = self.option_tid_for_payload(dst_tid)
            self.record_local_tid(out, src_local, opt_tid)
    out

fn CCodegen.body_copied_payload_enum_tids(self: CCodegen, body: MirBody, downcast_option_tids: Vec[i32]) -> Vec[i32]:
    let out = cc_zero_i32_vec(body.local_count())
    for bb in 0..body.block_count():
        let start = body.bb_stmt_starts.get(bb as i64)
        let count = body.bb_stmt_counts.get(bb as i64)
        for si in 0..count:
            let stmt_id = start + si
            if body.stmt_kinds.get(stmt_id as i64) != StmtKind.Assign:
                continue
            let dst_place = body.stmt_d0.get(stmt_id as i64)
            let dst_local = self.place_local_id(body, dst_place)
            if self.place_is_direct_local(body, dst_place, dst_local) == 0:
                continue
            let rval_id = body.stmt_d1.get(stmt_id as i64)
            if rval_id < 0 or rval_id >= body.rval_kinds.len() as i32:
                continue
            if body.rval_kinds.get(rval_id as i64) != RvalueKind.RK_USE:
                continue
            let src_operand = body.rval_d0.get(rval_id as i64)
            if src_operand < 0 or src_operand >= body.operand_kinds.len() as i32:
                continue
            let ok = body.operand_kinds.get(src_operand as i64)
            if ok != OperandKind.OK_COPY and ok != OperandKind.OK_MOVE:
                continue
            let src_place = body.operand_d0.get(src_operand as i64)
            let src_local = self.place_local_id(body, src_place)
            if src_local < 0 or self.place_is_direct_local(body, src_place, src_local) == 0:
                continue
            var src_tid = self.local_direct_call_return_tid(body, src_local)
            if src_tid == 0:
                src_tid = cc_vec_tid_at(downcast_option_tids, src_local)
            if self.type_is_payload_enum(src_tid) == 0:
                continue
            self.record_local_tid(out, dst_local, src_tid)
    out

fn CCodegen.body_ref_target_tids(self: CCodegen, body: MirBody) -> Vec[i32]:
    let out = cc_zero_i32_vec(body.local_count())
    for bb in 0..body.block_count():
        let start = body.bb_stmt_starts.get(bb as i64)
        let count = body.bb_stmt_counts.get(bb as i64)
        for si in 0..count:
            let stmt_id = start + si
            if body.stmt_kinds.get(stmt_id as i64) != StmtKind.Assign:
                continue
            let dst_place = body.stmt_d0.get(stmt_id as i64)
            let dst_local = self.place_local_id(body, dst_place)
            if self.place_is_direct_local(body, dst_place, dst_local) == 0:
                continue
            let rval_id = body.stmt_d1.get(stmt_id as i64)
            if rval_id < 0 or rval_id >= body.rval_kinds.len() as i32:
                continue
            let rk = body.rval_kinds.get(rval_id as i64)
            var src_place = -1
            if rk == RvalueKind.RK_REF:
                src_place = body.rval_d1.get(rval_id as i64)
            else if rk == RvalueKind.RK_ADDR_OF:
                src_place = body.rval_d0.get(rval_id as i64)
            else:
                continue
            let src_tid = self.place_ref_target_tid(body, src_place)
            self.record_local_tid(out, dst_local, src_tid)
    out

fn CCodegen.place_local_tid(self: CCodegen, body: MirBody, place_id: i32) -> i32:
    let local_id = self.place_local_id(body, place_id)
    self.local_declared_tid(body, local_id)

fn CCodegen.place_is_direct_local(self: CCodegen, body: MirBody, place_id: i32, local_id: i32) -> i32:
    let _ = self
    if place_id < 0 or place_id >= body.place_locals.len() as i32:
        return 0
    if body.place_locals.get(place_id as i64) != local_id:
        return 0
    if body.place_proj_counts.get(place_id as i64) != 0:
        return 0
    1

fn CCodegen.place_uses_local(self: CCodegen, body: MirBody, place_id: i32, local_id: i32) -> i32:
    let _ = self
    if place_id < 0 or place_id >= body.place_locals.len() as i32:
        return 0
    if body.place_locals.get(place_id as i64) == local_id:
        return 1
    0

fn CCodegen.local_is_read(self: CCodegen, body: MirBody, local_id: i32) -> i32:
    if local_id < 0:
        return 0
    for oi in 0..body.operand_kinds.len() as i32:
        let ok = body.operand_kinds.get(oi as i64)
        if ok != OperandKind.OK_COPY and ok != OperandKind.OK_MOVE:
            continue
        let place_id = body.operand_d0.get(oi as i64)
        if self.place_uses_local(body, place_id, local_id) != 0:
            return 1
    0

fn CCodegen.operand_uses_local(self: CCodegen, body: MirBody, operand_id: i32, local_id: i32) -> i32:
    if operand_id < 0 or operand_id >= body.operand_kinds.len() as i32:
        return 0
    let ok = body.operand_kinds.get(operand_id as i64)
    if ok != OperandKind.OK_COPY and ok != OperandKind.OK_MOVE:
        return 0
    let place_id = body.operand_d0.get(operand_id as i64)
    self.place_uses_local(body, place_id, local_id)

fn CCodegen.operand_direct_local_id(self: CCodegen, body: MirBody, operand_id: i32) -> i32:
    if operand_id < 0 or operand_id >= body.operand_kinds.len() as i32:
        return -1
    let ok = body.operand_kinds.get(operand_id as i64)
    if ok != OperandKind.OK_COPY and ok != OperandKind.OK_MOVE:
        return -1
    let place_id = body.operand_d0.get(operand_id as i64)
    let local_id = self.place_local_id(body, place_id)
    if self.place_is_direct_local(body, place_id, local_id) == 0:
        return -1
    local_id

fn CCodegen.rvalue_uses_local(self: CCodegen, body: MirBody, rval_id: i32, local_id: i32) -> i32:
    if rval_id < 0 or rval_id >= body.rval_kinds.len() as i32:
        return 0
    let rk = body.rval_kinds.get(rval_id as i64)
    let d0 = body.rval_d0.get(rval_id as i64)
    let d1 = body.rval_d1.get(rval_id as i64)
    let d2 = body.rval_d2.get(rval_id as i64)
    if rk == RvalueKind.RK_USE:
        return self.operand_uses_local(body, d0, local_id)
    if rk == RvalueKind.RK_ARRAY_FILL:
        return self.operand_uses_local(body, d0, local_id)
    if rk == RvalueKind.RK_BIN_OP:
        if self.operand_uses_local(body, d1, local_id) != 0:
            return 1
        return self.operand_uses_local(body, d2, local_id)
    if rk == RvalueKind.RK_STR_CONCAT_N:
        if d0 < 0 or d0 >= body.call_arg_starts.len() as i32:
            return 0
        let start = body.call_arg_starts.get(d0 as i64)
        let count = body.call_arg_counts.get(d0 as i64)
        for i in 0..count:
            if self.operand_uses_local(body, body.call_arg_operands.get((start + i) as i64), local_id) != 0:
                return 1
        return 0
    if rk == RvalueKind.RK_UN_OP:
        return self.operand_uses_local(body, d1, local_id)
    if rk == RvalueKind.RK_REF or rk == RvalueKind.RK_ADDR_OF or rk == RvalueKind.RK_DISCRIMINANT or rk == RvalueKind.RK_LEN:
        return self.place_uses_local(body, d0, local_id)
    if rk == RvalueKind.RK_CAST:
        return self.operand_uses_local(body, d0, local_id)
    if rk == RvalueKind.RK_AGGREGATE:
        let fields_id = body.rval_d1.get(rval_id as i64)
        if fields_id < 0 or fields_id >= body.agg_field_starts.len() as i32:
            return 0
        let start = body.agg_field_starts.get(fields_id as i64)
        let count = body.agg_field_counts.get(fields_id as i64)
        for i in 0..count:
            if self.operand_uses_local(body, body.agg_field_operands.get((start + i) as i64), local_id) != 0:
                return 1
    0

fn CCodegen.local_value_use_mark_place(self: CCodegen, body: MirBody, place_id: i32):
    let local_id = self.place_local_id(body, place_id)
    if local_id < 0:
        return
    self.local_value_use_cache.insert(cc_body_local_cache_key(body.fn_sym, local_id), 1)

fn CCodegen.local_value_use_mark_operand(self: CCodegen, body: MirBody, operand_id: i32):
    if operand_id < 0 or operand_id >= body.operand_kinds.len() as i32:
        return
    let ok = body.operand_kinds.get(operand_id as i64)
    if ok != OperandKind.OK_COPY and ok != OperandKind.OK_MOVE:
        return
    self.local_value_use_mark_place(body, body.operand_d0.get(operand_id as i64))

fn CCodegen.local_value_use_mark_rvalue(self: CCodegen, body: MirBody, rval_id: i32):
    if rval_id < 0 or rval_id >= body.rval_kinds.len() as i32:
        return
    let rk = body.rval_kinds.get(rval_id as i64)
    let d0 = body.rval_d0.get(rval_id as i64)
    let d1 = body.rval_d1.get(rval_id as i64)
    let d2 = body.rval_d2.get(rval_id as i64)
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
        if d0 < 0 or d0 >= body.call_arg_starts.len() as i32:
            return
        let start = body.call_arg_starts.get(d0 as i64)
        let count = body.call_arg_counts.get(d0 as i64)
        for i in 0..count:
            self.local_value_use_mark_operand(body, body.call_arg_operands.get((start + i) as i64))
        return
    if rk == RvalueKind.RK_UN_OP:
        self.local_value_use_mark_operand(body, d1)
        return
    if rk == RvalueKind.RK_REF or rk == RvalueKind.RK_ADDR_OF or rk == RvalueKind.RK_DISCRIMINANT or rk == RvalueKind.RK_LEN:
        self.local_value_use_mark_place(body, d0)
        return
    if rk == RvalueKind.RK_CAST:
        self.local_value_use_mark_operand(body, d0)
        return
    if rk == RvalueKind.RK_AGGREGATE:
        let fields_id = body.rval_d1.get(rval_id as i64)
        if fields_id < 0 or fields_id >= body.agg_field_starts.len() as i32:
            return
        let start = body.agg_field_starts.get(fields_id as i64)
        let count = body.agg_field_counts.get(fields_id as i64)
        for i in 0..count:
            self.local_value_use_mark_operand(body, body.agg_field_operands.get((start + i) as i64))

fn CCodegen.local_value_use_populate(self: CCodegen, body: MirBody):
    for li in 0..body.local_count():
        self.local_value_use_cache.insert(cc_body_local_cache_key(body.fn_sym, li), 0)
    for bb in 0..body.block_count():
        let start = body.bb_stmt_starts.get(bb as i64)
        let count = body.bb_stmt_counts.get(bb as i64)
        for si in 0..count:
            let stmt_id = start + si
            if body.stmt_kinds.get(stmt_id as i64) == StmtKind.Assign:
                self.local_value_use_mark_rvalue(body, body.stmt_d1.get(stmt_id as i64))
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

fn CCodegen.local_has_value_use(self: CCodegen, body: MirBody, local_id: i32) -> i32:
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

fn CCodegen.operand_tid(self: CCodegen, body: MirBody, operand_id: i32) -> i32:
    if operand_id < 0 or operand_id >= body.operand_kinds.len() as i32:
        return 0
    let ok = body.operand_kinds.get(operand_id as i64)
    let od = body.operand_d0.get(operand_id as i64)
    if ok == OperandKind.OK_COPY or ok == OperandKind.OK_MOVE:
        return self.place_tid(body, od)
    if ok == OperandKind.OK_CONSTANT:
        if od < 0 or od >= body.const_types.len() as i32:
            return 0
        return body.const_types.get(od as i64)
    0

fn CCodegen.operand_tid_no_infer(self: CCodegen, body: MirBody, operand_id: i32) -> i32:
    if operand_id < 0 or operand_id >= body.operand_kinds.len() as i32:
        return 0
    let ok = body.operand_kinds.get(operand_id as i64)
    let od = body.operand_d0.get(operand_id as i64)
    if ok == OperandKind.OK_COPY or ok == OperandKind.OK_MOVE:
        return self.place_tid_no_infer(body, od)
    if ok == OperandKind.OK_CONSTANT:
        if od < 0 or od >= body.const_types.len() as i32:
            return 0
        return body.const_types.get(od as i64)
    0

fn CCodegen.place_text(self: CCodegen, body: MirBody, place_id: i32) -> str:
    if place_id < 0 or place_id >= body.place_locals.len() as i32:
        self.fail(f"invalid place id {place_id}")
        return "_0"
    let base_local = body.place_locals.get(place_id as i64)
    let global_sym = self.local_global_sym(body, base_local)
    var out = if global_sym != 0:
        self.global_c_name(global_sym)
    else if self.local_is_c_pointer_param(body, base_local) != 0:
        f"(*_{base_local})"
    else:
        f"_{base_local}"
    var current_tid = self.local_effective_tid(body, base_local)
    if self.is_void_tid(current_tid) != 0:
        current_tid = self.place_local_tid(body, place_id)
    let start = body.place_proj_starts.get(place_id as i64)
    let count = body.place_proj_counts.get(place_id as i64)
    for i in 0..count:
        let pk = body.proj_kinds.get((start + i) as i64)
        let pd = body.proj_d0.get((start + i) as i64)
        let resolved = self.sema.resolve_alias(current_tid as TypeId)
        let tk = self.sema.get_type_kind(resolved)
        if pk == ProjKind.PK_FIELD:
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
            let field_name = cc_intern_resolve(self.intern, pd)
            out = out ++ "." ++ field_name
            if tk == TypeKind.TY_STRUCT:
                let ft_raw = self.struct_field_tid(resolved as i32, pd)
                let ft = self.effective_field_tid(resolved as i32, pd, ft_raw)
                current_tid = ft
            else if tk == TypeKind.TY_GENERIC_INST:
                current_tid = self.vec_synthetic_field_tid(resolved as i32, pd)
            else:
                current_tid = 0
            continue
        if pk == ProjKind.PK_INDEX:
            if tk == TypeKind.TY_STR:
                out = f"{out}.ptr[_{pd}]"
                current_tid = self.sema.ty_i32 as i32
                continue
            if tk == TypeKind.TY_ARRAY or tk == TypeKind.TY_SLICE:
                out = f"{out}[_{pd}]"
                current_tid = self.sema.get_type_d0(resolved)
                continue
            // Vec or other generic container: use with_vec_get_ptr runtime call
            let base_c = self.c_type(current_tid, 0)
            if base_c == "with_vec":
                var elem_tid = self.vec_element_tid(current_tid)
                if elem_tid == 0:
                    elem_tid = self.vec_local_element_tid(body, base_local)
                let elem_c = if elem_tid != 0: self.c_type(elem_tid, 0) else: "int64_t"
                out = "(*((" ++ elem_c ++ "*)with_vec_get_ptr(&(" ++ out ++ f"), (int64_t)(_{pd}))))"
                current_tid = if elem_tid != 0: elem_tid else: self.sema.ty_i64 as i32
                continue
            out = f"{out}[_{pd}]"
            current_tid = 0
            continue
        if pk == ProjKind.PK_DEREF:
            out = "(*" ++ out ++ ")"
            if tk == TypeKind.TY_PTR or tk == TypeKind.TY_REF:
                current_tid = self.sema.get_type_d0(resolved)
            else:
                current_tid = 0
            continue
        if pk == ProjKind.PK_DOWNCAST:
            if self.type_is_payload_enum(current_tid) != 0:
                let payload_count = self.sema.type_reflection_variant_payload_count(current_tid, pd)
                if payload_count == 1:
                    out = out ++ "." ++ self.payload_enum_variant_field(pd)
                    current_tid = self.sema.type_reflection_variant_payload_type(current_tid, pd, 0)
                    continue
                if payload_count == 0:
                    self.fail(f"payload downcast for unit enum variant {pd}")
                else:
                    self.fail(f"C backend does not support enum variants with {payload_count} payload fields")
                current_tid = 0
                continue
            out = f"{out}/*downcast{pd}*/"
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

fn CCodegen.exact_int_const_text(self: CCodegen, body: MirBody, const_id: i32) -> str:
    let node = body.const_d0.get(const_id as i64)
    let tid = body.const_types.get(const_id as i64)
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

fn CCodegen.exact_int_expr_text(self: CCodegen, node: i32, tid: i32) -> str:
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

fn CCodegen.global_init_text(self: CCodegen, node: i32, tid: i32, source_text: str) -> str:
    var expr = node
    while expr != 0:
        let k = self.ast.kind(expr)
        if k != NodeKind.NK_COMPTIME and k != NodeKind.NK_GROUPED:
            break
        expr = self.ast.get_data0(expr)
    if expr == 0:
        return self.zero_value_text(tid)
    let kind = self.ast.kind(expr)
    if kind == NodeKind.NK_INT_LIT or kind == NodeKind.NK_UNARY:
        let resolved = self.sema.resolve_alias(tid)
        let tk = self.sema.get_type_kind(resolved)
        if tk != TypeKind.TY_INT and tk != TypeKind.TY_BOOL and tk != TypeKind.TY_FLOAT:
            return self.zero_value_text(tid)
        return self.exact_int_expr_text(expr, tid)
    if kind == NodeKind.NK_BOOL_LIT:
        return if self.ast.get_data0(expr) != 0: "true" else: "false"
    if kind == NodeKind.NK_FLOAT_LIT:
        let str_idx = self.ast.get_data0(expr)
        if str_idx >= 0 and str_idx < self.ast.state.strings.len() as i32:
            return self.ast.get_string(str_idx)
        return "0.0"
    if kind == NodeKind.NK_STRING_LIT:
        let text = self.string_literal_node_payload_from_source(expr, source_text)
        let resolved = self.sema.resolve_alias(tid)
        let tk = self.sema.get_type_kind(resolved)
        if tk == TypeKind.TY_PTR or tk == TypeKind.TY_REF:
            let inner_tid = self.sema.resolve_alias(self.sema.get_type_d0(resolved) as TypeId)
            if self.sema.get_type_kind(inner_tid) == TypeKind.TY_INT and self.sema.get_type_d0(inner_tid) == 8:
                return "((" ++ self.c_type(tid, 0) ++ ")\"" ++ cc_escape_c_string(text) ++ "\")"
        return "WITH_STR_LIT(\"" ++ cc_escape_c_string(text) ++ "\")"
    if kind == NodeKind.NK_C_STRING_LIT:
        self.fail("emit-c does not yet support c-string literal CStr objects")
        return "0"
    if kind == NodeKind.NK_NULL_LIT:
        return "NULL"
    let resolved = self.sema.resolve_alias(tid)
    if self.sema.get_type_kind(resolved) == TypeKind.TY_ARRAY:
        return cc_lbrace() ++ "0" ++ cc_rbrace()
    self.zero_value_text(tid)

fn CCodegen.const_text(self: CCodegen, body: MirBody, const_id: i32) -> str:
    if const_id < 0 or const_id >= body.const_kinds.len() as i32:
        self.fail(f"invalid const id {const_id}")
        return "0"
    let ck = body.const_kinds.get(const_id as i64)
    let cd = body.const_d0.get(const_id as i64)
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
        self.fail("emit-c does not yet support c-string literal CStr objects")
        return "0"
    if ck == ConstKind.CK_UNIT:
        let unit_tid = body.const_types.get(const_id as i64)
        if unit_tid != 0:
            return self.zero_value_text(unit_tid)
        return "0"
    if ck == ConstKind.CK_FLOAT:
        if cd != 0:
            let lit = if cd >= 0 and cd < self.ast.state.strings.len() as i32: self.ast.get_string(cd) else: ""
            if lit.len() > 0:
                return lit
        return "0.0"
    if ck == ConstKind.CK_ZERO_SIZED:
        let zs_tid = body.const_types.get(const_id as i64)
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
    self.fail(f"unsupported const kind {ck}")
    "0"

fn CCodegen.operand_text(self: CCodegen, body: MirBody, operand_id: i32) -> str:
    if operand_id < 0 or operand_id >= body.operand_kinds.len() as i32:
        self.fail(f"invalid operand id {operand_id}")
        return "0"
    let ok = body.operand_kinds.get(operand_id as i64)
    let od = body.operand_d0.get(operand_id as i64)
    if ok == OperandKind.OK_COPY or ok == OperandKind.OK_MOVE:
        return self.place_text(body, od)
    if ok == OperandKind.OK_CONSTANT:
        return self.const_text(body, od)
    self.fail(f"unsupported operand kind {ok}")
    "0"

fn CCodegen.rvalue_tid(self: CCodegen, body: MirBody, rval_id: i32) -> i32:
    if rval_id < 0 or rval_id >= body.rval_kinds.len() as i32:
        return 0
    let rk = body.rval_kinds.get(rval_id as i64)
    let d0 = body.rval_d0.get(rval_id as i64)
    let d1 = body.rval_d1.get(rval_id as i64)
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
    0

fn CCodegen.binop_token(self: CCodegen, op: i32) -> str:
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

fn CCodegen.type_is_raw_pointer_tid(self: CCodegen, tid: i32) -> bool:
    if tid == 0:
        return false
    let resolved = self.sema.resolve_alias(tid)
    let kind = self.sema.get_type_kind(resolved)
    kind == TypeKind.TY_PTR or kind == TypeKind.TY_REF

fn CCodegen.raw_pointer_elem_size_expr(self: CCodegen, tid: i32) -> str:
    let resolved = self.sema.resolve_alias(tid)
    let kind = self.sema.get_type_kind(resolved)
    if kind != TypeKind.TY_PTR and kind != TypeKind.TY_REF:
        return "1"
    let inner = self.sema.get_type_d0(resolved)
    let inner_resolved = self.sema.resolve_alias(inner as TypeId)
    if self.sema.get_type_kind(inner_resolved) == TypeKind.TY_VOID or self.type_is_c_void(inner_resolved as i32) != 0:
        return "1"
    "sizeof(" ++ self.c_type(inner, 0) ++ ")"

fn CCodegen.raw_pointer_binop_text(self: CCodegen, op: i32, lhs: str, rhs: str, lhs_tid: i32, rhs_tid: i32) -> str:
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

fn CCodegen.rvalue_text(self: CCodegen, body: MirBody, rval_id: i32) -> str:
    if rval_id < 0 or rval_id >= body.rval_kinds.len() as i32:
        self.fail(f"invalid rvalue id {rval_id}")
        return "0"
    let rk = body.rval_kinds.get(rval_id as i64)
    let d0 = body.rval_d0.get(rval_id as i64)
    let d1 = body.rval_d1.get(rval_id as i64)
    let d2 = body.rval_d2.get(rval_id as i64)
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
        let lhs_tid_for_raw_ptr = self.operand_tid(body, d1)
        let rhs_tid_for_raw_ptr = self.operand_tid(body, d2)
        let raw_ptr_bin = self.raw_pointer_binop_text(d0, lhs, rhs, lhs_tid_for_raw_ptr, rhs_tid_for_raw_ptr)
        if raw_ptr_bin.len() > 0:
            return raw_ptr_bin
        if d0 == BinaryOp.OP_CONCAT:
            return "with_str_concat(" ++ lhs ++ ", " ++ rhs ++ ")"
        if d0 == BinaryOp.OP_EQ or d0 == BinaryOp.OP_NEQ:
            let lhs_tid = self.sema.resolve_alias(self.operand_tid(body, d1))
            let rhs_tid = self.sema.resolve_alias(self.operand_tid(body, d2))
            if self.sema.get_type_kind(lhs_tid) == TypeKind.TY_STR and self.sema.get_type_kind(rhs_tid) == TypeKind.TY_STR:
                let eq_expr = "with_str_eq(" ++ lhs ++ ", " ++ rhs ++ ")"
                if d0 == BinaryOp.OP_EQ:
                    return eq_expr
                return "(!(" ++ eq_expr ++ "))"
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
        return "(&" ++ self.place_text(body, d1) ++ ")"
    if rk == RvalueKind.RK_ADDR_OF:
        return "(&" ++ self.place_text(body, d0) ++ ")"
    if rk == RvalueKind.RK_CAST:
        let dst_c = self.c_type(d1, 0)
        let src = self.operand_text(body, d0)
        let src_tid = self.sema.resolve_alias(self.operand_tid(body, d0))
        let dst_tid = self.sema.resolve_alias(d1)
        let src_tk = self.sema.get_type_kind(src_tid)
        let dst_tk = self.sema.get_type_kind(dst_tid)
        if dst_tk == TypeKind.TY_PTR or dst_tk == TypeKind.TY_REF:
            if src_tk == TypeKind.TY_STR:
                return "((" ++ dst_c ++ ")(" ++ src ++ ".ptr))"
            if src_tk == TypeKind.TY_STRUCT:
                return "((" ++ dst_c ++ ")(&(" ++ src ++ ")))"
        return "((" ++ dst_c ++ ")(" ++ src ++ "))"
    if rk == RvalueKind.RK_DISCRIMINANT:
        return "(" ++ self.place_text(body, d0) ++ ").tag"
    if rk == RvalueKind.RK_LEN:
        let p = self.place_text(body, d0)
        let pt = self.place_tid(body, d0)
        if pt == CC_PSEUDO_TID_VEC:
            return "with_vec_len(&(" ++ p ++ "))"
        return "with_len(" ++ p ++ ")"
    if rk == RvalueKind.RK_AGGREGATE:
        if d1 < 0 or d1 >= body.agg_field_starts.len() as i32:
            return "0"
        let start = body.agg_field_starts.get(d1 as i64)
        let count = body.agg_field_counts.get(d1 as i64)
        if count <= 0:
            return "0"
        // Conservative lowering: record updates and implicit wrappers both
        // preserve payload/shape in operand 0 for this bootstrap path.
        let first = body.agg_field_operands.get(start as i64)
        return self.operand_text(body, first)
    self.fail(f"unknown MIR rvalue kind {rk}")
    "0"

fn CCodegen.call_arg_count(self: CCodegen, body: MirBody, args_id: i32) -> i32:
    if args_id < 0 or args_id >= body.call_arg_counts.len() as i32:
        return 0
    body.call_arg_counts.get(args_id as i64)

fn CCodegen.aggregate_compound_literal(self: CCodegen, body: MirBody, rval_id: i32, dst_tid: i32) -> str:
    if rval_id < 0 or rval_id >= body.rval_kinds.len() as i32:
        return ""
    if body.rval_kinds.get(rval_id as i64) != RvalueKind.RK_AGGREGATE:
        return ""
    let fields_id = body.rval_d1.get(rval_id as i64)
    if fields_id < 0 or fields_id >= body.agg_field_starts.len() as i32:
        return ""
    let start = body.agg_field_starts.get(fields_id as i64)
    let count = body.agg_field_counts.get(fields_id as i64)
    let dst_resolved = self.sema.resolve_alias(dst_tid)
    let dst_tk = self.sema.get_type_kind(dst_resolved)
    let dst_c = self.c_type(dst_tid, 0)
    let aggregate_kind = body.rval_d0.get(rval_id as i64)
    if aggregate_kind != 0:
        if self.type_is_payload_enum(dst_tid) == 0:
            if dst_tk == TypeKind.TY_ENUM:
                let tag = self.sema.type_reflection_variant_discriminant(dst_tid, body.rval_d2.get(rval_id as i64))
                return f"{tag}"
            return ""
        let variant_index = body.rval_d2.get(rval_id as i64)
        if count == 1:
            return self.payload_enum_literal(dst_tid, variant_index, self.operand_text(body, body.agg_field_operands.get(start as i64)))
        else if count > 1:
            self.fail(f"C backend does not support enum variants with {count} payload fields")
            return ""
        var unit_variant = variant_index
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
            let name_sym = if (start + i) >= 0 and (start + i) < body.agg_field_name_syms.len() as i32:
                body.agg_field_name_syms.get((start + i) as i64)
            else:
                0
            if dst_tk == TypeKind.TY_STRUCT and name_sym != 0:
                let field_name = cc_intern_resolve(self.intern, name_sym)
                if field_name.len() > 0 and self.struct_field_tid(dst_resolved as i32, name_sym) != 0:
                    out = out ++ "." ++ field_name ++ " = "
            out = out ++ self.operand_text(body, body.agg_field_operands.get((start + i) as i64))
    out = out ++ cc_rbrace()
    out

fn CCodegen.aggregate_array_initializer(self: CCodegen, body: MirBody, rval_id: i32) -> str:
    if rval_id < 0 or rval_id >= body.rval_kinds.len() as i32:
        return ""
    if body.rval_kinds.get(rval_id as i64) != RvalueKind.RK_AGGREGATE:
        return ""
    let fields_id = body.rval_d1.get(rval_id as i64)
    if fields_id < 0 or fields_id >= body.agg_field_starts.len() as i32:
        return ""
    let start = body.agg_field_starts.get(fields_id as i64)
    let count = body.agg_field_counts.get(fields_id as i64)
    var out = cc_lbrace()
    if count <= 0:
        out = out ++ "0"
    else:
        for i in 0..count:
            if i > 0:
                out = out ++ ", "
            out = out ++ self.operand_text(body, body.agg_field_operands.get((start + i) as i64))
    out ++ cc_rbrace()

fn CCodegen.aggregate_struct_assignment_with_array_fields(self: CCodegen, body: MirBody, rval_id: i32, dst_tid: i32, dst_place: str) -> str:
    if rval_id < 0 or rval_id >= body.rval_kinds.len() as i32:
        return ""
    if body.rval_kinds.get(rval_id as i64) != RvalueKind.RK_AGGREGATE:
        return ""
    if body.rval_d0.get(rval_id as i64) != 0:
        return ""
    let fields_id = body.rval_d1.get(rval_id as i64)
    if fields_id < 0 or fields_id >= body.agg_field_starts.len() as i32:
        return ""
    let dst_resolved = self.sema.resolve_alias(dst_tid)
    if self.sema.get_type_kind(dst_resolved) != TypeKind.TY_STRUCT:
        return ""
    let start = body.agg_field_starts.get(fields_id as i64)
    let count = body.agg_field_counts.get(fields_id as i64)
    var has_array_field = false
    for i in 0..count:
        let name_sym = if (start + i) >= 0 and (start + i) < body.agg_field_name_syms.len() as i32:
            body.agg_field_name_syms.get((start + i) as i64)
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
        let name_sym = if idx >= 0 and idx < body.agg_field_name_syms.len() as i32:
            body.agg_field_name_syms.get(idx as i64)
        else:
            0
        if name_sym == 0:
            self.fail("emit-c: struct aggregate assignment with array fields requires named fields")
            return ""
        let field_name = cc_intern_resolve(self.intern, name_sym)
        let field_tid = self.struct_field_tid(dst_resolved as i32, name_sym)
        if field_name.len() == 0 or field_tid == 0:
            self.fail("emit-c: unresolved struct field in aggregate assignment")
            return ""
        let operand_id = body.agg_field_operands.get(idx as i64)
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
    out ++ " " ++ cc_rbrace()

fn CCodegen.map_recv_text(self: CCodegen, body: MirBody, args_id: i32) -> str:
    let recv_operand = self.call_arg_operand(body, args_id, 0)
    let recv = self.operand_text(body, recv_operand)
    let recv_tid = self.sema.resolve_alias(self.operand_tid(body, recv_operand))
    let recv_tk = self.sema.get_type_kind(recv_tid)
    if recv_tk == TypeKind.TY_PTR or recv_tk == TypeKind.TY_REF:
        let inner = self.sema.resolve_alias(self.sema.get_type_d0(recv_tid))
        if inner != 0 and self.c_type(inner, 0) == "int64_t":
            return "(*(" ++ recv ++ "))"
    recv

fn CCodegen.vec_recv_ptr_text(self: CCodegen, body: MirBody, args_id: i32) -> str:
    let recv_operand = self.call_arg_operand(body, args_id, 0)
    let recv = self.operand_text(body, recv_operand)
    let recv_tid = self.sema.resolve_alias(self.operand_tid(body, recv_operand))
    let recv_tk = self.sema.get_type_kind(recv_tid)
    if recv_tk == TypeKind.TY_PTR or recv_tk == TypeKind.TY_REF:
        let inner = self.sema.resolve_alias(self.sema.get_type_d0(recv_tid))
        if inner != 0 and self.c_type(inner, 0) == "with_vec":
            return "((with_vec*)(" ++ recv ++ "))"
    "&(" ++ recv ++ ")"

fn CCodegen.atomic_recv_ptr_text(self: CCodegen, body: MirBody, args_id: i32) -> str:
    let recv_operand = self.call_arg_operand(body, args_id, 0)
    let recv = self.operand_text(body, recv_operand)
    let recv_tid = self.sema.resolve_alias(self.operand_tid(body, recv_operand))
    let recv_tk = self.sema.get_type_kind(recv_tid)
    if recv_tk == TypeKind.TY_PTR or recv_tk == TypeKind.TY_REF:
        return "(" ++ recv ++ ")"
    "&(" ++ recv ++ ")"

fn CCodegen.atomic_recv_value_tid(self: CCodegen, body: MirBody, args_id: i32) -> i32:
    let recv_operand = self.call_arg_operand(body, args_id, 0)
    var recv_tid = self.sema.resolve_alias(self.operand_tid(body, recv_operand))
    let recv_tk = self.sema.get_type_kind(recv_tid)
    if recv_tk == TypeKind.TY_PTR or recv_tk == TypeKind.TY_REF:
        recv_tid = self.sema.resolve_alias(self.sema.get_type_d0(recv_tid))
    if self.sema.get_type_kind(recv_tid) == TypeKind.TY_GENERIC_INST and self.generic_inst_base_name(recv_tid as i32) == "Atomic":
        if self.sema.get_generic_inst_arg_count(recv_tid as i32) > 0:
            return self.sema.get_generic_inst_arg(recv_tid as i32, 0)
    self.sema.ty_i64 as i32

fn CCodegen.atomic_order_text(self: CCodegen, order_text: str) -> str:
    let o = "(" ++ order_text ++ ")"
    "(" ++ o ++ " == 0 ? __ATOMIC_RELAXED : " ++ o ++ " == 1 ? __ATOMIC_ACQUIRE : " ++ o ++ " == 2 ? __ATOMIC_RELEASE : " ++ o ++ " == 3 ? __ATOMIC_ACQ_REL : __ATOMIC_SEQ_CST)"

fn CCodegen.call_arg_operand(self: CCodegen, body: MirBody, args_id: i32, idx: i32) -> i32:
    if args_id < 0 or args_id >= body.call_arg_starts.len() as i32:
        return 0
    let start = body.call_arg_starts.get(args_id as i64)
    let count = body.call_arg_counts.get(args_id as i64)
    if idx < 0 or idx >= count:
        return 0
    let at = start + idx
    if at < 0 or at >= body.call_arg_operands.len() as i32:
        return 0
    body.call_arg_operands.get(at as i64)

fn CCodegen.str_concat_n_text(self: CCodegen, body: MirBody, args_id: i32, move_first: i32) -> str:
    if args_id < 0 or args_id >= body.call_arg_starts.len() as i32:
        self.fail(f"invalid str_concat_n args id {args_id}")
        return "WITH_STR_LIT(\"\")"
    let start = body.call_arg_starts.get(args_id as i64)
    let count = body.call_arg_counts.get(args_id as i64)
    if count <= 0:
        return "WITH_STR_LIT(\"\")"
    if count == 1:
        return self.operand_text(body, body.call_arg_operands.get(start as i64))
    let concat_name = if move_first != 0: "with_str_concat_n_move_first" else: "with_str_concat_n"
    var out = concat_name ++ "((const with_str[]){"
    for i in 0..count:
        if i > 0:
            out = out ++ ", "
        out = out ++ self.operand_text(body, body.call_arg_operands.get((start + i) as i64))
    out ++ "}, " ++ with_i64_to_str(count as i64) ++ ")"

fn CCodegen.local_assigned_fn_sym_depth(self: CCodegen, body: MirBody, local_id: i32, depth: i32) -> i32:
    if local_id < 0:
        return 0
    if depth > 8:
        return 0
    var out = 0
    for bb in 0..body.block_count():
        let start = body.bb_stmt_starts.get(bb as i64)
        let count = body.bb_stmt_counts.get(bb as i64)
        for si in 0..count:
            let stmt_id = start + si
            if body.stmt_kinds.get(stmt_id as i64) != StmtKind.Assign:
                continue
            let dst_place = body.stmt_d0.get(stmt_id as i64)
            if self.place_is_direct_local(body, dst_place, local_id) == 0:
                continue
            let rval_id = body.stmt_d1.get(stmt_id as i64)
            if rval_id < 0 or rval_id >= body.rval_kinds.len() as i32:
                continue
            if body.rval_kinds.get(rval_id as i64) != RvalueKind.RK_USE:
                continue
            let src_operand = body.rval_d0.get(rval_id as i64)
            if src_operand < 0 or src_operand >= body.operand_kinds.len() as i32:
                continue
            let ok = body.operand_kinds.get(src_operand as i64)
            let od = body.operand_d0.get(src_operand as i64)
            var cand = 0
            if ok == OperandKind.OK_CONSTANT:
                if od < 0 or od >= body.const_kinds.len() as i32:
                    continue
                if body.const_kinds.get(od as i64) != ConstKind.CK_FN:
                    continue
                cand = body.const_d0.get(od as i64)
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

fn CCodegen.local_assigned_fn_sym(self: CCodegen, body: MirBody, local_id: i32) -> i32:
    self.local_assigned_fn_sym_depth(body, local_id, 0)

fn CCodegen.call_callee_fn_sym(self: CCodegen, body: MirBody, callee_operand: i32) -> i32:
    if callee_operand < 0 or callee_operand >= body.operand_kinds.len() as i32:
        return 0
    let ok = body.operand_kinds.get(callee_operand as i64)
    let od = body.operand_d0.get(callee_operand as i64)
    if ok == OperandKind.OK_CONSTANT:
        let const_id = od
        if const_id < 0 or const_id >= body.const_kinds.len() as i32:
            return 0
        if body.const_kinds.get(const_id as i64) != ConstKind.CK_FN:
            return 0
        return body.const_d0.get(const_id as i64)
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

fn CCodegen.call_method_base_name(self: CCodegen, body: MirBody, callee_operand: i32) -> str:
    let fn_sym = self.call_callee_fn_sym(body, callee_operand)
    if fn_sym == 0:
        return ""
    cc_base_name(cc_intern_resolve(self.intern, fn_sym))

fn CCodegen.call_first_arg_place_id(self: CCodegen, body: MirBody, args_id: i32) -> i32:
    if self.call_arg_count(body, args_id) <= 0:
        return -1
    let first_arg = self.call_arg_operand(body, args_id, 0)
    if first_arg < 0 or first_arg >= body.operand_kinds.len() as i32:
        return -1
    let ok = body.operand_kinds.get(first_arg as i64)
    if ok != OperandKind.OK_COPY and ok != OperandKind.OK_MOVE:
        return -1
    body.operand_d0.get(first_arg as i64)

fn CCodegen.place_same(self: CCodegen, body: MirBody, a: i32, b: i32) -> i32:
    let _ = self
    if a < 0 or b < 0:
        return 0
    if a >= body.place_locals.len() as i32 or b >= body.place_locals.len() as i32:
        return 0
    if body.place_locals.get(a as i64) != body.place_locals.get(b as i64):
        return 0
    let ac = body.place_proj_counts.get(a as i64)
    let bc = body.place_proj_counts.get(b as i64)
    if ac != bc:
        return 0
    let astart = body.place_proj_starts.get(a as i64)
    let bstart = body.place_proj_starts.get(b as i64)
    for i in 0..ac:
        if body.proj_kinds.get((astart + i) as i64) != body.proj_kinds.get((bstart + i) as i64):
            return 0
        if body.proj_d0.get((astart + i) as i64) != body.proj_d0.get((bstart + i) as i64):
            return 0
    1

fn CCodegen.place_kind_cache_lookup(self: CCodegen, body_fn_sym: i32, place_id: i32) -> Option[CcPlaceKind]:
    let raw = self.place_kind_cache.get(cc_body_local_cache_key(body_fn_sym, place_id))
    if raw.is_some():
        return Some(raw.unwrap() as CcPlaceKind)
    None

fn CCodegen.place_kind_cache_store(self: CCodegen, body_fn_sym: i32, place_id: i32, kind: CcPlaceKind):
    self.place_kind_cache.insert(cc_body_local_cache_key(body_fn_sym, place_id), kind as i32)

fn CCodegen.callee_hint_cache_lookup(self: CCodegen, fn_sym: i32) -> Option[CcCalleeHint]:
    let raw = self.callee_hint_cache.get(fn_sym)
    if raw.is_some():
        return Some(raw.unwrap() as CcCalleeHint)
    None

fn CCodegen.callee_hint_cache_store(self: CCodegen, fn_sym: i32, kind: CcCalleeHint):
    self.callee_hint_cache.insert(fn_sym, kind as i32)

fn CCodegen.callee_field_hint(self: CCodegen, fn_sym: i32) -> CcCalleeHint:
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
        if cc_str_contains(owner, "HashMap") != 0 or cc_str_contains(raw, "HashMap") != 0:
            out = CcCalleeHint.MAP_NEW
        else if cc_str_contains(owner, "Vec") != 0 or cc_str_contains(raw, "Vec") != 0:
            out = CcCalleeHint.VEC_NEW
        else if cc_str_contains(owner, "Option") != 0 or cc_str_contains(raw, "Option") != 0:
            out = CcCalleeHint.OPT_NEW
    else if owner.len() > 0:
        if cc_str_contains(owner, "HashMap") != 0:
            if base == "insert" or base == "get" or base == "contains" or cc_is_len_method(base) or base == "remove":
                out = CcCalleeHint.MAP_RECV
        else if cc_str_contains(owner, "Vec") != 0:
            if base == "push" or base == "get" or cc_is_len_method(base) or base == "set_i32" or base == "remove" or base == "clear" or base == "pop":
                out = CcCalleeHint.VEC_RECV
        else if cc_str_contains(owner, "Option") != 0:
            if base == "is_some" or base == "unwrap":
                out = CcCalleeHint.OPT_RECV

    self.callee_hint_cache_store(fn_sym, out)
    out

fn CCodegen.infer_place_kind_impl(self: CCodegen, body: MirBody, place_id: i32) -> CcPlaceKind:
    if place_id < 0 or place_id >= body.place_locals.len() as i32:
        return CcPlaceKind.UNKNOWN

    var vec_score = 0
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
        if method == "push" or method == "set_i32" or method == "clear" or method == "pop":
            vec_score = vec_score + 3
            continue
        if method == "insert":
            map_score = map_score + 3
            continue
        if method == "is_some" or method == "unwrap":
            opt_score = opt_score + 3
            continue
        if method == "get" or cc_is_len_method(method):
            vec_score = vec_score + 1
            map_score = map_score + 1
            continue
        if method == "contains" or method == "remove":
            map_score = map_score + 1
            continue
        if method == "new":
            vec_score = vec_score + 1
            map_score = map_score + 1
            continue
    if vec_score <= 0 and map_score <= 0 and opt_score <= 0:
        return CcPlaceKind.UNKNOWN
    if vec_score >= map_score and vec_score >= opt_score:
        return CcPlaceKind.VEC
    if map_score >= opt_score:
        return CcPlaceKind.HASHMAP
    CcPlaceKind.OPTION

fn CCodegen.infer_place_kind(self: CCodegen, body: MirBody, place_id: i32) -> CcPlaceKind:
    let cache_hit = self.place_kind_cache_lookup(body.fn_sym, place_id)
    if cache_hit.is_some():
        return cache_hit.unwrap()
    let kind = self.infer_place_kind_impl(body, place_id)
    self.place_kind_cache_store(body.fn_sym, place_id, kind)
    kind

fn CCodegen.local_place_kind_depth(self: CCodegen, body: MirBody, local_id: i32, depth: i32) -> CcPlaceKind:
    if local_id < 0:
        return CcPlaceKind.UNKNOWN
    if depth > 1:
        return CcPlaceKind.UNKNOWN

    var vec_score = 0
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
        if method == "push" or method == "set_i32" or method == "clear" or method == "pop":
            vec_score = vec_score + 4
            continue
        if method == "insert" or method == "contains":
            map_score = map_score + 4
            continue
        if method == "is_some" or method == "unwrap":
            opt_score = opt_score + 4
            continue
        if method == "get" or cc_is_len_method(method):
            vec_score = vec_score + 1
            map_score = map_score + 1
            continue
        if method == "remove":
            map_score = map_score + 2
            vec_score = vec_score + 1
            continue

    for bb in 0..body.block_count():
        let start = body.bb_stmt_starts.get(bb as i64)
        let count = body.bb_stmt_counts.get(bb as i64)
        for si in 0..count:
            let stmt_id = start + si
            if body.stmt_kinds.get(stmt_id as i64) != StmtKind.Assign:
                continue
            let rval_id = body.stmt_d1.get(stmt_id as i64)
            if rval_id < 0 or rval_id >= body.rval_kinds.len() as i32:
                continue
            if body.rval_kinds.get(rval_id as i64) != RvalueKind.RK_USE:
                continue
            let src_operand = body.rval_d0.get(rval_id as i64)
            if src_operand < 0 or src_operand >= body.operand_kinds.len() as i32:
                continue
            let ok = body.operand_kinds.get(src_operand as i64)
            if ok != OperandKind.OK_COPY and ok != OperandKind.OK_MOVE:
                continue
            let src_place = body.operand_d0.get(src_operand as i64)
            let dst_place = body.stmt_d0.get(stmt_id as i64)
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
                if k == CcPlaceKind.VEC:
                    vec_score = vec_score + 2
                else if k == CcPlaceKind.HASHMAP:
                    map_score = map_score + 2
                else if k == CcPlaceKind.OPTION:
                    opt_score = opt_score + 2
            if dst_local == local_id:
                let k = self.local_place_kind_depth(body, src_local, depth + 1)
                if k == CcPlaceKind.VEC:
                    vec_score = vec_score + 2
                else if k == CcPlaceKind.HASHMAP:
                    map_score = map_score + 2
                else if k == CcPlaceKind.OPTION:
                    opt_score = opt_score + 2

    if vec_score <= 0 and map_score <= 0 and opt_score <= 0:
        return CcPlaceKind.UNKNOWN
    if vec_score >= map_score and vec_score >= opt_score:
        return CcPlaceKind.VEC
    if map_score >= opt_score:
        return CcPlaceKind.HASHMAP
    CcPlaceKind.OPTION

fn CCodegen.local_place_kind(self: CCodegen, body: MirBody, local_id: i32) -> CcPlaceKind:
    self.local_place_kind_depth(body, local_id, 0)

fn CCodegen.call_dest_expected_tid(self: CCodegen, body: MirBody, dest_place: i32) -> i32:
    let dest_tid = self.place_local_tid(body, dest_place)
    if self.in_field_cache_build != 0:
        return dest_tid
    if dest_tid == CC_PSEUDO_TID_VEC:
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

fn CCodegen.sig_matches_call_name(self: CCodegen, sig_sym: i32, fn_sym: i32) -> i32:
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

fn CCodegen.infer_named_call_sym_scan(self: CCodegen, body: MirBody, fn_sym: i32, args_id: i32, dest_place: i32, only_local_defs: i32) -> i32:
    let raw = cc_intern_resolve(self.intern, fn_sym)
    if raw.len() == 0:
        return 0
    let base_name = cc_base_name(raw)
    let arg_count = self.call_arg_count(body, args_id)
    let want_ret_tid = self.call_dest_expected_tid(body, dest_place)
    var match_sym = 0
    var match_score = -1
    for si in 0..self.sema.sig_names.len() as i32:
        let sym = self.sema.sig_names.get(si as i64)
        if only_local_defs != 0 and self.has_body_for_sym(sym) == 0:
            continue
        if self.sig_matches_call_name(sym, fn_sym) == 0:
            continue
        if self.sema.sig_get_param_count(si) != arg_count:
            continue
        let sym_text = cc_intern_resolve(self.intern, sym)
        let ret_tid = self.sema.sig_return_type(si)
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

fn CCodegen.infer_named_call_sym(self: CCodegen, body: MirBody, fn_sym: i32, args_id: i32, dest_place: i32) -> i32:
    if self.infer_local_depth > 0:
        return self.infer_named_call_sym_scan(body, fn_sym, args_id, dest_place, 1)
    let cached = self.call_infer_cache_lookup("named", body.fn_sym, fn_sym, args_id, dest_place)
    if cached != -1234567:
        return cached
    let result = self.infer_named_call_sym_scan(body, fn_sym, args_id, dest_place, 1)
    self.call_infer_cache_store("named", body.fn_sym, fn_sym, args_id, dest_place, result)
    result

fn CCodegen.infer_body_method_sym(self: CCodegen, body: MirBody, fn_sym: i32, args_id: i32, dest_place: i32) -> i32:
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
    let first_owner = self.type_owner_text(self.call_first_arg_resolved_tid(body, args_id))
    var match_sym = 0
    var match_score = -1
    for i in 0..self.mir_mod.body_fn_syms.len() as i32:
        let cand = self.mir_mod.body_fn_syms.get(i as i64)
        let cand_text = cc_intern_resolve(self.intern, cand)
        if cc_name_matches(cand_text, raw) == 0:
            continue
        let sig_idx = self.sig_index_for_sym(cand)
        if sig_idx < 0:
            continue
        if self.sema.sig_get_param_count(sig_idx) != argc:
            continue
        let ret_tid = self.sema.sig_return_type(sig_idx)
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

fn CCodegen.infer_direct_call_sym_scan(self: CCodegen, body: MirBody, args_id: i32, dest_place: i32, only_local_defs: i32) -> i32:
    let arg_count = self.call_arg_count(body, args_id)
    let want_ret_tid = self.call_dest_expected_tid(body, dest_place)
    var match_sym = 0
    var match_score = -1
    for si in 0..self.sema.sig_names.len() as i32:
        let sym = self.sema.sig_names.get(si as i64)
        if only_local_defs != 0 and self.has_body_for_sym(sym) == 0:
            continue
        if self.sema.sig_get_param_count(si) != arg_count:
            continue
        let ret_tid = self.sema.sig_return_type(si)
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

fn CCodegen.describe_call_candidates(self: CCodegen, body: MirBody, args_id: i32, dest_place: i32, only_local_defs: i32) -> str:
    let arg_count = self.call_arg_count(body, args_id)
    let dest_tid = self.place_local_tid(body, dest_place)
    var out = ""
    var kept = 0
    for si in 0..self.sema.sig_names.len() as i32:
        let sym = self.sema.sig_names.get(si as i64)
        if only_local_defs != 0 and self.has_body_for_sym(sym) == 0:
            continue
        if self.sema.sig_get_param_count(si) != arg_count:
            continue
        let ret_tid = self.sema.sig_return_type(si)
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

fn CCodegen.describe_qualified_method_candidates(self: CCodegen, body: MirBody, method_sym: i32, args_id: i32, only_local_defs: i32) -> str:
    let raw = cc_intern_resolve(self.intern, method_sym)
    if raw.len() == 0:
        return ""
    let wanted = "." ++ raw
    let arg_count = self.call_arg_count(body, args_id)
    var out = ""
    for si in 0..self.sema.sig_names.len() as i32:
        let sym = self.sema.sig_names.get(si as i64)
        if only_local_defs != 0 and self.has_body_for_sym(sym) == 0:
            continue
        if self.sema.sig_get_param_count(si) != arg_count:
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

fn CCodegen.call_arg_tids_text(self: CCodegen, body: MirBody, args_id: i32) -> str:
    let arg_count = self.call_arg_count(body, args_id)
    var out = ""
    for ai in 0..arg_count:
        if ai > 0:
            out = out ++ ","
        let arg_operand = self.call_arg_operand(body, args_id, ai)
        out = out ++ f"{self.operand_tid(body, arg_operand)}"
    out

fn CCodegen.call_first_arg_hint_text(self: CCodegen, body: MirBody, args_id: i32) -> str:
    if self.call_arg_count(body, args_id) <= 0:
        return ""
    let first_arg = self.call_arg_operand(body, args_id, 0)
    let first_arg_tid = self.operand_tid(body, first_arg)
    let owner_text = self.type_owner_text(first_arg_tid)
    f"tid={first_arg_tid} type={self.sema.type_name(first_arg_tid)} owner={owner_text}"

fn CCodegen.call_first_arg_resolved_tid(self: CCodegen, body: MirBody, args_id: i32) -> i32:
    if self.call_arg_count(body, args_id) <= 0:
        return 0
    let first_arg = self.call_arg_operand(body, args_id, 0)
    let first_arg_tid = self.operand_tid(body, first_arg)
    self.sema.resolve_alias(first_arg_tid as TypeId) as i32

fn CCodegen.type_owner_text(self: CCodegen, tid: i32) -> str:
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

fn CCodegen.call_first_arg_owner_text(self: CCodegen, body: MirBody, args_id: i32) -> str:
    self.type_owner_text(self.call_first_arg_resolved_tid(body, args_id))

fn CCodegen.owner_named_body_sym(self: CCodegen, body: MirBody, fn_sym: i32, args_id: i32) -> i32:
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

fn CCodegen.method_infer_active(self: CCodegen, method_sym: i32, args_id: i32, dest_place: i32) -> i32:
    for i in 0..self.active_method_syms.len() as i32:
        if self.active_method_syms.get(i as i64) != method_sym:
            continue
        if self.active_method_args.get(i as i64) != args_id:
            continue
        if self.active_method_dests.get(i as i64) != dest_place:
            continue
        return 1
    0

fn CCodegen.method_infer_push(self: CCodegen, method_sym: i32, args_id: i32, dest_place: i32) -> void:
    self.active_method_syms.push(method_sym)
    self.active_method_args.push(args_id)
    self.active_method_dests.push(dest_place)

fn CCodegen.method_infer_pop(self: CCodegen):
    if self.active_method_syms.len() as i32 == 0:
        return
    self.active_method_syms.pop()
    self.active_method_args.pop()
    self.active_method_dests.pop()

fn CCodegen.direct_infer_active(self: CCodegen, args_id: i32, dest_place: i32) -> i32:
    for i in 0..self.active_direct_args.len() as i32:
        if self.active_direct_args.get(i as i64) != args_id:
            continue
        if self.active_direct_dests.get(i as i64) != dest_place:
            continue
        return 1
    0

fn CCodegen.direct_infer_push(self: CCodegen, args_id: i32, dest_place: i32) -> void:
    self.active_direct_args.push(args_id)
    self.active_direct_dests.push(dest_place)

fn CCodegen.direct_infer_pop(self: CCodegen):
    if self.active_direct_args.len() as i32 == 0:
        return
    self.active_direct_args.pop()
    self.active_direct_dests.pop()

fn cc_call_infer_cache_key(kind: str, body_fn_sym: i32, callee_sym: i32, args_id: i32, dest_place: i32) -> str:
    kind ++ ":" ++ f"{body_fn_sym}" ++ ":" ++ f"{callee_sym}" ++ ":" ++ f"{args_id}" ++ ":" ++ f"{dest_place}"

fn CCodegen.call_infer_cache_lookup(self: CCodegen, kind: str, body_fn_sym: i32, callee_sym: i32, args_id: i32, dest_place: i32) -> i32:
    let cached = self.call_infer_cache.get(cc_call_infer_cache_key(kind, body_fn_sym, callee_sym, args_id, dest_place))
    if cached.is_some():
        return cached.unwrap()
    -1234567

fn CCodegen.call_infer_cache_store(self: CCodegen, kind: str, body_fn_sym: i32, callee_sym: i32, args_id: i32, dest_place: i32, value: i32) -> void:
    self.call_infer_cache.insert(cc_call_infer_cache_key(kind, body_fn_sym, callee_sym, args_id, dest_place), value)

fn CCodegen.field_cache_lookup(self: CCodegen, struct_tid: i32, field_sym: i32) -> i32:
    for i in 0..self.field_cache_struct_tids.len() as i32:
        if self.field_cache_struct_tids.get(i as i64) != struct_tid:
            continue
        if self.field_cache_syms.get(i as i64) != field_sym:
            continue
        return self.field_cache_tids.get(i as i64)
    -1234567

fn CCodegen.field_cache_store(self: CCodegen, struct_tid: i32, field_sym: i32, tid: i32) -> void:
    self.field_cache_struct_tids.push(struct_tid)
    self.field_cache_syms.push(field_sym)
    self.field_cache_tids.push(tid)

fn CCodegen.field_cache_record(self: CCodegen, struct_tid: i32, field_sym: i32, tid: i32):
    if tid == 0 or self.is_void_tid(tid) != 0:
        return
    if self.field_cache_lookup(struct_tid, field_sym) != -1234567:
        return
    self.field_cache_store(struct_tid, field_sym, self.sema.resolve_alias(tid))

fn cc_body_local_cache_key(body_fn_sym: i32, local_id: i32) -> i64:
    (body_fn_sym as i64) + ((local_id as i64) * 4294967296)

fn CCodegen.local_infer_cache_lookup(self: CCodegen, body_fn_sym: i32, local_id: i32) -> i32:
    let cached = self.local_infer_cache.get(cc_body_local_cache_key(body_fn_sym, local_id))
    if cached.is_some():
        return cached.unwrap()
    -1234567

fn CCodegen.local_infer_cache_store(self: CCodegen, body_fn_sym: i32, local_id: i32, tid: i32):
    self.local_infer_cache.insert(cc_body_local_cache_key(body_fn_sym, local_id), tid)

fn CCodegen.local_usage_hint_cache_lookup(self: CCodegen, body_fn_sym: i32, local_id: i32) -> i32:
    let cached = self.local_usage_hint_cache.get(cc_body_local_cache_key(body_fn_sym, local_id))
    if cached.is_some():
        return cached.unwrap()
    -1234567

fn CCodegen.local_usage_hint_cache_store(self: CCodegen, body_fn_sym: i32, local_id: i32, tid: i32):
    self.local_usage_hint_cache.insert(cc_body_local_cache_key(body_fn_sym, local_id), tid)

fn CCodegen.local_usage_hint_tid(self: CCodegen, body: MirBody, local_id: i32) -> i32:
    if local_id < 0:
        return 0
    let cache_hit = self.local_usage_hint_cache_lookup(body.fn_sym, local_id)
    if cache_hit != -1234567:
        return cache_hit
    var hint_tid = 0

    // Prefer concrete typed use-sites where this local flows into a known call parameter.
    for bb in 0..body.block_count():
        if body.term_kind(bb) != TermKind.TK_CALL:
            continue
        let callee_operand = body.term_data0(bb)
        let args_id = body.term_data1(bb)
        var sig_idx = -1
        let fn_sym = self.call_callee_fn_sym(body, callee_operand)
        if fn_sym != 0:
            sig_idx = self.sig_index_for_sym(fn_sym)
        if sig_idx < 0:
            continue
        let argc = self.call_arg_count(body, args_id)
        for ai in 0..argc:
            let arg_operand = self.call_arg_operand(body, args_id, ai)
            if arg_operand < 0 or arg_operand >= body.operand_kinds.len() as i32:
                continue
            let ok = body.operand_kinds.get(arg_operand as i64)
            if ok != OperandKind.OK_COPY and ok != OperandKind.OK_MOVE:
                continue
            let p = body.operand_d0.get(arg_operand as i64)
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
        let start = body.bb_stmt_starts.get(bb as i64)
        let count = body.bb_stmt_counts.get(bb as i64)
        for si in 0..count:
            let stmt_id = start + si
            if body.stmt_kinds.get(stmt_id as i64) != StmtKind.Assign:
                continue
            let rval_id = body.stmt_d1.get(stmt_id as i64)
            if rval_id < 0 or rval_id >= body.rval_kinds.len() as i32:
                continue
            if body.rval_kinds.get(rval_id as i64) != RvalueKind.RK_AGGREGATE:
                continue
            let fields_id = body.rval_d1.get(rval_id as i64)
            if fields_id < 0 or fields_id >= body.agg_field_starts.len() as i32:
                continue
            let dst_tid = self.place_tid_no_infer(body, body.stmt_d0.get(stmt_id as i64))
            let dst_resolved = self.sema.resolve_alias(dst_tid)
            if self.sema.get_type_kind(dst_resolved) != TypeKind.TY_STRUCT:
                continue
            let field_start = body.agg_field_starts.get(fields_id as i64)
            let field_count = body.agg_field_counts.get(fields_id as i64)
            for fi in 0..field_count:
                let operand_id = body.agg_field_operands.get((field_start + fi) as i64)
                if self.operand_direct_local_id(body, operand_id) != local_id:
                    continue
                let name_sym = body.agg_field_name_syms.get((field_start + fi) as i64)
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
        let start = body.bb_stmt_starts.get(bb as i64)
        let count = body.bb_stmt_counts.get(bb as i64)
        for si in 0..count:
            let stmt_id = start + si
            if body.stmt_kinds.get(stmt_id as i64) != StmtKind.Assign:
                continue
            let rval_id = body.stmt_d1.get(stmt_id as i64)
            if rval_id < 0 or rval_id >= body.rval_kinds.len() as i32:
                continue
            if body.rval_kinds.get(rval_id as i64) != RvalueKind.RK_USE:
                continue
            let src_operand = body.rval_d0.get(rval_id as i64)
            if src_operand < 0 or src_operand >= body.operand_kinds.len() as i32:
                continue
            let ok = body.operand_kinds.get(src_operand as i64)
            if ok != OperandKind.OK_COPY and ok != OperandKind.OK_MOVE:
                continue
            let src_place = body.operand_d0.get(src_operand as i64)
            if self.place_is_direct_local(body, src_place, local_id) == 0:
                continue
            let dst_place = body.stmt_d0.get(stmt_id as i64)
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

fn CCodegen.infer_direct_call_sym(self: CCodegen, body: MirBody, args_id: i32, dest_place: i32) -> i32:
    let cache_hit = self.call_infer_cache_lookup("direct", body.fn_sym, 0, args_id, dest_place)
    if cache_hit != -1234567:
        return cache_hit
    if self.direct_infer_active(args_id, dest_place) != 0:
        self.call_infer_cache_store("direct", body.fn_sym, 0, args_id, dest_place, 0)
        return 0
    self.direct_infer_push(args_id, dest_place)
    let local_scan = self.infer_direct_call_sym_scan(body, args_id, dest_place, 1)
    var result = 0
    if local_scan == -2 or local_scan > 0:
        result = local_scan
    else:
        result = self.infer_direct_call_sym_scan(body, args_id, dest_place, 0)
    self.direct_infer_pop()
    self.call_infer_cache_store("direct", body.fn_sym, 0, args_id, dest_place, result)
    result

fn CCodegen.unique_method_owner_from_name(self: CCodegen, body: MirBody, fn_sym: i32, args_id: i32) -> str:
    let raw = cc_intern_resolve(self.intern, fn_sym)
    if raw.len() == 0:
        return ""
    if cc_str_contains_dot(raw) != 0:
        return cc_owner_prefix(raw)
    let wanted = "." ++ raw
    let arg_count = self.call_arg_count(body, args_id)
    var out = ""
    for si in 0..self.sema.sig_names.len() as i32:
        if self.sema.sig_get_param_count(si) != arg_count:
            continue
        let sym_text = cc_intern_resolve(self.intern, self.sema.sig_names.get(si as i64))
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

fn CCodegen.local_owner_hint_depth(self: CCodegen, body: MirBody, local_id: i32, depth: i32) -> str:
    if depth > 8:
        return ""
    for bb in 0..body.block_count():
        if body.term_kind(bb) != TermKind.TK_CALL:
            continue
        let dest_place = body.term_data2(bb)
        if self.place_is_direct_local(body, dest_place, local_id) == 0:
            continue
        let callee_operand = body.term_data0(bb)
        if callee_operand < 0 or callee_operand >= body.operand_kinds.len() as i32:
            continue
        if body.operand_kinds.get(callee_operand as i64) != OperandKind.OK_CONSTANT:
            continue
        let const_id = body.operand_d0.get(callee_operand as i64)
        if const_id < 0 or const_id >= body.const_kinds.len() as i32:
            continue
        if body.const_kinds.get(const_id as i64) != ConstKind.CK_FN:
            continue
        let fn_sym = body.const_d0.get(const_id as i64)
        if fn_sym == 0:
            continue
        let raw = cc_intern_resolve(self.intern, fn_sym)
        let owner = cc_owner_prefix(raw)
        if owner.len() > 0:
            return owner

    for bb in 0..body.block_count():
        let start = body.bb_stmt_starts.get(bb as i64)
        let count = body.bb_stmt_counts.get(bb as i64)
        for si in 0..count:
            let stmt_id = start + si
            if body.stmt_kinds.get(stmt_id as i64) != StmtKind.Assign:
                continue
            let dst_place = body.stmt_d0.get(stmt_id as i64)
            if self.place_is_direct_local(body, dst_place, local_id) == 0:
                continue
            let rval_id = body.stmt_d1.get(stmt_id as i64)
            if rval_id < 0 or rval_id >= body.rval_kinds.len() as i32:
                continue
            if body.rval_kinds.get(rval_id as i64) != RvalueKind.RK_USE:
                continue
            let op = body.rval_d0.get(rval_id as i64)
            if op < 0 or op >= body.operand_kinds.len() as i32:
                continue
            let ok = body.operand_kinds.get(op as i64)
            if ok != OperandKind.OK_COPY and ok != OperandKind.OK_MOVE:
                continue
            let p = body.operand_d0.get(op as i64)
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
        if first_arg < 0 or first_arg >= body.operand_kinds.len() as i32:
            continue
        let ok = body.operand_kinds.get(first_arg as i64)
        if ok != OperandKind.OK_COPY and ok != OperandKind.OK_MOVE:
            continue
        let p = body.operand_d0.get(first_arg as i64)
        if self.place_is_direct_local(body, p, local_id) == 0:
            continue
        let callee_operand = body.term_data0(bb)
        if callee_operand < 0 or callee_operand >= body.operand_kinds.len() as i32:
            continue
        if body.operand_kinds.get(callee_operand as i64) != OperandKind.OK_CONSTANT:
            continue
        let const_id = body.operand_d0.get(callee_operand as i64)
        if const_id < 0 or const_id >= body.const_kinds.len() as i32:
            continue
        if body.const_kinds.get(const_id as i64) != ConstKind.CK_FN:
            continue
        let fn_sym = body.const_d0.get(const_id as i64)
        if fn_sym == 0:
            continue
        let owner = self.unique_method_owner_from_name(body, fn_sym, args_id)
        if owner.len() > 0:
            return owner
    ""

fn CCodegen.local_owner_hint(self: CCodegen, body: MirBody, local_id: i32) -> str:
    self.local_owner_hint_depth(body, local_id, 0)

fn CCodegen.infer_qualified_method_sym_scan(self: CCodegen, body: MirBody, method_sym: i32, args_id: i32, dest_place: i32, only_local_defs: i32) -> i32:
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

    var match_sym = 0
    var match_score = -1
    for si in 0..self.sema.sig_names.len() as i32:
        let sym = self.sema.sig_names.get(si as i64)
        if only_local_defs != 0 and self.has_body_for_sym(sym) == 0:
            continue
        if self.sema.sig_get_param_count(si) != arg_count:
            continue
        let sym_text = cc_intern_resolve(self.intern, sym)
        if cc_str_ends_with(sym_text, wanted) == 0:
            continue
        let owner = cc_owner_prefix(sym_text)
        let owner_matched = if preferred_owner.len() > 0 and owner == preferred_owner: 1 else: 0
        let ret_tid = self.sema.sig_return_type(si)
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

fn CCodegen.infer_qualified_method_sym(self: CCodegen, body: MirBody, method_sym: i32, args_id: i32, dest_place: i32) -> i32:
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
    var result = 0
    if local_scan == -2 or local_scan > 0:
        result = local_scan
    else:
        result = self.infer_qualified_method_sym_scan(body, method_sym, args_id, dest_place, 0)
    self.method_infer_pop()
    self.call_infer_cache_store("qualified-method", body.fn_sym, method_sym, args_id, dest_place, result)
    result

fn CCodegen.infer_owner_method_sym_scan(self: CCodegen, body: MirBody, fn_sym: i32, args_id: i32, dest_place: i32, only_local_defs: i32) -> i32:
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
    var match_sym = 0
    var match_score = -1
    for si in 0..self.sema.sig_names.len() as i32:
        let sym = self.sema.sig_names.get(si as i64)
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
        let ret_tid = self.sema.sig_return_type(si)
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

fn CCodegen.infer_owner_method_sym(self: CCodegen, body: MirBody, fn_sym: i32, args_id: i32, dest_place: i32) -> i32:
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

fn CCodegen.infer_builtin_call_name(self: CCodegen, body: MirBody, args_id: i32, dest_place: i32) -> str:
    let _ = self
    let _ = body
    let _ = args_id
    let _ = dest_place
    ""

fn CCodegen.infer_print_call_name(self: CCodegen, body: MirBody, args_id: i32, dest_place: i32) -> str:
    let _ = self
    let _ = body
    let _ = args_id
    let _ = dest_place
    ""

fn CCodegen.extern_call_name(self: CCodegen, sym: i32, body: MirBody, args_id: i32, dest_place: i32) -> str:
    let _ = body
    let _ = args_id
    let _ = dest_place
    self.extern_sym_c_name(sym)

fn CCodegen.sig_index_for_sym(self: CCodegen, fn_sym: i32) -> i32:
    let raw = cc_intern_resolve(self.intern, fn_sym)
    if self.sig_idx_cache.contains(fn_sym):
        return self.sig_idx_cache.get(fn_sym).unwrap()

    var out = -1
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
        for si in 0..self.sema.sig_names.len() as i32:
            let sym = self.sema.sig_names.get(si as i64)
            if sym == fn_sym:
                out = si
                break
        if out < 0 and cc_str_contains_dot(raw) != 0:
            var match_idx = -1
            for si in 0..self.sema.sig_names.len() as i32:
                let sym_text = cc_intern_resolve(self.intern, self.sema.sig_names.get(si as i64))
                if sym_text != raw:
                    continue
                if match_idx < 0:
                    match_idx = si
                else:
                    match_idx = -2
                    break
            if match_idx >= 0:
                out = match_idx
        if out < 0 and cc_str_contains_dot(raw) == 0:
            let wanted = "." ++ raw
            var match_idx = -1
            for si in 0..self.sema.sig_names.len() as i32:
                let sym_text = cc_intern_resolve(self.intern, self.sema.sig_names.get(si as i64))
                if cc_str_ends_with(sym_text, wanted) == 0:
                    continue
                if match_idx < 0:
                    match_idx = si
                else:
                    match_idx = -2
                    break
            if match_idx >= 0:
                out = match_idx

    self.sig_idx_cache.insert(fn_sym, out)
    out

fn CCodegen.unqualified_builtin_method_name(self: CCodegen, body: MirBody, fn_sym: i32, args_id: i32) -> str:
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
        return "with_str_starts_with"
    if raw == "ends_with" and argc == 2:
        return "with_str_ends_with"
    if raw == "contains" and argc == 2:
        return "with_str_contains"
    if raw == "find" and argc == 2:
        return "with_str_index_of"
    if raw == "slice" and argc == 3:
        return "with_str_slice"
    if raw == "byte_at" and argc == 2:
        return "with_str_byte_at"
    ""

fn CCodegen.unqualified_builtin_method_ret_tid(self: CCodegen, body: MirBody, fn_sym: i32, args_id: i32) -> i32:
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

fn CCodegen.call_builtin_kind(self: CCodegen, body: MirBody, callee_operand: i32, args_id: i32, dest_place: i32) -> CcBuiltin:
    let method = self.call_method_base_name(body, callee_operand)
    if method.len() == 0:
        return CcBuiltin.NONE

    let callee_sym = self.call_callee_fn_sym(body, callee_operand)
    let callee_hint = self.callee_field_hint(callee_sym)
    let first_owner = self.type_owner_text(self.call_first_arg_resolved_tid(body, args_id))
    let recv_is_vec =
        if callee_hint == CcCalleeHint.VEC_RECV:
            1
        else if cc_str_contains(first_owner, "Vec") != 0:
            1
        else:
            0
    let recv_is_map =
        if callee_hint == CcCalleeHint.MAP_RECV:
            1
        else if cc_str_contains(first_owner, "HashMap") != 0:
            1
        else:
            0
    let recv_is_opt =
        if callee_hint == CcCalleeHint.OPT_RECV:
            1
        else if cc_str_contains(first_owner, "Option") != 0:
            1
        else:
            0
    let recv_is_vecslot = if cc_str_contains(first_owner, "VecSlot") != 0: 1 else: 0

    if method == "new":
        var dst_kind = self.infer_place_kind(body, dest_place)
        if dst_kind == CcPlaceKind.UNKNOWN:
            let dst_local = self.place_local_id(body, dest_place)
            if dst_local >= 0:
                dst_kind = self.local_place_kind(body, dst_local)
        if dst_kind == CcPlaceKind.VEC:
            return CcBuiltin.VEC_NEW
        if dst_kind == CcPlaceKind.HASHMAP:
            return CcBuiltin.MAP_NEW
        if callee_hint == CcCalleeHint.VEC_NEW:
            return CcBuiltin.VEC_NEW
        if callee_hint == CcCalleeHint.MAP_NEW:
            return CcBuiltin.MAP_NEW
        let hinted = self.call_dest_expected_tid(body, dest_place)
        if hinted == CC_PSEUDO_TID_VEC:
            return CcBuiltin.VEC_NEW
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
        else if cc_str_contains(first_owner, "Atomic") != 0:
            1
        else:
            0
    let allow_place_kind_guess = if first_owner.len() == 0: 1 else: 0
    let recv_kind_is_vec = if recv_is_vec != 0 or (allow_place_kind_guess != 0 and place_kind == CcPlaceKind.VEC): 1 else: 0
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

    if method == "slot":
        if recv_kind_is_vec != 0:
            return CcBuiltin.VEC_SLOT
        return CcBuiltin.NONE
    if method == "get_disjoint":
        if recv_kind_is_vec != 0:
            return CcBuiltin.VEC_GET_DISJOINT
        return CcBuiltin.NONE

    if method == "push":
        if recv_kind_is_vec != 0:
            return CcBuiltin.VEC_PUSH
        return CcBuiltin.NONE
    if method == "set_i32":
        if recv_kind_is_vec != 0:
            return CcBuiltin.VEC_SET_I32
        return CcBuiltin.NONE
    if method == "clear":
        if recv_kind_is_vec != 0:
            return CcBuiltin.VEC_CLEAR
        return CcBuiltin.NONE
    if method == "pop":
        if recv_kind_is_vec != 0:
            return CcBuiltin.VEC_POP
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

    if method == "set":
        if recv_is_vecslot != 0:
            return CcBuiltin.VECSLOT_SET
        return CcBuiltin.NONE

    if method == "get":
        if recv_is_vecslot != 0:
            return CcBuiltin.VECSLOT_GET
        if recv_kind_is_map != 0:
            return CcBuiltin.MAP_GET
        if recv_kind_is_vec != 0:
            return CcBuiltin.VEC_GET
        return CcBuiltin.NONE

    if method == "len":
        if first_tk == TypeKind.TY_STR:
            return CcBuiltin.NONE
        if recv_kind_is_map != 0:
            return CcBuiltin.MAP_LEN
        if recv_kind_is_vec != 0:
            return CcBuiltin.VEC_LEN
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
        if recv_kind_is_vec != 0:
            return CcBuiltin.VEC_REMOVE
        return CcBuiltin.NONE

    CcBuiltin.NONE

fn CCodegen.call_builtin_ret_tid(self: CCodegen, body: MirBody, callee_operand: i32, args_id: i32, dest_place: i32) -> i32:
    let mir_intrinsic = body.call_intrinsic(args_id)
    var kind = cc_builtin_from_mir_intrinsic(mir_intrinsic)
    if kind == CcBuiltin.NONE:
        kind = self.call_builtin_kind(body, callee_operand, args_id, dest_place)
    if kind == CcBuiltin.NONE:
        return 0
    if kind == CcBuiltin.VEC_NEW:
        return CC_PSEUDO_TID_VEC
    if kind == CcBuiltin.VEC_SLOT:
        let hinted = self.call_dest_expected_tid(body, dest_place)
        if hinted != 0 and self.is_void_tid(hinted) == 0:
            return hinted
        let dst = self.place_local_tid(body, dest_place)
        if dst != 0 and self.is_void_tid(dst) == 0:
            return dst
        return self.sema.ty_i64 as i32
    if kind == CcBuiltin.VEC_PUSH:
        let dst = self.place_local_tid(body, dest_place)
        if dst != 0 and self.is_void_tid(dst) != 0:
            return self.sema.ty_void as i32
        let hinted = self.call_dest_expected_tid(body, dest_place)
        if hinted != 0 and self.is_void_tid(hinted) == 0:
            return hinted
        if dst != 0 and self.is_void_tid(dst) == 0:
            return dst
        return self.operand_tid(body, self.call_arg_operand(body, args_id, 0))
    if kind == CcBuiltin.VEC_SET_I32 or kind == CcBuiltin.VEC_REMOVE or kind == CcBuiltin.VEC_CLEAR:
        return self.sema.ty_void as i32
    if kind == CcBuiltin.VECSLOT_SET:
        return self.sema.ty_void as i32
    if kind == CcBuiltin.VECSLOT_GET:
        let hinted = self.call_dest_expected_tid(body, dest_place)
        if hinted != 0 and self.is_void_tid(hinted) == 0:
            return hinted
        let slot_tid = self.operand_tid(body, self.call_arg_operand(body, args_id, 0))
        let elem_tid = self.vecslot_element_tid(slot_tid)
        if elem_tid != 0:
            return elem_tid
        let dst = self.place_local_tid(body, dest_place)
        if dst != 0 and self.is_void_tid(dst) == 0:
            return dst
        return self.sema.ty_i64 as i32
    if kind == CcBuiltin.VEC_POP:
        let hinted = self.call_dest_expected_tid(body, dest_place)
        if hinted != 0 and self.is_void_tid(hinted) == 0:
            return hinted
        let dst = self.place_local_tid(body, dest_place)
        if dst != 0 and self.is_void_tid(dst) == 0:
            return dst
        return self.sema.ty_i64 as i32
    if kind == CcBuiltin.VEC_GET:
        let hinted = self.call_dest_expected_tid(body, dest_place)
        if hinted != 0 and self.is_void_tid(hinted) == 0:
            return hinted
        let dst = self.place_local_tid(body, dest_place)
        if dst != 0 and self.is_void_tid(dst) == 0:
            return dst
        return self.sema.ty_i64 as i32
    if kind == CcBuiltin.VEC_LEN:
        return self.sema.ty_usize as i32
    if kind == CcBuiltin.VEC_LEN32:
        return self.sema.ty_i32 as i32
    if kind == CcBuiltin.VEC_LEN64:
        return self.sema.ty_i64 as i32
    if kind == CcBuiltin.VEC_ULEN32:
        return self.sema.ty_u32 as i32
    if kind == CcBuiltin.VEC_ITER:
        let hinted = self.call_dest_expected_tid(body, dest_place)
        if hinted != 0 and self.is_void_tid(hinted) == 0:
            return hinted
        let dst = self.place_local_tid(body, dest_place)
        if dst != 0 and self.is_void_tid(dst) == 0:
            return dst
        return CC_PSEUDO_TID_VEC
    if kind == CcBuiltin.VECITER_NEXT:
        let hinted = self.call_dest_expected_tid(body, dest_place)
        if hinted != 0 and self.is_void_tid(hinted) == 0:
            return hinted
        let dst = self.place_local_tid(body, dest_place)
        if dst != 0 and self.is_void_tid(dst) == 0:
            return dst
        return self.sema.ty_i64 as i32
    if kind == CcBuiltin.VEC_CONTAINS:
        return self.sema.ty_bool as i32
    if kind == CcBuiltin.VEC_JOIN:
        return self.sema.ty_str as i32
    if kind == CcBuiltin.VEC_WITH_CAPACITY:
        return CC_PSEUDO_TID_VEC
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
        if cc_str_contains(owner, "HashMap") != 0:
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
    if kind == CcBuiltin.OPT_UNWRAP:
        let hinted = self.call_dest_expected_tid(body, dest_place)
        if hinted != 0 and self.is_void_tid(hinted) == 0:
            return hinted
        let dst = self.place_local_tid(body, dest_place)
        if dst != 0 and self.is_void_tid(dst) == 0:
            return dst
        return self.sema.ty_i64 as i32
    if kind == CcBuiltin.ATOMIC_LOAD or kind == CcBuiltin.ATOMIC_SWAP:
        return self.atomic_recv_value_tid(body, args_id)
    if kind == CcBuiltin.ATOMIC_STORE:
        return self.sema.ty_void as i32
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
        return CC_PSEUDO_TID_VEC
    if kind == CcBuiltin.STR_TRIM or kind == CcBuiltin.STR_TO_UPPER or kind == CcBuiltin.STR_TO_LOWER or kind == CcBuiltin.STR_REPLACE or kind == CcBuiltin.STR_REPEAT:
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
    if kind == CcBuiltin.MIN or kind == CcBuiltin.MAX or kind == CcBuiltin.ABS:
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
    if kind == CcBuiltin.FMT_TO_STR or kind == CcBuiltin.FMT_DEBUG_STR or kind == CcBuiltin.FMT_DEBUG or kind == CcBuiltin.FMT_SPEC:
        return self.sema.ty_str as i32
    if kind == CcBuiltin.FMT_BUF_NEW:
        return CC_PSEUDO_TID_FMT_BUF
    if kind == CcBuiltin.FMT_BUF_WRITE_STR or kind == CcBuiltin.FMT_BUF_WRITE_FMT:
        return self.sema.ty_void as i32
    if kind == CcBuiltin.FMT_BUF_FINISH:
        return self.sema.ty_str as i32
    if kind == CcBuiltin.DYN_VTABLE_CMP:
        return self.sema.ty_bool as i32
    0

fn CCodegen.resolve_call_named_callee(self: CCodegen, body: MirBody, fn_sym: i32, args_id: i32, dest_place: i32) -> str:
    let fn_body_sym = self.canonical_body_sym(fn_sym)
    if fn_body_sym != 0:
        return self.fn_c_name(fn_body_sym)
    let owner_named = self.owner_named_body_sym(body, fn_sym, args_id)
    if owner_named != 0:
        return self.fn_c_name(owner_named)
    let builtin_method = self.unqualified_builtin_method_name(body, fn_sym, args_id)
    if builtin_method.len() > 0:
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

fn CCodegen.call_return_tid_for_fn_sym(self: CCodegen, body: MirBody, fn_sym: i32, args_id: i32, dest_place: i32, fallback: i32) -> i32:
    let fn_body_sym = self.canonical_body_sym(fn_sym)
    if fn_body_sym != 0:
        let body_sig = self.sig_index_for_sym(fn_body_sym)
        if body_sig >= 0:
            return self.sema.sig_return_type(body_sig)
    let owner_named = self.owner_named_body_sym(body, fn_sym, args_id)
    if owner_named != 0:
        let owner_named_sig = self.sig_index_for_sym(owner_named)
        if owner_named_sig >= 0:
            return self.sema.sig_return_type(owner_named_sig)
    let builtin_method_ret = self.unqualified_builtin_method_ret_tid(body, fn_sym, args_id)
    if builtin_method_ret != 0:
        return builtin_method_ret
    let inferred_named = self.infer_named_call_sym(body, fn_sym, args_id, dest_place)
    if inferred_named > 0:
        let named_sig = self.sig_index_for_sym(inferred_named)
        if named_sig >= 0:
            return self.sema.sig_return_type(named_sig)
    let inferred_method = self.infer_qualified_method_sym(body, fn_sym, args_id, dest_place)
    if inferred_method > 0:
        let method_sig = self.sig_index_for_sym(inferred_method)
        if method_sig >= 0:
            return self.sema.sig_return_type(method_sig)
    let owner_method = self.infer_owner_method_sym(body, fn_sym, args_id, dest_place)
    if owner_method > 0:
        let owner_sig = self.sig_index_for_sym(owner_method)
        if owner_sig >= 0:
            return self.sema.sig_return_type(owner_sig)
    let body_method = self.infer_body_method_sym(body, fn_sym, args_id, dest_place)
    if body_method > 0:
        let body_sig = self.sig_index_for_sym(body_method)
        if body_sig >= 0:
            return self.sema.sig_return_type(body_sig)
    let sig_idx = self.sig_index_for_sym(fn_sym)
    if sig_idx >= 0:
        return self.sema.sig_return_type(sig_idx)
    let raw = cc_intern_resolve(self.intern, fn_sym)
    if raw == "with_str_concat" or raw == "with_fs_read_file" or raw == "int_to_string":
        return self.sema.ty_str as i32
    if raw == "with_str_eq":
        return self.sema.ty_bool as i32
    if raw == "dump_async_mir" or raw == "Driver.dump_async_mir":
        return self.sema.ty_str as i32
    fallback

fn CCodegen.resolve_call_callee_text(self: CCodegen, body: MirBody, bb: i32, callee_operand: i32, args_id: i32, dest_place: i32) -> str:
    let _ = bb
    if callee_operand < 0 or callee_operand >= body.operand_kinds.len() as i32:
        self.fail(f"invalid call callee operand id {callee_operand}")
        return "/*invalid_callee*/"

    let ok = body.operand_kinds.get(callee_operand as i64)
    let od = body.operand_d0.get(callee_operand as i64)
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
        if od < 0 or od >= body.const_kinds.len() as i32:
            self.fail(f"invalid call callee constant id {od}")
            return "/*invalid_call_const*/"
        let ck = body.const_kinds.get(od as i64)
        if ck == ConstKind.CK_FN:
            let fn_sym = body.const_d0.get(od as i64)
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

fn CCodegen.call_return_tid(self: CCodegen, body: MirBody, bb: i32, callee_operand: i32, args_id: i32, dest_place: i32) -> i32:
    let fallback = self.place_local_tid(body, dest_place)
    let _ = bb
    let builtin_ret = self.call_builtin_ret_tid(body, callee_operand, args_id, dest_place)
    if builtin_ret != 0:
        return builtin_ret
    if callee_operand < 0 or callee_operand >= body.operand_kinds.len() as i32:
        return fallback

    let ok = body.operand_kinds.get(callee_operand as i64)
    let od = body.operand_d0.get(callee_operand as i64)

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
                return self.sema.sig_return_type(sig_idx)
        return fallback

    if ok == OperandKind.OK_CONSTANT:
        if od < 0 or od >= body.const_kinds.len() as i32:
            return fallback
        let ck = body.const_kinds.get(od as i64)
        if ck == ConstKind.CK_FN:
            let fn_sym = body.const_d0.get(od as i64)
            if fn_sym > 0:
                return self.call_return_tid_for_fn_sym(body, fn_sym, args_id, dest_place, fallback)
        let inferred = self.infer_direct_call_sym(body, args_id, dest_place)
        if inferred > 0:
            let sig_idx = self.sig_index_for_sym(inferred)
            if sig_idx >= 0:
                return self.sema.sig_return_type(sig_idx)
        return fallback

    fallback

fn CCodegen.call_callee_sig_return_tid(self: CCodegen, body: MirBody, callee_operand: i32) -> i32:
    if callee_operand < 0 or callee_operand >= body.operand_kinds.len() as i32:
        return 0
    if body.operand_kinds.get(callee_operand as i64) != OperandKind.OK_CONSTANT:
        return 0
    let const_id = body.operand_d0.get(callee_operand as i64)
    if const_id < 0 or const_id >= body.const_kinds.len() as i32:
        return 0
    if body.const_kinds.get(const_id as i64) != ConstKind.CK_FN:
        return 0
    let fn_sym = body.const_d0.get(const_id as i64)
    if fn_sym == 0:
        return 0
    let sig_idx = self.sig_index_for_sym(fn_sym)
    if sig_idx < 0:
        return 0
    self.sema.sig_return_type(sig_idx)

fn CCodegen.infer_local_tid_impl(self: CCodegen, body: MirBody, local_id: i32) -> i32:
    let declared = self.local_declared_tid(body, local_id)
    let declared_resolved = self.sema.resolve_alias(declared)
    let allow_container_receiver_infer =
        if self.is_void_tid(declared) == 0 and self.sema.get_type_kind(declared_resolved) != TypeKind.TY_ERR:
            0
        else:
            1
    var recv_hint = 0

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
                if kind == CcBuiltin.VEC_NEW or kind == CcBuiltin.VEC_PUSH or kind == CcBuiltin.VEC_GET or kind == CcBuiltin.VEC_LEN or kind == CcBuiltin.VEC_SET_I32 or kind == CcBuiltin.VEC_REMOVE or kind == CcBuiltin.VEC_CLEAR or kind == CcBuiltin.VEC_POP:
                    if recv_hint == 0:
                        recv_hint = CC_PSEUDO_TID_VEC
                if kind == CcBuiltin.MAP_NEW or kind == CcBuiltin.MAP_INSERT or kind == CcBuiltin.MAP_GET or kind == CcBuiltin.MAP_CONTAINS or kind == CcBuiltin.MAP_LEN or kind == CcBuiltin.MAP_REMOVE:
                    if recv_hint == 0:
                        recv_hint = self.sema.ty_i64 as i32
                if kind == CcBuiltin.OPT_IS_SOME or kind == CcBuiltin.OPT_UNWRAP:
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

        let start = body.bb_stmt_starts.get(bb as i64)
        let count = body.bb_stmt_counts.get(bb as i64)
        for si in 0..count:
            let stmt_id = start + si
            if body.stmt_kinds.get(stmt_id as i64) != StmtKind.Assign:
                continue
            let dst_place = body.stmt_d0.get(stmt_id as i64)
            if self.place_is_direct_local(body, dst_place, local_id) == 0:
                continue
            let rval_id = body.stmt_d1.get(stmt_id as i64)
            if rval_id < 0 or rval_id >= body.rval_kinds.len() as i32:
                continue
            let rk = body.rval_kinds.get(rval_id as i64)
            let d0 = body.rval_d0.get(rval_id as i64)
            let d1 = body.rval_d1.get(rval_id as i64)
            let d2 = body.rval_d2.get(rval_id as i64)
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

    if recv_hint != 0 and self.is_void_tid(recv_hint) == 0:
        return recv_hint
    0

fn CCodegen.infer_local_tid(self: CCodegen, body: MirBody, local_id: i32) -> i32:
    if local_id < 0 or local_id >= body.local_type_ids.len() as i32:
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
    for i in 0..self.active_local_ids.len() as i32:
        if self.active_local_body_fns.get(i as i64) != body.fn_sym:
            continue
        if self.active_local_ids.get(i as i64) == local_id:
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

fn CCodegen.callee_fn_type_from_operand(self: CCodegen, body: MirBody, callee_op: i32) -> i32:
    if callee_op < 0 or callee_op >= body.operand_kinds.len() as i32:
        return 0
    let ok = body.operand_kinds.get(callee_op as i64)
    if ok == OperandKind.OK_COPY or ok == OperandKind.OK_MOVE:
        return self.sema.callable_any_fn_type(self.operand_tid_no_infer(body, callee_op) as TypeId)
    0

fn CCodegen.operand_ref_target_tid(self: CCodegen, body: MirBody, operand_id: i32) -> i32:
    if operand_id < 0 or operand_id >= body.operand_kinds.len() as i32:
        return 0
    let ok = body.operand_kinds.get(operand_id as i64)
    if ok != OperandKind.OK_COPY and ok != OperandKind.OK_MOVE:
        return 0
    let place_id = body.operand_d0.get(operand_id as i64)
    let local_id = self.place_local_id(body, place_id)
    if local_id < 0:
        return 0
    if self.place_is_direct_local(body, place_id, local_id) == 0:
        return 0
    self.local_ref_target_tid(body, local_id)

fn CCodegen.operand_is_pointer_value(self: CCodegen, body: MirBody, operand_id: i32) -> i32:
    let tid = self.operand_tid(body, operand_id)
    if tid == 0:
        return 0
    let resolved = self.sema.resolve_alias(tid)
    let kind = self.sema.get_type_kind(resolved)
    if kind == TypeKind.TY_PTR or kind == TypeKind.TY_REF:
        return 1
    0

fn CCodegen.call_args_text(self: CCodegen, body: MirBody, args_id: i32, callee_operand: i32) -> str:
    if args_id < 0 or args_id >= body.call_arg_starts.len() as i32:
        return ""
    let start = body.call_arg_starts.get(args_id as i64)
    let count = body.call_arg_counts.get(args_id as i64)
    // Resolve callee signature to know which params expect pointers
    let callee_sig = self.callee_sig_from_operand(body, callee_operand)
    let callee_extern_name = self.callee_extern_name_from_operand(body, callee_operand)
    let callee_fn_tid = if callee_sig >= 0: 0 else: self.callee_fn_type_from_operand(body, callee_operand)
    let callee_param_count = if callee_sig >= 0: self.sema.sig_get_param_count(callee_sig) else if callee_fn_tid != 0: self.sema.get_type_d1(callee_fn_tid) else: 0
    var out = ""
    for i in 0..count:
        if i > 0:
            out = out ++ ", "
        let op_id = body.call_arg_operands.get((start + i) as i64)
        let arg_text = self.operand_text(body, op_id)
        if callee_extern_name == "strtod" and i == 1:
            out = out ++ "((char **)" ++ arg_text ++ ")"
            continue
        if self.call_param_expects_c_pointer(body, callee_operand, i) != 0:
            if arg_text == "0" or arg_text == "NULL":
                out = out ++ "NULL"
                continue
            if self.operand_is_pointer_value(body, op_id) != 0:
                out = out ++ arg_text
                continue
            out = out ++ "&(" ++ arg_text ++ ")"
            continue
        // If the argument is a struct value but the callee expects a pointer, emit &
        if i < callee_param_count:
            let p_tid = if callee_sig >= 0: self.sema.sig_param_type(callee_sig, i) else: self.sema.fn_type_param_type(callee_fn_tid, i)
            let p_resolved = self.sema.resolve_alias(p_tid)
            let p_tk = self.sema.get_type_kind(p_resolved)
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
                if arg_tk_for_ptr == TypeKind.TY_STR:
                    out = out ++ "((" ++ self.c_type(p_tid, 0) ++ ")((" ++ arg_text ++ ").ptr))"
                    continue
                if self.operand_ref_target_tid(body, op_id) != 0:
                    out = out ++ arg_text
                    continue
                let arg_tid = arg_tid_for_ptr
                let arg_resolved = arg_resolved_for_ptr
                let arg_tk = arg_tk_for_ptr
                if arg_tk != TypeKind.TY_PTR and arg_tk != TypeKind.TY_REF:
                    out = out ++ "&(" ++ arg_text ++ ")"
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

fn CCodegen.callee_extern_name_from_operand(self: CCodegen, body: MirBody, callee_op: i32) -> str:
    if callee_op < 0 or callee_op >= body.operand_kinds.len() as i32:
        return ""
    let ok = body.operand_kinds.get(callee_op as i64)
    if ok == OperandKind.OK_CONSTANT:
        let cd = body.operand_d0.get(callee_op as i64)
        if cd >= 0 and cd < body.const_kinds.len() as i32:
            let ck = body.const_kinds.get(cd as i64)
            if ck == ConstKind.CK_FN:
                let fn_sym = body.const_d0.get(cd as i64)
                return self.canonical_extern_name(cc_intern_resolve(self.intern, fn_sym))
    ""

fn CCodegen.callee_sig_from_operand(self: CCodegen, body: MirBody, callee_op: i32) -> i32:
    if callee_op < 0 or callee_op >= body.operand_kinds.len() as i32:
        return -1
    let ok = body.operand_kinds.get(callee_op as i64)
    if ok == OperandKind.OK_CONSTANT:
        let cd = body.operand_d0.get(callee_op as i64)
        if cd >= 0 and cd < body.const_kinds.len() as i32:
            let ck = body.const_kinds.get(cd as i64)
            if ck == ConstKind.CK_FN:
                let fn_sym = body.const_d0.get(cd as i64)
                return self.body_sig_index(fn_sym)
    -1

fn CCodegen.emit_len_result(self: CCodegen, body: MirBody, dest_place: i32, raw_expr: str, kind: CcBuiltin, has_ret: i32) -> str:
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
    if intrinsic == MirIntrinsic.VEC_NEW: return CcBuiltin.VEC_NEW
    if intrinsic == MirIntrinsic.VEC_PUSH: return CcBuiltin.VEC_PUSH
    if intrinsic == MirIntrinsic.VEC_GET: return CcBuiltin.VEC_GET
    if intrinsic == MirIntrinsic.VEC_LEN: return CcBuiltin.VEC_LEN
    if intrinsic == MirIntrinsic.VEC_LEN32: return CcBuiltin.VEC_LEN32
    if intrinsic == MirIntrinsic.VEC_LEN64: return CcBuiltin.VEC_LEN64
    if intrinsic == MirIntrinsic.VEC_ULEN32: return CcBuiltin.VEC_ULEN32
    if intrinsic == MirIntrinsic.VEC_SET: return CcBuiltin.VEC_SET_I32
    if intrinsic == MirIntrinsic.VEC_REMOVE: return CcBuiltin.VEC_REMOVE
    if intrinsic == MirIntrinsic.VEC_CLEAR: return CcBuiltin.VEC_CLEAR
    if intrinsic == MirIntrinsic.VEC_POP: return CcBuiltin.VEC_POP
    if intrinsic == MirIntrinsic.MAP_NEW: return CcBuiltin.MAP_NEW
    if intrinsic == MirIntrinsic.MAP_INSERT: return CcBuiltin.MAP_INSERT
    if intrinsic == MirIntrinsic.MAP_GET: return CcBuiltin.MAP_GET
    if intrinsic == MirIntrinsic.MAP_CONTAINS: return CcBuiltin.MAP_CONTAINS
    if intrinsic == MirIntrinsic.MAP_LEN: return CcBuiltin.MAP_LEN
    if intrinsic == MirIntrinsic.MAP_LEN32: return CcBuiltin.MAP_LEN32
    if intrinsic == MirIntrinsic.MAP_LEN64: return CcBuiltin.MAP_LEN64
    if intrinsic == MirIntrinsic.MAP_ULEN32: return CcBuiltin.MAP_ULEN32
    if intrinsic == MirIntrinsic.MAP_REMOVE: return CcBuiltin.MAP_REMOVE
    if intrinsic == MirIntrinsic.OPT_IS_SOME: return CcBuiltin.OPT_IS_SOME
    if intrinsic == MirIntrinsic.OPT_UNWRAP: return CcBuiltin.OPT_UNWRAP
    if intrinsic == MirIntrinsic.ATOMIC_LOAD: return CcBuiltin.ATOMIC_LOAD
    if intrinsic == MirIntrinsic.ATOMIC_STORE: return CcBuiltin.ATOMIC_STORE
    if intrinsic == MirIntrinsic.ATOMIC_SWAP: return CcBuiltin.ATOMIC_SWAP
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
    if intrinsic == MirIntrinsic.VECITER_NEXT: return CcBuiltin.VECITER_NEXT
    if intrinsic == MirIntrinsic.VEC_ITER: return CcBuiltin.VEC_ITER
    if intrinsic == MirIntrinsic.OPT_IS_NONE: return CcBuiltin.OPT_IS_NONE
    if intrinsic == MirIntrinsic.STR_SPLIT: return CcBuiltin.STR_SPLIT
    if intrinsic == MirIntrinsic.STR_TRIM: return CcBuiltin.STR_TRIM
    if intrinsic == MirIntrinsic.STR_TO_UPPER: return CcBuiltin.STR_TO_UPPER
    if intrinsic == MirIntrinsic.STR_TO_LOWER: return CcBuiltin.STR_TO_LOWER
    if intrinsic == MirIntrinsic.STR_REPLACE: return CcBuiltin.STR_REPLACE
    if intrinsic == MirIntrinsic.STR_INDEX_OF: return CcBuiltin.STR_INDEX_OF
    if intrinsic == MirIntrinsic.MAP_INCREMENT: return CcBuiltin.MAP_INCREMENT
    if intrinsic == MirIntrinsic.MAP_DECREMENT: return CcBuiltin.MAP_DECREMENT
    if intrinsic == MirIntrinsic.MAP_UPDATE: return CcBuiltin.MAP_UPDATE
    if intrinsic == MirIntrinsic.VEC_MAP: return CcBuiltin.VEC_MAP
    if intrinsic == MirIntrinsic.VEC_FILTER: return CcBuiltin.VEC_FILTER
    if intrinsic == MirIntrinsic.VEC_FOLD: return CcBuiltin.VEC_FOLD
    if intrinsic == MirIntrinsic.ITER_MAP or intrinsic == MirIntrinsic.ITER_FILTER or intrinsic == MirIntrinsic.ITER_TAKE or intrinsic == MirIntrinsic.ITER_ZIP or intrinsic == MirIntrinsic.ITER_FLAT_MAP:
        return CcBuiltin.GENERIC_CALL
    if intrinsic == MirIntrinsic.ITER_FOLD or intrinsic == MirIntrinsic.ITER_REDUCE or intrinsic == MirIntrinsic.ITER_SUM or intrinsic == MirIntrinsic.ITER_COUNT or intrinsic == MirIntrinsic.ITER_COLLECT_VEC or intrinsic == MirIntrinsic.ITER_PARTITION:
        return CcBuiltin.GENERIC_CALL
    if intrinsic == MirIntrinsic.MAPITER_NEXT or intrinsic == MirIntrinsic.FILTERITER_NEXT or intrinsic == MirIntrinsic.TAKEITER_NEXT or intrinsic == MirIntrinsic.ZIPITER_NEXT or intrinsic == MirIntrinsic.FLATMAPITER_NEXT:
        return CcBuiltin.GENERIC_CALL
    if intrinsic == MirIntrinsic.VEC_CONTAINS: return CcBuiltin.VEC_CONTAINS
    if intrinsic == MirIntrinsic.STR_REPEAT: return CcBuiltin.STR_REPEAT
    if intrinsic == MirIntrinsic.ARR_LEN: return CcBuiltin.ARR_LEN
    if intrinsic == MirIntrinsic.ARR_LEN32: return CcBuiltin.ARR_LEN32
    if intrinsic == MirIntrinsic.ARR_LEN64: return CcBuiltin.ARR_LEN64
    if intrinsic == MirIntrinsic.ARR_ULEN32: return CcBuiltin.ARR_ULEN32
    if intrinsic == MirIntrinsic.GENERIC_CALL: return CcBuiltin.GENERIC_CALL
    if intrinsic == MirIntrinsic.VEC_JOIN: return CcBuiltin.VEC_JOIN
    if intrinsic == MirIntrinsic.DYN_VTABLE_CMP: return CcBuiltin.DYN_VTABLE_CMP
    if intrinsic == MirIntrinsic.DYN_DOWNCAST: return CcBuiltin.DYN_DOWNCAST
    if intrinsic == MirIntrinsic.DYN_CALL: return CcBuiltin.DYN_CALL
    if intrinsic == MirIntrinsic.OPT_FILTER: return CcBuiltin.OPT_FILTER
    if intrinsic == MirIntrinsic.ROTATE_LEFT: return CcBuiltin.ROTATE_LEFT
    if intrinsic == MirIntrinsic.ROTATE_RIGHT: return CcBuiltin.ROTATE_RIGHT
    if intrinsic == MirIntrinsic.VEC_WITH_CAPACITY: return CcBuiltin.VEC_WITH_CAPACITY
    if intrinsic == MirIntrinsic.FMT_TO_STR: return CcBuiltin.FMT_TO_STR
    if intrinsic == MirIntrinsic.FMT_DEBUG_STR: return CcBuiltin.FMT_DEBUG_STR
    if intrinsic == MirIntrinsic.FMT_DEBUG: return CcBuiltin.FMT_DEBUG
    if intrinsic == MirIntrinsic.FMT_SPEC: return CcBuiltin.FMT_SPEC
    if intrinsic == MirIntrinsic.FMT_BUF_NEW: return CcBuiltin.FMT_BUF_NEW
    if intrinsic == MirIntrinsic.FMT_BUF_WRITE_STR: return CcBuiltin.FMT_BUF_WRITE_STR
    if intrinsic == MirIntrinsic.FMT_BUF_WRITE_FMT: return CcBuiltin.FMT_BUF_WRITE_FMT
    if intrinsic == MirIntrinsic.FMT_BUF_FINISH: return CcBuiltin.FMT_BUF_FINISH
    if intrinsic == MirIntrinsic.VEC_SLOT: return CcBuiltin.VEC_SLOT
    if intrinsic == MirIntrinsic.VEC_GET_DISJOINT: return CcBuiltin.VEC_GET_DISJOINT
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
    CcBuiltin.NONE

fn CCodegen.emit_builtin_vec_core_call_term(self: CCodegen, body: MirBody, kind: CcBuiltin, args_id: i32, dest_place: i32, next_bb: i32, argc: i32, ret_tid: i32, has_ret: i32) -> str:
    if kind == CcBuiltin.DYN_CALL:
        self.fail("C backend is LLVM-only for dyn trait method dispatch by design (#301); compile this program with the LLVM backend")
        return "    abort();"

    if kind == CcBuiltin.MULTI_INDEX:
        self.fail("C backend is LLVM-only for MultiIndex intrinsics by design (#301); compile this program with the LLVM backend")
        return "    abort();"

    if kind == CcBuiltin.VEC_NEW:
        var out = ""
        if has_ret != 0:
            let elem_size = self.vec_new_elem_size_text(body, dest_place)
            out = out ++ "    " ++ self.place_text(body, dest_place) ++ " = (with_vec)" ++ cc_lbrace() ++ " .ptr = NULL, .len = 0, .cap = 0, .elem_size = " ++ elem_size ++ " " ++ cc_rbrace() ++ ";\n"
        else:
            out = out ++ "    (void)0;\n"
        out = out ++ f"    goto bb{next_bb};"
        return out

    if kind == CcBuiltin.VEC_SLOT:
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
    // VecRange (and their *_LEN32/64/ULEN32 variants, which route here) are
    // intentionally unsupported in the C backend.
    if kind == CcBuiltin.VEC_GET_DISJOINT:
        self.fail("C backend is LLVM-only for Vec.get_disjoint by design (#301); compile this program with the LLVM backend")
        return "    abort();"

    if kind == CcBuiltin.SLOTMAP:
        self.fail("C backend is LLVM-only for SlotMap intrinsics by design (#301); compile this program with the LLVM backend")
        return "    abort();"

    if kind == CcBuiltin.VECRANGE:
        self.fail("C backend is LLVM-only for VecRange intrinsics by design (#301); compile this program with the LLVM backend")
        return "    abort();"

    if kind == CcBuiltin.VECSLOT_GET:
        if argc < 1:
            self.fail("VecSlot.get expects one argument")
            return "    abort();"
        let recv = self.operand_text(body, self.call_arg_operand(body, args_id, 0))
        var elem_tid = ret_tid
        if elem_tid == 0 or self.is_void_tid(elem_tid) != 0:
            elem_tid = self.vecslot_element_tid(self.operand_tid(body, self.call_arg_operand(body, args_id, 0)))
        if elem_tid == 0 or self.is_void_tid(elem_tid) != 0:
            elem_tid = self.sema.ty_i64 as i32
        let elem_ty = self.c_type(elem_tid, 0)
        var out = ""
        if has_ret != 0:
            out = out ++ "    " ++ self.place_text(body, dest_place) ++ " = ((" ++ elem_ty ++ "*)(intptr_t)((" ++ recv ++ ").data_ptr))[(" ++ recv ++ ").index];\n"
        else:
            out = out ++ "    (void)((" ++ elem_ty ++ "*)(intptr_t)((" ++ recv ++ ").data_ptr))[(" ++ recv ++ ").index];\n"
        out = out ++ f"    goto bb{next_bb};"
        return out

    if kind == CcBuiltin.VECSLOT_SET:
        if argc < 2:
            self.fail("VecSlot.set expects two arguments")
            return "    abort();"
        let recv = self.operand_text(body, self.call_arg_operand(body, args_id, 0))
        let val_operand = self.call_arg_operand(body, args_id, 1)
        let val = self.operand_text(body, val_operand)
        var elem_tid = self.operand_tid(body, val_operand)
        if elem_tid == 0 or self.is_void_tid(elem_tid) != 0:
            elem_tid = self.vecslot_element_tid(self.operand_tid(body, self.call_arg_operand(body, args_id, 0)))
        if elem_tid == 0 or self.is_void_tid(elem_tid) != 0:
            elem_tid = self.sema.ty_i64 as i32
        let elem_ty = self.c_type(elem_tid, 0)
        var out = "    ((" ++ elem_ty ++ "*)(intptr_t)((" ++ recv ++ ").data_ptr))[(" ++ recv ++ ").index] = " ++ val ++ ";\n"
        out = out ++ f"    goto bb{next_bb};"
        return out

    if kind == CcBuiltin.VEC_PUSH:
        if argc < 2:
            self.fail("vec.push expects two arguments")
            return "    abort();"
        let recv_ptr = self.vec_recv_ptr_text(body, args_id)
        let elem_operand = self.call_arg_operand(body, args_id, 1)
        let elem_text = self.operand_text(body, elem_operand)
        var elem_tid = self.operand_tid(body, elem_operand)
        if elem_tid == 0 or self.is_void_tid(elem_tid) != 0:
            elem_tid = self.sema.ty_i64 as i32
        let elem_ty = self.c_type(elem_tid, 0)
        var out = "    " ++ cc_lbrace() ++ " " ++ elem_ty ++ " __with_tmp = " ++ elem_text ++ "; with_vec_push(" ++ recv_ptr ++ ", &__with_tmp); " ++ cc_rbrace() ++ "\n"
        if has_ret != 0:
            out = out ++ "    " ++ self.place_text(body, dest_place) ++ " = *(" ++ recv_ptr ++ ");\n"
        out = out ++ f"    goto bb{next_bb};"
        return out

    if kind == CcBuiltin.VEC_GET:
        if argc < 2:
            self.fail("vec.get expects two arguments")
            return "    abort();"
        let recv_ptr = self.vec_recv_ptr_text(body, args_id)
        let idx = self.operand_text(body, self.call_arg_operand(body, args_id, 1))
        let dst = self.place_text(body, dest_place)
        var out = "    memset(&(" ++ dst ++ "), 0, sizeof(" ++ dst ++ "));\n"
        out = out ++ "    if ((int64_t)(" ++ idx ++ ") >= 0 && (int64_t)(" ++ idx ++ ") < with_vec_len(" ++ recv_ptr ++ ")) " ++ cc_lbrace() ++ " memcpy(&(" ++ dst ++ "), with_vec_get_ptr(" ++ recv_ptr ++ ", (int64_t)(" ++ idx ++ ")), sizeof(" ++ dst ++ ")); " ++ cc_rbrace() ++ "\n"
        out = out ++ f"    goto bb{next_bb};"
        return out

    if cc_builtin_is_vec_len(kind):
        if argc < 1:
            self.fail("vec.len expects one argument")
            return "    abort();"
        let recv_ptr = self.vec_recv_ptr_text(body, args_id)
        var out = self.emit_len_result(body, dest_place, "with_vec_len(" ++ recv_ptr ++ ")", kind, has_ret)
        out = out ++ f"    goto bb{next_bb};"
        return out

    if kind == CcBuiltin.VEC_SET_I32:
        if argc < 3:
            self.fail("vec.set_i32 expects three arguments")
            return "    abort();"
        let recv_ptr = self.vec_recv_ptr_text(body, args_id)
        let idx = self.operand_text(body, self.call_arg_operand(body, args_id, 1))
        let val = self.operand_text(body, self.call_arg_operand(body, args_id, 2))
        var out = "    with_vec_set_i32(" ++ recv_ptr ++ ", (int64_t)(" ++ idx ++ "), (int32_t)(" ++ val ++ "));\n"
        out = out ++ f"    goto bb{next_bb};"
        return out

    if kind == CcBuiltin.VEC_REMOVE:
        if argc < 2:
            self.fail("vec.remove expects two arguments")
            return "    abort();"
        let recv_ptr = self.vec_recv_ptr_text(body, args_id)
        let idx = self.operand_text(body, self.call_arg_operand(body, args_id, 1))
        var out = "    with_vec_remove(" ++ recv_ptr ++ ", (int64_t)(" ++ idx ++ "));\n"
        out = out ++ f"    goto bb{next_bb};"
        return out

    if kind == CcBuiltin.VEC_CLEAR:
        if argc < 1:
            self.fail("vec.clear expects one argument")
            return "    abort();"
        let recv_ptr = self.vec_recv_ptr_text(body, args_id)
        var out = "    with_vec_clear(" ++ recv_ptr ++ ");\n"
        out = out ++ f"    goto bb{next_bb};"
        return out

    if kind == CcBuiltin.VEC_POP:
        if argc < 1:
            self.fail("vec.pop expects one argument")
            return "    abort();"
        let recv_ptr = self.vec_recv_ptr_text(body, args_id)
        var out = "    " ++ cc_lbrace() ++ " int64_t __with_n = with_vec_len(" ++ recv_ptr ++ ");\n"
        if has_ret != 0:
            let dst = self.place_text(body, dest_place)
            out = out ++ "        memset(&(" ++ dst ++ "), 0, sizeof(" ++ dst ++ "));\n"
            out = out ++ "        if (__with_n > 0) " ++ cc_lbrace() ++ " memcpy(&(" ++ dst ++ "), with_vec_get_ptr(" ++ recv_ptr ++ ", __with_n - 1), sizeof(" ++ dst ++ ")); with_vec_remove(" ++ recv_ptr ++ ", __with_n - 1); " ++ cc_rbrace() ++ "\n"
        else:
            out = out ++ "        if (__with_n > 0) " ++ cc_lbrace() ++ " with_vec_remove(" ++ recv_ptr ++ ", __with_n - 1); " ++ cc_rbrace() ++ "\n"
        out = out ++ "    " ++ cc_rbrace() ++ "\n"
        out = out ++ f"    goto bb{next_bb};"
        return out

    ""

fn CCodegen.emit_builtin_map_call_term(self: CCodegen, body: MirBody, kind: CcBuiltin, args_id: i32, dest_place: i32, next_bb: i32, argc: i32, ret_tid: i32, has_ret: i32) -> str:
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
            out = out ++ "    " ++ self.place_text(body, dest_place) ++ " = (int64_t)(intptr_t)with_hashmap_new(sizeof(" ++ key_ty ++ "), sizeof(" ++ val_ty ++ "));\n"
        else:
            out = out ++ "    (void)0;\n"
        out = out ++ f"    goto bb{next_bb};"
        return out

    if kind == CcBuiltin.MAP_INSERT:
        if argc < 3:
            self.fail("map.insert expects three arguments")
            return "    abort();"
        let recv = self.map_recv_text(body, args_id)
        let key_operand = self.call_arg_operand(body, args_id, 1)
        let val_operand = self.call_arg_operand(body, args_id, 2)
        let key_text = self.operand_text(body, key_operand)
        let val_text = self.operand_text(body, val_operand)
        var key_tid = self.operand_tid(body, key_operand)
        if key_tid == 0 or self.is_void_tid(key_tid) != 0:
            key_tid = self.sema.ty_i64 as i32
        var val_tid = self.operand_tid(body, val_operand)
        if val_tid == 0 or self.is_void_tid(val_tid) != 0:
            val_tid = self.sema.ty_i64 as i32
        let key_ty = self.c_type(key_tid, 0)
        let val_ty = self.c_type(val_tid, 0)
        let is_str_key = if self.sema.get_type_kind(self.sema.resolve_alias(key_tid as TypeId)) == TypeKind.TY_STR: "1" else: "0"
        var out = "    " ++ cc_lbrace() ++ " " ++ key_ty ++ " __with_k = " ++ key_text ++ "; " ++ val_ty ++ " __with_v = " ++ val_text ++ ";"
        out = out ++ " if ((" ++ recv ++ ") == 0) " ++ cc_lbrace() ++ " " ++ recv ++ " = (int64_t)(intptr_t)with_hashmap_new(sizeof(__with_k), sizeof(__with_v)); " ++ cc_rbrace()
        out = out ++ " with_hashmap_insert((void*)(intptr_t)(" ++ recv ++ "), &__with_k, &__with_v, " ++ is_str_key ++ "); " ++ cc_rbrace() ++ "\n"
        out = out ++ f"    goto bb{next_bb};"
        return out

    if kind == CcBuiltin.MAP_CONTAINS:
        if argc < 2:
            self.fail("map.contains expects two arguments")
            return "    abort();"
        let recv = self.map_recv_text(body, args_id)
        let key_operand = self.call_arg_operand(body, args_id, 1)
        let key_text = self.operand_text(body, key_operand)
        var key_tid = self.operand_tid(body, key_operand)
        if key_tid == 0 or self.is_void_tid(key_tid) != 0:
            key_tid = self.sema.ty_i64 as i32
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
        let recv_is_hashmap = if cc_str_contains(owner, "HashMap") != 0: 1 else: 0
        let key_operand = self.call_arg_operand(body, args_id, 1)
        let key_text = self.operand_text(body, key_operand)
        var key_tid = self.operand_tid(body, key_operand)
        if key_tid == 0 or self.is_void_tid(key_tid) != 0:
            key_tid = self.sema.ty_i64 as i32
        let key_ty = self.c_type(key_tid, 0)
        let is_str_key = if self.sema.get_type_kind(self.sema.resolve_alias(key_tid as TypeId)) == TypeKind.TY_STR: "1" else: "0"
        var out = f"    {cc_lbrace()} {key_ty} __with_k = {key_text}; "
        if recv_is_hashmap != 0:
            let dst = self.place_text(body, dest_place)
            out = out ++ "int64_t __with_v = 0;"
            out = out ++ " int64_t __with_r = 0;"
            out = out ++ " if ((" ++ recv ++ ") != 0 && with_hashmap_remove((void*)(intptr_t)(" ++ recv ++ "), &__with_k, &__with_v, " ++ is_str_key ++ ") != 0) "
            out = out ++ cc_lbrace() ++ " __with_r = (__with_v + 1); " ++ cc_rbrace()
            out = out ++ " memcpy(&(" ++ dst ++ "), &__with_r, sizeof(__with_r) < sizeof(" ++ dst ++ ") ? sizeof(__with_r) : sizeof(" ++ dst ++ ")); " ++ cc_rbrace() ++ "\n"
        else:
            if has_ret != 0:
                out = out ++ self.place_text(body, dest_place) ++ " = "
            out = out ++ "(((" ++ recv ++ ") != 0) && (with_hashmap_remove((void*)(intptr_t)(" ++ recv ++ "), &__with_k, (void*)0, " ++ is_str_key ++ ") != 0)); " ++ cc_rbrace() ++ "\n"
        out = out ++ f"    goto bb{next_bb};"
        return out

    if kind == CcBuiltin.MAP_GET:
        if argc < 2:
            self.fail("map.get expects two arguments")
            return "    abort();"
        let recv = self.map_recv_text(body, args_id)
        let key_operand = self.call_arg_operand(body, args_id, 1)
        let key_text = self.operand_text(body, key_operand)
        var key_tid = self.operand_tid(body, key_operand)
        if key_tid == 0 or self.is_void_tid(key_tid) != 0:
            key_tid = self.sema.ty_i64 as i32
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
            let payload_tid = self.sema.type_reflection_variant_payload_type(dst_tid, some_variant, 0)
            let payload_c = self.c_type(payload_tid, 0)
            var out = "    " ++ cc_lbrace() ++ " " ++ key_ty ++ " __with_k = " ++ key_text ++ "; " ++ payload_c ++ " __with_v = " ++ self.zero_value_text(payload_tid) ++ ";"
            out = out ++ " if ((" ++ recv ++ ") != 0 && with_hashmap_get((void*)(intptr_t)(" ++ recv ++ "), &__with_k, &__with_v, " ++ is_str_key ++ ") != 0) "
            out = out ++ cc_lbrace() ++ " " ++ dst ++ " = " ++ self.payload_enum_literal(dst_tid, some_variant, "__with_v") ++ "; " ++ cc_rbrace()
            out = out ++ " else " ++ cc_lbrace() ++ " " ++ dst ++ " = " ++ self.payload_enum_literal(dst_tid, none_variant, "") ++ "; " ++ cc_rbrace()
            out = out ++ " " ++ cc_rbrace() ++ "\n"
            out = out ++ f"    goto bb{next_bb};"
            return out
        // Legacy encoded Option path for pointer/integer option lowering.
        var out = "    " ++ cc_lbrace() ++ " " ++ key_ty ++ " __with_k = " ++ key_text ++ "; int64_t __with_v = 0;"
        out = out ++ " int64_t __with_r = 0;"
        out = out ++ " if ((" ++ recv ++ ") != 0 && with_hashmap_get((void*)(intptr_t)(" ++ recv ++ "), &__with_k, &__with_v, " ++ is_str_key ++ ") != 0) "
        out = out ++ cc_lbrace() ++ " __with_r = (__with_v + 1); " ++ cc_rbrace()
        out = out ++ " memcpy(&(" ++ dst ++ "), &__with_r, sizeof(__with_r) < sizeof(" ++ dst ++ ") ? sizeof(__with_r) : sizeof(" ++ dst ++ ")); " ++ cc_rbrace() ++ "\n"
        out = out ++ f"    goto bb{next_bb};"
        return out

    ""

fn CCodegen.emit_builtin_option_call_term(self: CCodegen, body: MirBody, kind: CcBuiltin, args_id: i32, dest_place: i32, next_bb: i32, argc: i32, ret_tid: i32, has_ret: i32) -> str:
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
            test_text = "((" ++ opt_text ++ ").tag == " ++ f"{tag}" ++ ")"
        var out = ""
        if has_ret != 0:
            out = out ++ "    " ++ self.place_text(body, dest_place) ++ " = " ++ test_text ++ ";\n"
        else:
            out = out ++ "    (void)" ++ test_text ++ ";\n"
        out = out ++ f"    goto bb{next_bb};"
        return out

    if kind == CcBuiltin.OPT_UNWRAP:
        if argc < 1:
            self.fail("Option.unwrap expects one argument")
            return "    abort();"
        let opt_operand = self.call_arg_operand(body, args_id, 0)
        let opt_text = self.operand_text(body, opt_operand)
        let opt_tid = self.operand_tid(body, opt_operand)
        let dst = self.place_text(body, dest_place)
        if self.type_is_payload_enum(opt_tid) != 0:
            let some_variant = self.payload_enum_single_payload_variant(opt_tid)
            if some_variant < 0:
                self.fail("Option.unwrap expects an enum with one payload-bearing variant")
                return "    abort();"
            var out = "    " ++ dst ++ " = " ++ opt_text ++ "." ++ self.payload_enum_variant_field(some_variant) ++ ";\n"
            out = out ++ f"    goto bb{next_bb};"
            return out
        // Option unwrap: value = encoded - 1. Use memcpy to handle with_str/with_vec destinations.
        var out = "    " ++ cc_lbrace() ++ " int64_t __uw = ((" ++ opt_text ++ ") - 1); memcpy(&(" ++ dst ++ "), &__uw, sizeof(" ++ dst ++ ") < sizeof(__uw) ? sizeof(" ++ dst ++ ") : sizeof(__uw)); " ++ cc_rbrace() ++ "\n"
        out = out ++ f"    goto bb{next_bb};"
        return out

    ""

fn CCodegen.emit_builtin_atomic_call_term(self: CCodegen, body: MirBody, kind: CcBuiltin, args_id: i32, dest_place: i32, next_bb: i32, argc: i32, ret_tid: i32, has_ret: i32) -> str:
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

    ""

fn CCodegen.emit_builtin_string_call_term(self: CCodegen, body: MirBody, kind: CcBuiltin, args_id: i32, dest_place: i32, next_bb: i32, argc: i32, ret_tid: i32, has_ret: i32) -> str:
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
            out = out ++ "    " ++ self.place_text(body, dest_place) ++ " = with_str_byte_at(" ++ recv ++ ", (int64_t)(" ++ idx ++ "));\n"
        else:
            out = out ++ "    (void)with_str_byte_at(" ++ recv ++ ", (int64_t)(" ++ idx ++ "));\n"
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
            out = out ++ "    " ++ self.place_text(body, dest_place) ++ " = with_str_slice(" ++ recv ++ ", (int64_t)(" ++ start ++ "), (int64_t)(" ++ end_ ++ "));\n"
        else:
            out = out ++ "    (void)with_str_slice(" ++ recv ++ ", (int64_t)(" ++ start ++ "), (int64_t)(" ++ end_ ++ "));\n"
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
            out = out ++ "    " ++ self.place_text(body, dest_place) ++ " = with_str_contains(" ++ recv ++ ", " ++ needle ++ ");\n"
        else:
            out = out ++ "    (void)with_str_contains(" ++ recv ++ ", " ++ needle ++ ");\n"
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
            out = out ++ "    " ++ self.place_text(body, dest_place) ++ " = with_str_contains_char(" ++ recv ++ ", (int32_t)(" ++ ch ++ "));\n"
        else:
            out = out ++ "    (void)with_str_contains_char(" ++ recv ++ ", (int32_t)(" ++ ch ++ "));\n"
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
            out = out ++ "    " ++ self.place_text(body, dest_place) ++ " = with_str_starts_with(" ++ recv ++ ", " ++ prefix ++ ");\n"
        else:
            out = out ++ "    (void)with_str_starts_with(" ++ recv ++ ", " ++ prefix ++ ");\n"
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
            out = out ++ "    " ++ self.place_text(body, dest_place) ++ " = with_str_ends_with(" ++ recv ++ ", " ++ suffix ++ ");\n"
        else:
            out = out ++ "    (void)with_str_ends_with(" ++ recv ++ ", " ++ suffix ++ ");\n"
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
            out = out ++ "    " ++ self.place_text(body, dest_place) ++ " = with_str_index_of(" ++ recv ++ ", " ++ needle ++ ");\n"
        else:
            out = out ++ "    (void)with_str_index_of(" ++ recv ++ ", " ++ needle ++ ");\n"
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
            out = out ++ "    " ++ self.place_text(body, dest_place) ++ " = with_str_index_of(" ++ recv ++ ", " ++ needle ++ ");\n"
        else:
            out = out ++ "    (void)with_str_index_of(" ++ recv ++ ", " ++ needle ++ ");\n"
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
            out = out ++ "    with_str_split_vec(&(" ++ self.place_text(body, dest_place) ++ "), " ++ recv ++ ", " ++ delim ++ ");\n"
        else:
            out = out ++ "    " ++ cc_lbrace() ++ " with_vec __with_tmp_split; with_str_split_vec(&__with_tmp_split, " ++ recv ++ ", " ++ delim ++ "); " ++ cc_rbrace() ++ "\n"
        out = out ++ f"    goto bb{next_bb};"
        return out

    if kind == CcBuiltin.STR_TRIM:
        if argc < 1:
            self.fail("str.trim expects one argument")
            return "    abort();"
        let recv = self.operand_text(body, self.call_arg_operand(body, args_id, 0))
        var out = ""
        if has_ret != 0:
            out = out ++ "    " ++ self.place_text(body, dest_place) ++ " = with_str_trim(" ++ recv ++ ");\n"
        else:
            out = out ++ "    (void)with_str_trim(" ++ recv ++ ");\n"
        out = out ++ f"    goto bb{next_bb};"
        return out

    if kind == CcBuiltin.STR_TO_UPPER:
        if argc < 1:
            self.fail("str.to_upper expects one argument")
            return "    abort();"
        let recv = self.operand_text(body, self.call_arg_operand(body, args_id, 0))
        var out = ""
        if has_ret != 0:
            out = out ++ "    " ++ self.place_text(body, dest_place) ++ " = with_str_to_upper(" ++ recv ++ ");\n"
        else:
            out = out ++ "    (void)with_str_to_upper(" ++ recv ++ ");\n"
        out = out ++ f"    goto bb{next_bb};"
        return out

    if kind == CcBuiltin.STR_TO_LOWER:
        if argc < 1:
            self.fail("str.to_lower expects one argument")
            return "    abort();"
        let recv = self.operand_text(body, self.call_arg_operand(body, args_id, 0))
        var out = ""
        if has_ret != 0:
            out = out ++ "    " ++ self.place_text(body, dest_place) ++ " = with_str_to_lower(" ++ recv ++ ");\n"
        else:
            out = out ++ "    (void)with_str_to_lower(" ++ recv ++ ");\n"
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
            out = out ++ "    " ++ self.place_text(body, dest_place) ++ " = with_str_replace(" ++ recv ++ ", " ++ old_s ++ ", " ++ new_s ++ ");\n"
        else:
            out = out ++ "    (void)with_str_replace(" ++ recv ++ ", " ++ old_s ++ ", " ++ new_s ++ ");\n"
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
            out = out ++ "    " ++ self.place_text(body, dest_place) ++ " = with_str_repeat(" ++ recv ++ ", (int64_t)(" ++ n ++ "));\n"
        else:
            out = out ++ "    (void)with_str_repeat(" ++ recv ++ ", (int64_t)(" ++ n ++ "));\n"
        out = out ++ f"    goto bb{next_bb};"
        return out

    ""

fn CCodegen.emit_builtin_option_string_call_term(self: CCodegen, body: MirBody, kind: CcBuiltin, args_id: i32, dest_place: i32, next_bb: i32, argc: i32, ret_tid: i32, has_ret: i32) -> str:
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

fn CCodegen.emit_builtin_vec_extra_call_term(self: CCodegen, body: MirBody, kind: CcBuiltin, args_id: i32, dest_place: i32, next_bb: i32, argc: i32, ret_tid: i32, has_ret: i32) -> str:
    if kind == CcBuiltin.MAP_CLEAR:
        if argc < 1:
            self.fail("map.clear expects one argument")
            return "    abort();"
        let recv = self.map_recv_text(body, args_id)
        var out = "    if ((" ++ recv ++ ") != 0) with_hashmap_clear((void*)(intptr_t)(" ++ recv ++ "));\n"
        out = out ++ f"    goto bb{next_bb};"
        return out

    if kind == CcBuiltin.MAP_INCREMENT or kind == CcBuiltin.MAP_DECREMENT:
        if argc < 2:
            self.fail("map increment/decrement expects two arguments")
            return "    abort();"
        let recv = self.map_recv_text(body, args_id)
        let key_operand = self.call_arg_operand(body, args_id, 1)
        let key_text = self.operand_text(body, key_operand)
        var key_tid = self.operand_tid(body, key_operand)
        if key_tid == 0 or self.is_void_tid(key_tid) != 0:
            key_tid = self.sema.ty_i64 as i32
        let key_ty = self.c_type(key_tid, 0)
        let is_str_key = if self.sema.get_type_kind(self.sema.resolve_alias(key_tid as TypeId)) == TypeKind.TY_STR: "1" else: "0"
        let fn_name = if kind == CcBuiltin.MAP_INCREMENT: "with_hashmap_increment" else: "with_hashmap_decrement"
        var out = "    " ++ cc_lbrace() ++ " " ++ key_ty ++ " __with_k = " ++ key_text ++ "; " ++ fn_name ++ "((void*)(intptr_t)(" ++ recv ++ "), &__with_k, " ++ is_str_key ++ "); " ++ cc_rbrace() ++ "\n"
        out = out ++ f"    goto bb{next_bb};"
        return out

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
            test_text = "((" ++ opt_text ++ ").tag != " ++ f"{tag}" ++ ")"
        var out = ""
        if has_ret != 0:
            out = out ++ "    " ++ self.place_text(body, dest_place) ++ " = " ++ test_text ++ ";\n"
        else:
            out = out ++ "    (void)" ++ test_text ++ ";\n"
        out = out ++ f"    goto bb{next_bb};"
        return out

    if kind == CcBuiltin.VEC_ITER:
        // Vec is its own iterator in C — return the vec as the iterator value
        if argc < 1:
            self.fail("vec.iter expects one argument")
            return "    abort();"
        let recv = self.operand_text(body, self.call_arg_operand(body, args_id, 0))
        var out = ""
        if has_ret != 0:
            let dst = self.place_text(body, dest_place)
            out = out ++ "    " ++ dst ++ " = " ++ recv ++ ";\n"
        else:
            out = out ++ "    (void)0;\n"
        out = out ++ f"    goto bb{next_bb};"
        return out

    if kind == CcBuiltin.VECITER_NEXT:
        // Advance iterator: returns Option (0 = None, value+1 = Some(value))
        // args: recv = {vec, index_i64} — treat as vec + separate index local
        if argc < 1:
            self.fail("veciter.next expects one argument")
            return "    abort();"
        let recv_ptr = self.vec_recv_ptr_text(body, args_id)
        let dst = self.place_text(body, dest_place)
        var out = "    " ++ cc_lbrace() ++ " int64_t __with_n = with_vec_len(" ++ recv_ptr ++ "); int64_t __with_i = 0;"
        out = out ++ " if (__with_i < __with_n) " ++ cc_lbrace()
        out = out ++ " int64_t __with_elem = 0; memcpy(&__with_elem, with_vec_get_ptr(" ++ recv_ptr ++ ", __with_i), sizeof(int64_t));"
        out = out ++ " " ++ dst ++ " = __with_elem + 1; " ++ cc_rbrace()
        out = out ++ " else " ++ cc_lbrace() ++ " " ++ dst ++ " = 0; " ++ cc_rbrace()
        out = out ++ " " ++ cc_rbrace() ++ "\n"
        out = out ++ f"    goto bb{next_bb};"
        return out

    if kind == CcBuiltin.VEC_CONTAINS:
        if argc < 2:
            self.fail("vec.contains expects two arguments")
            return "    abort();"
        let recv_ptr = self.vec_recv_ptr_text(body, args_id)
        let elem_operand = self.call_arg_operand(body, args_id, 1)
        let elem_text = self.operand_text(body, elem_operand)
        var elem_tid = self.operand_tid(body, elem_operand)
        if elem_tid == 0 or self.is_void_tid(elem_tid) != 0:
            elem_tid = self.sema.ty_i64 as i32
        let elem_ty = self.c_type(elem_tid, 0)
        let dst = self.place_text(body, dest_place)
        var out = "    " ++ cc_lbrace() ++ " int64_t __with_found = 0; int64_t __with_ci; int64_t __with_cn = with_vec_len(" ++ recv_ptr ++ "); " ++ elem_ty ++ " __with_needle = " ++ elem_text ++ ";"
        out = out ++ " for (__with_ci = 0; __with_ci < __with_cn; __with_ci++) " ++ cc_lbrace()
        out = out ++ " " ++ elem_ty ++ " __with_cur; memcpy(&__with_cur, with_vec_get_ptr(" ++ recv_ptr ++ ", __with_ci), sizeof(" ++ elem_ty ++ "));"
        out = out ++ " if (memcmp(&__with_cur, &__with_needle, sizeof(" ++ elem_ty ++ ")) == 0) " ++ cc_lbrace() ++ " __with_found = 1; break; " ++ cc_rbrace()
        out = out ++ " " ++ cc_rbrace()
        if has_ret != 0:
            out = out ++ " " ++ dst ++ " = __with_found;"
        out = out ++ " " ++ cc_rbrace() ++ "\n"
        out = out ++ f"    goto bb{next_bb};"
        return out

    if kind == CcBuiltin.VEC_JOIN:
        if argc < 2:
            self.fail("vec.join expects two arguments")
            return "    abort();"
        let recv_ptr = self.vec_recv_ptr_text(body, args_id)
        let sep = self.operand_text(body, self.call_arg_operand(body, args_id, 1))
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
        let recv = self.operand_text(body, self.call_arg_operand(body, args_id, 0))
        let raw = "(int64_t)(sizeof(" ++ recv ++ ") / sizeof((" ++ recv ++ ")[0]))"
        var out = self.emit_len_result(body, dest_place, raw, kind, has_ret)
        out = out ++ f"    goto bb{next_bb};"
        return out

    if kind == CcBuiltin.VEC_WITH_CAPACITY:
        var out = ""
        if has_ret != 0:
            let elem_size = self.vec_new_elem_size_text(body, dest_place)
            let cap_operand = if argc > 0: self.call_arg_operand(body, args_id, 0) else: -1
            let cap_text = if cap_operand >= 0: self.operand_text(body, cap_operand) else: "0"
            out = out ++ "    with_vec_new_with_capacity_out(&(" ++ self.place_text(body, dest_place) ++ "), " ++ elem_size ++ ", (int64_t)(" ++ cap_text ++ "));\n"
        else:
            out = out ++ "    (void)0;\n"
        out = out ++ f"    goto bb{next_bb};"
        return out

    ""

fn CCodegen.emit_builtin_numeric_call_term(self: CCodegen, body: MirBody, kind: CcBuiltin, args_id: i32, dest_place: i32, next_bb: i32, argc: i32, ret_tid: i32, has_ret: i32) -> str:
    if kind == CcBuiltin.ROTATE_LEFT:
        if argc < 2:
            self.fail("rotate_left expects two arguments")
            return "    abort();"
        let val = self.operand_text(body, self.call_arg_operand(body, args_id, 0))
        let n = self.operand_text(body, self.call_arg_operand(body, args_id, 1))
        var out = ""
        if has_ret != 0:
            let dst = self.place_text(body, dest_place)
            out = out ++ "    " ++ cc_lbrace() ++ " uint32_t __with_v = (uint32_t)(" ++ val ++ "); uint32_t __with_n = (uint32_t)(" ++ n ++ ") & 31u;"
            out = out ++ " " ++ dst ++ " = (int32_t)((__with_v << __with_n) | (__with_v >> (32u - __with_n))); " ++ cc_rbrace() ++ "\n"
        else:
            out = out ++ "    (void)0;\n"
        out = out ++ f"    goto bb{next_bb};"
        return out

    if kind == CcBuiltin.ROTATE_RIGHT:
        if argc < 2:
            self.fail("rotate_right expects two arguments")
            return "    abort();"
        let val = self.operand_text(body, self.call_arg_operand(body, args_id, 0))
        let n = self.operand_text(body, self.call_arg_operand(body, args_id, 1))
        var out = ""
        if has_ret != 0:
            let dst = self.place_text(body, dest_place)
            out = out ++ "    " ++ cc_lbrace() ++ " uint32_t __with_v = (uint32_t)(" ++ val ++ "); uint32_t __with_n = (uint32_t)(" ++ n ++ ") & 31u;"
            out = out ++ " " ++ dst ++ " = (int32_t)((__with_v >> __with_n) | (__with_v << (32u - __with_n))); " ++ cc_rbrace() ++ "\n"
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

    ""

fn CCodegen.emit_builtin_format_call_term(self: CCodegen, body: MirBody, kind: CcBuiltin, args_id: i32, dest_place: i32, next_bb: i32, argc: i32, ret_tid: i32, has_ret: i32) -> str:
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
        var out = "    with_fmt_buf_write_str((uint8_t*)(" ++ buf ++ "), " ++ text ++ ");\n"
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
        let tk = self.sema.get_type_kind(resolved)
        var out = ""
        if tk == TypeKind.TY_FLOAT:
            out = out ++ "    with_fmt_buf_write_f64_spec((uint8_t*)(" ++ buf ++ "), (double)(" ++ val ++ "), (int64_t)(" ++ flags ++ "), (int32_t)(" ++ width ++ "), (int32_t)(" ++ precision ++ "), (int32_t)(((" ++ flags ++ ") & 255)));\n"
        else if tk == TypeKind.TY_STR:
            out = out ++ "    with_fmt_buf_write_str_spec((uint8_t*)(" ++ buf ++ "), " ++ val ++ ", (int64_t)(" ++ flags ++ "), (int32_t)(" ++ width ++ "), (int32_t)(" ++ precision ++ "));\n"
        else:
            out = out ++ "    with_fmt_buf_write_i64_spec((uint8_t*)(" ++ buf ++ "), (int64_t)(" ++ val ++ "), 0, (int64_t)(" ++ flags ++ "), (int32_t)(" ++ width ++ "), (int32_t)(" ++ precision ++ "), (int32_t)(((" ++ flags ++ ") & 255)));\n"
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
        let tk = self.sema.get_type_kind(resolved)
        let fmt_fn = if tk == TypeKind.TY_STR: "with_fmt_str"
            else if tk == TypeKind.TY_BOOL: "with_fmt_bool"
            else if tk == TypeKind.TY_FLOAT: "with_fmt_f64"
            else: "with_fmt_i64"
        let cast_prefix = if tk == TypeKind.TY_FLOAT: "(double)("
            else if tk == TypeKind.TY_BOOL: "(int32_t)("
            else if tk == TypeKind.TY_STR: "("
            else: "(int64_t)("
        var out = ""
        if has_ret != 0:
            out = out ++ "    " ++ self.place_text(body, dest_place) ++ " = " ++ fmt_fn ++ "(" ++ cast_prefix ++ val_text ++ "));\n"
        else:
            out = out ++ "    (void)" ++ fmt_fn ++ "(" ++ cast_prefix ++ val_text ++ "));\n"
        out = out ++ f"    goto bb{next_bb};"
        return out

    if kind == CcBuiltin.FMT_DEBUG_STR:
        if argc < 1:
            self.fail("fmt.debug_str expects one argument")
            return "    abort();"
        let val_text = self.operand_text(body, self.call_arg_operand(body, args_id, 0))
        var out = ""
        if has_ret != 0:
            out = out ++ "    " ++ self.place_text(body, dest_place) ++ " = with_fmt_str_debug(" ++ val_text ++ ");\n"
        else:
            out = out ++ "    (void)with_fmt_str_debug(" ++ val_text ++ ");\n"
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
        let resolved = self.sema.resolve_alias(val_tid as TypeId)
        let tk = self.sema.get_type_kind(resolved)
        let fmt_fn = if tk == TypeKind.TY_STR: "with_fmt_str_debug"
            else if tk == TypeKind.TY_BOOL: "with_fmt_bool"
            else if tk == TypeKind.TY_FLOAT: "with_fmt_f64"
            else: "with_fmt_i64"
        let cast_prefix = if tk == TypeKind.TY_FLOAT: "(double)("
            else if tk == TypeKind.TY_BOOL: "(int32_t)("
            else if tk == TypeKind.TY_STR: "("
            else: "(int64_t)("
        var out = ""
        if has_ret != 0:
            out = out ++ "    " ++ self.place_text(body, dest_place) ++ " = " ++ fmt_fn ++ "(" ++ cast_prefix ++ val_text ++ "));\n"
        else:
            out = out ++ "    (void)" ++ fmt_fn ++ "(" ++ cast_prefix ++ val_text ++ "));\n"
        out = out ++ f"    goto bb{next_bb};"
        return out

    if kind == CcBuiltin.FMT_SPEC:
        // args: value, flags(i64), width(i32), precision(i32)
        if argc < 4:
            self.fail("fmt.spec expects four arguments")
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
        let tk = self.sema.get_type_kind(resolved)
        var out = ""
        if has_ret != 0:
            let dst = self.place_text(body, dest_place)
            if tk == TypeKind.TY_FLOAT:
                out = out ++ "    " ++ dst ++ " = with_fmt_f64_spec((double)(" ++ val_text ++ "), (int64_t)(" ++ flags_text ++ "), (int32_t)(" ++ width_text ++ "), (int32_t)(" ++ prec_text ++ "));\n"
            else if tk == TypeKind.TY_STR:
                out = out ++ "    " ++ dst ++ " = with_fmt_str_spec(" ++ val_text ++ ", (int64_t)(" ++ flags_text ++ "), (int32_t)(" ++ width_text ++ "), (int32_t)(" ++ prec_text ++ "));\n"
            else:
                out = out ++ "    " ++ dst ++ " = with_fmt_int_spec((int64_t)(" ++ val_text ++ "), 0, (int64_t)(" ++ flags_text ++ "), (int32_t)(" ++ width_text ++ "), (int32_t)(" ++ prec_text ++ "));\n"
        else:
            out = out ++ "    (void)0;\n"
        out = out ++ f"    goto bb{next_bb};"
        return out

    ""

fn CCodegen.emit_builtin_dyn_unsupported_call_term(self: CCodegen, body: MirBody, kind: CcBuiltin, args_id: i32, dest_place: i32, next_bb: i32, argc: i32, ret_tid: i32, has_ret: i32) -> str:
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
        // Dynamic trait downcast — not fully implementable without type info; abort
        var out = "    /* dyn_downcast: not supported in C backend */ abort();\n"
        out = out ++ f"    goto bb{next_bb};"
        return out

    if kind == CcBuiltin.OPT_FILTER:
        // opt.filter requires closure support — not available in C backend
        var out = "    /* opt.filter: requires closure support */ abort();\n"
        out = out ++ f"    goto bb{next_bb};"
        return out

    if kind == CcBuiltin.VEC_MAP:
        // vec.map requires closure support — not available in C backend
        var out = "    /* vec.map: requires closure support */ abort();\n"
        out = out ++ f"    goto bb{next_bb};"
        return out

    if kind == CcBuiltin.VEC_FILTER:
        // vec.filter requires closure support — not available in C backend
        var out = "    /* vec.filter: requires closure support */ abort();\n"
        out = out ++ f"    goto bb{next_bb};"
        return out

    if kind == CcBuiltin.VEC_FOLD:
        // vec.fold requires closure support — not available in C backend
        var out = "    /* vec.fold: requires closure support */ abort();\n"
        out = out ++ f"    goto bb{next_bb};"
        return out

    if kind == CcBuiltin.GENERIC_CALL:
        // GENERIC_CALL should be resolved before reaching the C backend
        var out = "    /* generic_call: should be resolved before C backend */ abort();\n"
        out = out ++ f"    goto bb{next_bb};"
        return out

    ""

fn CCodegen.emit_builtin_numeric_format_call_term(self: CCodegen, body: MirBody, kind: CcBuiltin, args_id: i32, dest_place: i32, next_bb: i32, argc: i32, ret_tid: i32, has_ret: i32) -> str:
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

fn CCodegen.emit_builtin_call_term(self: CCodegen, body: MirBody, bb: i32, callee_operand: i32, args_id: i32, dest_place: i32, next_bb: i32) -> str:
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
    let has_ret = if self.is_void_tid(ret_tid) == 0: 1 else: 0

    // LLVM-only-by-design intrinsic families (#301). The C backend exists only to
    // self-bootstrap the compiler (see with-bootstrap-runbook.md, "Scope of the C
    // backend"); the compiler uses none of these internally, and user programs are
    // always compiled through LLVM. These loud failures are intentional and
    // permanent — reaching parity is NOT a goal. If the compiler ever starts using
    // one of these, `make emit-c-fixpoint` fails loudly and points here. Keep the
    // loud fail; never add a silent fallback to make --emit-c pass.
    var out = self.emit_builtin_vec_core_call_term(body, kind, args_id, dest_place, next_bb, argc, ret_tid, has_ret)
    if out.len() > 0:
        return out
    out = self.emit_builtin_map_call_term(body, kind, args_id, dest_place, next_bb, argc, ret_tid, has_ret)
    if out.len() > 0:
        return out
    out = self.emit_builtin_option_string_call_term(body, kind, args_id, dest_place, next_bb, argc, ret_tid, has_ret)
    if out.len() > 0:
        return out
    out = self.emit_builtin_vec_extra_call_term(body, kind, args_id, dest_place, next_bb, argc, ret_tid, has_ret)
    if out.len() > 0:
        return out
    out = self.emit_builtin_numeric_format_call_term(body, kind, args_id, dest_place, next_bb, argc, ret_tid, has_ret)
    if out.len() > 0:
        return out
    ""

fn CCodegen.field_place_matches(self: CCodegen, body: MirBody, place_id: i32, struct_tid: i32, field_sym: i32) -> i32:
    if place_id < 0 or place_id >= body.place_locals.len() as i32:
        return 0
    let count = body.place_proj_counts.get(place_id as i64)
    if count != 1:
        return 0
    let start = body.place_proj_starts.get(place_id as i64)
    if body.proj_kinds.get(start as i64) != ProjKind.PK_FIELD:
        return 0
    if body.proj_d0.get(start as i64) != field_sym:
        return 0
    let lid = body.place_locals.get(place_id as i64)
    if lid < 0 or lid >= body.local_type_ids.len() as i32:
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

fn CCodegen.rvalue_infer_tid(self: CCodegen, body: MirBody, rval_id: i32) -> i32:
    if rval_id < 0 or rval_id >= body.rval_kinds.len() as i32:
        return 0
    let no_infer = if self.in_field_cache_build != 0: 1 else: 0
    let rk = body.rval_kinds.get(rval_id as i64)
    let d0 = body.rval_d0.get(rval_id as i64)
    let d1 = body.rval_d1.get(rval_id as i64)
    let d2 = body.rval_d2.get(rval_id as i64)
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
        if d1 < 0 or d1 >= body.agg_field_starts.len() as i32:
            return 0
        let start = body.agg_field_starts.get(d1 as i64)
        let count = body.agg_field_counts.get(d1 as i64)
        if count <= 0:
            return 0
        let first = body.agg_field_operands.get(start as i64)
        if no_infer != 0:
            return self.operand_tid_no_infer(body, first)
        return self.operand_tid(body, first)
    if rk == RvalueKind.RK_LEN:
        return self.sema.ty_i64 as i32
    if rk == RvalueKind.RK_DISCRIMINANT:
        return self.sema.ty_i32 as i32
    0

fn CCodegen.record_field_tid_from_place(self: CCodegen, body: MirBody, place_id: i32, tid: i32):
    if place_id < 0 or place_id >= body.place_locals.len() as i32:
        return
    if tid == 0:
        return
    let count = body.place_proj_counts.get(place_id as i64)
    if count != 1:
        return
    let start = body.place_proj_starts.get(place_id as i64)
    if body.proj_kinds.get(start as i64) != ProjKind.PK_FIELD:
        return
    let field_sym = body.proj_d0.get(start as i64)
    let lid = body.place_locals.get(place_id as i64)
    if lid < 0 or lid >= body.local_type_ids.len() as i32:
        return
    var base_tid = self.local_effective_tid(body, lid)
    if self.is_void_tid(base_tid) != 0:
        base_tid = self.local_declared_tid(body, lid)
    let base_resolved = self.sema.resolve_alias(base_tid)
    if self.sema.get_type_kind(base_resolved) != TypeKind.TY_STRUCT:
        return
    self.field_cache_record(base_resolved, field_sym, tid)

fn CCodegen.place_is_single_field(self: CCodegen, body: MirBody, place_id: i32) -> i32:
    let _ = self
    if place_id < 0 or place_id >= body.place_locals.len() as i32:
        return 0
    if body.place_proj_counts.get(place_id as i64) != 1:
        return 0
    let start = body.place_proj_starts.get(place_id as i64)
    if body.proj_kinds.get(start as i64) != ProjKind.PK_FIELD:
        return 0
    1

fn CCodegen.build_field_cache_from_usage(self: CCodegen):
    if self.field_cache_ready != 0:
        return
    self.field_cache_ready = 1
    self.in_field_cache_build = 1

    for bi in 0..self.mir_mod.bodies.len() as i32:
        if self.check_interrupted() != 0:
            self.in_field_cache_build = 0
            return
        let body: MirBody = self.mir_mod.bodies.get(bi as i64)
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
                if hint == CcCalleeHint.VEC_RECV:
                    self.record_field_tid_from_place(body, recv_place, CC_PSEUDO_TID_VEC)
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
                if hint == CcCalleeHint.VEC_NEW:
                    self.record_field_tid_from_place(body, dest_place, CC_PSEUDO_TID_VEC)
                    continue
                if hint == CcCalleeHint.OPT_NEW:
                    self.record_field_tid_from_place(body, dest_place, self.sema.ty_i64)
                    continue
    self.in_field_cache_build = 0

fn CCodegen.infer_struct_field_tid_from_usage(self: CCodegen, struct_tid: i32, field_sym: i32) -> i32:
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

    var inferred = 0
    for bi in 0..self.mir_mod.bodies.len() as i32:
        if self.check_interrupted() != 0:
            return 0
        let body: MirBody = self.mir_mod.bodies.get(bi as i64)

        for bb in 0..body.block_count():
            if self.check_interrupted() != 0:
                return 0

            if body.term_kind(bb) == TermKind.TK_CALL:
                let callee_operand = body.term_data0(bb)
                let args_id = body.term_data1(bb)
                let dest_place = body.term_data2(bb)

                var sig_idx = -1
                if callee_operand >= 0 and callee_operand < body.operand_kinds.len() as i32:
                    if body.operand_kinds.get(callee_operand as i64) == OperandKind.OK_CONSTANT:
                        let const_id = body.operand_d0.get(callee_operand as i64)
                        if const_id >= 0 and const_id < body.const_kinds.len() as i32:
                            if body.const_kinds.get(const_id as i64) == ConstKind.CK_FN:
                                let fn_sym = body.const_d0.get(const_id as i64)
                                if fn_sym != 0:
                                    sig_idx = self.sig_index_for_sym(fn_sym)

                if sig_idx >= 0:
                    let argc = self.call_arg_count(body, args_id)
                    let param_count = self.sema.sig_get_param_count(sig_idx)
                    for ai in 0..argc:
                        if ai >= param_count:
                            break
                        let arg_operand = self.call_arg_operand(body, args_id, ai)
                        if arg_operand < 0 or arg_operand >= body.operand_kinds.len() as i32:
                            continue
                        let ok = body.operand_kinds.get(arg_operand as i64)
                        if ok != OperandKind.OK_COPY and ok != OperandKind.OK_MOVE:
                            continue
                        let arg_place = body.operand_d0.get(arg_operand as i64)
                        if self.field_place_matches(body, arg_place, resolved_struct, field_sym) == 0:
                            continue
                        let p_tid = self.sema.sig_param_type(sig_idx, ai)
                        inferred = self.prefer_inferred_tid(inferred, p_tid)

                    if self.field_place_matches(body, dest_place, resolved_struct, field_sym) != 0:
                        let ret_tid = self.sema.sig_return_type(sig_idx)
                        inferred = self.prefer_inferred_tid(inferred, ret_tid)

            let start = body.bb_stmt_starts.get(bb as i64)
            let count = body.bb_stmt_counts.get(bb as i64)
            for si in 0..count:
                let stmt_id = start + si
                if body.stmt_kinds.get(stmt_id as i64) != StmtKind.Assign:
                    continue
                let dst_place = body.stmt_d0.get(stmt_id as i64)
                let rval_id = body.stmt_d1.get(stmt_id as i64)

                if self.field_place_matches(body, dst_place, resolved_struct, field_sym) != 0:
                    var rv_tid = 0
                    if rval_id >= 0 and rval_id < body.rval_kinds.len() as i32:
                        let rk = body.rval_kinds.get(rval_id as i64)
                        let rd0 = body.rval_d0.get(rval_id as i64)
                        let rd1 = body.rval_d1.get(rval_id as i64)
                        if rk == RvalueKind.RK_USE:
                            if rd0 >= 0 and rd0 < body.operand_kinds.len() as i32:
                                let ok = body.operand_kinds.get(rd0 as i64)
                                let od = body.operand_d0.get(rd0 as i64)
                                if ok == OperandKind.OK_COPY or ok == OperandKind.OK_MOVE:
                                    let src_local = self.place_local_id(body, od)
                                    if src_local >= 0 and self.place_is_direct_local(body, od, src_local) != 0:
                                        rv_tid = self.local_declared_tid(body, src_local)
                                else if ok == OperandKind.OK_CONSTANT:
                                    if od >= 0 and od < body.const_types.len() as i32:
                                        rv_tid = body.const_types.get(od as i64)
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

                if rval_id < 0 or rval_id >= body.rval_kinds.len() as i32:
                    continue
                if body.rval_kinds.get(rval_id as i64) != RvalueKind.RK_USE:
                    continue
                let src_operand = body.rval_d0.get(rval_id as i64)
                if src_operand < 0 or src_operand >= body.operand_kinds.len() as i32:
                    continue
                let src_ok = body.operand_kinds.get(src_operand as i64)
                if src_ok != OperandKind.OK_COPY and src_ok != OperandKind.OK_MOVE:
                    continue
                let src_place = body.operand_d0.get(src_operand as i64)
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

fn CCodegen.effective_field_tid(self: CCodegen, struct_tid: i32, field_sym: i32, raw_field_tid: i32) -> i32:
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
                return CC_PSEUDO_TID_VEC
            if field_name == "module_map" or field_name == "link_lib_set" or field_name == "binding_map":
                return self.sema.ty_i64 as i32
    raw_field_tid

fn CCodegen.is_unit_rvalue(self: CCodegen, body: MirBody, rval_id: i32) -> i32:
    let _ = self
    if rval_id < 0 or rval_id >= body.rval_kinds.len() as i32:
        return 0
    if body.rval_kinds.get(rval_id as i64) != RvalueKind.RK_USE:
        return 0
    let op = body.rval_d0.get(rval_id as i64)
    if op < 0 or op >= body.operand_kinds.len() as i32:
        return 0
    if body.operand_kinds.get(op as i64) != OperandKind.OK_CONSTANT:
        return 0
    let const_id = body.operand_d0.get(op as i64)
    if const_id < 0 or const_id >= body.const_kinds.len() as i32:
        return 0
    let ck = body.const_kinds.get(const_id as i64)
    if ck == ConstKind.CK_UNIT or ck == ConstKind.CK_ZERO_SIZED:
        return 1
    0

fn CCodegen.rvalue_direct_local_id(self: CCodegen, body: MirBody, rval_id: i32) -> i32:
    let _ = self
    if rval_id < 0 or rval_id >= body.rval_kinds.len() as i32:
        return -1
    if body.rval_kinds.get(rval_id as i64) != RvalueKind.RK_USE:
        return -1
    let op = body.rval_d0.get(rval_id as i64)
    if op < 0 or op >= body.operand_kinds.len() as i32:
        return -1
    let ok = body.operand_kinds.get(op as i64)
    if ok != OperandKind.OK_COPY and ok != OperandKind.OK_MOVE:
        return -1
    let place_id = body.operand_d0.get(op as i64)
    if place_id < 0 or place_id >= body.place_locals.len() as i32:
        return -1
    let local_id = body.place_locals.get(place_id as i64)
    if local_id < 0:
        return -1
    if body.place_proj_counts.get(place_id as i64) != 0:
        return -1
    local_id

fn CCodegen.local_has_assignment(self: CCodegen, body: MirBody, local_id: i32) -> i32:
    if local_id < 0:
        return 0
    for bb in 0..body.block_count():
        let start = body.bb_stmt_starts.get(bb as i64)
        let count = body.bb_stmt_counts.get(bb as i64)
        for si in 0..count:
            let stmt_id = start + si
            if body.stmt_kinds.get(stmt_id as i64) != StmtKind.Assign:
                continue
            let dst_place = body.stmt_d0.get(stmt_id as i64)
            if self.place_is_direct_local(body, dst_place, local_id) != 0:
                return 1
        if body.term_kind(bb) == TermKind.TK_CALL:
            let dest_place = body.term_data2(bb)
            if self.place_is_direct_local(body, dest_place, local_id) != 0:
                return 1
    0

fn CCodegen.zero_value_text(self: CCodegen, tid: i32) -> str:
    let resolved = self.sema.resolve_alias(tid)
    let tk = self.sema.get_type_kind(resolved)
    if tk == TypeKind.TY_BOOL:
        return "false"
    if tk == TypeKind.TY_FLOAT:
        return "0.0"
    if tk == TypeKind.TY_PTR or tk == TypeKind.TY_REF:
        return "NULL"
    if tk == TypeKind.TY_GENERIC_INST and self.generic_inst_base_name(resolved as i32) == "Vec":
        return "(with_vec)" ++ cc_lbrace() ++ "0" ++ cc_rbrace()
    if tk == TypeKind.TY_GENERIC_INST and self.generic_inst_needs_struct_def(resolved as i32) != 0:
        return "(" ++ self.c_type(resolved, 0) ++ ")" ++ cc_lbrace() ++ "0" ++ cc_rbrace()
    if tk == TypeKind.TY_STR or tk == TypeKind.TY_STRUCT or tk == TypeKind.TY_TUPLE or self.type_is_payload_enum(resolved as i32) != 0:
        return "(" ++ self.c_type(resolved, 0) ++ ")" ++ cc_lbrace() ++ "0" ++ cc_rbrace()
    "0"

fn CCodegen.line_directive(self: CCodegen, body: MirBody, stmt_id: i32) -> str:
    if self.source_path.len() == 0:
        return ""
    if stmt_id < 0 or stmt_id >= body.stmt_spans.len() as i32:
        return ""
    let span = body.stmt_spans.get(stmt_id as i64)
    if span <= 0:
        return ""
    let loc = self.di_source.offset_to_location(span)
    let line = loc.line + 1
    if line == self.last_line_directive:
        return ""
    self.last_line_directive = line
    f"#line {line} \"{cc_line_directive_path(self.source_path)}\"\n"

fn CCodegen.emit_stmt_line(self: CCodegen, body: MirBody, stmt_id: i32) -> str:
    if stmt_id < 0 or stmt_id >= body.stmt_kinds.len() as i32:
        self.fail(f"invalid statement id {stmt_id}")
        return "    /* invalid statement */"
    let sk = body.stmt_kinds.get(stmt_id as i64)
    let d0 = body.stmt_d0.get(stmt_id as i64)
    let d1 = body.stmt_d1.get(stmt_id as i64)
    if sk == StmtKind.Assign:
        let dst_local = self.place_local_id(body, d0)
        if self.place_is_direct_local(body, d0, dst_local) != 0 and self.local_has_value_use(body, dst_local) == 0:
            if d1 >= 0 and d1 < body.rval_kinds.len() as i32 and body.rval_kinds.get(d1 as i64) == RvalueKind.RK_AGGREGATE:
                return "    /* dead aggregate temp */"
        let dst_place = self.place_text(body, d0)
        if self.is_unit_rvalue(body, d1) != 0:
            return "    " ++ dst_place ++ " = " ++ self.zero_value_text(self.place_tid(body, d0)) ++ ";"
        let dst_tid = self.place_tid(body, d0)
        let dst_resolved = self.sema.resolve_alias(dst_tid)
        let dst_tk = self.sema.get_type_kind(dst_resolved)
        if dst_tk == TypeKind.TY_ARRAY and d1 >= 0 and d1 < body.rval_kinds.len() as i32 and body.rval_kinds.get(d1 as i64) == RvalueKind.RK_ARRAY_FILL:
            let fill_op = body.rval_d0.get(d1 as i64)
            let fill_count = body.rval_d1.get(d1 as i64)
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
        // Vec zero-init: c_type returns "with_vec" for TY_GENERIC_INST(Vec)
        if (rval == "0" or rval == "0LL") and self.c_type(dst_tid, 0) == "with_vec":
            return "    " ++ dst_place ++ " = (with_vec)" ++ cc_lbrace() ++ "0" ++ cc_rbrace() ++ ";"
        // If destination is struct/str/vec and rvalue looks like a scalar, wrap it
        let dst_c_type = self.c_type(dst_tid, 0)
        let dst_is_distinct = self.type_is_distinct(dst_tid)
        let dst_is_compound = (dst_tk == TypeKind.TY_STRUCT and dst_is_distinct == 0) or dst_tk == TypeKind.TY_TUPLE or dst_tk == TypeKind.TY_STR or dst_tid == CC_PSEUDO_TID_VEC or dst_resolved == CC_PSEUDO_TID_VEC or dst_c_type == "with_str" or dst_c_type == "with_vec"
        if dst_is_compound:
            if rval == "0" or rval == "0LL":
                return "    " ++ dst_place ++ " = " ++ self.zero_value_text(dst_tid) ++ ";"
            // If the rvalue type doesn't match the struct destination, wrap
            let rv_tid = self.rvalue_tid(body, d1)
            let rv_resolved = if rv_tid != 0: self.sema.resolve_alias(rv_tid) else: 0
            let rv_tk = if rv_resolved != 0: self.sema.get_type_kind(rv_resolved) else: 0
            var needs_wrap = rv_tk == TypeKind.TY_INT or rv_tk == TypeKind.TY_BOOL or rv_tk == TypeKind.TY_ENUM
            if not needs_wrap and rv_resolved != 0 and rv_resolved != dst_resolved:
                // Check C type strings before assuming incompatibility — pseudo Vec and
                // real Vec[T] have different sema type kinds but the same C type.
                let dst_c = self.c_type(dst_tid, 0)
                let rv_c = self.c_type(rv_tid, 0)
                if dst_c != rv_c:
                    needs_wrap = true
            // If rvalue type is unknown but the rvalue text looks like a simple scalar, wrap it
            if not needs_wrap and rv_tid == 0:
                let rv_looks_scalar = rval.len() > 0 and rval.byte_at(0) != 40 and rval.byte_at(0) != 123
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
            if dst_kind_for_copy == TypeKind.TY_PTR or dst_kind_for_copy == TypeKind.TY_REF:
                if rval.len() >= 2 and rval.byte_at(0) == 40 and rval.byte_at(1) == 38:
                    return "    " ++ dst_place ++ " = (" ++ dst_c_for_copy ++ ")" ++ rval ++ ";"
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
        let p = self.place_text(body, d0)
        let pt = self.place_tid(body, d0)
        if pt == CC_PSEUDO_TID_VEC:
            return "    with_vec_clear(&(" ++ p ++ "));"
        return "    /* drop(" ++ p ++ "); */"
    if sk == StmtKind.Nop:
        return "    /* nop */"
    self.fail(f"unsupported statement kind {sk}")
    "    /* unsupported statement */"

fn CCodegen.emit_switch_term(self: CCodegen, body: MirBody, d0: i32, d1: i32, d2: i32) -> str:
    let cond = self.operand_text(body, d0)
    if d1 < 0 or d1 >= body.switch_table_starts.len() as i32:
        self.fail(f"invalid switch table id {d1}")
        if d2 != 0:
            return f"    goto bb{d2};"
        return "    abort();"

    let start = body.switch_table_starts.get(d1 as i64)
    let count = body.switch_table_counts.get(d1 as i64)
    var out = ""
    for i in 0..count:
        let val = body.switch_table_vals.get((start + i) as i64)
        let tgt = body.switch_table_targets.get((start + i) as i64)
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

fn CCodegen.emit_term(self: CCodegen, body: MirBody, bb: i32) -> str:
    let tk = body.term_kind(bb)
    let d0 = body.term_data0(bb)
    let d1 = body.term_data1(bb)
    let d2 = body.term_data2(bb)
    let d3 = body.term_data3(bb)
    if tk == TermKind.TK_GOTO:
        return f"    goto bb{d0};"
    if tk == TermKind.TK_RETURN:
        let sig_idx = self.body_sig_index(body.fn_sym)
        let ret_tid = if sig_idx >= 0: self.sema.sig_return_type(sig_idx) else:
            if body.local_type_ids.len() as i32 > 0: body.local_type_ids.get(0) else: self.sema.ty_void
        if self.is_void_tid(ret_tid) != 0:
            return "    return;"
        return "    return _0;"
    if tk == TermKind.TK_UNREACHABLE:
        return "    abort();"
    if tk == TermKind.TK_SWITCH_INT:
        return self.emit_switch_term(body, d0, d1, d2)
    if tk == TermKind.TK_CALL:
        let builtin_term = self.emit_builtin_call_term(body, bb, d0, d1, d2, d3)
        if builtin_term.len() > 0:
            return builtin_term
        let callee = self.resolve_call_callee_text(body, bb, d0, d1, d2)
        let ret_tid = self.call_return_tid(body, bb, d0, d1, d2)
        if callee == "/*unresolved_call*/" or callee == "/*ambiguous_call*/" or callee == "/*ambiguous_method*/":
            let _ = ret_tid
            return "    abort();"
        let args = self.call_args_text(body, d1, d0)
        var out = ""
        if self.is_void_tid(ret_tid) != 0:
            out = out ++ "    " ++ callee ++ "(" ++ args ++ ");\n"
        else:
            out = out ++ "    " ++ self.place_text(body, d2) ++ " = " ++ callee ++ "(" ++ args ++ ");\n"
        out = out ++ f"    goto bb{d3};"
        return out
    if tk == TermKind.TK_DROP_AND_GOTO:
        let p = self.place_text(body, d0)
        let pt = self.place_tid(body, d0)
        var out = ""
        if pt == CC_PSEUDO_TID_VEC:
            out = out ++ "    with_vec_clear(&(" ++ p ++ "));\n"
        else:
            out = out ++ "    /* drop(" ++ p ++ "); */\n"
        out = out ++ f"    goto bb{d1};"
        return out
    self.fail(f"unsupported terminator kind {tk}")
    "    abort();"

// docs/mut.md Rev 8 §5.1 — accumulator state for struct-type collection.
// Bundling out + seen_names into a single CollectStructTypes value lets the
// recursive walk be a method with `mut self: Self` instead of taking two
// separate `&mut` accumulators.
type CollectStructTypes {
    out: Vec[i32],
    seen_names: HashMap[i32, i32],
    seen_c_names: HashMap[str, i32],
}

fn CollectStructTypes.new -> CollectStructTypes:
    CollectStructTypes { out: Vec.new(), seen_names: HashMap.new(), seen_c_names: HashMap.new() }

type CollectFnTypes {
    out: Vec[i32],
    seen_names: HashMap[i32, i32],
    seen_types: HashMap[i32, i32],
}

fn CollectFnTypes.new -> CollectFnTypes:
    CollectFnTypes { out: Vec.new(), seen_names: HashMap.new(), seen_types: HashMap.new() }

fn CCodegen.collect_struct_types_from_tid(self: CCodegen, mut acc: CollectStructTypes, tid: i32) -> CollectStructTypes:
    let resolved = self.sema.resolve_alias(tid)
    if resolved == 0:
        return acc
    let tk = self.sema.get_type_kind(resolved)
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
                    let payload_tid = self.sema.type_reflection_variant_payload_type(resolved as i32, vi, pi)
                    payload_acc = self.collect_struct_types_from_tid(payload_acc, payload_tid)
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
            tuple_acc = self.collect_struct_types_from_tid(tuple_acc, self.sema.type_extra.get((start + ti) as i64))
        return tuple_acc
    if tk == TypeKind.TY_GENERIC_INST:
        let base_name = self.generic_inst_base_name(resolved as i32)
        if self.generic_inst_needs_struct_def(resolved as i32) != 0:
            if not acc.seen_names.contains(resolved as i32):
                acc.seen_names.insert(resolved as i32, 1)
                acc.out.push(resolved as i32)
            var generic_acc = acc
            let field_tids = self.synthetic_generic_struct_field_tids(resolved as i32)
            for fi in 0..field_tids.len() as i32:
                generic_acc = self.collect_struct_types_from_tid(generic_acc, field_tids.get(fi as i64))
            return generic_acc
        if base_name == "Vec" or base_name == "HashMap" or base_name == "HashSet":
            return acc
    if tk == TypeKind.TY_PTR or tk == TypeKind.TY_REF or tk == TypeKind.TY_ARRAY or tk == TypeKind.TY_SLICE:
        let inner_tid = self.sema.get_type_d0(resolved)
        return self.collect_struct_types_from_tid(acc, inner_tid)
    acc

fn CCodegen.synthetic_generic_struct_field_tids(self: CCodegen, tid: i32) -> Vec[i32]:
    let fields: Vec[i32] = Vec.new()
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

fn CCodegen.collect_fn_types_from_tid(self: CCodegen, acc: CollectFnTypes, tid: i32) -> CollectFnTypes:
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
        cur = self.collect_fn_types_from_tid(cur, ret_tid)
        let start = self.sema.get_type_d0(resolved)
        let count = self.sema.get_type_d1(resolved)
        for pi in 0..count:
            cur = self.collect_fn_types_from_tid(cur, self.sema.type_extra.get((start + pi) as i64))
        return cur
    if tk == TypeKind.TY_PTR or tk == TypeKind.TY_REF or tk == TypeKind.TY_ARRAY or tk == TypeKind.TY_SLICE:
        return self.collect_fn_types_from_tid(cur, self.sema.get_type_d0(resolved))
    if tk == TypeKind.TY_GENERIC_INST:
        let arg_count = self.sema.get_generic_inst_arg_count(resolved as i32)
        for ai in 0..arg_count:
            cur = self.collect_fn_types_from_tid(cur, self.sema.get_generic_inst_arg(resolved as i32, ai))
        return cur
    if tk == TypeKind.TY_STRUCT:
        let start = self.sema.get_type_d1(resolved)
        let count = self.sema.get_type_d2(resolved)
        for fi in 0..count:
            let raw_field_tid = self.sema.type_extra.get((start + fi * 3 + 1) as i64)
            cur = self.collect_fn_types_from_tid(cur, raw_field_tid)
        return cur
    if tk == TypeKind.TY_TUPLE:
        let start = self.sema.get_type_d0(resolved)
        let count = self.sema.get_type_d1(resolved)
        for ti in 0..count:
            cur = self.collect_fn_types_from_tid(cur, self.sema.type_extra.get((start + ti) as i64))
        return cur
    if self.type_is_payload_enum(resolved as i32) != 0:
        let variant_count = self.sema.type_reflection_variant_count(resolved as i32)
        for vi in 0..variant_count:
            let payload_count = self.sema.type_reflection_variant_payload_count(resolved as i32, vi)
            for pi in 0..payload_count:
                cur = self.collect_fn_types_from_tid(cur, self.sema.type_reflection_variant_payload_type(resolved as i32, vi, pi))
        return cur
    cur

fn CCodegen.collect_used_fn_types(self: CCodegen) -> Vec[i32]:
    var acc = CollectFnTypes.new()
    for bi in 0..self.mir_mod.bodies.len() as i32:
        if self.check_interrupted() != 0:
            return acc.out
        let body: MirBody = self.mir_mod.bodies.get(bi as i64)
        for li in 0..body.local_type_ids.len() as i32:
            acc = self.collect_fn_types_from_tid(acc, body.local_type_ids.get(li as i64))
        let sig_idx = self.body_sig_index(body.fn_sym)
        if sig_idx >= 0:
            acc = self.collect_fn_types_from_tid(acc, self.sema.sig_return_type(sig_idx))
            let param_count = self.sema.sig_get_param_count(sig_idx)
            for pi in 0..param_count:
                acc = self.collect_fn_types_from_tid(acc, self.sema.sig_param_type(sig_idx, pi))
    acc.out

fn CCodegen.collect_used_struct_types(self: CCodegen) -> Vec[i32]:
    var acc = CollectStructTypes.new()

    for bi in 0..self.mir_mod.bodies.len() as i32:
        if self.check_interrupted() != 0:
            return acc.out
        let body: MirBody = self.mir_mod.bodies.get(bi as i64)
        for bb in 0..body.block_count():
            if self.check_interrupted() != 0:
                return acc.out
            if body.term_kind(bb) != TermKind.TK_CALL:
                continue
            let args_id = body.term_data1(bb)
            if body.call_intrinsic(args_id) != MirIntrinsic.MAP_GET:
                continue
            let recv_operand = self.call_arg_operand(body, args_id, 0)
            let recv_tid = self.operand_tid_no_infer(body, recv_operand)
            let value_tid = self.hashmap_value_tid(recv_tid)
            if value_tid != 0 and self.is_void_tid(value_tid) == 0:
                let opt_tid = self.option_tid_for_payload(value_tid)
                acc = self.collect_struct_types_from_tid(acc, opt_tid)
            let dst_tid = self.place_local_tid(body, body.term_data2(bb))
            if dst_tid != 0 and self.is_void_tid(dst_tid) == 0 and self.is_scalar_like_tid(dst_tid) == 0:
                let dst_opt_tid = self.option_tid_for_payload(dst_tid)
                acc = self.collect_struct_types_from_tid(acc, dst_opt_tid)
        for li in 0..body.local_type_ids.len() as i32:
            if self.check_interrupted() != 0:
                return acc.out
            let tid = self.local_struct_collection_tid(body, li)
            acc = self.collect_struct_types_from_tid(acc, tid)
        let sig_idx = self.body_sig_index(body.fn_sym)
        if sig_idx >= 0:
            let ret_tid = self.sema.sig_return_type(sig_idx)
            acc = self.collect_struct_types_from_tid(acc, ret_tid)
            let param_count = self.sema.sig_get_param_count(sig_idx)
            for pi in 0..param_count:
                let p_tid = self.sema.sig_param_type(sig_idx, pi)
                acc = self.collect_struct_types_from_tid(acc, p_tid)

    var i = 0
    while i < acc.out.len() as i32:
        if self.check_interrupted() != 0:
            return acc.out
        let tid = acc.out.get(i as i64)
        i = i + 1
        let resolved = self.sema.resolve_alias(tid as TypeId) as i32
        let tk = self.sema.get_type_kind(resolved as TypeId)
        if tk == TypeKind.TY_GENERIC_INST and self.generic_inst_needs_struct_def(resolved) != 0:
            let field_tids = self.synthetic_generic_struct_field_tids(resolved)
            for fi in 0..field_tids.len() as i32:
                if self.check_interrupted() != 0:
                    return acc.out
                acc = self.collect_struct_types_from_tid(acc, field_tids.get(fi as i64))
            continue
        if self.type_is_payload_enum(resolved) != 0:
            let variant_count = self.sema.type_reflection_variant_count(resolved)
            for vi in 0..variant_count:
                let payload_count = self.sema.type_reflection_variant_payload_count(resolved, vi)
                for pi in 0..payload_count:
                    if self.check_interrupted() != 0:
                        return acc.out
                    acc = self.collect_struct_types_from_tid(acc, self.sema.type_reflection_variant_payload_type(resolved, vi, pi))
            continue
        if tk == TypeKind.TY_TUPLE:
            let start = self.sema.get_type_d0(resolved as TypeId)
            let count = self.sema.get_type_d1(resolved as TypeId)
            for ti in 0..count:
                if self.check_interrupted() != 0:
                    return acc.out
                acc = self.collect_struct_types_from_tid(acc, self.sema.type_extra.get((start + ti) as i64))
            continue
        if tk != TypeKind.TY_STRUCT:
            continue
        let start = self.sema.get_type_d1(resolved as TypeId)
        let count = self.sema.get_type_d2(resolved as TypeId)
        for fi in 0..count:
            if self.check_interrupted() != 0:
                return acc.out
            let raw_field_tid = self.sema.type_extra.get((start + fi * 3 + 1) as i64)
            acc = self.collect_struct_types_from_tid(acc, raw_field_tid)

    acc.out

fn CCodegen.emit_fn_type_defs(self: CCodegen) -> str:
    let fn_tids = self.collect_used_fn_types()
    var out = ""
    for i in 0..fn_tids.len() as i32:
        if self.check_interrupted() != 0:
            return ""
        let tid = self.sema.resolve_alias(fn_tids.get(i as i64) as TypeId)
        let tid_kind = self.sema.get_type_kind(tid)
        if tid_kind != TypeKind.TY_FN and tid_kind != TypeKind.TY_EXTERN_FN:
            continue
        let ret_tid = self.sema.get_type_d2(tid)
        let start = self.sema.get_type_d0(tid)
        let count = self.sema.get_type_d1(tid)
        out = out ++ "typedef " ++ self.c_type(ret_tid, 1) ++ " (*" ++ self.fn_type_c_name(tid as i32) ++ ")("
        if count == 0:
            out = out ++ "void"
        else:
            for pi in 0..count:
                if pi > 0:
                    out = out ++ ", "
                out = out ++ self.c_type(self.sema.type_extra.get((start + pi) as i64), 0)
        out = out ++ ");\n"
    if out.len() > 0:
        out = out ++ "\n"
    out

fn CCodegen.emit_struct_type_defs(self: CCodegen) -> str:
    let struct_tids = self.collect_used_struct_types()
    if self.had_error != 0:
        return ""
    if struct_tids.len() as i32 == 0:
        return ""

    let ordered: Vec[i32] = Vec.new()
    let emitted_names: HashMap[i32, i32] = HashMap.new()
    while ordered.len() as i32 < struct_tids.len() as i32:
        if self.check_interrupted() != 0:
            return ""
        var progressed = 0
        for i in 0..struct_tids.len() as i32:
            if self.check_interrupted() != 0:
                return ""
            let resolved = self.sema.resolve_alias(struct_tids.get(i as i64) as TypeId) as i32
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
                    if (self.sema.get_type_kind(key_tid) == TypeKind.TY_STRUCT or self.sema.get_type_kind(key_tid) == TypeKind.TY_TUPLE or self.type_is_payload_enum(key_tid as i32) != 0) and key_tid != resolved and not emitted_names.contains(key_tid as i32):
                        ready = 0
                if base_name == "Atomic":
                    let value_tid = self.sema.resolve_alias(self.sema.get_generic_inst_arg(resolved, 0) as TypeId)
                    if (self.sema.get_type_kind(value_tid) == TypeKind.TY_STRUCT or self.sema.get_type_kind(value_tid) == TypeKind.TY_TUPLE or self.type_is_payload_enum(value_tid as i32) != 0) and value_tid != resolved and not emitted_names.contains(value_tid as i32):
                        ready = 0
            else if self.type_is_payload_enum(resolved) != 0:
                let variant_count = self.sema.type_reflection_variant_count(resolved)
                for vi in 0..variant_count:
                    let payload_count = self.sema.type_reflection_variant_payload_count(resolved, vi)
                    for pi in 0..payload_count:
                        let field_tid = self.sema.resolve_alias(self.sema.type_reflection_variant_payload_type(resolved, vi, pi) as TypeId)
                        if self.sema.get_type_kind(field_tid) != TypeKind.TY_STRUCT and self.sema.get_type_kind(field_tid) != TypeKind.TY_TUPLE and self.type_is_payload_enum(field_tid as i32) == 0:
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
                    let field_tid = self.sema.resolve_alias(self.sema.type_extra.get((tuple_start + ti) as i64) as TypeId)
                    if self.sema.get_type_kind(field_tid) != TypeKind.TY_STRUCT and self.sema.get_type_kind(field_tid) != TypeKind.TY_TUPLE and self.type_is_payload_enum(field_tid as i32) == 0:
                        continue
                    if field_tid != resolved and not emitted_names.contains(field_tid as i32):
                        ready = 0
                        break
            else:
                for fi in 0..count:
                    if self.check_interrupted() != 0:
                        return ""
                    let field_sym = self.sema.type_extra.get((start + fi * 3) as i64)
                    let raw_field_tid = self.sema.type_extra.get((start + fi * 3 + 1) as i64)
                    let field_tid = self.sema.resolve_alias(self.effective_field_tid(resolved, field_sym, raw_field_tid) as TypeId)
                    if self.sema.get_type_kind(field_tid) != TypeKind.TY_STRUCT and self.sema.get_type_kind(field_tid) != TypeKind.TY_TUPLE and self.type_is_payload_enum(field_tid as i32) == 0:
                        continue
                    if field_tid != resolved and not emitted_names.contains(field_tid as i32):
                        ready = 0
                        break
            if ready == 0:
                continue
            ordered.push(resolved)
            emitted_names.insert(resolved, 1)
            progressed = 1
        if progressed == 0:
            for i in 0..struct_tids.len() as i32:
                if self.check_interrupted() != 0:
                    return ""
                let resolved = self.sema.resolve_alias(struct_tids.get(i as i64) as TypeId) as i32
                if emitted_names.contains(resolved):
                    continue
                ordered.push(resolved)
                emitted_names.insert(resolved, 1)

    var out = ""
    for i in 0..ordered.len() as i32:
        if self.check_interrupted() != 0:
            return ""
        let tid = ordered.get(i as i64)
        let resolved = self.sema.resolve_alias(tid)
        if self.sema.get_type_kind(resolved) == TypeKind.TY_TUPLE:
            let name = self.struct_c_name(tid)
            out = out ++ "typedef struct " ++ name ++ " " ++ name ++ ";\n"
            continue
        let name_sym = self.sema.get_type_d0(resolved)
        let count = self.sema.get_type_d2(resolved)
        if self.type_is_payload_enum(resolved as i32) == 0 and count == 1 and self.sema.distinct_type_names.contains(name_sym):
            continue  // distinct types get their typedef in the definition pass
        let name = self.struct_c_name(tid)
        out = out ++ "typedef struct " ++ name ++ " " ++ name ++ ";\n"
    out = out ++ "\n"
    out = out ++ self.emit_fn_type_defs()

    for i in 0..ordered.len() as i32:
        if self.check_interrupted() != 0:
            return ""
        let tid = ordered.get(i as i64)
        let resolved = self.sema.resolve_alias(tid)
        let name = self.struct_c_name(resolved)
        if self.sema.get_type_kind(resolved) == TypeKind.TY_TUPLE:
            let start = self.sema.get_type_d0(resolved)
            let count = self.sema.get_type_d1(resolved)
            out = out ++ "struct " ++ name ++ " " ++ cc_lbrace() ++ "\n"
            for ti in 0..count:
                if self.check_interrupted() != 0:
                    return ""
                let elem_tid = self.sema.type_extra.get((start + ti) as i64)
                out = out ++ "    " ++ self.c_decl(elem_tid, f"field{ti}") ++ ";\n"
            out = out ++ cc_rbrace() ++ ";\n\n"
            continue
        let generic_base_name = self.generic_inst_base_name(resolved as i32)
        if self.sema.is_opaque_value_type(resolved as i32) != 0:
            continue
        if generic_base_name == "VecSlot":
            out = out ++ "struct " ++ name ++ " " ++ cc_lbrace() ++ "\n"
            out = out ++ "    int64_t data_ptr;\n"
            out = out ++ "    int64_t index;\n"
            out = out ++ cc_rbrace() ++ ";\n\n"
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
                    if payload_count != 1:
                        self.fail(f"C backend does not support enum variants with {payload_count} payload fields")
                        return ""
                    let payload_tid = self.sema.type_reflection_variant_payload_type(resolved as i32, vi, 0)
                    out = out ++ "        " ++ self.c_decl(payload_tid, self.payload_enum_variant_field(vi)) ++ ";\n"
                out = out ++ "    " ++ cc_rbrace() ++ ";\n"
            out = out ++ cc_rbrace() ++ ";\n\n"
            continue
        if generic_base_name == "VecIter" or generic_base_name == "VecIterPlace":
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
        let start = self.sema.get_type_d1(resolved)
        let count = self.sema.get_type_d2(resolved)
        // Distinct types (single-field wrapper) → emit as typedef to underlying C type
        let name_sym = self.sema.get_type_d0(resolved)
        if count == 1 and self.sema.distinct_type_names.contains(name_sym):
            let raw_field_tid = self.sema.type_extra.get((start + 1) as i64)
            let field_sym = self.sema.type_extra.get(start as i64)
            let field_tid = self.effective_field_tid(resolved, field_sym, raw_field_tid)
            out = out ++ "typedef " ++ self.c_decl(field_tid, name) ++ ";\n\n"
            continue
        out = out ++ "struct " ++ name ++ " " ++ cc_lbrace() ++ "\n"
        for fi in 0..count:
            if self.check_interrupted() != 0:
                return ""
            let field_sym = self.sema.type_extra.get((start + fi * 3) as i64)
            let raw_field_tid = self.sema.type_extra.get((start + fi * 3 + 1) as i64)
            let field_tid = self.effective_field_tid(resolved, field_sym, raw_field_tid)
            let field_name = cc_intern_resolve(self.intern, field_sym)
            out = out ++ "    " ++ self.c_decl(field_tid, field_name) ++ ";\n"
        out = out ++ cc_rbrace() ++ ";\n\n"
    out

fn CCodegen.global_var_definition(self: CCodegen, decl: NodeId) -> str:
    let sym = self.ast.get_data0(decl)
    let tid = self.global_decl_tid(decl)
    if tid == 0:
        return ""
    let name = self.global_c_name(sym)
    let init = self.global_init_text(self.ast.get_data1(decl), tid, self.decl_source_text(decl))
    "static " ++ self.c_decl(tid, name) ++ " = " ++ init ++ ";\n"

fn CCodegen.collect_referenced_global_syms(self: CCodegen) -> HashMap[i32, i32]:
    let used = HashMap[i32, i32].new()
    for bi in 0..self.mir_mod.bodies.len() as i32:
        if self.check_interrupted() != 0:
            return used
        let body: MirBody = self.mir_mod.bodies.get(bi as i64)
        for li in 0..body.local_names.len() as i32:
            let sym = self.local_global_sym(body, li)
            if sym != 0:
                used.insert(sym, 1)
    used

fn CCodegen.collect_referenced_fn_syms(self: CCodegen) -> HashMap[i32, i32]:
    let used = HashMap[i32, i32].new()
    for bi in 0..self.mir_mod.bodies.len() as i32:
        if self.check_interrupted() != 0:
            return used
        let body: MirBody = self.mir_mod.bodies.get(bi as i64)
        for oi in 0..body.operand_kinds.len() as i32:
            if body.operand_kinds.get(oi as i64) != OperandKind.OK_CONSTANT:
                continue
            let const_id = body.operand_d0.get(oi as i64)
            if const_id < 0 or const_id >= body.const_kinds.len() as i32:
                continue
            if body.const_kinds.get(const_id as i64) != ConstKind.CK_FN:
                continue
            let fn_sym = body.const_d0.get(const_id as i64)
            if fn_sym != 0:
                used.insert(fn_sym, 1)
    used

fn CCodegen.emit_global_var_defs(self: CCodegen) -> str:
    var out = ""
    let used_globals = self.collect_referenced_global_syms()
    if self.had_error != 0:
        return ""
    for di in 0..self.ast.decl_count():
        if self.check_interrupted() != 0:
            return ""
        let decl = self.ast.get_decl(di)
        let kind = self.ast.kind(decl)
        if kind == NodeKind.NK_LET_DECL:
            let sym = self.ast.get_data0(decl)
            let flags = self.ast.get_data2(decl)
            if flags % 2 == 0 and not used_globals.contains(sym):
                continue
            out = out ++ self.global_var_definition(decl)
            continue
        if kind == NodeKind.NK_EXTERN_VAR:
            let sym = self.ast.get_data0(decl)
            let tid = self.global_decl_tid(decl)
            if tid == 0:
                continue
            out = out ++ "extern " ++ self.c_decl(tid, self.global_c_name(sym)) ++ ";\n"
    if out.len() > 0:
        out = out ++ "\n"
    out

fn CCodegen.emit_extern_fn_decl(self: CCodegen, decl: NodeId) -> str:
    let fn_sym = self.ast.get_data0(decl)
    let sig_idx = self.sig_index_for_sym(fn_sym)
    if sig_idx < 0:
        self.fail(f"emit-c: missing signature for extern fn {cc_intern_resolve(self.intern, fn_sym)}")
        return ""
    var out = "extern " ++ self.c_type(self.sema.sig_return_type(sig_idx), 1) ++ " " ++ self.extern_sym_c_name(fn_sym) ++ "("
    let param_count = self.sema.sig_get_param_count(sig_idx)
    for i in 0..param_count:
        if i > 0:
            out = out ++ ", "
        let p_tid = self.sema.sig_param_type(sig_idx, i)
        if self.fn_param_is_c_pointer(fn_sym, i) != 0:
            out = out ++ self.c_type(p_tid, 0) ++ f"* _{i + 1}"
        else:
            out = out ++ self.c_type(p_tid, 0) ++ f" _{i + 1}"
    if self.sema.sig_is_variadic(sig_idx) != 0:
        if param_count > 0:
            out = out ++ ", ..."
        else:
            out = out ++ "..."
    else:
        if param_count == 0:
            out = out ++ "void"
    out ++ ");\n"

fn CCodegen.should_emit_extern_fn_decl(self: CCodegen, fn_sym: i32, referenced: HashMap[i32, i32]) -> i32:
    if not referenced.contains(fn_sym):
        return 0
    let name = self.canonical_extern_name(cc_intern_resolve(self.intern, fn_sym))
    if cc_str_starts_with(name, "with_") != 0:
        return 0
    if cc_str_starts_with(name, "wl_") != 0:
        return 0
    if name == "malloc" or name == "free":
        return 0
    if name == "mkstemp" or name == "strtod" or name == "realpath" or name == "getenv":
        return 0
    if name == "strlen" or name == "strcmp" or name == "strncmp" or name == "memchr":
        return 0
    if name == "strcpy" or name == "strncpy" or name == "strstr" or name == "strerror":
        return 0
    if name == "strtol" or name == "strtoul":
        return 0
    if name == "isalpha" or name == "isdigit" or name == "isalnum" or name == "isspace":
        return 0
    if name == "isupper" or name == "islower" or name == "isxdigit" or name == "isprint":
        return 0
    if name == "isgraph" or name == "ispunct" or name == "iscntrl" or name == "tolower" or name == "toupper":
        return 0
    if name == "sqrt" or name == "pow" or name == "floor" or name == "ceil" or name == "round":
        return 0
    if name == "sin" or name == "cos" or name == "tan" or name == "log" or name == "log10":
        return 0
    if name == "exp" or name == "fabs" or name == "fmod" or name == "asin" or name == "acos":
        return 0
    if name == "atan" or name == "atan2":
        return 0
    if name == "fprintf" or name == "printf" or name == "snprintf" or name == "sprintf":
        return 0
    if name == "fopen" or name == "fclose" or name == "fflush" or name == "fileno":
        return 0
    if name == "fgets" or name == "fgetc" or name == "fputc" or name == "fputs" or name == "putc":
        return 0
    if name == "feof" or name == "fread" or name == "fwrite":
        return 0
    if name == "setlocale" or name == "exit" or name == "clock" or name == "time" or name == "isatty":
        return 0
    if name == "getrlimit" or name == "setrlimit":
        return 0
    if name == "rename" or name == "unlink" or name == "write" or name == "read" or name == "close":
        return 0
    if name == "open" or name == "__open" or name == "gethostname" or name == "mkdir" or name == "rmdir":
        return 0
    if name == "chmod" or name == "access" or name == "symlink":
        return 0
    if name == "setenv" or name == "execv" or name == "execvp" or name == "chdir":
        return 0
    1

fn CCodegen.emit_extern_fn_decls(self: CCodegen) -> str:
    var out = ""
    let referenced = self.collect_referenced_fn_syms()
    for di in 0..self.ast.decl_count():
        if self.check_interrupted() != 0:
            return ""
        let decl = self.ast.get_decl(di)
        if self.ast.kind(decl) != NodeKind.NK_EXTERN_FN:
            continue
        if self.should_emit_extern_fn_decl(self.ast.get_data0(decl), referenced) == 0:
            continue
        out = out ++ self.emit_extern_fn_decl(decl)
    if out.len() > 0:
        out = out ++ "\n"
    out

fn CCodegen.emit_fn_decl(self: CCodegen, body: MirBody) -> str:
    let fn_sym = body.fn_sym
    let fn_name = self.fn_c_name(fn_sym)
    let sig_idx = self.body_sig_index(fn_sym)
    let ret_tid = if sig_idx >= 0: self.sema.sig_return_type(sig_idx) else:
        if body.local_type_ids.len() > 0: body.local_type_ids.get(0) else: self.sema.ty_void
    var out = self.c_type(ret_tid, 1) ++ " " ++ fn_name ++ "("
    let param_count = if sig_idx >= 0: self.sema.sig_get_param_count(sig_idx) else: 0
    for i in 0..param_count:
        if i > 0:
            out = out ++ ", "
        let p_tid = self.sema.sig_param_type(sig_idx, i)
        if self.fn_param_is_c_pointer(fn_sym, i) != 0:
            out = out ++ self.c_type(p_tid, 0) ++ f"* _{i + 1}"
        else:
            out = out ++ self.c_type(p_tid, 0) ++ f" _{i + 1}"
    out = out ++ ")"
    out

fn CCodegen.prepare_c_type_instantiations(self: CCodegen):
    for i in 0..self.mir_mod.bodies.len() as i32:
        if self.check_interrupted() != 0:
            return
        let body: MirBody = self.mir_mod.bodies.get(i as i64)
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
                let _ = self.option_tid_for_payload(value_tid)
            let dest_place = body.term_data2(bb)
            let dst_tid = self.place_local_tid(body, dest_place)
            if dst_tid != 0 and self.is_void_tid(dst_tid) == 0 and self.is_scalar_like_tid(dst_tid) == 0:
                let _ = self.option_tid_for_payload(dst_tid)

fn CCodegen.local_receives_ref(self: CCodegen, body: MirBody, local_id: i32) -> bool:
    self.local_ref_target_tid(body, local_id) != 0

fn CCodegen.local_ref_target_tid(self: CCodegen, body: MirBody, local_id: i32) -> i32:
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
    var out = 0
    for bb in 0..body.block_count():
        let start = body.bb_stmt_starts.get(bb as i64)
        let count = body.bb_stmt_counts.get(bb as i64)
        for si in 0..count:
            let stmt_id = start + si
            if body.stmt_kinds.get(stmt_id as i64) != StmtKind.Assign:
                continue
            let dst_place = body.stmt_d0.get(stmt_id as i64)
            if self.place_is_direct_local(body, dst_place, local_id) == 0:
                continue
            let rval_id = body.stmt_d1.get(stmt_id as i64)
            if rval_id < 0 or rval_id >= body.rval_kinds.len() as i32:
                continue
            let rk = body.rval_kinds.get(rval_id as i64)
            var src_place = -1
            if rk == RvalueKind.RK_REF:
                src_place = body.rval_d1.get(rval_id as i64)
            else if rk == RvalueKind.RK_ADDR_OF:
                src_place = body.rval_d0.get(rval_id as i64)
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

fn CCodegen.local_receives_arith(self: CCodegen, body: MirBody, local_id: i32) -> bool:
    for bb in 0..body.block_count():
        // Check statements
        let start = body.bb_stmt_starts.get(bb as i64)
        let count = body.bb_stmt_counts.get(bb as i64)
        for si in 0..count:
            let stmt_id = start + si
            if body.stmt_kinds.get(stmt_id as i64) != StmtKind.Assign:
                continue
            let dst_place = body.stmt_d0.get(stmt_id as i64)
            if self.place_is_direct_local(body, dst_place, local_id) == 0:
                continue
            let rval_id = body.stmt_d1.get(stmt_id as i64)
            if rval_id < 0 or rval_id >= body.rval_kinds.len() as i32:
                continue
            let rk = body.rval_kinds.get(rval_id as i64)
            if rk == RvalueKind.RK_BIN_OP:
                let op = body.rval_d0.get(rval_id as i64)
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

fn CCodegen.operand_is_int_const(self: CCodegen, body: MirBody, operand_id: i32, value: i64) -> bool:
    let _ = self
    if operand_id < 0 or operand_id >= body.operand_kinds.len() as i32:
        return false
    if body.operand_kinds.get(operand_id as i64) != OperandKind.OK_CONSTANT:
        return false
    let const_id = body.operand_d0.get(operand_id as i64)
    if const_id < 0 or const_id >= body.const_kinds.len() as i32:
        return false
    let ck = body.const_kinds.get(const_id as i64)
    if ck != ConstKind.CK_INT and ck != ConstKind.CK_INT_EXACT:
        return false
    mir_const_int_value(body, const_id) == value

fn CCodegen.local_originates_from_map_get_depth(self: CCodegen, body: MirBody, local_id: i32, depth: i32) -> bool:
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
        let start = body.bb_stmt_starts.get(bb as i64)
        let count = body.bb_stmt_counts.get(bb as i64)
        for si in 0..count:
            let stmt_id = start + si
            if body.stmt_kinds.get(stmt_id as i64) != StmtKind.Assign:
                continue
            let dst_place = body.stmt_d0.get(stmt_id as i64)
            if self.place_is_direct_local(body, dst_place, local_id) == 0:
                continue
            let src_local = self.rvalue_direct_local_id(body, body.stmt_d1.get(stmt_id as i64))
            if src_local >= 0 and src_local != local_id and self.local_originates_from_map_get_depth(body, src_local, depth + 1):
                return true
    false

fn CCodegen.local_originates_from_map_get(self: CCodegen, body: MirBody, local_id: i32) -> bool:
    self.local_originates_from_map_get_depth(body, local_id, 0)

fn CCodegen.local_used_as_vec_receiver(self: CCodegen, body: MirBody, local_id: i32) -> bool:
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
        if not cc_builtin_uses_vec_receiver(kind):
            continue
        let recv_place = self.call_first_arg_place_id(body, args_id)
        if self.place_is_direct_local(body, recv_place, local_id) != 0:
            return true
    false

fn CCodegen.local_used_as_option_receiver(self: CCodegen, body: MirBody, local_id: i32) -> bool:
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

fn cc_mark_local_repr(flags_in: Vec[i32], local_id: i32, mark: i32) -> Vec[i32]:
    var flags = flags_in
    if local_id < 0 or local_id >= flags.len() as i32:
        return flags
    let existing = flags.get(local_id as i64)
    if mark == 2 or existing == 0:
        let slot_index = local_id as i64
        with flags.slot(slot_index) as mut slot:
            slot.set(mark)
    flags

fn CCodegen.encoded_option_local_flags(self: CCodegen, body: MirBody) -> Vec[i32]:
    var flags: Vec[i32] = Vec.new()
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
                if cc_builtin_uses_vec_receiver(kind):
                    flags = cc_mark_local_repr(flags, recv_local, 2)
                else if cc_builtin_uses_option_receiver(kind):
                    flags = cc_mark_local_repr(flags, recv_local, 1)

        let start = body.bb_stmt_starts.get(bb as i64)
        let count = body.bb_stmt_counts.get(bb as i64)
        for si in 0..count:
            let stmt_id = start + si
            if body.stmt_kinds.get(stmt_id as i64) != StmtKind.Assign:
                continue
            let rval_id = body.stmt_d1.get(stmt_id as i64)
            if rval_id < 0 or rval_id >= body.rval_kinds.len() as i32:
                continue
            if body.rval_kinds.get(rval_id as i64) != RvalueKind.RK_BIN_OP:
                continue
            let op = body.rval_d0.get(rval_id as i64)
            if op != BinaryOp.OP_SUB and op != BinaryOp.OP_NEQ and op != BinaryOp.OP_EQ:
                continue
            let lhs = body.rval_d1.get(rval_id as i64)
            let rhs = body.rval_d2.get(rval_id as i64)
            if op == BinaryOp.OP_SUB and self.operand_is_int_const(body, rhs, 1):
                flags = cc_mark_local_repr(flags, self.operand_direct_local_id(body, lhs), 1)
            else if op == BinaryOp.OP_NEQ or op == BinaryOp.OP_EQ:
                if self.operand_is_int_const(body, rhs, 0):
                    flags = cc_mark_local_repr(flags, self.operand_direct_local_id(body, lhs), 1)
                if self.operand_is_int_const(body, lhs, 0):
                    flags = cc_mark_local_repr(flags, self.operand_direct_local_id(body, rhs), 1)
    flags

fn CCodegen.local_used_as_encoded_option(self: CCodegen, body: MirBody, local_id: i32) -> bool:
    if local_id < 0:
        return false
    if self.local_used_as_vec_receiver(body, local_id):
        return false
    if self.local_used_as_option_receiver(body, local_id):
        return true
    for bb in 0..body.block_count():
        let start = body.bb_stmt_starts.get(bb as i64)
        let count = body.bb_stmt_counts.get(bb as i64)
        for si in 0..count:
            let stmt_id = start + si
            if body.stmt_kinds.get(stmt_id as i64) != StmtKind.Assign:
                continue
            let rval_id = body.stmt_d1.get(stmt_id as i64)
            if rval_id < 0 or rval_id >= body.rval_kinds.len() as i32:
                continue
            let rk = body.rval_kinds.get(rval_id as i64)
            if rk != RvalueKind.RK_BIN_OP:
                continue
            let op = body.rval_d0.get(rval_id as i64)
            if op != BinaryOp.OP_SUB and op != BinaryOp.OP_NEQ and op != BinaryOp.OP_EQ:
                continue
            let lhs = body.rval_d1.get(rval_id as i64)
            let rhs = body.rval_d2.get(rval_id as i64)
            if op == BinaryOp.OP_SUB and self.operand_uses_local(body, lhs, local_id) != 0 and self.operand_is_int_const(body, rhs, 1):
                return true
            if (op == BinaryOp.OP_NEQ or op == BinaryOp.OP_EQ) and self.operand_uses_local(body, lhs, local_id) != 0 and self.operand_is_int_const(body, rhs, 0):
                return true
            if (op == BinaryOp.OP_NEQ or op == BinaryOp.OP_EQ) and self.operand_uses_local(body, rhs, local_id) != 0 and self.operand_is_int_const(body, lhs, 0):
                return true
    false

fn CCodegen.emit_fn_body(self: CCodegen, body: MirBody) -> str:
    if self.check_interrupted() != 0:
        return ""
    let fn_sym = body.fn_sym
    let sig_idx = self.body_sig_index(fn_sym)
    if sig_idx < 0:
        return ""
    let fn_sig = self.emit_fn_decl(body)
    let param_count = if sig_idx >= 0: self.sema.sig_get_param_count(sig_idx) else: 0
    let out = COut.new()
    out.write(fn_sig ++ " " ++ cc_lbrace() ++ "\n")
    let call_override_locals: Vec[i32] = Vec.new()
    let call_override_tids: Vec[i32] = Vec.new()
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
        var ret_tid = 0
        if call_kind == CcBuiltin.MAP_GET:
            ret_tid = self.call_builtin_ret_tid(body, callee_operand, args_id, dest_place)
        else if intrinsic_kind != CcBuiltin.NONE:
            ret_tid = self.call_builtin_ret_tid(body, callee_operand, args_id, dest_place)
        else:
            ret_tid = self.call_return_tid(body, bb, callee_operand, args_id, dest_place)
        if ret_tid == 0 or self.is_void_tid(ret_tid) != 0:
            continue
        var seen = 0
        for oi in 0..call_override_locals.len() as i32:
            if call_override_locals.get(oi as i64) == local_id:
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
        let declared_tid = if li == 0 and sig_idx >= 0: self.sema.sig_return_type(sig_idx) else:
            if li < body.local_type_ids.len() as i32: body.local_type_ids.get(li as i64) else: self.sema.ty_i32
        var use_tid = declared_tid
        let declared_resolved = self.sema.resolve_alias(declared_tid)
        let declared_kind = self.sema.get_type_kind(declared_resolved)
        if self.is_void_tid(declared_tid) == 0 and declared_resolved != 0 and declared_kind != TypeKind.TY_ERR:
            for oi in 0..call_override_locals.len() as i32:
                if call_override_locals.get(oi as i64) != li:
                    continue
                let override_tid = call_override_tids.get(oi as i64)
                let declared_kind_for_override = self.sema.get_type_kind(self.sema.resolve_alias(declared_tid))
                let override_kind = self.sema.get_type_kind(self.sema.resolve_alias(override_tid))
                if declared_kind_for_override != override_kind or self.strict_type_match(declared_tid, override_tid) == 0:
                    use_tid = override_tid
                break
        let downcast_opt_tid = cc_vec_tid_at(downcast_option_tids, li)
        if downcast_opt_tid != 0 and self.is_void_tid(downcast_opt_tid) == 0:
            use_tid = downcast_opt_tid
        let copied_payload_enum_tid = cc_vec_tid_at(copied_payload_enum_tids, li)
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
        let ref_target_tid = cc_vec_tid_at(ref_target_tids, li)
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
        if is_compound_local and li < encoded_option_locals.len() as i32 and encoded_option_locals.get(li as i64) == 1:
            local_ty = "int64_t"
        // Array types need C's declarator syntax, including nested dimensions.
        if use_kind == TypeKind.TY_ARRAY:
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
        let start = body.bb_stmt_starts.get(bb as i64)
        let count = body.bb_stmt_counts.get(bb as i64)
        for si in 0..count:
            if self.check_interrupted() != 0:
                return ""
            out.write(self.line_directive(body, start + si))
            out.write(self.emit_stmt_line(body, start + si))
            out.write("\n")
        out.write(self.emit_term(body, bb))
        out.write("\n")
    // Emit stub labels for any BB indices referenced beyond block_count
    let max_ref = self.max_referenced_bb(body)
    var stub_bb = body.block_count()
    while stub_bb <= max_ref:
        out.write(f"bb{stub_bb}: ;\n")
        stub_bb = stub_bb + 1
    out.write(cc_rbrace() ++ "\n")
    out.finish()

fn CCodegen.max_referenced_bb(self: CCodegen, body: MirBody) -> i32:
    var max_bb = body.block_count() - 1
    for bb in 0..body.block_count():
        let tk = body.term_kind(bb)
        let d0 = body.term_data0(bb)
        let d1 = body.term_data1(bb)
        let d2 = body.term_data2(bb)
        let d3 = body.term_data3(bb)
        if d2 > max_bb: max_bb = d2
        if d3 > max_bb: max_bb = d3
        if tk == TermKind.TK_SWITCH_INT and d1 >= 0 and d1 < body.switch_table_starts.len() as i32:
            let start = body.switch_table_starts.get(d1 as i64)
            let count = body.switch_table_counts.get(d1 as i64)
            for i in 0..count:
                let tgt = body.switch_table_targets.get((start + i) as i64)
                if tgt > max_bb: max_bb = tgt
    max_bb

fn CCodegen.find_main_sym(self: CCodegen) -> i32:
    for i in 0..self.mir_mod.body_fn_syms.len() as i32:
        let sym = self.mir_mod.body_fn_syms.get(i as i64)
        if cc_intern_resolve(self.intern, sym) == "main":
            return sym
    0

fn CCodegen.uses_async_runtime(self: CCodegen) -> bool:
    for i in 0..self.mir_mod.body_fn_syms.len() as i32:
        let sym = self.mir_mod.body_fn_syms.get(i as i64)
        if self.sema.task_fns.contains(sym):
            return true
    false

fn CCodegen.emit_runtime_fiber_config_call(self: CCodegen) -> str:
    if not self.uses_async_runtime():
        return ""
    let stack_size = self.sema.runtime_fiber_stack_size
    let pool_size = self.sema.runtime_fiber_pool_size
    if stack_size <= 0 and pool_size <= 0:
        return ""
    "    if (with_runtime_configure_fibers(" ++ with_i64_to_str(stack_size) ++ "LL, " ++ with_i64_to_str(pool_size as i64) ++ ") != 0) {\n" ++
    "        with_panic(WITH_STR_LIT(\"runtime fiber configuration cannot change after fibers exist\"), WITH_STR_LIT(\"\"), 0);\n" ++
    "    }\n"

fn CCodegen.emit_main_wrapper(self: CCodegen) -> str:
    let main_sym = self.find_main_sym()
    if main_sym == 0:
        return ""
    let main_name = self.fn_c_name(main_sym)
    let sig_idx = self.sema.get_sig(main_sym)
    let ret_tid = if sig_idx >= 0: self.sema.sig_return_type(sig_idx) else: self.sema.ty_void
    var out = "int main(int argc, char** argv) " ++ cc_lbrace() ++ "\n"
    out = out ++ "    with_runtime_set_argv(argc, argv);\n"
    out = out ++ self.emit_runtime_fiber_config_call()
    out = out ++ "    with_runtime_init();\n"
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

fn CCodegen.emit_module(self: CCodegen) -> str:
    if self.check_interrupted() != 0:
        return ""
    let out = COut.new()
    out.write("/* Generated by with --emit-c (conservative MIR subset). */\n")
    out.write("#include <stdint.h>\n")
    out.write("#include <stdbool.h>\n")
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
    // Extra declarations for functions used by emitted C but not in with_runtime.h
    out.write("/* Extra runtime declarations */\n")
    out.write("#define fmt_buf_new with_fmt_buf_new\n")
    out.write("#define fmt_buf_write_str with_fmt_buf_write_str\n")
    out.write("#define fmt_buf_finish with_fmt_buf_finish\n")
    out.write("extern uint8_t* with_fmt_buf_new(void);\n")
    out.write("extern void with_fmt_buf_write_str(uint8_t*, with_str);\n")
    out.write("extern void with_fmt_buf_write_i64_spec(uint8_t*, int64_t, int32_t, int64_t, int32_t, int32_t, int32_t);\n")
    out.write("extern void with_fmt_buf_write_f64_spec(uint8_t*, double, int64_t, int32_t, int32_t, int32_t);\n")
    out.write("extern void with_fmt_buf_write_str_spec(uint8_t*, with_str, int64_t, int32_t, int32_t);\n")
    out.write("extern with_str with_fmt_buf_finish(uint8_t*);\n")
    if self.module_exports_c_name("with_alloc") == 0:
        out.write("extern void* with_alloc(int64_t);\n")
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
    out.write("extern int64_t with_clock_nanos(void);\n")
    out.write("extern int32_t with_nanosleep(int64_t);\n")
    out.write("extern double with_parse_float(with_str);\n")
    out.write("extern with_str with_sysinfo_os(void);\n")
    out.write("extern with_str with_sysinfo_arch(void);\n")
    out.write("extern with_str with_sysinfo_hostname(void);\n")
    out.write("extern with_str with_str_trim(with_str);\n")
    out.write("extern with_str with_str_clone(with_str);\n\n")
    out.write("extern with_str with_regex_error_message(int32_t);\n")
    out.write("extern const int8_t* with_regex_compile(with_str, int32_t, int32_t*, int32_t*);\n")
    out.write("extern const int8_t* with_regex_code_copy(const int8_t*);\n")
    out.write("extern void with_regex_code_free(const int8_t*);\n")
    out.write("extern int32_t with_regex_capture_count(const int8_t*);\n")
    out.write("extern const int32_t* with_regex_match_spans_alloc(const int8_t*, with_str, int32_t*);\n")
    out.write("extern const int32_t* with_regex_match_spans_alloc_at(const int8_t*, with_str, int32_t, int32_t*);\n")
    out.write("extern int32_t with_regex_capture_name_count(const int8_t*);\n")
    out.write("extern with_str with_regex_capture_name_at(const int8_t*, int32_t);\n")
    out.write("extern int32_t with_regex_group_name_to_index(const int8_t*, with_str);\n")
    out.write("extern with_str with_regex_substitute(const int8_t*, with_str, with_str, int32_t);\n\n")
    out.write("#ifdef WITH_BOOTSTRAP_TYPES_H\n")
    out.write("extern with_str with_str_concat(with_str, with_str);\n")
    out.write("extern with_str with_str_concat_n(const with_str*, int64_t);\n")
    out.write("extern with_str with_str_concat_n_move_first(const with_str*, int64_t);\n")
    out.write("extern int64_t with_str_len(with_str);\n")
    out.write("extern int32_t with_str_byte_at(with_str, int64_t);\n")
    out.write("extern int32_t with_str_contains_char(with_str, int32_t);\n")
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
    out.write("extern int32_t with_runtime_configure_fibers(int64_t, int32_t);\n")
    out.write("extern int32_t with_fiber_in_fiber(void);\n")
    out.write("extern void with_fiber_await(int32_t);\n")
    out.write("extern void with_fiber_cleanup_await(int32_t);\n")
    out.write("extern int32_t with_fiber_cancel(int32_t);\n")
    out.write("#endif\n")
    out.write("extern void with_fiber_panic_capture(const uint8_t*, int32_t);\n")
    out.write("\n")

    self.prepare_c_type_instantiations()
    if self.had_error != 0:
        return ""
    out.write(self.emit_struct_type_defs())
    if self.had_error != 0:
        return ""
    out.write(self.emit_global_var_defs())
    if self.had_error != 0:
        return ""
    out.write(self.emit_extern_fn_decls())
    if self.had_error != 0:
        return ""

    // Forward declarations for all lowered functions.
    for i in 0..self.mir_mod.bodies.len() as i32:
        if self.check_interrupted() != 0:
            return ""
        let body: MirBody = self.mir_mod.bodies.get(i as i64)
        if self.body_sig_index(body.fn_sym) < 0:
            continue
        out.write(self.emit_fn_decl(body))
        out.write(";\n")
    if self.mir_mod.bodies.len() as i32 > 0:
        out.write("\n")

    // Function bodies.
    for i in 0..self.mir_mod.bodies.len() as i32:
        if self.check_interrupted() != 0:
            return ""
        let body: MirBody = self.mir_mod.bodies.get(i as i64)
        out.write(self.emit_fn_body(body))
        out.write("\n")

    // C entrypoint wrapper for With `main`.
    out.write(self.emit_main_wrapper())
    out.finish()
