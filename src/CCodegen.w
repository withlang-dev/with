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

extern fn with_i64_to_str(n: i64) -> str
extern fn str_from_byte(b: i32) -> str
extern fn with_interrupt_requested() -> i32

fn cc_intern_resolve(intern: InternPool, sym: i32) -> str:
    intern.resolve_symbol(sym)

fn cc_intern_intern(intern: &mut InternPool, s: str) -> i32:
    intern.intern(s)

fn cc_lbrace -> str:
    str_from_byte(123)

fn cc_rbrace -> str:
    str_from_byte(125)

fn cc_pseudo_tid_vec -> i32:
    1900001

fn cc_place_kind_unknown -> i32:
    0

fn cc_place_kind_vec -> i32:
    1

fn cc_place_kind_hashmap -> i32:
    2

fn cc_place_kind_option -> i32:
    3

fn cc_builtin_none -> i32:
    0

fn cc_builtin_vec_new -> i32:
    1

fn cc_builtin_vec_push -> i32:
    2

fn cc_builtin_vec_get -> i32:
    3

fn cc_builtin_vec_len -> i32:
    4

fn cc_builtin_vec_set_i32 -> i32:
    5

fn cc_builtin_vec_remove -> i32:
    6

fn cc_builtin_vec_clear -> i32:
    7

fn cc_builtin_map_new -> i32:
    8

fn cc_builtin_map_insert -> i32:
    9

fn cc_builtin_map_get -> i32:
    10

fn cc_builtin_map_contains -> i32:
    11

fn cc_builtin_map_len -> i32:
    12

fn cc_builtin_map_remove -> i32:
    13

fn cc_builtin_opt_is_some -> i32:
    14

fn cc_builtin_opt_unwrap -> i32:
    15

fn cc_builtin_vec_pop -> i32:
    16

fn cc_builtin_str_len -> i32:
    17

fn cc_builtin_str_byte_at -> i32:
    18

fn cc_builtin_str_slice -> i32:
    19

fn cc_builtin_str_contains -> i32:
    20

fn cc_builtin_str_starts_with -> i32:
    21

fn cc_builtin_str_ends_with -> i32:
    22

fn cc_builtin_str_find -> i32:
    23

fn cc_builtin_map_clear -> i32:
    24

fn cc_builtin_veciter_next -> i32:
    25

fn cc_builtin_vec_iter -> i32:
    26

fn cc_builtin_opt_is_none -> i32:
    27

fn cc_builtin_str_split -> i32:
    28

fn cc_builtin_str_trim -> i32:
    29

fn cc_builtin_str_to_upper -> i32:
    30

fn cc_builtin_str_to_lower -> i32:
    31

fn cc_builtin_str_replace -> i32:
    32

fn cc_builtin_str_index_of -> i32:
    33

fn cc_builtin_map_increment -> i32:
    34

fn cc_builtin_vec_map -> i32:
    35

fn cc_builtin_vec_filter -> i32:
    36

fn cc_builtin_vec_fold -> i32:
    37

fn cc_builtin_vec_contains -> i32:
    38

fn cc_builtin_str_repeat -> i32:
    39

fn cc_builtin_arr_len -> i32:
    40

fn cc_builtin_generic_call -> i32:
    41

fn cc_builtin_vec_join -> i32:
    42

fn cc_builtin_dyn_vtable_cmp -> i32:
    43

fn cc_builtin_dyn_downcast -> i32:
    44

fn cc_builtin_opt_filter -> i32:
    45

fn cc_builtin_rotate_left -> i32:
    46

fn cc_builtin_rotate_right -> i32:
    47

fn cc_builtin_vec_with_capacity -> i32:
    48

fn cc_builtin_fmt_to_str -> i32:
    49

fn cc_builtin_fmt_debug_str -> i32:
    50

fn cc_builtin_fmt_debug -> i32:
    51

fn cc_builtin_fmt_spec -> i32:
    52

fn cc_builtin_int_swap_bytes -> i32:
    53

fn cc_builtin_min -> i32:
    59

fn cc_builtin_max -> i32:
    60

fn cc_builtin_abs -> i32:
    61

fn cc_builtin_fma -> i32:
    62

fn cc_builtin_popcount -> i32:
    55

fn cc_builtin_clz -> i32:
    56

fn cc_builtin_ctz -> i32:
    57

fn cc_builtin_bitreverse -> i32:
    58

fn cc_callee_hint_none -> i32:
    0

fn cc_callee_hint_vec_recv -> i32:
    1

fn cc_callee_hint_map_recv -> i32:
    2

fn cc_callee_hint_opt_recv -> i32:
    3

fn cc_callee_hint_vec_new -> i32:
    4

fn cc_callee_hint_map_new -> i32:
    5

fn cc_callee_hint_opt_new -> i32:
    6

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
    had_error: i32,
    err_msg: str,
    source_path: str,
    source_text: str,
    di_source: Source,
    last_line_directive: i32,
    body_fn_map: HashMap[i32, i32],
    body_fn_name_map: HashMap[str, i32],
    canonical_body_cache: HashMap[i32, i32],
    sig_idx_cache: HashMap[i32, i32],
    infer_local_depth: i32,
    active_local_body_fns: Vec[i32],
    active_local_ids: Vec[i32],
    active_method_syms: Vec[i32],
    active_method_args: Vec[i32],
    active_method_dests: Vec[i32],
    active_direct_args: Vec[i32],
    active_direct_dests: Vec[i32],
    direct_cache_body_fns: Vec[i32],
    direct_cache_args: Vec[i32],
    direct_cache_dests: Vec[i32],
    direct_cache_values: Vec[i32],
    method_cache_body_fns: Vec[i32],
    method_cache_syms: Vec[i32],
    method_cache_args: Vec[i32],
    method_cache_dests: Vec[i32],
    method_cache_values: Vec[i32],
    field_cache_struct_tids: Vec[i32],
    field_cache_syms: Vec[i32],
    field_cache_tids: Vec[i32],
    field_cache_ready: i32,
    in_field_cache_build: i32,
    local_infer_body_fns: Vec[i32],
    local_infer_ids: Vec[i32],
    local_infer_vals: Vec[i32],
    local_usage_hint_body_fns: Vec[i32],
    local_usage_hint_ids: Vec[i32],
    local_usage_hint_vals: Vec[i32],
    place_kind_cache_body_fns: Vec[i32],
    place_kind_cache_place_ids: Vec[i32],
    place_kind_cache_vals: Vec[i32],
    callee_hint_cache: HashMap[i32, i32],
}

fn CCodegen.intern_intern(self: CCodegen, s: str) -> i32:
    let intern = &mut self.intern
    cc_intern_intern(intern, s)

fn c_emit_module(mir_mod: MirModule, ast: AstPool, intern: InternPool, sema: Sema, source_path: str, source_text: str) -> CEmitResult:
    var cg = CCodegen {
        mir_mod,
        ast,
        intern,
        sema,
        had_error: 0,
        err_msg: "",
        source_path,
        source_text,
        di_source: Source.from_string(source_path, source_text, 0),
        last_line_directive: 0,
        body_fn_map: HashMap.new(),
        body_fn_name_map: HashMap.new(),
        canonical_body_cache: HashMap.new(),
        sig_idx_cache: HashMap.new(),
        infer_local_depth: 0,
        active_local_body_fns: Vec.new(),
        active_local_ids: Vec.new(),
        active_method_syms: Vec.new(),
        active_method_args: Vec.new(),
        active_method_dests: Vec.new(),
        active_direct_args: Vec.new(),
        active_direct_dests: Vec.new(),
        direct_cache_body_fns: Vec.new(),
        direct_cache_args: Vec.new(),
        direct_cache_dests: Vec.new(),
        direct_cache_values: Vec.new(),
        method_cache_body_fns: Vec.new(),
        method_cache_syms: Vec.new(),
        method_cache_args: Vec.new(),
        method_cache_dests: Vec.new(),
        method_cache_values: Vec.new(),
        field_cache_struct_tids: Vec.new(),
        field_cache_syms: Vec.new(),
        field_cache_tids: Vec.new(),
        field_cache_ready: 0,
        in_field_cache_build: 0,
        local_infer_body_fns: Vec.new(),
        local_infer_ids: Vec.new(),
        local_infer_vals: Vec.new(),
        local_usage_hint_body_fns: Vec.new(),
        local_usage_hint_ids: Vec.new(),
        local_usage_hint_vals: Vec.new(),
        place_kind_cache_body_fns: Vec.new(),
        place_kind_cache_place_ids: Vec.new(),
        place_kind_cache_vals: Vec.new(),
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
    var out = ""
    for i in 0..text.len():
        let b = text.byte_at(i as i64)
        if b == 92: // '\'
            out = out ++ "\\\\"
            continue
        if b == 34: // '"'
            out = out ++ "\\\""
            continue
        if b == 10:
            out = out ++ "\\n"
            continue
        if b == 13:
            out = out ++ "\\r"
            continue
        if b == 9:
            out = out ++ "\\t"
            continue
        if b >= 32 and b <= 126:
            out = out ++ text.slice(i as i64, (i + 1) as i64)
            continue
        let hi = b / 16
        let lo = b % 16
        out = out ++ "\\x" ++ cc_hex_digit(hi) ++ cc_hex_digit(lo)
    out

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

fn cc_str_find_last_char(text: str, ch: i32) -> i32:
    var i = text.len() as i32 - 1
    while i >= 0:
        if text.byte_at(i as i64) == ch:
            return i
        i = i - 1
    0 - 1

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

fn cc_name_matches(raw: str, wanted: str) -> i32:
    if raw == wanted:
        return 1
    cc_str_ends_with(raw, "." ++ wanted)

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
    if name == "set_i32" or name == "remove" or name == "clear" or name == "pop":
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

fn CCodegen.fn_c_name(self: CCodegen, fn_sym: i32) -> str:
    if fn_sym == 0:
        return "sym0"
    let raw = cc_intern_resolve(self.intern, fn_sym)
    let id = cc_sanitize_ident(raw)
    if id == "main":
        return f"__with_main__{fn_sym}"
    f"{id}__{fn_sym}"

fn CCodegen.extern_sym_c_name(self: CCodegen, fn_sym: i32) -> str:
    if fn_sym == 0:
        return "sym0"
    let raw = cc_intern_resolve(self.intern, fn_sym)
    if raw.len() == 0:
        return "sym0"
    cc_sanitize_ident(raw)

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
    let name_sym = self.sema.get_type_d0(resolved)
    let raw = cc_intern_resolve(self.intern, name_sym)
    if raw.len() == 0:
        return f"with_struct_{resolved as i32}"
    let out = cc_sanitize_ident(raw)
    if self.check_interrupted() != 0:
        return "with_interrupted"
    out

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
            if tk == TypeKind.TY_STRUCT:
                let ft_raw = self.struct_field_tid(resolved as i32, pd)
                let ft = self.effective_field_tid(resolved as i32, pd, ft_raw)
                if ft == 0:
                    return 0
                tid = ft
                continue
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
            return 0
        if pk == ProjKind.PK_DEREF:
            if tk == TypeKind.TY_PTR or tk == TypeKind.TY_REF:
                tid = self.sema.get_type_d0(resolved)
                continue
            return 0
        if pk == ProjKind.PK_DOWNCAST:
            continue
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
            if tk == TypeKind.TY_STRUCT:
                let ft_raw = self.struct_field_tid(resolved as i32, pd)
                let ft = self.effective_field_tid(resolved as i32, pd, ft_raw)
                if ft == 0:
                    return 0
                tid = ft
                continue
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
            return 0
        if pk == ProjKind.PK_DEREF:
            if tk == TypeKind.TY_PTR or tk == TypeKind.TY_REF:
                tid = self.sema.get_type_d0(resolved)
                continue
            return 0
        if pk == ProjKind.PK_DOWNCAST:
            continue
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
    if tid == cc_pseudo_tid_vec():
        return "with_vec"
    let resolved = self.sema.resolve_alias(tid)
    if resolved == cc_pseudo_tid_vec():
        return "with_vec"
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
        return self.struct_c_name(resolved)
    if tk == TypeKind.TY_ENUM:
        return "int32_t"
    if tk == TypeKind.TY_PTR or tk == TypeKind.TY_REF:
        let inner_tid = self.sema.get_type_d0(resolved)
        var base = self.c_type(inner_tid, 0)
        if base == "void":
            base = "uint8_t"
        if tk == TypeKind.TY_REF and self.sema.get_type_d1(resolved) == 0:
            return "const " ++ base ++ "*"
        return base ++ "*"
    // Conservative fallback for currently unsupported higher-level layouts.
    "int64_t"

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
    if self.in_field_cache_build != 0:
        return declared
    let sig_idx = self.body_sig_index(body.fn_sym)
    let param_count = if sig_idx >= 0: self.sema.sig_get_param_count(sig_idx) else: 0
    if local_id <= param_count:
        return declared
    let declared_resolved = self.sema.resolve_alias(declared)
    let declared_kind = self.sema.get_type_kind(declared_resolved)
    let inferred = self.infer_local_tid(body, local_id)
    if self.is_void_tid(declared) == 0 and (declared_resolved == 0 or declared_kind != TypeKind.TY_ERR):
        if inferred != 0 and self.is_void_tid(inferred) == 0:
            let inferred_resolved = self.sema.resolve_alias(inferred)
            let inferred_kind = self.sema.get_type_kind(inferred_resolved)
            if declared_kind != inferred_kind:
                return inferred
            if self.strict_type_match(declared, inferred) == 0:
                return inferred
        return declared
    if inferred != 0 and self.is_void_tid(inferred) == 0:
        return inferred
    declared

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
    var out = f"_{base_local}"
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
            else:
                current_tid = 0
            continue
        if pk == ProjKind.PK_INDEX:
            if tk == TypeKind.TY_STR:
                out = f"{out}.ptr[_{pd}]"
                current_tid = self.sema.ty_i32 as i32
                continue
            out = f"{out}[_{pd}]"
            if tk == TypeKind.TY_ARRAY or tk == TypeKind.TY_SLICE:
                current_tid = self.sema.get_type_d0(resolved)
            else:
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
            out = f"{out}/*downcast{pd}*/"
            current_tid = 0
            continue
        self.fail(f"unsupported place projection kind {pk}")
    out

fn cc_hex_digit(nibble: i32) -> str:
    if nibble < 10:
        return str_from_byte(48 + nibble)
    str_from_byte(87 + nibble)

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
        let text = if cd != 0: cc_intern_resolve(self.intern, cd) else: ""
        return "WITH_STR_LIT(\"" ++ cc_escape_c_string(text) ++ "\")"
    if ck == ConstKind.CK_UNIT:
        return "0"
    if ck == ConstKind.CK_FLOAT:
        if cd != 0:
            let lit = cc_intern_resolve(self.intern, cd)
            if lit.len() > 0:
                return lit
        return "0.0"
    if ck == ConstKind.CK_ZERO_SIZED:
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
    if rk == RvalueKind.RK_BIN_OP:
        let lhs = self.operand_text(body, d1)
        let rhs = self.operand_text(body, d2)
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
        let tok = self.binop_token(d0)
        if tok.len() == 0:
            self.fail(f"unsupported binop {d0}")
            return "0"
        return "(" ++ lhs ++ " " ++ tok ++ " " ++ rhs ++ ")"
    if rk == RvalueKind.RK_UN_OP:
        let inner = self.operand_text(body, d1)
        if d0 == UnaryOp.UOP_NEGATE:
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
        return "((" ++ self.c_type(d1, 0) ++ ")(" ++ self.operand_text(body, d0) ++ "))"
    if rk == RvalueKind.RK_DISCRIMINANT:
        return "(" ++ self.place_text(body, d0) ++ ").tag"
    if rk == RvalueKind.RK_LEN:
        let p = self.place_text(body, d0)
        let pt = self.place_tid(body, d0)
        if pt == cc_pseudo_tid_vec():
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
                if cand == 0 - 2:
                    return 0 - 2
            else:
                continue
            if cand <= 0:
                continue
            if out == 0:
                out = cand
                continue
            if out != cand:
                return 0 - 2
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
        return 0 - 1
    let first_arg = self.call_arg_operand(body, args_id, 0)
    if first_arg < 0 or first_arg >= body.operand_kinds.len() as i32:
        return 0 - 1
    let ok = body.operand_kinds.get(first_arg as i64)
    if ok != OperandKind.OK_COPY and ok != OperandKind.OK_MOVE:
        return 0 - 1
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

fn CCodegen.place_kind_cache_lookup(self: CCodegen, body_fn_sym: i32, place_id: i32) -> i32:
    for i in 0..self.place_kind_cache_body_fns.len() as i32:
        if self.place_kind_cache_body_fns.get(i as i64) != body_fn_sym:
            continue
        if self.place_kind_cache_place_ids.get(i as i64) != place_id:
            continue
        return self.place_kind_cache_vals.get(i as i64)
    0 - 1234567

fn CCodegen.place_kind_cache_store(self: CCodegen, body_fn_sym: i32, place_id: i32, kind: i32):
    self.place_kind_cache_body_fns.push(body_fn_sym)
    self.place_kind_cache_place_ids.push(place_id)
    self.place_kind_cache_vals.push(kind)

fn CCodegen.callee_hint_cache_lookup(self: CCodegen, fn_sym: i32) -> i32:
    if self.callee_hint_cache.contains(fn_sym):
        let v = self.callee_hint_cache.get(fn_sym)
        if v.is_some():
            return v.unwrap()
    0 - 1234567

fn CCodegen.callee_hint_cache_store(self: CCodegen, fn_sym: i32, kind: i32):
    self.callee_hint_cache.insert(fn_sym, kind)

fn CCodegen.callee_field_hint(self: CCodegen, fn_sym: i32) -> i32:
    if fn_sym == 0:
        return cc_callee_hint_none()
    let cache_hit = self.callee_hint_cache_lookup(fn_sym)
    if cache_hit != 0 - 1234567:
        return cache_hit

    let raw = cc_intern_resolve(self.intern, fn_sym)
    let base = cc_base_name(raw)
    let owner = cc_owner_prefix(raw)
    var out = cc_callee_hint_none()

    if base == "new":
        if cc_str_contains(owner, "HashMap") != 0 or cc_str_contains(raw, "HashMap") != 0:
            out = cc_callee_hint_map_new()
        else if cc_str_contains(owner, "Vec") != 0 or cc_str_contains(raw, "Vec") != 0:
            out = cc_callee_hint_vec_new()
        else if cc_str_contains(owner, "Option") != 0 or cc_str_contains(raw, "Option") != 0:
            out = cc_callee_hint_opt_new()
    else if owner.len() > 0:
        if cc_str_contains(owner, "HashMap") != 0:
            if base == "insert" or base == "get" or base == "contains" or base == "len" or base == "remove":
                out = cc_callee_hint_map_recv()
        else if cc_str_contains(owner, "Vec") != 0:
            if base == "push" or base == "get" or base == "len" or base == "set_i32" or base == "remove" or base == "clear" or base == "pop":
                out = cc_callee_hint_vec_recv()
        else if cc_str_contains(owner, "Option") != 0:
            if base == "is_some" or base == "unwrap":
                out = cc_callee_hint_opt_recv()

    self.callee_hint_cache_store(fn_sym, out)
    out

fn CCodegen.infer_place_kind_impl(self: CCodegen, body: MirBody, place_id: i32) -> i32:
    if place_id < 0 or place_id >= body.place_locals.len() as i32:
        return cc_place_kind_unknown()

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
        if method == "get" or method == "len":
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
        return cc_place_kind_unknown()
    if vec_score >= map_score and vec_score >= opt_score:
        return cc_place_kind_vec()
    if map_score >= opt_score:
        return cc_place_kind_hashmap()
    cc_place_kind_option()

fn CCodegen.infer_place_kind(self: CCodegen, body: MirBody, place_id: i32) -> i32:
    let cache_hit = self.place_kind_cache_lookup(body.fn_sym, place_id)
    if cache_hit != 0 - 1234567:
        return cache_hit
    let kind = self.infer_place_kind_impl(body, place_id)
    self.place_kind_cache_store(body.fn_sym, place_id, kind)
    kind

fn CCodegen.local_place_kind_depth(self: CCodegen, body: MirBody, local_id: i32, depth: i32) -> i32:
    if local_id < 0:
        return cc_place_kind_unknown()
    if depth > 1:
        return cc_place_kind_unknown()

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
        if method == "get" or method == "len":
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
                if k == cc_place_kind_vec():
                    vec_score = vec_score + 2
                else if k == cc_place_kind_hashmap():
                    map_score = map_score + 2
                else if k == cc_place_kind_option():
                    opt_score = opt_score + 2
            if dst_local == local_id:
                let k = self.local_place_kind_depth(body, src_local, depth + 1)
                if k == cc_place_kind_vec():
                    vec_score = vec_score + 2
                else if k == cc_place_kind_hashmap():
                    map_score = map_score + 2
                else if k == cc_place_kind_option():
                    opt_score = opt_score + 2

    if vec_score <= 0 and map_score <= 0 and opt_score <= 0:
        return cc_place_kind_unknown()
    if vec_score >= map_score and vec_score >= opt_score:
        return cc_place_kind_vec()
    if map_score >= opt_score:
        return cc_place_kind_hashmap()
    cc_place_kind_option()

fn CCodegen.local_place_kind(self: CCodegen, body: MirBody, local_id: i32) -> i32:
    self.local_place_kind_depth(body, local_id, 0)

fn CCodegen.call_dest_expected_tid(self: CCodegen, body: MirBody, dest_place: i32) -> i32:
    let dest_tid = self.place_local_tid(body, dest_place)
    if self.in_field_cache_build != 0:
        return dest_tid
    if dest_tid == cc_pseudo_tid_vec():
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
    var match_score = 0 - 1
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
    self.infer_named_call_sym_scan(body, fn_sym, args_id, dest_place, 1)

fn CCodegen.infer_body_method_sym(self: CCodegen, body: MirBody, fn_sym: i32, args_id: i32, dest_place: i32) -> i32:
    let raw = cc_intern_resolve(self.intern, fn_sym)
    if raw.len() == 0:
        return 0
    let base_name = cc_base_name(raw)
    let argc = self.call_arg_count(body, args_id)
    let want_ret_tid = self.call_dest_expected_tid(body, dest_place)
    let first_owner = self.type_owner_text(self.call_first_arg_resolved_tid(body, args_id))
    var match_sym = 0
    var match_score = 0 - 1
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
    match_sym

fn CCodegen.infer_direct_call_sym_scan(self: CCodegen, body: MirBody, args_id: i32, dest_place: i32, only_local_defs: i32) -> i32:
    let arg_count = self.call_arg_count(body, args_id)
    let want_ret_tid = self.call_dest_expected_tid(body, dest_place)
    var match_sym = 0
    var match_score = 0 - 1
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

fn CCodegen.method_infer_push(self: CCodegen, method_sym: i32, args_id: i32, dest_place: i32):
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

fn CCodegen.direct_infer_push(self: CCodegen, args_id: i32, dest_place: i32):
    self.active_direct_args.push(args_id)
    self.active_direct_dests.push(dest_place)

fn CCodegen.direct_infer_pop(self: CCodegen):
    if self.active_direct_args.len() as i32 == 0:
        return
    self.active_direct_args.pop()
    self.active_direct_dests.pop()

fn CCodegen.direct_cache_lookup(self: CCodegen, body_fn_sym: i32, args_id: i32, dest_place: i32) -> i32:
    for i in 0..self.direct_cache_body_fns.len() as i32:
        if self.direct_cache_body_fns.get(i as i64) != body_fn_sym:
            continue
        if self.direct_cache_args.get(i as i64) != args_id:
            continue
        if self.direct_cache_dests.get(i as i64) != dest_place:
            continue
        return self.direct_cache_values.get(i as i64)
    0 - 1234567

fn CCodegen.direct_cache_store(self: CCodegen, body_fn_sym: i32, args_id: i32, dest_place: i32, value: i32):
    self.direct_cache_body_fns.push(body_fn_sym)
    self.direct_cache_args.push(args_id)
    self.direct_cache_dests.push(dest_place)
    self.direct_cache_values.push(value)

fn CCodegen.method_cache_lookup(self: CCodegen, body_fn_sym: i32, method_sym: i32, args_id: i32, dest_place: i32) -> i32:
    for i in 0..self.method_cache_body_fns.len() as i32:
        if self.method_cache_body_fns.get(i as i64) != body_fn_sym:
            continue
        if self.method_cache_syms.get(i as i64) != method_sym:
            continue
        if self.method_cache_args.get(i as i64) != args_id:
            continue
        if self.method_cache_dests.get(i as i64) != dest_place:
            continue
        return self.method_cache_values.get(i as i64)
    0 - 1234567

fn CCodegen.method_cache_store(self: CCodegen, body_fn_sym: i32, method_sym: i32, args_id: i32, dest_place: i32, value: i32):
    self.method_cache_body_fns.push(body_fn_sym)
    self.method_cache_syms.push(method_sym)
    self.method_cache_args.push(args_id)
    self.method_cache_dests.push(dest_place)
    self.method_cache_values.push(value)

fn CCodegen.field_cache_lookup(self: CCodegen, struct_tid: i32, field_sym: i32) -> i32:
    for i in 0..self.field_cache_struct_tids.len() as i32:
        if self.field_cache_struct_tids.get(i as i64) != struct_tid:
            continue
        if self.field_cache_syms.get(i as i64) != field_sym:
            continue
        return self.field_cache_tids.get(i as i64)
    0 - 1234567

fn CCodegen.field_cache_store(self: CCodegen, struct_tid: i32, field_sym: i32, tid: i32):
    self.field_cache_struct_tids.push(struct_tid)
    self.field_cache_syms.push(field_sym)
    self.field_cache_tids.push(tid)

fn CCodegen.field_cache_record(self: CCodegen, struct_tid: i32, field_sym: i32, tid: i32):
    if tid == 0 or self.is_void_tid(tid) != 0:
        return
    if self.field_cache_lookup(struct_tid, field_sym) != 0 - 1234567:
        return
    self.field_cache_store(struct_tid, field_sym, self.sema.resolve_alias(tid))

fn CCodegen.local_infer_cache_lookup(self: CCodegen, body_fn_sym: i32, local_id: i32) -> i32:
    for i in 0..self.local_infer_body_fns.len() as i32:
        if self.local_infer_body_fns.get(i as i64) != body_fn_sym:
            continue
        if self.local_infer_ids.get(i as i64) != local_id:
            continue
        return self.local_infer_vals.get(i as i64)
    0 - 1234567

fn CCodegen.local_infer_cache_store(self: CCodegen, body_fn_sym: i32, local_id: i32, tid: i32):
    self.local_infer_body_fns.push(body_fn_sym)
    self.local_infer_ids.push(local_id)
    self.local_infer_vals.push(tid)

fn CCodegen.local_usage_hint_cache_lookup(self: CCodegen, body_fn_sym: i32, local_id: i32) -> i32:
    for i in 0..self.local_usage_hint_body_fns.len() as i32:
        if self.local_usage_hint_body_fns.get(i as i64) != body_fn_sym:
            continue
        if self.local_usage_hint_ids.get(i as i64) != local_id:
            continue
        return self.local_usage_hint_vals.get(i as i64)
    0 - 1234567

fn CCodegen.local_usage_hint_cache_store(self: CCodegen, body_fn_sym: i32, local_id: i32, tid: i32):
    self.local_usage_hint_body_fns.push(body_fn_sym)
    self.local_usage_hint_ids.push(local_id)
    self.local_usage_hint_vals.push(tid)

fn CCodegen.local_usage_hint_tid(self: CCodegen, body: MirBody, local_id: i32) -> i32:
    if local_id < 0:
        return 0
    let cache_hit = self.local_usage_hint_cache_lookup(body.fn_sym, local_id)
    if cache_hit != 0 - 1234567:
        return cache_hit
    var hint_tid = 0

    // Prefer concrete typed use-sites where this local flows into a known call parameter.
    for bb in 0..body.block_count():
        if body.term_kind(bb) != TermKind.TK_CALL:
            continue
        let callee_operand = body.term_data0(bb)
        let args_id = body.term_data1(bb)
        var sig_idx = 0 - 1
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
    let cache_hit = self.direct_cache_lookup(body.fn_sym, args_id, dest_place)
    if cache_hit != 0 - 1234567:
        return cache_hit
    if self.direct_infer_active(args_id, dest_place) != 0:
        self.direct_cache_store(body.fn_sym, args_id, dest_place, 0)
        return 0
    self.direct_infer_push(args_id, dest_place)
    let local_scan = self.infer_direct_call_sym_scan(body, args_id, dest_place, 1)
    var result = 0
    if local_scan == 0 - 2 or local_scan > 0:
        result = local_scan
    else:
        result = self.infer_direct_call_sym_scan(body, args_id, dest_place, 0)
    self.direct_infer_pop()
    self.direct_cache_store(body.fn_sym, args_id, dest_place, result)
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
    var match_score = 0 - 1
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
    let cache_hit = self.method_cache_lookup(body.fn_sym, method_sym, args_id, dest_place)
    if cache_hit != 0 - 1234567:
        return cache_hit
    if self.method_infer_active(method_sym, args_id, dest_place) != 0:
        self.method_cache_store(body.fn_sym, method_sym, args_id, dest_place, 0)
        return 0
    self.method_infer_push(method_sym, args_id, dest_place)
    let local_scan = self.infer_qualified_method_sym_scan(body, method_sym, args_id, dest_place, 1)
    var result = 0
    if local_scan == 0 - 2 or local_scan > 0:
        result = local_scan
    else:
        result = self.infer_qualified_method_sym_scan(body, method_sym, args_id, dest_place, 0)
    self.method_infer_pop()
    self.method_cache_store(body.fn_sym, method_sym, args_id, dest_place, result)
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
    var match_score = 0 - 1
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
    let local = self.infer_owner_method_sym_scan(body, fn_sym, args_id, dest_place, 1)
    if local > 0:
        return local
    self.infer_owner_method_sym_scan(body, fn_sym, args_id, dest_place, 0)

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

    var out = 0 - 1
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
            var match_idx = 0 - 1
            for si in 0..self.sema.sig_names.len() as i32:
                let sym_text = cc_intern_resolve(self.intern, self.sema.sig_names.get(si as i64))
                if sym_text != raw:
                    continue
                if match_idx < 0:
                    match_idx = si
                else:
                    match_idx = 0 - 2
                    break
            if match_idx >= 0:
                out = match_idx
        if out < 0 and cc_str_contains_dot(raw) == 0:
            let wanted = "." ++ raw
            var match_idx = 0 - 1
            for si in 0..self.sema.sig_names.len() as i32:
                let sym_text = cc_intern_resolve(self.intern, self.sema.sig_names.get(si as i64))
                if cc_str_ends_with(sym_text, wanted) == 0:
                    continue
                if match_idx < 0:
                    match_idx = si
                else:
                    match_idx = 0 - 2
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

fn CCodegen.call_builtin_kind(self: CCodegen, body: MirBody, callee_operand: i32, args_id: i32, dest_place: i32) -> i32:
    let method = self.call_method_base_name(body, callee_operand)
    if method.len() == 0:
        return cc_builtin_none()

    let callee_sym = self.call_callee_fn_sym(body, callee_operand)
    let callee_hint = self.callee_field_hint(callee_sym)
    let first_owner = self.type_owner_text(self.call_first_arg_resolved_tid(body, args_id))
    let recv_is_vec =
        if callee_hint == cc_callee_hint_vec_recv():
            1
        else if cc_str_contains(first_owner, "Vec") != 0:
            1
        else:
            0
    let recv_is_map =
        if callee_hint == cc_callee_hint_map_recv():
            1
        else if cc_str_contains(first_owner, "HashMap") != 0:
            1
        else:
            0
    let recv_is_opt =
        if callee_hint == cc_callee_hint_opt_recv():
            1
        else if cc_str_contains(first_owner, "Option") != 0:
            1
        else:
            0

    if method == "new":
        var dst_kind = self.infer_place_kind(body, dest_place)
        if dst_kind == cc_place_kind_unknown():
            let dst_local = self.place_local_id(body, dest_place)
            if dst_local >= 0:
                dst_kind = self.local_place_kind(body, dst_local)
        if dst_kind == cc_place_kind_vec():
            return cc_builtin_vec_new()
        if dst_kind == cc_place_kind_hashmap():
            return cc_builtin_map_new()
        if callee_hint == cc_callee_hint_vec_new():
            return cc_builtin_vec_new()
        if callee_hint == cc_callee_hint_map_new():
            return cc_builtin_map_new()
        let hinted = self.call_dest_expected_tid(body, dest_place)
        if hinted == cc_pseudo_tid_vec():
            return cc_builtin_vec_new()
        return cc_builtin_none()

    let argc = self.call_arg_count(body, args_id)
    if argc <= 0:
        return cc_builtin_none()

    let first_place = self.call_first_arg_place_id(body, args_id)
    let place_kind = if first_place >= 0: self.infer_place_kind(body, first_place) else: cc_place_kind_unknown()
    let first_tid = self.sema.resolve_alias(self.call_first_arg_resolved_tid(body, args_id))
    let first_tk = self.sema.get_type_kind(first_tid)
    let recv_kind_is_vec = if place_kind == cc_place_kind_vec() or recv_is_vec != 0: 1 else: 0
    let recv_kind_is_map = if place_kind == cc_place_kind_hashmap() or recv_is_map != 0: 1 else: 0
    let recv_kind_is_opt = if recv_is_opt != 0: 1 else: 0

    if method == "push":
        if recv_kind_is_vec != 0:
            return cc_builtin_vec_push()
        return cc_builtin_none()
    if method == "set_i32":
        if recv_kind_is_vec != 0:
            return cc_builtin_vec_set_i32()
        return cc_builtin_none()
    if method == "clear":
        if recv_kind_is_vec != 0:
            return cc_builtin_vec_clear()
        return cc_builtin_none()
    if method == "pop":
        if recv_kind_is_vec != 0:
            return cc_builtin_vec_pop()
        return cc_builtin_none()
    if method == "insert":
        if recv_kind_is_map != 0:
            return cc_builtin_map_insert()
        return cc_builtin_none()
    if method == "is_some":
        if recv_kind_is_opt != 0:
            return cc_builtin_opt_is_some()
        return cc_builtin_none()
    if method == "unwrap":
        if recv_kind_is_opt != 0:
            return cc_builtin_opt_unwrap()
        return cc_builtin_none()

    if method == "get":
        if recv_kind_is_map != 0:
            return cc_builtin_map_get()
        if recv_kind_is_vec != 0:
            return cc_builtin_vec_get()
        return cc_builtin_none()

    if method == "len":
        if first_tk == TypeKind.TY_STR:
            return cc_builtin_none()
        if recv_kind_is_map != 0:
            return cc_builtin_map_len()
        if recv_kind_is_vec != 0:
            return cc_builtin_vec_len()
        return cc_builtin_none()

    if method == "contains":
        if first_tk == TypeKind.TY_STR:
            return cc_builtin_none()
        if recv_kind_is_map != 0:
            return cc_builtin_map_contains()
        return cc_builtin_none()

    if method == "remove":
        if recv_kind_is_map != 0:
            return cc_builtin_map_remove()
        if recv_kind_is_vec != 0:
            return cc_builtin_vec_remove()
        return cc_builtin_none()

    cc_builtin_none()

fn CCodegen.call_builtin_ret_tid(self: CCodegen, body: MirBody, callee_operand: i32, args_id: i32, dest_place: i32) -> i32:
    let mir_intrinsic = body.call_intrinsic(args_id)
    var kind = cc_builtin_from_mir_intrinsic(mir_intrinsic)
    if kind == cc_builtin_none():
        kind = self.call_builtin_kind(body, callee_operand, args_id, dest_place)
    if kind == cc_builtin_none():
        return 0
    if kind == cc_builtin_vec_new():
        return cc_pseudo_tid_vec()
    if kind == cc_builtin_vec_push() or kind == cc_builtin_vec_set_i32() or kind == cc_builtin_vec_remove() or kind == cc_builtin_vec_clear():
        return self.sema.ty_void as i32
    if kind == cc_builtin_vec_pop():
        let hinted = self.call_dest_expected_tid(body, dest_place)
        if hinted != 0 and self.is_void_tid(hinted) == 0:
            return hinted
        let dst = self.place_local_tid(body, dest_place)
        if dst != 0 and self.is_void_tid(dst) == 0:
            return dst
        return self.sema.ty_i64 as i32
    if kind == cc_builtin_vec_get():
        let hinted = self.call_dest_expected_tid(body, dest_place)
        if hinted != 0 and self.is_void_tid(hinted) == 0:
            return hinted
        let dst = self.place_local_tid(body, dest_place)
        if dst != 0 and self.is_void_tid(dst) == 0:
            return dst
        return self.sema.ty_i64 as i32
    if kind == cc_builtin_vec_len():
        return self.sema.ty_i64 as i32
    if kind == cc_builtin_map_new():
        return self.sema.ty_i64 as i32
    if kind == cc_builtin_map_insert():
        return self.sema.ty_void as i32
    if kind == cc_builtin_map_get():
        let hinted = self.call_dest_expected_tid(body, dest_place)
        if hinted != 0 and self.is_void_tid(hinted) == 0:
            return hinted
        let dst = self.place_local_tid(body, dest_place)
        if dst != 0 and self.is_void_tid(dst) == 0:
            return dst
        return self.sema.ty_i64 as i32
    if kind == cc_builtin_map_contains():
        return self.sema.ty_bool as i32
    if kind == cc_builtin_map_len():
        return self.sema.ty_i64 as i32
    if kind == cc_builtin_map_remove():
        return self.sema.ty_bool as i32
    if kind == cc_builtin_opt_is_some():
        return self.sema.ty_bool as i32
    if kind == cc_builtin_opt_unwrap():
        let hinted = self.call_dest_expected_tid(body, dest_place)
        if hinted != 0 and self.is_void_tid(hinted) == 0:
            return hinted
        let dst = self.place_local_tid(body, dest_place)
        if dst != 0 and self.is_void_tid(dst) == 0:
            return dst
        return self.sema.ty_i64 as i32
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
    if inferred_method == 0 - 2:
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
    if callee_operand < 0 or callee_operand >= body.operand_kinds.len() as i32:
        self.fail(f"invalid call callee operand id {callee_operand}")
        return "/*invalid_callee*/"

    let ok = body.operand_kinds.get(callee_operand as i64)
    let od = body.operand_d0.get(callee_operand as i64)
    if ok == OperandKind.OK_COPY or ok == OperandKind.OK_MOVE:
        let local_id = self.place_local_id(body, od)
        if local_id >= 0 and self.place_is_direct_local(body, od, local_id) != 0:
            let local_fn_sym = self.local_assigned_fn_sym(body, local_id)
            if local_fn_sym == 0 - 2:
                return "/*ambiguous_call*/"
            if local_fn_sym > 0:
                return self.resolve_call_named_callee(body, local_fn_sym, args_id, dest_place)
        let callee_tid = self.sema.resolve_alias(self.operand_tid_no_infer(body, callee_operand))
        if self.sema.get_type_kind(callee_tid) == TypeKind.TY_FN:
            return self.place_text(body, od)
        let inferred = self.infer_direct_call_sym(body, args_id, dest_place)
        if inferred == 0 - 2:
            return "/*ambiguous_call*/"
        if inferred > 0:
            let inferred_body_sym = self.canonical_body_sym(inferred)
            if inferred_body_sym != 0:
                return self.fn_c_name(inferred_body_sym)
            return self.extern_call_name(inferred, body, args_id, dest_place)
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
        if inferred == 0 - 2:
            return "/*ambiguous_call*/"
        if inferred > 0:
            let inferred_body_sym = self.canonical_body_sym(inferred)
            if inferred_body_sym != 0:
                return self.fn_c_name(inferred_body_sym)
            return self.extern_call_name(inferred, body, args_id, dest_place)
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
        let callee_tid = self.sema.resolve_alias(self.operand_tid(body, callee_operand))
        if self.sema.get_type_kind(callee_tid) == TypeKind.TY_FN:
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
            if allow_container_receiver_infer != 0 and self.place_is_direct_local(body, recv_place, local_id) != 0:
                let kind = self.call_builtin_kind(body, callee_operand, args_id, dest_place)
                if kind == cc_builtin_vec_new() or kind == cc_builtin_vec_push() or kind == cc_builtin_vec_get() or kind == cc_builtin_vec_len() or kind == cc_builtin_vec_set_i32() or kind == cc_builtin_vec_remove() or kind == cc_builtin_vec_clear() or kind == cc_builtin_vec_pop():
                    if recv_hint == 0:
                        recv_hint = cc_pseudo_tid_vec()
                if kind == cc_builtin_map_new() or kind == cc_builtin_map_insert() or kind == cc_builtin_map_get() or kind == cc_builtin_map_contains() or kind == cc_builtin_map_len() or kind == cc_builtin_map_remove():
                    if recv_hint == 0:
                        recv_hint = self.sema.ty_i64 as i32
                if kind == cc_builtin_opt_is_some() or kind == cc_builtin_opt_unwrap():
                    if recv_hint == 0:
                        recv_hint = self.sema.ty_i64 as i32
            if self.place_is_direct_local(body, dest_place, local_id) != 0:
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
    if cache_hit != 0 - 1234567:
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

fn CCodegen.call_args_text(self: CCodegen, body: MirBody, args_id: i32) -> str:
    if args_id < 0 or args_id >= body.call_arg_starts.len() as i32:
        return ""
    let start = body.call_arg_starts.get(args_id as i64)
    let count = body.call_arg_counts.get(args_id as i64)
    // Resolve callee signature to know which params expect pointers
    let callee_sig = self.call_args_callee_sig(body, args_id)
    var out = ""
    for i in 0..count:
        if i > 0:
            out = out ++ ", "
        let op_id = body.call_arg_operands.get((start + i) as i64)
        let arg_text = self.operand_text(body, op_id)
        // If the argument is a struct value but the callee expects a pointer, emit &
        let arg_tid = self.operand_tid(body, op_id)
        let arg_resolved = self.sema.resolve_alias(arg_tid)
        let arg_tk = self.sema.get_type_kind(arg_resolved)
        if arg_tk == TypeKind.TY_STRUCT:
            // Check if callee param is a pointer type
            var param_is_ptr = 0
            if callee_sig >= 0 and i < self.sema.sig_get_param_count(callee_sig):
                let p_tid = self.sema.sig_param_type(callee_sig, i)
                let p_resolved = self.sema.resolve_alias(p_tid)
                let p_tk = self.sema.get_type_kind(p_resolved)
                if p_tk == TypeKind.TY_PTR or p_tk == TypeKind.TY_REF:
                    param_is_ptr = 1
            if param_is_ptr != 0:
                out = out ++ "&(" ++ arg_text ++ ")"
                continue
        out = out ++ arg_text
    out

fn CCodegen.call_args_callee_sig(self: CCodegen, body: MirBody, args_id: i32) -> i32:
    // Find the callee's signature index for the call that uses args_id.
    // Walk basic blocks looking for a TK_CALL whose args match.
    for bb in 0..body.block_count():
        if body.term_kind(bb) != TermKind.TK_CALL:
            continue
        let t_d1 = body.term_d1(bb)
        if t_d1 != args_id:
            continue
        let t_d0 = body.term_d0(bb)
        // d0 is the callee operand
        let ok = body.operand_kinds.get(t_d0 as i64)
        if ok == OperandKind.OK_CONSTANT:
            let cd = body.operand_d0.get(t_d0 as i64)
            let ck = body.const_kinds.get(cd as i64)
            if ck == ConstKind.CK_FN:
                let fn_sym = body.const_d0.get(cd as i64)
                return self.body_sig_index(fn_sym)
        return 0 - 1
    0 - 1

fn cc_builtin_from_mir_intrinsic(intrinsic: i32) -> i32:
    if intrinsic == MirIntrinsic.MIR_INTRINSIC_VEC_NEW: return cc_builtin_vec_new()
    if intrinsic == MirIntrinsic.MIR_INTRINSIC_VEC_PUSH: return cc_builtin_vec_push()
    if intrinsic == MirIntrinsic.MIR_INTRINSIC_VEC_GET: return cc_builtin_vec_get()
    if intrinsic == MirIntrinsic.MIR_INTRINSIC_VEC_LEN: return cc_builtin_vec_len()
    if intrinsic == MirIntrinsic.MIR_INTRINSIC_VEC_SET: return cc_builtin_vec_set_i32()
    if intrinsic == MirIntrinsic.MIR_INTRINSIC_VEC_REMOVE: return cc_builtin_vec_remove()
    if intrinsic == MirIntrinsic.MIR_INTRINSIC_VEC_CLEAR: return cc_builtin_vec_clear()
    if intrinsic == MirIntrinsic.MIR_INTRINSIC_VEC_POP: return cc_builtin_vec_pop()
    if intrinsic == MirIntrinsic.MIR_INTRINSIC_MAP_NEW: return cc_builtin_map_new()
    if intrinsic == MirIntrinsic.MIR_INTRINSIC_MAP_INSERT: return cc_builtin_map_insert()
    if intrinsic == MirIntrinsic.MIR_INTRINSIC_MAP_GET: return cc_builtin_map_get()
    if intrinsic == MirIntrinsic.MIR_INTRINSIC_MAP_CONTAINS: return cc_builtin_map_contains()
    if intrinsic == MirIntrinsic.MIR_INTRINSIC_MAP_LEN: return cc_builtin_map_len()
    if intrinsic == MirIntrinsic.MIR_INTRINSIC_MAP_REMOVE: return cc_builtin_map_remove()
    if intrinsic == MirIntrinsic.MIR_INTRINSIC_OPT_IS_SOME: return cc_builtin_opt_is_some()
    if intrinsic == MirIntrinsic.MIR_INTRINSIC_OPT_UNWRAP: return cc_builtin_opt_unwrap()
    if intrinsic == MirIntrinsic.MIR_INTRINSIC_STR_LEN: return cc_builtin_str_len()
    if intrinsic == MirIntrinsic.MIR_INTRINSIC_STR_BYTE_AT: return cc_builtin_str_byte_at()
    if intrinsic == MirIntrinsic.MIR_INTRINSIC_STR_SLICE: return cc_builtin_str_slice()
    if intrinsic == MirIntrinsic.MIR_INTRINSIC_STR_CONTAINS: return cc_builtin_str_contains()
    if intrinsic == MirIntrinsic.MIR_INTRINSIC_STR_STARTS_WITH: return cc_builtin_str_starts_with()
    if intrinsic == MirIntrinsic.MIR_INTRINSIC_STR_ENDS_WITH: return cc_builtin_str_ends_with()
    if intrinsic == MirIntrinsic.MIR_INTRINSIC_STR_FIND: return cc_builtin_str_find()
    if intrinsic == MirIntrinsic.MIR_INTRINSIC_MAP_CLEAR: return cc_builtin_map_clear()
    if intrinsic == MirIntrinsic.MIR_INTRINSIC_VECITER_NEXT: return cc_builtin_veciter_next()
    if intrinsic == MirIntrinsic.MIR_INTRINSIC_VEC_ITER: return cc_builtin_vec_iter()
    if intrinsic == MirIntrinsic.MIR_INTRINSIC_OPT_IS_NONE: return cc_builtin_opt_is_none()
    if intrinsic == MirIntrinsic.MIR_INTRINSIC_STR_SPLIT: return cc_builtin_str_split()
    if intrinsic == MirIntrinsic.MIR_INTRINSIC_STR_TRIM: return cc_builtin_str_trim()
    if intrinsic == MirIntrinsic.MIR_INTRINSIC_STR_TO_UPPER: return cc_builtin_str_to_upper()
    if intrinsic == MirIntrinsic.MIR_INTRINSIC_STR_TO_LOWER: return cc_builtin_str_to_lower()
    if intrinsic == MirIntrinsic.MIR_INTRINSIC_STR_REPLACE: return cc_builtin_str_replace()
    if intrinsic == MirIntrinsic.MIR_INTRINSIC_STR_INDEX_OF: return cc_builtin_str_index_of()
    if intrinsic == MirIntrinsic.MIR_INTRINSIC_MAP_INCREMENT: return cc_builtin_map_increment()
    if intrinsic == MirIntrinsic.MIR_INTRINSIC_VEC_MAP: return cc_builtin_vec_map()
    if intrinsic == MirIntrinsic.MIR_INTRINSIC_VEC_FILTER: return cc_builtin_vec_filter()
    if intrinsic == MirIntrinsic.MIR_INTRINSIC_VEC_FOLD: return cc_builtin_vec_fold()
    if intrinsic == MirIntrinsic.MIR_INTRINSIC_VEC_CONTAINS: return cc_builtin_vec_contains()
    if intrinsic == MirIntrinsic.MIR_INTRINSIC_STR_REPEAT: return cc_builtin_str_repeat()
    if intrinsic == MirIntrinsic.MIR_INTRINSIC_ARR_LEN: return cc_builtin_arr_len()
    if intrinsic == MirIntrinsic.MIR_INTRINSIC_GENERIC_CALL: return cc_builtin_generic_call()
    if intrinsic == MirIntrinsic.MIR_INTRINSIC_VEC_JOIN: return cc_builtin_vec_join()
    if intrinsic == MirIntrinsic.MIR_INTRINSIC_DYN_VTABLE_CMP: return cc_builtin_dyn_vtable_cmp()
    if intrinsic == MirIntrinsic.MIR_INTRINSIC_DYN_DOWNCAST: return cc_builtin_dyn_downcast()
    if intrinsic == MirIntrinsic.MIR_INTRINSIC_OPT_FILTER: return cc_builtin_opt_filter()
    if intrinsic == MirIntrinsic.MIR_INTRINSIC_ROTATE_LEFT: return cc_builtin_rotate_left()
    if intrinsic == MirIntrinsic.MIR_INTRINSIC_ROTATE_RIGHT: return cc_builtin_rotate_right()
    if intrinsic == MirIntrinsic.MIR_INTRINSIC_VEC_WITH_CAPACITY: return cc_builtin_vec_with_capacity()
    if intrinsic == MirIntrinsic.MIR_INTRINSIC_FMT_TO_STR: return cc_builtin_fmt_to_str()
    if intrinsic == MirIntrinsic.MIR_INTRINSIC_FMT_DEBUG_STR: return cc_builtin_fmt_debug_str()
    if intrinsic == MirIntrinsic.MIR_INTRINSIC_FMT_DEBUG: return cc_builtin_fmt_debug()
    if intrinsic == MirIntrinsic.MIR_INTRINSIC_FMT_SPEC: return cc_builtin_fmt_spec()
    if intrinsic == MirIntrinsic.MIR_INTRINSIC_INT_SWAP_BYTES: return cc_builtin_int_swap_bytes()
    if intrinsic == MirIntrinsic.MIR_INTRINSIC_POPCOUNT: return cc_builtin_popcount()
    if intrinsic == MirIntrinsic.MIR_INTRINSIC_CLZ: return cc_builtin_clz()
    if intrinsic == MirIntrinsic.MIR_INTRINSIC_CTZ: return cc_builtin_ctz()
    if intrinsic == MirIntrinsic.MIR_INTRINSIC_BITREVERSE: return cc_builtin_bitreverse()
    if intrinsic == MirIntrinsic.MIR_INTRINSIC_MIN: return cc_builtin_min()
    if intrinsic == MirIntrinsic.MIR_INTRINSIC_MAX: return cc_builtin_max()
    if intrinsic == MirIntrinsic.MIR_INTRINSIC_ABS: return cc_builtin_abs()
    if intrinsic == MirIntrinsic.MIR_INTRINSIC_FMA: return cc_builtin_fma()
    cc_builtin_none()

fn CCodegen.emit_builtin_call_term(self: CCodegen, body: MirBody, bb: i32, callee_operand: i32, args_id: i32, dest_place: i32, next_bb: i32) -> str:
    // Read intrinsic marker from MIR instead of name-heuristic inference.
    let mir_intrinsic = body.call_intrinsic(args_id)
    var kind = cc_builtin_from_mir_intrinsic(mir_intrinsic)
    // Fall back to legacy heuristic for MIR produced without markers.
    if kind == cc_builtin_none():
        kind = self.call_builtin_kind(body, callee_operand, args_id, dest_place)
    if kind == cc_builtin_none():
        return ""
    let _ = bb
    let argc = self.call_arg_count(body, args_id)
    let ret_tid = self.call_builtin_ret_tid(body, callee_operand, args_id, dest_place)
    let has_ret = if self.is_void_tid(ret_tid) == 0: 1 else: 0

    if kind == cc_builtin_vec_new():
        var out = ""
        if has_ret != 0:
            out = out ++ "    " ++ self.place_text(body, dest_place) ++ " = (with_vec)" ++ cc_lbrace() ++ "0" ++ cc_rbrace() ++ ";\n"
        else:
            out = out ++ "    (void)0;\n"
        out = out ++ f"    goto bb{next_bb};"
        return out

    if kind == cc_builtin_vec_push():
        if argc < 2:
            self.fail("vec.push expects two arguments")
            return "    abort();"
        let recv = self.operand_text(body, self.call_arg_operand(body, args_id, 0))
        let elem_operand = self.call_arg_operand(body, args_id, 1)
        let elem_text = self.operand_text(body, elem_operand)
        var elem_tid = self.operand_tid(body, elem_operand)
        if elem_tid == 0 or self.is_void_tid(elem_tid) != 0:
            elem_tid = self.sema.ty_i64 as i32
        let elem_ty = self.c_type(elem_tid, 0)
        var out = "    " ++ cc_lbrace() ++ " " ++ elem_ty ++ " __with_tmp = " ++ elem_text ++ "; with_vec_push(&(" ++ recv ++ "), &__with_tmp); " ++ cc_rbrace() ++ "\n"
        out = out ++ f"    goto bb{next_bb};"
        return out

    if kind == cc_builtin_vec_get():
        if argc < 2:
            self.fail("vec.get expects two arguments")
            return "    abort();"
        let recv = self.operand_text(body, self.call_arg_operand(body, args_id, 0))
        let idx = self.operand_text(body, self.call_arg_operand(body, args_id, 1))
        let dst = self.place_text(body, dest_place)
        var out = "    memset(&(" ++ dst ++ "), 0, sizeof(" ++ dst ++ "));\n"
        out = out ++ "    if ((int64_t)(" ++ idx ++ ") >= 0 && (int64_t)(" ++ idx ++ ") < with_vec_len(&(" ++ recv ++ "))) " ++ cc_lbrace() ++ " memcpy(&(" ++ dst ++ "), with_vec_get_ptr(&(" ++ recv ++ "), (int64_t)(" ++ idx ++ ")), sizeof(" ++ dst ++ ")); " ++ cc_rbrace() ++ "\n"
        out = out ++ f"    goto bb{next_bb};"
        return out

    if kind == cc_builtin_vec_len():
        if argc < 1:
            self.fail("vec.len expects one argument")
            return "    abort();"
        let recv = self.operand_text(body, self.call_arg_operand(body, args_id, 0))
        var out = ""
        if has_ret != 0:
            out = out ++ "    " ++ self.place_text(body, dest_place) ++ " = with_vec_len(&(" ++ recv ++ "));\n"
        else:
            out = out ++ "    (void)with_vec_len(&(" ++ recv ++ "));\n"
        out = out ++ f"    goto bb{next_bb};"
        return out

    if kind == cc_builtin_vec_set_i32():
        if argc < 3:
            self.fail("vec.set_i32 expects three arguments")
            return "    abort();"
        let recv = self.operand_text(body, self.call_arg_operand(body, args_id, 0))
        let idx = self.operand_text(body, self.call_arg_operand(body, args_id, 1))
        let val = self.operand_text(body, self.call_arg_operand(body, args_id, 2))
        var out = "    with_vec_set_i32(&(" ++ recv ++ "), (int64_t)(" ++ idx ++ "), (int32_t)(" ++ val ++ "));\n"
        out = out ++ f"    goto bb{next_bb};"
        return out

    if kind == cc_builtin_vec_remove():
        if argc < 2:
            self.fail("vec.remove expects two arguments")
            return "    abort();"
        let recv = self.operand_text(body, self.call_arg_operand(body, args_id, 0))
        let idx = self.operand_text(body, self.call_arg_operand(body, args_id, 1))
        var out = "    with_vec_remove(&(" ++ recv ++ "), (int64_t)(" ++ idx ++ "));\n"
        out = out ++ f"    goto bb{next_bb};"
        return out

    if kind == cc_builtin_vec_clear():
        if argc < 1:
            self.fail("vec.clear expects one argument")
            return "    abort();"
        let recv = self.operand_text(body, self.call_arg_operand(body, args_id, 0))
        var out = "    with_vec_clear(&(" ++ recv ++ "));\n"
        out = out ++ f"    goto bb{next_bb};"
        return out

    if kind == cc_builtin_vec_pop():
        if argc < 1:
            self.fail("vec.pop expects one argument")
            return "    abort();"
        let recv = self.operand_text(body, self.call_arg_operand(body, args_id, 0))
        var out = "    " ++ cc_lbrace() ++ " int64_t __with_n = with_vec_len(&(" ++ recv ++ "));\n"
        if has_ret != 0:
            let dst = self.place_text(body, dest_place)
            out = out ++ "        memset(&(" ++ dst ++ "), 0, sizeof(" ++ dst ++ "));\n"
            out = out ++ "        if (__with_n > 0) " ++ cc_lbrace() ++ " memcpy(&(" ++ dst ++ "), with_vec_get_ptr(&(" ++ recv ++ "), __with_n - 1), sizeof(" ++ dst ++ ")); with_vec_remove(&(" ++ recv ++ "), __with_n - 1); " ++ cc_rbrace() ++ "\n"
        else:
            out = out ++ "        if (__with_n > 0) " ++ cc_lbrace() ++ " with_vec_remove(&(" ++ recv ++ "), __with_n - 1); " ++ cc_rbrace() ++ "\n"
        out = out ++ "    " ++ cc_rbrace() ++ "\n"
        out = out ++ f"    goto bb{next_bb};"
        return out

    if kind == cc_builtin_map_new():
        var out = ""
        if has_ret != 0:
            out = out ++ "    " ++ self.place_text(body, dest_place) ++ " = 0;\n"
        else:
            out = out ++ "    (void)0;\n"
        out = out ++ f"    goto bb{next_bb};"
        return out

    if kind == cc_builtin_map_insert():
        if argc < 3:
            self.fail("map.insert expects three arguments")
            return "    abort();"
        let recv = self.operand_text(body, self.call_arg_operand(body, args_id, 0))
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

    if kind == cc_builtin_map_contains():
        if argc < 2:
            self.fail("map.contains expects two arguments")
            return "    abort();"
        let recv = self.operand_text(body, self.call_arg_operand(body, args_id, 0))
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

    if kind == cc_builtin_map_len():
        if argc < 1:
            self.fail("map.len expects one argument")
            return "    abort();"
        let recv = self.operand_text(body, self.call_arg_operand(body, args_id, 0))
        var out = ""
        if has_ret != 0:
            out = out ++ "    " ++ self.place_text(body, dest_place) ++ " = (((" ++ recv ++ ") != 0) ? with_hashmap_len((void*)(intptr_t)(" ++ recv ++ ")) : 0);\n"
        else:
            out = out ++ "    (void)(((" ++ recv ++ ") != 0) ? with_hashmap_len((void*)(intptr_t)(" ++ recv ++ ")) : 0);\n"
        out = out ++ f"    goto bb{next_bb};"
        return out

    if kind == cc_builtin_map_remove():
        if argc < 2:
            self.fail("map.remove expects two arguments")
            return "    abort();"
        let recv = self.operand_text(body, self.call_arg_operand(body, args_id, 0))
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
        out = out ++ "(((" ++ recv ++ ") != 0) && (with_hashmap_remove((void*)(intptr_t)(" ++ recv ++ "), &__with_k, " ++ is_str_key ++ ") != 0)); " ++ cc_rbrace() ++ "\n"
        out = out ++ f"    goto bb{next_bb};"
        return out

    if kind == cc_builtin_map_get():
        if argc < 2:
            self.fail("map.get expects two arguments")
            return "    abort();"
        let recv = self.operand_text(body, self.call_arg_operand(body, args_id, 0))
        let key_operand = self.call_arg_operand(body, args_id, 1)
        let key_text = self.operand_text(body, key_operand)
        var key_tid = self.operand_tid(body, key_operand)
        if key_tid == 0 or self.is_void_tid(key_tid) != 0:
            key_tid = self.sema.ty_i64 as i32
        let key_ty = self.c_type(key_tid, 0)
        let is_str_key = if self.sema.get_type_kind(self.sema.resolve_alias(key_tid as TypeId)) == TypeKind.TY_STR: "1" else: "0"
        let dst = self.place_text(body, dest_place)
        var out = "    " ++ cc_lbrace() ++ " " ++ key_ty ++ " __with_k = " ++ key_text ++ "; int64_t __with_v = 0;"
        out = out ++ " if ((" ++ recv ++ ") != 0 && with_hashmap_get((void*)(intptr_t)(" ++ recv ++ "), &__with_k, &__with_v, " ++ is_str_key ++ ") != 0) "
        out = out ++ cc_lbrace() ++ " " ++ dst ++ " = (__with_v + 1); " ++ cc_rbrace() ++ " else " ++ cc_lbrace() ++ " " ++ dst ++ " = 0; " ++ cc_rbrace()
        out = out ++ " " ++ cc_rbrace() ++ "\n"
        out = out ++ f"    goto bb{next_bb};"
        return out

    if kind == cc_builtin_opt_is_some():
        if argc < 1:
            self.fail("Option.is_some expects one argument")
            return "    abort();"
        let opt_text = self.operand_text(body, self.call_arg_operand(body, args_id, 0))
        var out = ""
        if has_ret != 0:
            out = out ++ "    " ++ self.place_text(body, dest_place) ++ " = ((" ++ opt_text ++ ") != 0);\n"
        else:
            out = out ++ "    (void)((" ++ opt_text ++ ") != 0);\n"
        out = out ++ f"    goto bb{next_bb};"
        return out

    if kind == cc_builtin_opt_unwrap():
        if argc < 1:
            self.fail("Option.unwrap expects one argument")
            return "    abort();"
        let opt_text = self.operand_text(body, self.call_arg_operand(body, args_id, 0))
        let dst = self.place_text(body, dest_place)
        var out = "    " ++ dst ++ " = ((" ++ opt_text ++ ") - 1);\n"
        out = out ++ f"    goto bb{next_bb};"
        return out

    if kind == cc_builtin_str_len():
        if argc < 1:
            self.fail("str.len expects one argument")
            return "    abort();"
        let recv = self.operand_text(body, self.call_arg_operand(body, args_id, 0))
        var out = ""
        if has_ret != 0:
            out = out ++ "    " ++ self.place_text(body, dest_place) ++ " = with_str_len(" ++ recv ++ ");\n"
        else:
            out = out ++ "    (void)with_str_len(" ++ recv ++ ");\n"
        out = out ++ f"    goto bb{next_bb};"
        return out

    if kind == cc_builtin_str_byte_at():
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

    if kind == cc_builtin_str_slice():
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

    if kind == cc_builtin_str_contains():
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

    if kind == cc_builtin_str_starts_with():
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

    if kind == cc_builtin_str_ends_with():
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

    if kind == cc_builtin_str_find():
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

    if kind == cc_builtin_str_index_of():
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

    if kind == cc_builtin_str_split():
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

    if kind == cc_builtin_str_trim():
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

    if kind == cc_builtin_str_to_upper():
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

    if kind == cc_builtin_str_to_lower():
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

    if kind == cc_builtin_str_replace():
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

    if kind == cc_builtin_str_repeat():
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

    if kind == cc_builtin_map_clear():
        if argc < 1:
            self.fail("map.clear expects one argument")
            return "    abort();"
        let recv = self.operand_text(body, self.call_arg_operand(body, args_id, 0))
        var out = "    if ((" ++ recv ++ ") != 0) with_hashmap_clear((void*)(intptr_t)(" ++ recv ++ "));\n"
        out = out ++ f"    goto bb{next_bb};"
        return out

    if kind == cc_builtin_map_increment():
        if argc < 2:
            self.fail("map.increment expects two arguments")
            return "    abort();"
        let recv = self.operand_text(body, self.call_arg_operand(body, args_id, 0))
        let key_operand = self.call_arg_operand(body, args_id, 1)
        let key_text = self.operand_text(body, key_operand)
        var key_tid = self.operand_tid(body, key_operand)
        if key_tid == 0 or self.is_void_tid(key_tid) != 0:
            key_tid = self.sema.ty_i64 as i32
        let key_ty = self.c_type(key_tid, 0)
        let is_str_key = if self.sema.get_type_kind(self.sema.resolve_alias(key_tid as TypeId)) == TypeKind.TY_STR: "1" else: "0"
        var out = "    " ++ cc_lbrace() ++ " " ++ key_ty ++ " __with_k = " ++ key_text ++ "; with_hashmap_increment((void*)(intptr_t)(" ++ recv ++ "), &__with_k, " ++ is_str_key ++ "); " ++ cc_rbrace() ++ "\n"
        out = out ++ f"    goto bb{next_bb};"
        return out

    if kind == cc_builtin_opt_is_none():
        if argc < 1:
            self.fail("Option.is_none expects one argument")
            return "    abort();"
        let opt_text = self.operand_text(body, self.call_arg_operand(body, args_id, 0))
        var out = ""
        if has_ret != 0:
            out = out ++ "    " ++ self.place_text(body, dest_place) ++ " = ((" ++ opt_text ++ ") == 0);\n"
        else:
            out = out ++ "    (void)((" ++ opt_text ++ ") == 0);\n"
        out = out ++ f"    goto bb{next_bb};"
        return out

    if kind == cc_builtin_vec_iter():
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

    if kind == cc_builtin_veciter_next():
        // Advance iterator: returns Option (0 = None, value+1 = Some(value))
        // args: recv = {vec, index_i64} — treat as vec + separate index local
        if argc < 1:
            self.fail("veciter.next expects one argument")
            return "    abort();"
        let recv = self.operand_text(body, self.call_arg_operand(body, args_id, 0))
        let dst = self.place_text(body, dest_place)
        var out = "    " ++ cc_lbrace() ++ " int64_t __with_n = with_vec_len(&(" ++ recv ++ ")); int64_t __with_i = 0;"
        out = out ++ " if (__with_i < __with_n) " ++ cc_lbrace()
        out = out ++ " int64_t __with_elem = 0; memcpy(&__with_elem, with_vec_get_ptr(&(" ++ recv ++ "), __with_i), sizeof(int64_t));"
        out = out ++ " " ++ dst ++ " = __with_elem + 1; " ++ cc_rbrace()
        out = out ++ " else " ++ cc_lbrace() ++ " " ++ dst ++ " = 0; " ++ cc_rbrace()
        out = out ++ " " ++ cc_rbrace() ++ "\n"
        out = out ++ f"    goto bb{next_bb};"
        return out

    if kind == cc_builtin_vec_contains():
        if argc < 2:
            self.fail("vec.contains expects two arguments")
            return "    abort();"
        let recv = self.operand_text(body, self.call_arg_operand(body, args_id, 0))
        let elem_operand = self.call_arg_operand(body, args_id, 1)
        let elem_text = self.operand_text(body, elem_operand)
        var elem_tid = self.operand_tid(body, elem_operand)
        if elem_tid == 0 or self.is_void_tid(elem_tid) != 0:
            elem_tid = self.sema.ty_i64 as i32
        let elem_ty = self.c_type(elem_tid, 0)
        let dst = self.place_text(body, dest_place)
        var out = "    " ++ cc_lbrace() ++ " int64_t __with_found = 0; int64_t __with_ci; int64_t __with_cn = with_vec_len(&(" ++ recv ++ ")); " ++ elem_ty ++ " __with_needle = " ++ elem_text ++ ";"
        out = out ++ " for (__with_ci = 0; __with_ci < __with_cn; __with_ci++) " ++ cc_lbrace()
        out = out ++ " " ++ elem_ty ++ " __with_cur; memcpy(&__with_cur, with_vec_get_ptr(&(" ++ recv ++ "), __with_ci), sizeof(" ++ elem_ty ++ "));"
        out = out ++ " if (memcmp(&__with_cur, &__with_needle, sizeof(" ++ elem_ty ++ ")) == 0) " ++ cc_lbrace() ++ " __with_found = 1; break; " ++ cc_rbrace()
        out = out ++ " " ++ cc_rbrace()
        if has_ret != 0:
            out = out ++ " " ++ dst ++ " = __with_found;"
        out = out ++ " " ++ cc_rbrace() ++ "\n"
        out = out ++ f"    goto bb{next_bb};"
        return out

    if kind == cc_builtin_vec_join():
        if argc < 2:
            self.fail("vec.join expects two arguments")
            return "    abort();"
        let recv = self.operand_text(body, self.call_arg_operand(body, args_id, 0))
        let sep = self.operand_text(body, self.call_arg_operand(body, args_id, 1))
        var out = ""
        if has_ret != 0:
            out = out ++ "    " ++ self.place_text(body, dest_place) ++ " = with_vec_join_str(&(" ++ recv ++ "), " ++ sep ++ ");\n"
        else:
            out = out ++ "    (void)with_vec_join_str(&(" ++ recv ++ "), " ++ sep ++ ");\n"
        out = out ++ f"    goto bb{next_bb};"
        return out

    if kind == cc_builtin_arr_len():
        if argc < 1:
            self.fail("arr.len expects one argument")
            return "    abort();"
        let recv = self.operand_text(body, self.call_arg_operand(body, args_id, 0))
        var out = ""
        if has_ret != 0:
            out = out ++ "    " ++ self.place_text(body, dest_place) ++ " = (int64_t)(sizeof(" ++ recv ++ ") / sizeof((" ++ recv ++ ")[0]));\n"
        else:
            out = out ++ "    (void)(sizeof(" ++ recv ++ ") / sizeof((" ++ recv ++ ")[0]));\n"
        out = out ++ f"    goto bb{next_bb};"
        return out

    if kind == cc_builtin_vec_with_capacity():
        // Capacity hint is ignored in C; just initialize an empty vec
        var out = ""
        if has_ret != 0:
            out = out ++ "    " ++ self.place_text(body, dest_place) ++ " = (with_vec)" ++ cc_lbrace() ++ "0" ++ cc_rbrace() ++ ";\n"
        else:
            out = out ++ "    (void)0;\n"
        out = out ++ f"    goto bb{next_bb};"
        return out

    if kind == cc_builtin_rotate_left():
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

    if kind == cc_builtin_rotate_right():
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

    if kind == cc_builtin_int_swap_bytes():
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

    if kind == cc_builtin_popcount():
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

    if kind == cc_builtin_clz():
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

    if kind == cc_builtin_ctz():
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

    if kind == cc_builtin_bitreverse():
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

    if kind == cc_builtin_min():
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

    if kind == cc_builtin_max():
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

    if kind == cc_builtin_abs():
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

    if kind == cc_builtin_fma():
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

    if kind == cc_builtin_fmt_to_str():
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

    if kind == cc_builtin_fmt_debug_str():
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

    if kind == cc_builtin_fmt_debug():
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

    if kind == cc_builtin_fmt_spec():
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

    if kind == cc_builtin_dyn_vtable_cmp():
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

    if kind == cc_builtin_dyn_downcast():
        // Dynamic trait downcast — not fully implementable without type info; abort
        var out = "    /* dyn_downcast: not supported in C backend */ abort();\n"
        out = out ++ f"    goto bb{next_bb};"
        return out

    if kind == cc_builtin_opt_filter():
        // opt.filter requires closure support — not available in C backend
        var out = "    /* opt.filter: requires closure support */ abort();\n"
        out = out ++ f"    goto bb{next_bb};"
        return out

    if kind == cc_builtin_vec_map():
        // vec.map requires closure support — not available in C backend
        var out = "    /* vec.map: requires closure support */ abort();\n"
        out = out ++ f"    goto bb{next_bb};"
        return out

    if kind == cc_builtin_vec_filter():
        // vec.filter requires closure support — not available in C backend
        var out = "    /* vec.filter: requires closure support */ abort();\n"
        out = out ++ f"    goto bb{next_bb};"
        return out

    if kind == cc_builtin_vec_fold():
        // vec.fold requires closure support — not available in C backend
        var out = "    /* vec.fold: requires closure support */ abort();\n"
        out = out ++ f"    goto bb{next_bb};"
        return out

    if kind == cc_builtin_generic_call():
        // GENERIC_CALL should be resolved before reaching the C backend
        var out = "    /* generic_call: should be resolved before C backend */ abort();\n"
        out = out ++ f"    goto bb{next_bb};"
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
            if hint == cc_callee_hint_none():
                continue

            if recv_is_field != 0:
                if hint == cc_callee_hint_vec_recv():
                    self.record_field_tid_from_place(body, recv_place, cc_pseudo_tid_vec())
                    continue
                if hint == cc_callee_hint_map_recv():
                    self.record_field_tid_from_place(body, recv_place, self.sema.ty_i64)
                    continue
                if hint == cc_callee_hint_opt_recv():
                    self.record_field_tid_from_place(body, recv_place, self.sema.ty_i64)
                    continue

            if dest_is_field != 0:
                if hint == cc_callee_hint_map_new():
                    self.record_field_tid_from_place(body, dest_place, self.sema.ty_i64)
                    continue
                if hint == cc_callee_hint_vec_new():
                    self.record_field_tid_from_place(body, dest_place, cc_pseudo_tid_vec())
                    continue
                if hint == cc_callee_hint_opt_new():
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
    if cached != 0 - 1234567:
        return cached

    self.build_field_cache_from_usage()
    let hinted = self.field_cache_lookup(resolved_struct, field_sym)
    if hinted != 0 - 1234567:
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

                var sig_idx = 0 - 1
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
        if cached == 0 - 1234567:
            self.build_field_cache_from_usage()
            cached = self.field_cache_lookup(owner_tid, field_sym)
        if cached != 0 - 1234567 and cached != 0 and self.is_void_tid(cached) == 0:
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
                return cc_pseudo_tid_vec()
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

fn CCodegen.zero_value_text(self: CCodegen, tid: i32) -> str:
    let resolved = self.sema.resolve_alias(tid)
    let tk = self.sema.get_type_kind(resolved)
    if tk == TypeKind.TY_BOOL:
        return "false"
    if tk == TypeKind.TY_FLOAT:
        return "0.0"
    if tk == TypeKind.TY_PTR or tk == TypeKind.TY_REF:
        return "NULL"
    if tk == TypeKind.TY_STR or tk == TypeKind.TY_STRUCT:
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
    f"#line {line} \"{self.source_path}\"\n"

fn CCodegen.emit_stmt_line(self: CCodegen, body: MirBody, stmt_id: i32) -> str:
    if stmt_id < 0 or stmt_id >= body.stmt_kinds.len() as i32:
        self.fail(f"invalid statement id {stmt_id}")
        return "    /* invalid statement */"
    let sk = body.stmt_kinds.get(stmt_id as i64)
    let d0 = body.stmt_d0.get(stmt_id as i64)
    let d1 = body.stmt_d1.get(stmt_id as i64)
    if sk == StmtKind.Assign:
        if self.is_unit_rvalue(body, d1) != 0:
            let dst_tid = self.place_tid(body, d0)
            return "    " ++ self.place_text(body, d0) ++ " = " ++ self.zero_value_text(dst_tid) ++ ";"
        return "    " ++ self.place_text(body, d0) ++ " = " ++ self.rvalue_text(body, d1) ++ ";"
    if sk == StmtKind.StorageLive:
        return f"    /* StorageLive(_{d0}); */"
    if sk == StmtKind.StorageDead:
        return f"    /* StorageDead(_{d0}); */"
    if sk == StmtKind.Drop:
        let p = self.place_text(body, d0)
        let pt = self.place_tid(body, d0)
        if pt == cc_pseudo_tid_vec():
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
            var out = ""
            if self.is_void_tid(ret_tid) == 0:
                out = out ++ "    " ++ self.place_text(body, d2) ++ " = " ++ self.zero_value_text(ret_tid) ++ ";\n"
            else:
                out = out ++ "    /* unresolved call elided */\n"
            out = out ++ f"    goto bb{d3};"
            return out
        let args = self.call_args_text(body, d1)
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
        if pt == cc_pseudo_tid_vec():
            out = out ++ "    with_vec_clear(&(" ++ p ++ "));\n"
        else:
            out = out ++ "    /* drop(" ++ p ++ "); */\n"
        out = out ++ f"    goto bb{d1};"
        return out
    self.fail(f"unsupported terminator kind {tk}")
    "    abort();"

fn CCodegen.collect_struct_types_from_tid(self: CCodegen, out: &mut Vec[i32], seen_names: &mut HashMap[i32, i32], tid: i32):
    let resolved = self.sema.resolve_alias(tid)
    if resolved == 0:
        return
    let tk = self.sema.get_type_kind(resolved)
    if tk == TypeKind.TY_STRUCT:
        let name_sym = self.sema.get_type_d0(resolved)
        if not seen_names.contains(name_sym):
            seen_names.insert(name_sym, 1)
            out.push(resolved as i32)
        return
    if tk == TypeKind.TY_PTR or tk == TypeKind.TY_REF or tk == TypeKind.TY_ARRAY or tk == TypeKind.TY_SLICE:
        let inner_tid = self.sema.get_type_d0(resolved)
        self.collect_struct_types_from_tid(out, seen_names, inner_tid)

fn CCodegen.collect_used_struct_types(self: CCodegen) -> Vec[i32]:
    var out: Vec[i32] = Vec.new()
    var seen_names: HashMap[i32, i32] = HashMap.new()

    for bi in 0..self.mir_mod.bodies.len() as i32:
        if self.check_interrupted() != 0:
            return out
        let body: MirBody = self.mir_mod.bodies.get(bi as i64)
        for li in 0..body.local_type_ids.len() as i32:
            if self.check_interrupted() != 0:
                return out
            let tid = body.local_type_ids.get(li as i64)
            self.collect_struct_types_from_tid(&mut out, &mut seen_names, tid)
        let sig_idx = self.body_sig_index(body.fn_sym)
        if sig_idx >= 0:
            let ret_tid = self.sema.sig_return_type(sig_idx)
            self.collect_struct_types_from_tid(&mut out, &mut seen_names, ret_tid)
            let param_count = self.sema.sig_get_param_count(sig_idx)
            for pi in 0..param_count:
                let p_tid = self.sema.sig_param_type(sig_idx, pi)
                self.collect_struct_types_from_tid(&mut out, &mut seen_names, p_tid)

    var i = 0
    while i < out.len() as i32:
        if self.check_interrupted() != 0:
            return out
        let tid = out.get(i as i64)
        i = i + 1
        let start = self.sema.get_type_d1(tid)
        let count = self.sema.get_type_d2(tid)
        for fi in 0..count:
            if self.check_interrupted() != 0:
                return out
            let raw_field_tid = self.sema.type_extra.get((start + fi * 3 + 1) as i64)
            self.collect_struct_types_from_tid(&mut out, &mut seen_names, raw_field_tid)

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
            let name_sym = self.sema.get_type_d0(resolved as TypeId)
            if emitted_names.contains(name_sym):
                continue
            let start = self.sema.get_type_d1(resolved as TypeId)
            let count = self.sema.get_type_d2(resolved as TypeId)
            var ready = 1
            for fi in 0..count:
                if self.check_interrupted() != 0:
                    return ""
                let field_sym = self.sema.type_extra.get((start + fi * 3) as i64)
                let raw_field_tid = self.sema.type_extra.get((start + fi * 3 + 1) as i64)
                let field_tid = self.sema.resolve_alias(self.effective_field_tid(resolved, field_sym, raw_field_tid) as TypeId)
                if self.sema.get_type_kind(field_tid) != TypeKind.TY_STRUCT:
                    continue
                let dep_name = self.sema.get_type_d0(field_tid)
                if dep_name != name_sym and not emitted_names.contains(dep_name):
                    ready = 0
                    break
            if ready == 0:
                continue
            ordered.push(resolved)
            emitted_names.insert(name_sym, 1)
            progressed = 1
        if progressed == 0:
            for i in 0..struct_tids.len() as i32:
                if self.check_interrupted() != 0:
                    return ""
                let resolved = self.sema.resolve_alias(struct_tids.get(i as i64) as TypeId) as i32
                let name_sym = self.sema.get_type_d0(resolved as TypeId)
                if emitted_names.contains(name_sym):
                    continue
                ordered.push(resolved)
                emitted_names.insert(name_sym, 1)

    var out = ""
    for i in 0..ordered.len() as i32:
        if self.check_interrupted() != 0:
            return ""
        let tid = ordered.get(i as i64)
        let resolved = self.sema.resolve_alias(tid)
        let name_sym = self.sema.get_type_d0(resolved)
        let count = self.sema.get_type_d2(resolved)
        if count == 1 and self.sema.distinct_type_names.contains(name_sym):
            continue  // distinct types get their typedef in the definition pass
        let name = self.struct_c_name(tid)
        out = out ++ "typedef struct " ++ name ++ " " ++ name ++ ";\n"
    out = out ++ "\n"

    for i in 0..ordered.len() as i32:
        if self.check_interrupted() != 0:
            return ""
        let tid = ordered.get(i as i64)
        let resolved = self.sema.resolve_alias(tid)
        let name = self.struct_c_name(resolved)
        let start = self.sema.get_type_d1(resolved)
        let count = self.sema.get_type_d2(resolved)
        // Distinct types (single-field wrapper) → emit as typedef to underlying C type
        let name_sym = self.sema.get_type_d0(resolved)
        if count == 1 and self.sema.distinct_type_names.contains(name_sym):
            let raw_field_tid = self.sema.type_extra.get((start + 1) as i64)
            let field_sym = self.sema.type_extra.get(start as i64)
            let field_tid = self.effective_field_tid(resolved, field_sym, raw_field_tid)
            out = out ++ "typedef " ++ self.c_type(field_tid, 0) ++ " " ++ name ++ ";\n\n"
            continue
        out = out ++ "struct " ++ name ++ " " ++ cc_lbrace() ++ "\n"
        for fi in 0..count:
            if self.check_interrupted() != 0:
                return ""
            let field_sym = self.sema.type_extra.get((start + fi * 3) as i64)
            let raw_field_tid = self.sema.type_extra.get((start + fi * 3 + 1) as i64)
            let field_tid = self.effective_field_tid(resolved, field_sym, raw_field_tid)
            let field_name = cc_intern_resolve(self.intern, field_sym)
            out = out ++ "    " ++ self.c_type(field_tid, 0) ++ " " ++ field_name ++ ";\n"
        out = out ++ cc_rbrace() ++ ";\n\n"
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
        out = out ++ self.c_type(p_tid, 0) ++ f" _{i + 1}"
    out = out ++ ")"
    out

fn CCodegen.emit_fn_body(self: CCodegen, body: MirBody) -> str:
    if self.check_interrupted() != 0:
        return ""
    let fn_sig = self.emit_fn_decl(body)
    let fn_sym = body.fn_sym
    let sig_idx = self.body_sig_index(fn_sym)
    let param_count = if sig_idx >= 0: self.sema.sig_get_param_count(sig_idx) else: 0
    var out = fn_sig ++ " " ++ cc_lbrace() ++ "\n"
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
        let ret_tid = self.call_return_tid(body, bb, callee_operand, args_id, dest_place)
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
    for li in 0..body.local_count():
        if self.check_interrupted() != 0:
            return ""
        if li >= 1 and li <= param_count:
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
        let inferred_tid = self.infer_local_tid(body, li)
        if inferred_tid != 0 and self.is_void_tid(inferred_tid) == 0:
            let use_kind = self.sema.get_type_kind(self.sema.resolve_alias(use_tid))
            let inferred_kind = self.sema.get_type_kind(self.sema.resolve_alias(inferred_tid))
            if self.is_void_tid(use_tid) != 0 or use_kind != inferred_kind or self.strict_type_match(use_tid, inferred_tid) == 0:
                use_tid = inferred_tid
        let local_ty = if li == 0 and self.is_void_tid(use_tid) != 0: "int32_t" else: self.c_type(use_tid, 0)
        out = out ++ "    " ++ local_ty ++ f" _{li} __attribute__((unused)) = " ++ cc_lbrace() ++ "0" ++ cc_rbrace() ++ ";\n"
    if body.block_count() == 0:
        self.fail("function has no basic blocks: " ++ cc_intern_resolve(self.intern, fn_sym))
        out = out ++ "    abort();\n"
        out = out ++ cc_rbrace() ++ "\n"
        return out
    out = out ++ "    goto bb0;\n"
    for bb in 0..body.block_count():
        if self.check_interrupted() != 0:
            return ""
        out = out ++ f"bb{bb}:\n"
        let start = body.bb_stmt_starts.get(bb as i64)
        let count = body.bb_stmt_counts.get(bb as i64)
        for si in 0..count:
            if self.check_interrupted() != 0:
                return ""
            out = out ++ self.line_directive(body, start + si) ++ self.emit_stmt_line(body, start + si) ++ "\n"
        out = out ++ self.emit_term(body, bb) ++ "\n"
    out = out ++ cc_rbrace() ++ "\n"
    out

fn CCodegen.find_main_sym(self: CCodegen) -> i32:
    for i in 0..self.mir_mod.body_fn_syms.len() as i32:
        let sym = self.mir_mod.body_fn_syms.get(i as i64)
        if cc_intern_resolve(self.intern, sym) == "main":
            return sym
    0

fn CCodegen.emit_main_wrapper(self: CCodegen) -> str:
    let main_sym = self.find_main_sym()
    if main_sym == 0:
        return ""
    let main_name = self.fn_c_name(main_sym)
    let sig_idx = self.sema.get_sig(main_sym)
    let ret_tid = if sig_idx >= 0: self.sema.sig_return_type(sig_idx) else: self.sema.ty_void
    var out = "int main(int argc, char** argv) " ++ cc_lbrace() ++ "\n"
    out = out ++ "    with_runtime_set_argv(argc, argv);\n"
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
    var out = ""
    out = out ++ "/* Generated by with --emit-c (conservative MIR subset). */\n"
    out = out ++ "#include <stdint.h>\n"
    out = out ++ "#include <stdbool.h>\n"
    out = out ++ "#include <math.h>\n"
    out = out ++ "#include <stdlib.h>\n"
    out = out ++ "#include <string.h>\n"
    out = out ++ "#include \"with_runtime.h\"\n\n"

    out = out ++ self.emit_struct_type_defs()
    if self.had_error != 0:
        return ""

    // Forward declarations for all lowered functions.
    for i in 0..self.mir_mod.bodies.len() as i32:
        if self.check_interrupted() != 0:
            return ""
        let body: MirBody = self.mir_mod.bodies.get(i as i64)
        out = out ++ self.emit_fn_decl(body) ++ ";\n"
    if self.mir_mod.bodies.len() as i32 > 0:
        out = out ++ "\n"

    // Function bodies.
    for i in 0..self.mir_mod.bodies.len() as i32:
        if self.check_interrupted() != 0:
            return ""
        let body: MirBody = self.mir_mod.bodies.get(i as i64)
        out = out ++ self.emit_fn_body(body) ++ "\n"

    // C entrypoint wrapper for With `main`.
    out = out ++ self.emit_main_wrapper()
    out
