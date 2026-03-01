// Sema — Semantic analysis: name resolution, type checking, and validation.
//
// Sema runs as a validation pass between parsing and codegen. It walks
// the AST, resolves all names, computes types for every expression, and
// reports type errors with source spans. Codegen continues to work as
// before — Sema is purely additive validation.

use Ast
use BorrowCfg
use Span
use Diagnostic
use InternPool

extern fn int_to_string(n: i32) -> str

// ── Type kind constants ──────────────────────────────────────────

fn TY_ERR -> i32: 0
fn TY_INT -> i32: 1
fn TY_FLOAT -> i32: 2
fn TY_BOOL -> i32: 3
fn TY_VOID -> i32: 4
fn TY_STR -> i32: 5
fn TY_STRUCT -> i32: 6
fn TY_ENUM -> i32: 7
fn TY_ARRAY -> i32: 8
fn TY_SLICE -> i32: 9
fn TY_TUPLE -> i32: 10
fn TY_RANGE -> i32: 11
fn TY_FN -> i32: 12
fn TY_PTR -> i32: 13
fn TY_REF -> i32: 14
fn TY_ALIAS -> i32: 15
fn TY_GENERIC_FN -> i32: 16

// Var state constants
fn VS_LIVE -> i32: 0
fn VS_MOVED -> i32: 1

// Borrow kind constants
fn BK_SHARED -> i32: 0
fn BK_EXCLUSIVE -> i32: 1

// Derive requirement constants
fn DR_COPY -> i32: 0
fn DR_CLONE -> i32: 1
fn DR_EQ -> i32: 2

// ── Sema state ───────────────────────────────────────────────────

type Sema = {
    pool: InternPool,
    diags: DiagnosticList,
    ast: AstPool,

    // Type table (SoA parallel arrays)
    type_kinds: Vec[i32],
    type_d0: Vec[i32],
    type_d1: Vec[i32],
    type_d2: Vec[i32],
    type_extra: Vec[i32],

    // Named type lookup: sym → TypeId
    named_types: HashMap[i32, i32],

    // Function signatures (parallel arrays)
    sig_names: Vec[i32],
    sig_type_ids: Vec[i32],
    sig_ret_types: Vec[i32],
    sig_param_starts: Vec[i32],
    sig_param_counts: Vec[i32],
    sig_variadic: Vec[i32],
    sig_params: Vec[i32],
    sig_lookup: HashMap[i32, i32],

    // Extern fn names
    extern_fn_names: HashMap[i32, i32],
    // Function AST node indices by name
    fn_decl_nodes: HashMap[i32, i32],
    // Generic function node indices by name
    generic_fn_nodes: HashMap[i32, i32],

    // Methods: hash(type_sym, method_sym) → sig index
    // Variant lookup: variant_sym → (enum_tid * 65536 + variant_index)
    variant_lookup: HashMap[i32, i32],

    // Trait declarations
    trait_method_names: Vec[i32],
    trait_method_starts: Vec[i32],
    trait_method_counts: Vec[i32],
    trait_name_syms: Vec[i32],
    trait_lookup: HashMap[i32, i32],
    // Type implementations: type_sym → list of trait syms (encoded in impl_extra)
    impl_extra: Vec[i32],
    impl_starts: Vec[i32],
    impl_counts: Vec[i32],
    impl_type_syms: Vec[i32],
    impl_lookup: HashMap[i32, i32],

    // Local trait/type names
    local_trait_names: HashMap[i32, i32],
    local_type_names: HashMap[i32, i32],
    ephemeral_types: HashMap[i32, i32],

    // Must-use / result-option / task fn tracking
    must_use_fns: HashMap[i32, i32],
    result_option_fns: HashMap[i32, i32],
    task_fns: HashMap[i32, i32],

    // Method origin tracking
    method_decl_origins: HashMap[i32, i32],
    method_has_inherent: HashMap[i32, i32],

    // Scope binding storage (stack-based with watermarks)
    bind_names: Vec[i32],
    bind_types: Vec[i32],
    bind_muts: Vec[i32],
    bind_states: Vec[i32],
    bind_is_task: Vec[i32],
    scope_starts: Vec[i32],

    // Borrow tracking
    borrow_kinds: Vec[i32],
    borrow_places: Vec[i32],
    borrow_fields: Vec[i32],
    borrow_refs: Vec[i32],

    // Current state
    current_return_type: i32,
    current_gen_yield_type: i32,
    has_gen_yield_type: i32,
    in_pipeline_rhs: i32,
    in_comptime_fn: i32,
    no_std: i32,
    alloc: i32,
    in_defer: i32,
    break_value_type: i32,
    has_break_value_type: i32,
    loop_depth: i32,
    closure_direct_arg_depth: i32,
    expected_expr_type: i32,
    has_expected_type: i32,
    local_file_id: i32,
    collecting_types: i32,

    // Canonical primitive TypeIds
    ty_i8: i32,
    ty_i16: i32,
    ty_i32: i32,
    ty_i64: i32,
    ty_u8: i32,
    ty_u16: i32,
    ty_u32: i32,
    ty_u64: i32,
    ty_f32: i32,
    ty_f64: i32,
    ty_bool: i32,
    ty_void: i32,
    ty_str: i32,
    ty_str_view: i32,
}

fn Sema.init(pool: InternPool, diags: DiagnosticList, ast: AstPool) -> Sema:
    var s = Sema {
        pool: pool,
        diags: diags,
        ast: ast,
        type_kinds: Vec.new(),
        type_d0: Vec.new(),
        type_d1: Vec.new(),
        type_d2: Vec.new(),
        type_extra: Vec.new(),
        named_types: HashMap.new(),
        sig_names: Vec.new(),
        sig_type_ids: Vec.new(),
        sig_ret_types: Vec.new(),
        sig_param_starts: Vec.new(),
        sig_param_counts: Vec.new(),
        sig_variadic: Vec.new(),
        sig_params: Vec.new(),
        sig_lookup: HashMap.new(),
        extern_fn_names: HashMap.new(),
        fn_decl_nodes: HashMap.new(),
        generic_fn_nodes: HashMap.new(),
        variant_lookup: HashMap.new(),
        trait_method_names: Vec.new(),
        trait_method_starts: Vec.new(),
        trait_method_counts: Vec.new(),
        trait_name_syms: Vec.new(),
        trait_lookup: HashMap.new(),
        impl_extra: Vec.new(),
        impl_starts: Vec.new(),
        impl_counts: Vec.new(),
        impl_type_syms: Vec.new(),
        impl_lookup: HashMap.new(),
        local_trait_names: HashMap.new(),
        local_type_names: HashMap.new(),
        ephemeral_types: HashMap.new(),
        must_use_fns: HashMap.new(),
        result_option_fns: HashMap.new(),
        task_fns: HashMap.new(),
        method_decl_origins: HashMap.new(),
        method_has_inherent: HashMap.new(),
        bind_names: Vec.new(),
        bind_types: Vec.new(),
        bind_muts: Vec.new(),
        bind_states: Vec.new(),
        bind_is_task: Vec.new(),
        scope_starts: Vec.new(),
        borrow_kinds: Vec.new(),
        borrow_places: Vec.new(),
        borrow_fields: Vec.new(),
        borrow_refs: Vec.new(),
        current_return_type: 0,
        current_gen_yield_type: 0,
        has_gen_yield_type: 0,
        in_pipeline_rhs: 0,
        in_comptime_fn: 0,
        no_std: 0,
        alloc: 0,
        in_defer: 0,
        break_value_type: 0,
        has_break_value_type: 0,
        loop_depth: 0,
        closure_direct_arg_depth: 0,
        expected_expr_type: 0,
        has_expected_type: 0,
        local_file_id: 0,
        collecting_types: 0,
        ty_i8: 0, ty_i16: 0, ty_i32: 0, ty_i64: 0,
        ty_u8: 0, ty_u16: 0, ty_u32: 0, ty_u64: 0,
        ty_f32: 0, ty_f64: 0, ty_bool: 0, ty_void: 0,
        ty_str: 0, ty_str_view: 0,
    }

    // Index 0 = error type (sentinel).
    s.add_type(TY_ERR(), 0, 0, 0)

    // Register primitive types.
    s.ty_i8 = s.add_type(TY_INT(), 8, 1, 0)
    s.ty_i16 = s.add_type(TY_INT(), 16, 1, 0)
    s.ty_i32 = s.add_type(TY_INT(), 32, 1, 0)
    s.ty_i64 = s.add_type(TY_INT(), 64, 1, 0)
    s.ty_u8 = s.add_type(TY_INT(), 8, 0, 0)
    s.ty_u16 = s.add_type(TY_INT(), 16, 0, 0)
    s.ty_u32 = s.add_type(TY_INT(), 32, 0, 0)
    s.ty_u64 = s.add_type(TY_INT(), 64, 0, 0)
    s.ty_f32 = s.add_type(TY_FLOAT(), 32, 0, 0)
    s.ty_f64 = s.add_type(TY_FLOAT(), 64, 0, 0)
    s.ty_bool = s.add_type(TY_BOOL(), 0, 0, 0)
    s.ty_void = s.add_type(TY_VOID(), 0, 0, 0)
    s.ty_str = s.add_type(TY_STR(), 0, 0, 0)
    s.ty_str_view = s.add_type(TY_REF(), s.ty_str, 0, 0)

    // Register primitive names.
    s.register_prim("i8", s.ty_i8)
    s.register_prim("i16", s.ty_i16)
    s.register_prim("i32", s.ty_i32)
    s.register_prim("i64", s.ty_i64)
    s.register_prim("u8", s.ty_u8)
    s.register_prim("u16", s.ty_u16)
    s.register_prim("u32", s.ty_u32)
    s.register_prim("u64", s.ty_u64)
    s.register_prim("f32", s.ty_f32)
    s.register_prim("f64", s.ty_f64)
    s.register_prim("bool", s.ty_bool)
    s.register_prim("void", s.ty_void)
    s.register_prim("str", s.ty_str)
    s.register_prim("String", s.ty_str)
    s.register_prim("StrView", s.ty_str_view)

    // Push root scope marker
    s.scope_starts.push(0)
    s

fn Sema.register_prim(self: Sema, name: str, tid: i32):
    let sym = self.pool.intern(name)
    self.named_types.insert(sym, tid)

// ── Type management ──────────────────────────────────────────────

fn Sema.add_type(self: Sema, kind: i32, d0: i32, d1: i32, d2: i32) -> i32:
    let id = self.type_kinds.len() as i32
    self.type_kinds.push(kind)
    self.type_d0.push(d0)
    self.type_d1.push(d1)
    self.type_d2.push(d2)
    id

fn Sema.get_type_kind(self: Sema, tid: i32) -> i32:
    if tid < 0 or tid >= self.type_kinds.len() as i32:
        return TY_ERR()
    self.type_kinds.get(tid as i64)

fn Sema.get_type_d0(self: Sema, tid: i32) -> i32:
    if tid < 0 or tid >= self.type_d0.len() as i32:
        return 0
    self.type_d0.get(tid as i64)

fn Sema.get_type_d1(self: Sema, tid: i32) -> i32:
    if tid < 0 or tid >= self.type_d1.len() as i32:
        return 0
    self.type_d1.get(tid as i64)

fn Sema.get_type_d2(self: Sema, tid: i32) -> i32:
    if tid < 0 or tid >= self.type_d2.len() as i32:
        return 0
    self.type_d2.get(tid as i64)

fn Sema.resolve_alias(self: Sema, tid: i32) -> i32:
    var current = tid
    var depth = 0
    while depth < 32:
        if self.get_type_kind(current) == TY_ALIAS():
            current = self.get_type_d0(current)
        else:
            return current
        depth = depth + 1
    current

// ── Scope management ─────────────────────────────────────────────

fn Sema.push_scope(self: Sema):
    self.scope_starts.push(self.bind_names.len() as i32)

fn Sema.pop_scope(self: Sema):
    let len = self.scope_starts.len() as i32
    if len == 0:
        return
    let start = self.scope_starts.get((len - 1) as i64)
    // Expire borrows for bindings leaving scope
    self.expire_borrows_in_scope(start)
    // Remove bindings
    while self.bind_names.len() as i32 > start:
        self.bind_names.pop()
        self.bind_types.pop()
        self.bind_muts.pop()
        self.bind_states.pop()
        self.bind_is_task.pop()
    self.scope_starts.pop()

fn Sema.scope_put(self: Sema, sym: i32, tid: i32, is_mut: i32):
    self.bind_names.push(sym)
    self.bind_types.push(tid)
    self.bind_muts.push(is_mut)
    self.bind_states.push(VS_LIVE())
    self.bind_is_task.push(0)

fn Sema.scope_lookup(self: Sema, sym: i32) -> i32:
    var i = self.bind_names.len() as i32 - 1
    while i >= 0:
        if self.bind_names.get(i as i64) == sym:
            return self.bind_types.get(i as i64)
        i = i - 1
    0 - 1

fn Sema.scope_lookup_mut(self: Sema, sym: i32) -> i32:
    var i = self.bind_names.len() as i32 - 1
    while i >= 0:
        if self.bind_names.get(i as i64) == sym:
            return self.bind_muts.get(i as i64)
        i = i - 1
    0

fn Sema.scope_lookup_state(self: Sema, sym: i32) -> i32:
    var i = self.bind_names.len() as i32 - 1
    while i >= 0:
        if self.bind_names.get(i as i64) == sym:
            return self.bind_states.get(i as i64)
        i = i - 1
    VS_LIVE()

fn Sema.scope_set_state(self: Sema, sym: i32, state: i32):
    var i = self.bind_names.len() as i32 - 1
    while i >= 0:
        if self.bind_names.get(i as i64) == sym:
            self.bind_states.set_i32(i as i64, state)
            return
        i = i - 1

fn Sema.scope_has(self: Sema, sym: i32) -> i32:
    var i = self.bind_names.len() as i32 - 1
    while i >= 0:
        if self.bind_names.get(i as i64) == sym:
            return 1
        i = i - 1
    0

// ── Function signature management ────────────────────────────────

fn Sema.add_sig(self: Sema, name: i32, fn_tid: i32, ret: i32, param_start: i32, param_count: i32, variadic: i32):
    let idx = self.sig_names.len() as i32
    self.sig_names.push(name)
    self.sig_type_ids.push(fn_tid)
    self.sig_ret_types.push(ret)
    self.sig_param_starts.push(param_start)
    self.sig_param_counts.push(param_count)
    self.sig_variadic.push(variadic)
    self.sig_lookup.insert(name, idx)

fn Sema.get_sig(self: Sema, name: i32) -> i32:
    if self.sig_lookup.contains(name):
        return self.sig_lookup.get(name).unwrap()
    0 - 1

fn Sema.sig_return_type(self: Sema, idx: i32) -> i32:
    self.sig_ret_types.get(idx as i64)

fn Sema.sig_param_type(self: Sema, idx: i32, param_i: i32) -> i32:
    let start = self.sig_param_starts.get(idx as i64)
    self.sig_params.get((start + param_i) as i64)

fn Sema.sig_get_param_count(self: Sema, idx: i32) -> i32:
    self.sig_param_counts.get(idx as i64)

fn Sema.sig_is_variadic(self: Sema, idx: i32) -> i32:
    self.sig_variadic.get(idx as i64)

// ── Main entry point ─────────────────────────────────────────────

fn Sema.check_module(self: Sema):
    self.compute_method_origins()
    self.collect_declarations()
    self.check_bodies()

// ── Pass 1: Declaration collection ───────────────────────────────

fn Sema.compute_method_origins(self: Sema):
    var di = 0
    while di < self.ast.decl_count():
        let decl = self.ast.get_decl(di)
        let kind = self.ast.kind(decl)
        if kind == NK_IMPL_DECL():
            let trait_sym = self.ast.get_data2(decl)
            var origin = 0
            if trait_sym != 0:
                origin = 1
            // Walk backwards finding method fn_decls
            let impl_extra = self.ast.get_data1(decl)
            // Methods are added as decls before the impl_decl
            var j = di
            while j > 0:
                j = j - 1
                let md = self.ast.get_decl(j)
                if self.ast.kind(md) != NK_FN_DECL():
                    break
                let fn_name = self.ast.get_data0(md)
                self.method_decl_origins.insert(j, origin)
                if origin == 0:
                    if self.is_method_symbol(fn_name):
                        self.method_has_inherent.insert(fn_name, 1)
        di = di + 1

    // Top-level method syntax
    di = 0
    while di < self.ast.decl_count():
        let decl = self.ast.get_decl(di)
        if self.ast.kind(decl) == NK_FN_DECL():
            let fn_name = self.ast.get_data0(decl)
            if self.is_method_symbol(fn_name):
                if not self.method_decl_origins.contains(di):
                    self.method_has_inherent.insert(fn_name, 1)
        di = di + 1

fn Sema.is_method_symbol(self: Sema, sym: i32) -> i32:
    let name = self.pool.resolve(sym)
    var i = 0
    while i < name.len() as i32:
        if name[i] == 46:
            return 1
        i = i + 1
    0

fn Sema.should_skip_trait_method(self: Sema, decl_idx: i32, fn_sym: i32) -> i32:
    if self.is_method_symbol(fn_sym) == 0:
        return 0
    if self.method_decl_origins.contains(decl_idx):
        let origin = self.method_decl_origins.get(decl_idx).unwrap()
        if origin == 1:
            if self.method_has_inherent.contains(fn_sym):
                return 1
    0

fn Sema.collect_declarations(self: Sema):
    self.collecting_types = 1
    // Pass 1: collect named types and traits first so functions can refer
    // to imported or forward-declared types regardless of declaration order.
    var di = 0
    while di < self.ast.decl_count():
        let decl = self.ast.get_decl(di)
        let kind = self.ast.kind(decl)
        if kind == NK_TYPE_DECL():
            self.collect_type_decl(decl)
        if kind == NK_TRAIT_DECL():
            self.collect_trait_decl(decl)
        di = di + 1

    // Pass 2: collect impl declarations once trait/type tables exist.
    di = 0
    while di < self.ast.decl_count():
        let decl = self.ast.get_decl(di)
        if self.ast.kind(decl) == NK_IMPL_DECL():
            self.collect_impl_decl(decl)
        di = di + 1

    self.collecting_types = 0

    // Pass 3: collect function signatures and top-level let decls.
    di = 0
    while di < self.ast.decl_count():
        let decl = self.ast.get_decl(di)
        let kind = self.ast.kind(decl)
        if kind == NK_FN_DECL():
            let fn_name = self.ast.get_data0(decl)
            if self.should_skip_trait_method(di, fn_name) == 0:
                self.collect_fn_decl(decl)
        if kind == NK_EXTERN_FN():
            self.collect_extern_fn(decl)
        if kind == NK_LET_DECL():
            self.collect_let_decl(decl)
        di = di + 1

fn Sema.collect_type_decl(self: Sema, node: i32):
    let name = self.ast.get_data0(node)
    let extra_start = self.ast.get_data1(node)
    let sub_kind = self.ast.get_data2(node)

    if sub_kind == TDK_STRUCT():
        let field_count = self.ast.get_extra(extra_start)
        let te_start = self.type_extra.len() as i32
        var fi = 0
        while fi < field_count:
            let base = extra_start + 1 + fi * 3
            let f_name = self.ast.get_extra(base)
            let f_type_node = self.ast.get_extra(base + 1)
            let f_default = self.ast.get_extra(base + 2)
            let f_tid = self.resolve_type_expr(f_type_node)
            self.type_extra.push(f_name)
            self.type_extra.push(f_tid)
            self.type_extra.push(f_default)
            fi = fi + 1
        let tid = self.add_type(TY_STRUCT(), name, te_start, field_count)
        self.named_types.insert(name, tid)

    if sub_kind == TDK_ENUM():
        let variant_count = self.ast.get_extra(extra_start)
        let te_start = self.type_extra.len() as i32
        var vi = 0
        var epos = extra_start + 1
        while vi < variant_count:
            let v_name = self.ast.get_extra(epos)
            epos = epos + 1
            let payload_count = self.ast.get_extra(epos)
            epos = epos + 1
            self.type_extra.push(v_name)
            self.type_extra.push(payload_count)
            var pi = 0
            while pi < payload_count:
                let pt_node = self.ast.get_extra(epos)
                epos = epos + 1
                let pt_tid = self.resolve_type_expr(pt_node)
                self.type_extra.push(pt_tid)
                pi = pi + 1
            // Register variant lookup
            self.variant_lookup.insert(v_name, vi)
            vi = vi + 1
        let tid = self.add_type(TY_ENUM(), name, te_start, variant_count)
        self.named_types.insert(name, tid)
        // Re-register variants with actual enum TypeId
        vi = 0
        var vpos = te_start
        while vi < variant_count:
            let v_name = self.type_extra.get(vpos as i64)
            self.variant_lookup.insert(v_name, tid * 65536 + vi)
            let pc = self.type_extra.get((vpos + 1) as i64)
            vpos = vpos + 2 + pc
            vi = vi + 1

    if sub_kind == TDK_ALIAS():
        let aliased_node = self.ast.get_extra(extra_start)
        let target = self.resolve_type_expr(aliased_node)
        let tid = self.add_type(TY_ALIAS(), target, 0, 0)
        self.named_types.insert(name, tid)

    if sub_kind == TDK_DISTINCT():
        let inner_node = self.ast.get_extra(extra_start)
        let inner = self.resolve_type_expr(inner_node)
        // Distinct type: treat as single-field struct
        let te_start = self.type_extra.len() as i32
        let val_sym = self.pool.intern("value")
        self.type_extra.push(val_sym)
        self.type_extra.push(inner)
        self.type_extra.push(0)
        let tid = self.add_type(TY_STRUCT(), name, te_start, 1)
        self.named_types.insert(name, tid)

    self.local_type_names.insert(name, 1)

fn Sema.collect_fn_decl(self: Sema, node: i32):
    let fn_name = self.ast.get_data0(node)
    self.fn_decl_nodes.insert(fn_name, node)

    // Look up fn_meta for parameter info
    let meta = self.ast.find_fn_meta(node)
    if meta < 0:
        // No meta available — register with no params
        let fn_tid = self.add_type(TY_FN(), 0, 0, self.ty_void)
        self.add_sig(fn_name, fn_tid, self.ty_void, 0, 0, 0)
        return

    let flags = self.ast.fn_meta_flags(meta)
    let ret_node = self.ast.fn_meta_ret(meta)
    let param_start = self.ast.fn_meta_param_start(meta)
    let param_count = self.ast.fn_meta_param_count(meta)
    let tp_count = self.ast.fn_meta_tp_count(meta)

    // Generic functions: store for later monomorphization
    if tp_count > 0:
        self.generic_fn_nodes.insert(fn_name, node)
        return

    // Resolve param types
    let sig_param_start = self.sig_params.len() as i32
    var pi = 0
    while pi < param_count:
        let p_type_node = self.ast.get_extra(param_start + pi * 2 + 1)
        let p_tid = self.resolve_type_expr(p_type_node)
        self.sig_params.push(p_tid)
        pi = pi + 1

    let ret_type = self.resolve_type_expr(ret_node)
    let actual_ret = ret_type
    if actual_ret == 0 and ret_node == 0:
        // no return type annotation → void
        let _ = 0

    // Build fn type
    let fn_extra_start = self.type_extra.len() as i32
    pi = 0
    while pi < param_count:
        self.type_extra.push(self.sig_params.get((sig_param_start + pi) as i64))
        pi = pi + 1
    let fn_tid = self.add_type(TY_FN(), fn_extra_start, param_count, ret_type)

    self.add_sig(fn_name, fn_tid, ret_type, sig_param_start, param_count, 0)

    // Track must_use
    if (flags / FN_FLAG_MUST_USE()) % 2 == 1:
        self.must_use_fns.insert(fn_name, 1)
    // Track async fns
    if (flags / FN_FLAG_ASYNC()) % 2 == 1:
        self.task_fns.insert(fn_name, 1)

fn Sema.collect_extern_fn(self: Sema, node: i32):
    let name = self.ast.get_data0(node)
    let flags = self.ast.get_data2(node)
    let is_variadic = flags % 2

    let meta = self.ast.find_fn_meta(node)
    if meta < 0:
        let fn_tid = self.add_type(TY_FN(), 0, 0, self.ty_void)
        self.add_sig(name, fn_tid, self.ty_void, 0, 0, is_variadic)
        self.extern_fn_names.insert(name, 1)
        return

    let ret_node = self.ast.fn_meta_ret(meta)
    let param_start = self.ast.fn_meta_param_start(meta)
    let param_count = self.ast.fn_meta_param_count(meta)

    let sig_param_start = self.sig_params.len() as i32
    var pi = 0
    while pi < param_count:
        // extern params use the same parser extra layout as regular fns: [name, type]*
        let p_type_node = self.ast.get_extra(param_start + pi * 2 + 1)
        let p_tid = self.resolve_type_expr(p_type_node)
        self.sig_params.push(p_tid)
        pi = pi + 1

    let ret_type = self.resolve_type_expr(ret_node)

    let fn_extra_start = self.type_extra.len() as i32
    pi = 0
    while pi < param_count:
        self.type_extra.push(self.sig_params.get((sig_param_start + pi) as i64))
        pi = pi + 1
    let fn_tid = self.add_type(TY_FN(), fn_extra_start, param_count, ret_type)

    self.add_sig(name, fn_tid, ret_type, sig_param_start, param_count, is_variadic)
    self.extern_fn_names.insert(name, 1)

fn Sema.collect_let_decl(self: Sema, node: i32):
    let name = self.ast.get_data0(node)
    let flags = self.ast.get_data2(node)
    let is_mut = flags % 2
    self.scope_put(name, 0, is_mut)

fn Sema.collect_trait_decl(self: Sema, node: i32):
    let name = self.ast.get_data0(node)
    let extra_start = self.ast.get_data1(node)
    // Store trait info
    let trait_idx = self.trait_name_syms.len() as i32
    self.trait_name_syms.push(name)
    self.trait_method_starts.push(self.trait_method_names.len() as i32)
    // Parse trait methods from extra
    // extra layout: [method_count, [method_name, has_default, param_count, params...]*]
    // Simplified: just record the trait name
    self.trait_method_counts.push(0)
    self.trait_lookup.insert(name, trait_idx)
    self.local_trait_names.insert(name, 1)

fn Sema.collect_impl_decl(self: Sema, node: i32):
    let type_name = self.ast.get_data0(node)
    let trait_sym = self.ast.get_data2(node)
    if trait_sym == 0:
        return

    // Record impl
    if self.impl_lookup.contains(type_name):
        let idx = self.impl_lookup.get(type_name).unwrap()
        let count = self.impl_counts.get(idx as i64)
        self.impl_extra.push(trait_sym)
        self.impl_counts.set_i32(idx as i64, count + 1)
    else:
        let idx = self.impl_type_syms.len() as i32
        self.impl_type_syms.push(type_name)
        self.impl_starts.push(self.impl_extra.len() as i32)
        self.impl_counts.push(1)
        self.impl_extra.push(trait_sym)
        self.impl_lookup.insert(type_name, idx)

// ── Type expression resolution ───────────────────────────────────

fn Sema.resolve_type_expr(self: Sema, node: i32) -> i32:
    if node == 0:
        return 0

    let kind = self.ast.kind(node)

    if kind == NK_TYPE_NAMED():
        let sym = self.ast.get_data0(node)
        if self.named_types.contains(sym):
            return self.named_types.get(sym).unwrap()
        if self.collecting_types != 0:
            return 0
        self.emit_error("unknown type", node)
        return 0

    if kind == NK_TYPE_PTR():
        let pointee = self.resolve_type_expr(self.ast.get_data0(node))
        let is_mut = self.ast.get_data1(node)
        return self.add_type(TY_PTR(), pointee, is_mut, 0)

    if kind == NK_TYPE_REF():
        let pointee = self.resolve_type_expr(self.ast.get_data0(node))
        let is_mut = self.ast.get_data1(node)
        return self.add_type(TY_REF(), pointee, is_mut, 0)

    if kind == NK_TYPE_FN():
        let extra_start = self.ast.get_data0(node)
        let param_count = self.ast.get_data1(node)
        let ret_node = self.ast.get_data2(node)
        let te_start = self.type_extra.len() as i32
        var pi = 0
        while pi < param_count:
            let p_node = self.ast.get_extra(extra_start + pi)
            self.type_extra.push(self.resolve_type_expr(p_node))
            pi = pi + 1
        let ret = self.resolve_type_expr(ret_node)
        return self.add_type(TY_FN(), te_start, param_count, ret)

    if kind == NK_TYPE_ARRAY():
        let elem = self.resolve_type_expr(self.ast.get_data0(node))
        let size = self.ast.get_data1(node)
        return self.add_type(TY_ARRAY(), elem, size, 0)

    if kind == NK_TYPE_SLICE():
        let elem = self.resolve_type_expr(self.ast.get_data0(node))
        return self.add_type(TY_SLICE(), elem, 0, 0)

    if kind == NK_TYPE_TUPLE():
        let extra_start = self.ast.get_data0(node)
        let elem_count = self.ast.get_data1(node)
        let te_start = self.type_extra.len() as i32
        var ei = 0
        while ei < elem_count:
            let e_node = self.ast.get_extra(extra_start + ei)
            self.type_extra.push(self.resolve_type_expr(e_node))
            ei = ei + 1
        return self.add_type(TY_TUPLE(), te_start, elem_count, 0)

    if kind == NK_TYPE_OPTIONAL():
        let inner = self.resolve_type_expr(self.ast.get_data0(node))
        return 0

    if kind == NK_TYPE_TRAIT_OBJ():
        return 0

    if kind == NK_TYPE_GENERIC():
        return 0

    if kind == NK_TYPE_INFERRED():
        return 0

    0

// ── Pass 2: Check function bodies ────────────────────────────────

fn Sema.check_bodies(self: Sema):
    var di = 0
    while di < self.ast.decl_count():
        let decl = self.ast.get_decl(di)
        if self.ast.kind(decl) == NK_FN_DECL():
            let fn_name = self.ast.get_data0(decl)
            if self.should_skip_trait_method(di, fn_name) == 0:
                // Skip generic functions
                let meta = self.ast.find_fn_meta(decl)
                var tp_count = 0
                if meta >= 0:
                    tp_count = self.ast.fn_meta_tp_count(meta)
                if tp_count == 0:
                    self.check_fn_body(decl)
        di = di + 1

fn Sema.check_fn_body(self: Sema, node: i32):
    let fn_name = self.ast.get_data0(node)
    let body = self.ast.get_data1(node)
    let flags = self.ast.get_data2(node)

    let sig_idx = self.get_sig(fn_name)
    if sig_idx < 0:
        return

    let ret_type = self.sig_return_type(sig_idx)

    // Push function scope
    self.push_scope()

    // Add parameters to scope
    let meta = self.ast.find_fn_meta(node)
    if meta >= 0:
        let param_start = self.ast.fn_meta_param_start(meta)
        let param_count = self.ast.fn_meta_param_count(meta)
        var pi = 0
        while pi < param_count:
            let p_name = self.ast.get_extra(param_start + pi * 2)
            let p_tid = self.sig_param_type(sig_idx, pi)
            self.scope_put(p_name, p_tid, 0)
            pi = pi + 1

    // Set current return type
    let saved_ret = self.current_return_type
    let is_gen = (flags / FN_FLAG_GEN()) % 2
    if is_gen == 1:
        self.current_return_type = self.ty_void
    else:
        self.current_return_type = ret_type
    let saved_comptime = self.in_comptime_fn
    if (flags / FN_FLAG_COMPTIME()) % 2 == 1:
        self.in_comptime_fn = 1

    // Check body
    self.check_expr(body)

    // Restore state
    self.current_return_type = saved_ret
    self.in_comptime_fn = saved_comptime
    self.pop_scope()

// ── Expression type checking ─────────────────────────────────────

fn Sema.check_expr(self: Sema, node: i32) -> i32:
    if node == 0:
        return 0

    let kind = self.ast.kind(node)

    if kind == NK_INT_LIT():
        return self.ty_i32

    if kind == NK_FLOAT_LIT():
        return self.ty_f64

    if kind == NK_BOOL_LIT():
        return self.ty_bool

    if kind == NK_STRING_LIT():
        return self.ty_str

    if kind == NK_C_STRING_LIT():
        return self.add_type(TY_PTR(), self.ty_i8, 0, 0)

    if kind == NK_IDENT():
        return self.check_ident(self.ast.get_data0(node), node)

    if kind == NK_BINARY():
        return self.check_binary(node)

    if kind == NK_UNARY():
        return self.check_unary(node)

    if kind == NK_GROUPED():
        return self.check_expr(self.ast.get_data0(node))

    if kind == NK_BLOCK():
        return self.check_block(node)

    if kind == NK_LET_BINDING():
        return self.check_let_binding(node)

    if kind == NK_IF_EXPR():
        return self.check_if_expr(node)

    if kind == NK_CALL():
        return self.check_call(node)

    if kind == NK_RETURN():
        return self.check_return(node)

    if kind == NK_ASSIGN():
        return self.check_assign(node)

    if kind == NK_WHILE():
        let cond = self.ast.get_data0(node)
        let body = self.ast.get_data1(node)
        self.check_expr(cond)
        self.loop_depth = self.loop_depth + 1
        self.check_expr(body)
        self.loop_depth = self.loop_depth - 1
        return self.ty_void

    if kind == NK_LOOP():
        let saved_break = self.break_value_type
        let saved_has = self.has_break_value_type
        self.break_value_type = 0
        self.has_break_value_type = 0
        self.loop_depth = self.loop_depth + 1
        self.check_expr(self.ast.get_data0(node))
        self.loop_depth = self.loop_depth - 1
        var result = self.ty_void
        if self.has_break_value_type != 0:
            result = self.break_value_type
        self.break_value_type = saved_break
        self.has_break_value_type = saved_has
        return result

    if kind == NK_FOR():
        return self.check_for(node)

    if kind == NK_BREAK():
        if self.in_defer != 0:
            self.emit_error("break not allowed in defer", node)
        if self.loop_depth == 0:
            self.emit_error("break outside of loop", node)
        let val = self.ast.get_data0(node)
        if val != 0:
            let vt = self.check_expr(val)
            if vt != 0:
                self.break_value_type = vt
                self.has_break_value_type = 1
        return self.ty_void

    if kind == NK_CONTINUE():
        if self.in_defer != 0:
            self.emit_error("continue not allowed in defer", node)
        if self.loop_depth == 0:
            self.emit_error("continue outside of loop", node)
        return self.ty_void

    if kind == NK_FIELD_ACCESS():
        return self.check_field_access(node)

    if kind == NK_INDEX():
        return self.check_index(node)

    if kind == NK_SLICE():
        return self.check_slice(node)

    if kind == NK_ARRAY_LIT():
        return self.check_array_literal(node)

    if kind == NK_STRUCT_LIT():
        return self.check_struct_literal(node)

    if kind == NK_MATCH():
        return self.check_match_expr(node)

    if kind == NK_ENUM_VARIANT():
        return self.check_enum_variant(node)

    if kind == NK_CLOSURE():
        return self.check_closure(node)

    if kind == NK_CAST():
        self.check_expr(self.ast.get_data0(node))
        return self.resolve_type_expr(self.ast.get_data1(node))

    if kind == NK_PIPELINE():
        return self.check_pipeline(node)

    if kind == NK_DEFER():
        let saved = self.in_defer
        self.in_defer = 1
        self.check_expr(self.ast.get_data0(node))
        self.in_defer = saved
        return self.ty_void

    if kind == NK_TUPLE():
        return self.check_tuple(node)

    if kind == NK_RANGE():
        return self.check_range(node)

    if kind == NK_VARIANT_SHORTHAND():
        let name = self.ast.get_data0(node)
        if self.variant_lookup.contains(name):
            let vi = self.variant_lookup.get(name).unwrap()
            return vi / 65536
        return 0

    if kind == NK_WITH_EXPR():
        return self.check_with_expr(node)

    if kind == NK_RECORD_UPDATE():
        return self.check_record_update(node)

    if kind == NK_LET_ELSE():
        return self.check_let_else(node)

    if kind == NK_TUPLE_DESTRUCTURE():
        return self.check_tuple_destructure(node)

    if kind == NK_AWAIT():
        return self.check_expr(self.ast.get_data0(node))

    if kind == NK_ASYNC_BLOCK():
        return self.check_expr(self.ast.get_data0(node))

    if kind == NK_SPAWN():
        self.check_expr(self.ast.get_data0(node))
        return self.ty_void

    if kind == NK_YIELD():
        let inner = self.check_expr(self.ast.get_data0(node))
        if self.has_gen_yield_type == 0:
            self.emit_error("yield used outside generator function", node)
        return self.ty_void

    if kind == NK_COMPTIME():
        return self.check_expr(self.ast.get_data0(node))

    if kind == NK_ASYNC_SCOPE():
        let body = self.ast.get_data1(node)
        let name = self.ast.get_data0(node)
        self.push_scope()
        self.scope_put(name, self.ty_void, 0)
        let result = self.check_expr(body)
        self.pop_scope()
        return result

    if kind == NK_SELECT_AWAIT():
        let extra_start = self.ast.get_data0(node)
        let arm_count = self.ast.get_data1(node)
        var result = self.ty_void
        var ai = 0
        while ai < arm_count:
            // Each select arm has: task_node, name_sym, body_node
            let task = self.ast.get_extra(extra_start + ai * 3)
            let arm_name = self.ast.get_extra(extra_start + ai * 3 + 1)
            let arm_body = self.ast.get_extra(extra_start + ai * 3 + 2)
            self.check_expr(task)
            self.push_scope()
            self.scope_put(arm_name, self.ty_i32, 0)
            result = self.check_expr(arm_body)
            self.pop_scope()
            ai = ai + 1
        return result

    if kind == NK_ARRAY_COMPREHENSION():
        let expr = self.ast.get_data0(node)
        let binding = self.ast.get_data1(node)
        let iterable = self.ast.get_data2(node)
        self.push_scope()
        let iter_ty = self.check_expr(iterable)
        let elem_ty = self.infer_for_element_type(iter_ty)
        self.scope_put(binding, elem_ty, 0)
        let result_elem = self.check_expr(expr)
        self.pop_scope()
        return self.add_type(TY_ARRAY(), result_elem, 0, 0)

    if kind == NK_OPTIONAL_CHAIN():
        let base = self.check_expr(self.ast.get_data0(node))
        return base

    if kind == NK_POISONED_EXPR():
        return 0

    0

// ── Expression checking helpers ──────────────────────────────────

fn Sema.check_ident(self: Sema, sym: i32, node: i32) -> i32:
    // Check local/param scope
    let tid = self.scope_lookup(sym)
    if tid >= 0:
        let state = self.scope_lookup_state(sym)
        if state == VS_MOVED():
            self.emit_error("use of moved value", node)
        return tid

    // Check function names
    let sig_idx = self.get_sig(sym)
    if sig_idx >= 0:
        return self.sig_type_ids.get(sig_idx as i64)

    // Check generic functions
    if self.generic_fn_nodes.contains(sym):
        return 0

    // Check type names
    if self.named_types.contains(sym):
        return self.named_types.get(sym).unwrap()

    // Check enum variants
    if self.variant_lookup.contains(sym):
        let vi = self.variant_lookup.get(sym).unwrap()
        return vi / 65536

    // Built-in functions
    if self.is_builtin_fn(sym):
        return 0

    // Built-in values
    if self.is_builtin_value(sym):
        return 0

    // Unknown identifier
    self.emit_error("undefined variable", node)
    0

fn Sema.check_binary(self: Sema, node: i32) -> i32:
    let op = self.ast.get_data0(node)
    let lhs = self.check_expr(self.ast.get_data1(node))
    let rhs = self.check_expr(self.ast.get_data2(node))

    if lhs == 0 or rhs == 0:
        return 0

    // Comparison operators return bool
    if op == OP_EQ() or op == OP_NEQ() or op == OP_LT() or op == OP_GT() or op == OP_LTE() or op == OP_GTE() or op == OP_IN() or op == OP_NOT_IN():
        return self.ty_bool

    // Logical operators
    if op == OP_AND() or op == OP_OR():
        if lhs != self.ty_bool:
            self.emit_error("left operand of logical operator must be bool", node)
        if rhs != self.ty_bool:
            self.emit_error("right operand of logical operator must be bool", node)
        return self.ty_bool

    // Arithmetic
    if op == OP_ADD() or op == OP_SUB() or op == OP_MUL() or op == OP_DIV() or op == OP_MOD():
        if op == OP_ADD() and lhs == self.ty_str and rhs == self.ty_str:
            return self.ty_str
        let result = self.arithmetic_result_type(lhs, rhs)
        if result != 0:
            return result
        self.emit_error("arithmetic operator requires numeric operands", node)
        return 0

    // Bitwise
    if op == OP_BIT_AND() or op == OP_BIT_OR() or op == OP_BIT_XOR() or op == OP_SHL() or op == OP_SHR():
        return lhs

    // Wrapping arithmetic
    if op == OP_ADD_WRAP() or op == OP_SUB_WRAP() or op == OP_MUL_WRAP():
        return lhs

    // Default (??)
    if op == OP_DEFAULT():
        return lhs

    // Concat (++)
    if op == OP_CONCAT():
        return self.ty_str

    0

fn Sema.check_unary(self: Sema, node: i32) -> i32:
    let op = self.ast.get_data0(node)
    let operand = self.check_expr(self.ast.get_data1(node))
    if operand == 0:
        return 0

    if op == UOP_NEGATE():
        return operand
    if op == UOP_NOT():
        return self.ty_bool
    if op == UOP_REF():
        return self.add_type(TY_REF(), operand, 0, 0)
    if op == UOP_MUT_REF():
        return self.add_type(TY_REF(), operand, 1, 0)
    if op == UOP_DEREF():
        let resolved = self.resolve_alias(operand)
        let tk = self.get_type_kind(resolved)
        if tk == TY_REF():
            return self.get_type_d0(resolved)
        if tk == TY_PTR():
            return self.get_type_d0(resolved)
        return 0
    if op == UOP_TRY():
        if self.in_defer != 0:
            self.emit_error("? operator not allowed in defer", node)
        return 0

    0

fn Sema.check_block(self: Sema, node: i32) -> i32:
    let extra_start = self.ast.get_data0(node)
    let stmt_count = self.ast.get_data1(node)
    let tail = self.ast.get_data2(node)

    self.push_scope()

    var i = 0
    while i < stmt_count:
        let stmt = self.ast.get_extra(extra_start + i)
        self.check_expr(stmt)
        i = i + 1

    var result = self.ty_void
    if tail != 0:
        result = self.check_expr(tail)

    self.pop_scope()
    result

fn Sema.check_let_binding(self: Sema, node: i32) -> i32:
    let name = self.ast.get_data0(node)
    let value = self.ast.get_data1(node)
    let flags = self.ast.get_data2(node)
    let is_mut = flags % 2

    let val_type = self.check_expr(value)

    // Move semantics
    self.mark_moved_if_consumed(value)

    self.scope_put(name, val_type, is_mut)
    self.ty_void

fn Sema.check_if_expr(self: Sema, node: i32) -> i32:
    let cond = self.ast.get_data0(node)
    let then_body = self.ast.get_data1(node)
    let else_body = self.ast.get_data2(node)

    self.check_expr(cond)
    let then_type = self.check_expr(then_body)

    if else_body != 0:
        let else_type = self.check_expr(else_body)
        if then_type != 0 and else_type != 0:
            if self.types_compatible(then_type, else_type):
                return then_type
            return self.arithmetic_result_type(then_type, else_type)
        if then_type != 0:
            return then_type
        return else_type

    then_type

fn Sema.check_return(self: Sema, node: i32) -> i32:
    if self.in_defer != 0:
        self.emit_error("return not allowed in defer", node)
    let value = self.ast.get_data0(node)
    if value != 0:
        let val_type = self.check_expr(value)
        if self.current_return_type != 0 and val_type != 0:
            if not self.types_compatible(self.current_return_type, val_type):
                if self.arithmetic_result_type(self.current_return_type, val_type) == 0:
                    self.emit_error("return type mismatch", node)
    self.ty_void

fn Sema.check_assign(self: Sema, node: i32) -> i32:
    let target = self.ast.get_data0(node)
    let value = self.ast.get_data1(node)

    let target_type = self.check_expr(target)
    let value_type = self.check_expr(value)

    // Check mutability
    if self.ast.kind(target) == NK_IDENT():
        let target_sym = self.ast.get_data0(target)
        if self.scope_has(target_sym) != 0:
            if self.scope_lookup_mut(target_sym) == 0:
                self.emit_error("cannot assign to immutable variable", node)

    // Check type compatibility
    if target_type != 0 and value_type != 0:
        if not self.types_compatible(target_type, value_type):
            if self.arithmetic_result_type(target_type, value_type) == 0:
                self.emit_error("type mismatch in assignment", node)

    // Move semantics
    self.mark_moved_if_consumed(value)

    // Reinitialize target
    if self.ast.kind(target) == NK_IDENT():
        let target_sym = self.ast.get_data0(target)
        self.scope_set_state(target_sym, VS_LIVE())

    self.ty_void

fn Sema.check_for(self: Sema, node: i32) -> i32:
    let binding = self.ast.get_data0(node)
    let iterable = self.ast.get_data1(node)
    let body = self.ast.get_data2(node)

    let iter_type = self.check_expr(iterable)
    let elem_type = self.infer_for_element_type(iter_type)

    self.push_scope()
    self.scope_put(binding, elem_type, 0)
    self.loop_depth = self.loop_depth + 1
    self.check_expr(body)
    self.loop_depth = self.loop_depth - 1
    self.pop_scope()
    self.ty_void

fn Sema.check_field_access(self: Sema, node: i32) -> i32:
    let expr = self.ast.get_data0(node)
    let field = self.ast.get_data1(node)
    let obj_type = self.check_expr(expr)

    if obj_type == 0:
        return 0

    let resolved = self.resolve_alias(obj_type)
    let tk = self.get_type_kind(resolved)

    // Auto-deref through ptrs and refs
    var field_base = resolved
    if tk == TY_PTR() or tk == TY_REF():
        field_base = self.resolve_alias(self.get_type_d0(resolved))

    let ftk = self.get_type_kind(field_base)

    if ftk == TY_STRUCT():
        let st_name = self.get_type_d0(field_base)
        let te_start = self.get_type_d1(field_base)
        let field_count = self.get_type_d2(field_base)
        var fi = 0
        while fi < field_count:
            let f_name = self.type_extra.get((te_start + fi * 3) as i64)
            if f_name == field:
                return self.type_extra.get((te_start + fi * 3 + 1) as i64)
            fi = fi + 1
        return 0

    if ftk == TY_TUPLE():
        let te_start = self.get_type_d0(field_base)
        let elem_count = self.get_type_d1(field_base)
        let field_name = self.pool.resolve(field)
        // Parse field index
        var idx = 0
        var vi = 0
        while vi < field_name.len() as i32:
            let ch = field_name[vi]
            if ch >= 48 and ch <= 57:
                idx = idx * 10 + ch - 48
            vi = vi + 1
        if idx < elem_count:
            return self.type_extra.get((te_start + idx) as i64)
        return 0

    if ftk == TY_ARRAY() or ftk == TY_SLICE() or ftk == TY_STR():
        let field_name = self.pool.resolve(field)
        if field_name == "len":
            return self.ty_i64
        return 0

    if ftk == TY_ENUM():
        return field_base

    0

fn Sema.check_index(self: Sema, node: i32) -> i32:
    let expr = self.ast.get_data0(node)
    let index = self.ast.get_data1(node)
    let arr_type = self.check_expr(expr)
    self.check_expr(index)

    if arr_type == 0:
        return 0

    let resolved = self.resolve_alias(arr_type)
    let tk = self.get_type_kind(resolved)
    if tk == TY_ARRAY():
        return self.get_type_d0(resolved)
    if tk == TY_SLICE():
        return self.get_type_d0(resolved)
    0

fn Sema.check_slice(self: Sema, node: i32) -> i32:
    let expr = self.ast.get_data0(node)
    let start = self.ast.get_data1(node)
    let end = self.ast.get_data2(node)
    let arr_type = self.check_expr(expr)
    if start != 0:
        self.check_expr(start)
    if end != 0:
        self.check_expr(end)

    if arr_type == 0:
        return 0

    let resolved = self.resolve_alias(arr_type)
    let tk = self.get_type_kind(resolved)
    if tk == TY_ARRAY():
        let elem = self.get_type_d0(resolved)
        return self.add_type(TY_SLICE(), elem, 0, 0)
    if tk == TY_SLICE():
        return resolved
    0

fn Sema.check_array_literal(self: Sema, node: i32) -> i32:
    let extra_start = self.ast.get_data0(node)
    let elem_count = self.ast.get_data1(node)
    if elem_count == 0:
        return 0

    var elem_type = 0
    var i = 0
    while i < elem_count:
        let elem = self.ast.get_extra(extra_start + i)
        let et = self.check_expr(elem)
        if elem_type == 0:
            elem_type = et
        i = i + 1

    self.add_type(TY_ARRAY(), elem_type, elem_count, 0)

fn Sema.check_struct_literal(self: Sema, node: i32) -> i32:
    let name = self.ast.get_data0(node)
    let extra_start = self.ast.get_data1(node)
    let field_count = self.ast.get_data2(node)

    if self.named_types.contains(name):
        let tid = self.named_types.get(name).unwrap()
        let resolved = self.resolve_alias(tid)
        if self.get_type_kind(resolved) == TY_STRUCT():
            // Check field initializers
            var fi = 0
            while fi < field_count:
                let f_name = self.ast.get_extra(extra_start + fi * 2)
                let f_value = self.ast.get_extra(extra_start + fi * 2 + 1)
                self.check_expr(f_value)
                fi = fi + 1
            return resolved
    0

fn Sema.check_match_expr(self: Sema, node: i32) -> i32:
    let subject = self.ast.get_data0(node)
    let extra_start = self.ast.get_data1(node)
    let arm_count = self.ast.get_data2(node)

    let subject_type = self.check_expr(subject)
    var result_type = 0

    var ai = 0
    while ai < arm_count:
        let arm_node = self.ast.get_extra(extra_start + ai)
        let pat = self.ast.get_data0(arm_node)
        let arm_body = self.ast.get_data1(arm_node)
        let guard = self.ast.get_data2(arm_node)

        self.push_scope()
        self.check_pattern(pat, subject_type)
        if guard != 0:
            self.check_expr(guard)
        let arm_type = self.check_expr(arm_body)
        self.pop_scope()

        if result_type == 0:
            result_type = arm_type
        ai = ai + 1

    result_type

fn Sema.check_pattern(self: Sema, node: i32, subject_type: i32):
    if node == 0:
        return

    let kind = self.ast.kind(node)

    if kind == NK_PAT_WILDCARD():
        return

    if kind == NK_PAT_IDENT():
        let sym = self.ast.get_data0(node)
        self.scope_put(sym, subject_type, 0)
        return

    if kind == NK_PAT_INT() or kind == NK_PAT_BOOL() or kind == NK_PAT_STRING():
        return

    if kind == NK_PAT_VARIANT():
        let v_name = self.ast.get_data0(node)
        let v_extra = self.ast.get_data1(node)
        let bind_count = self.ast.get_data2(node)
        // Bind each payload variable
        var bi = 0
        while bi < bind_count:
            let b_sym = self.ast.get_extra(v_extra + bi)
            self.scope_put(b_sym, 0, 0)
            bi = bi + 1
        return

    if kind == NK_PAT_OR():
        let p_extra = self.ast.get_data0(node)
        let p_count = self.ast.get_data1(node)
        var pi = 0
        while pi < p_count:
            self.check_pattern(self.ast.get_extra(p_extra + pi), subject_type)
            pi = pi + 1
        return

    if kind == NK_PAT_AT_BINDING():
        let at_name = self.ast.get_data0(node)
        let inner = self.ast.get_data1(node)
        self.scope_put(at_name, subject_type, 0)
        self.check_pattern(inner, subject_type)
        return

    if kind == NK_PAT_TUPLE():
        let t_extra = self.ast.get_data0(node)
        let t_count = self.ast.get_data1(node)
        var ti = 0
        while ti < t_count:
            self.check_pattern(self.ast.get_extra(t_extra + ti), 0)
            ti = ti + 1
        return

    if kind == NK_PAT_SLICE():
        let s_extra = self.ast.get_data0(node)
        let head_count = self.ast.get_data1(node)
        let rest_sym = self.ast.get_data2(node)
        var elem_type = 0
        let resolved = self.resolve_alias(subject_type)
        let stk = self.get_type_kind(resolved)
        if stk == TY_ARRAY():
            elem_type = self.get_type_d0(resolved)
        if stk == TY_SLICE():
            elem_type = self.get_type_d0(resolved)
        let has_rest = self.ast.get_extra(s_extra)
        var hi = 0
        while hi < head_count:
            let h_sym = self.ast.get_extra(s_extra + 1 + hi)
            if h_sym != 0:
                self.scope_put(h_sym, elem_type, 0)
            hi = hi + 1
        if has_rest != 0 and rest_sym != 0:
            self.scope_put(rest_sym, self.ty_i64, 0)
        let tail_count = self.ast.get_extra(s_extra + 1 + head_count)
        var ti = 0
        while ti < tail_count:
            let t_sym = self.ast.get_extra(s_extra + 2 + head_count + ti)
            if t_sym != 0:
                self.scope_put(t_sym, elem_type, 0)
            ti = ti + 1
        return

    if kind == NK_PAT_STRUCT():
        let sp_extra = self.ast.get_data1(node)
        let sp_count = self.ast.get_data2(node)
        let has_rest = self.ast.get_extra(sp_extra)
        var spi = 0
        while spi < sp_count:
            let f_name = self.ast.get_extra(sp_extra + 1 + spi * 2)
            let f_pat = self.ast.get_extra(sp_extra + 1 + spi * 2 + 1)
            if f_pat != 0:
                self.check_pattern(f_pat, 0)
            else:
                self.scope_put(f_name, 0, 0)
            spi = spi + 1
        return

fn Sema.check_enum_variant(self: Sema, node: i32) -> i32:
    let type_name = self.ast.get_data0(node)
    let variant_name = self.ast.get_data1(node)
    let extra_start = self.ast.get_data2(node)
    let arg_count = self.ast.get_extra(extra_start)
    var ai = 0
    while ai < arg_count:
        self.check_expr(self.ast.get_extra(extra_start + 1 + ai))
        ai = ai + 1
    if self.named_types.contains(type_name):
        return self.resolve_alias(self.named_types.get(type_name).unwrap())
    0

fn Sema.check_closure(self: Sema, node: i32) -> i32:
    let body = self.ast.get_data0(node)
    let extra_start = self.ast.get_data1(node)
    let param_count = self.ast.get_data2(node)

    self.push_scope()
    let te_start = self.type_extra.len() as i32
    var pi = 0
    while pi < param_count:
        let p_sym = self.ast.get_extra(extra_start + pi)
        self.scope_put(p_sym, self.ty_i32, 0)
        self.type_extra.push(self.ty_i32)
        pi = pi + 1
    self.check_expr(body)
    self.pop_scope()

    self.add_type(TY_FN(), te_start, param_count, self.ty_i32)

fn Sema.check_pipeline(self: Sema, node: i32) -> i32:
    let lhs = self.ast.get_data0(node)
    let rhs = self.ast.get_data1(node)
    self.check_expr(lhs)
    let saved = self.in_pipeline_rhs
    self.in_pipeline_rhs = 1
    let rhs_ty = self.check_expr(rhs)
    self.in_pipeline_rhs = saved
    if rhs_ty != 0:
        let resolved = self.resolve_alias(rhs_ty)
        if self.get_type_kind(resolved) == TY_FN():
            return self.get_type_d2(resolved)
    rhs_ty

fn Sema.check_tuple(self: Sema, node: i32) -> i32:
    let extra_start = self.ast.get_data0(node)
    let elem_count = self.ast.get_data1(node)
    let te_start = self.type_extra.len() as i32
    var ei = 0
    while ei < elem_count:
        let elem = self.ast.get_extra(extra_start + ei)
        let et = self.check_expr(elem)
        self.type_extra.push(et)
        ei = ei + 1
    self.add_type(TY_TUPLE(), te_start, elem_count, 0)

fn Sema.check_range(self: Sema, node: i32) -> i32:
    let start = self.ast.get_data0(node)
    let end = self.ast.get_data1(node)
    let inclusive = self.ast.get_data2(node)
    var elem_type = self.ty_i32
    if start != 0:
        elem_type = self.check_expr(start)
    if end != 0:
        let end_ty = self.check_expr(end)
        if start == 0:
            elem_type = end_ty
    self.add_type(TY_RANGE(), elem_type, inclusive, 0)

fn Sema.check_with_expr(self: Sema, node: i32) -> i32:
    let source = self.ast.get_data0(node)
    let body = self.ast.get_data1(node)
    let name = self.ast.get_data2(node)
    let source_ty = self.check_expr(source)
    self.push_scope()
    self.scope_put(name, source_ty, 0)
    let body_ty = self.check_expr(body)
    self.pop_scope()
    body_ty

fn Sema.check_record_update(self: Sema, node: i32) -> i32:
    let source = self.ast.get_data0(node)
    let extra_start = self.ast.get_data1(node)
    let field_count = self.ast.get_data2(node)
    let source_ty = self.check_expr(source)
    var fi = 0
    while fi < field_count:
        let f_name = self.ast.get_extra(extra_start + fi * 2)
        let f_value = self.ast.get_extra(extra_start + fi * 2 + 1)
        self.check_expr(f_value)
        fi = fi + 1
    source_ty

fn Sema.check_let_else(self: Sema, node: i32) -> i32:
    let pattern = self.ast.get_data0(node)
    let value = self.ast.get_data1(node)
    let else_body = self.ast.get_data2(node)
    let val_type = self.check_expr(value)
    self.check_pattern(pattern, val_type)
    self.check_expr(else_body)
    self.ty_void

fn Sema.check_tuple_destructure(self: Sema, node: i32) -> i32:
    let extra_start = self.ast.get_data0(node)
    let name_count = self.ast.get_data1(node)
    let value = self.ast.get_data2(node)
    let val_type = self.check_expr(value)
    var ni = 0
    while ni < name_count:
        let n_sym = self.ast.get_extra(extra_start + ni)
        self.scope_put(n_sym, 0, 0)
        ni = ni + 1
    self.ty_void

fn Sema.check_call(self: Sema, node: i32) -> i32:
    let callee = self.ast.get_data0(node)
    let extra_start = self.ast.get_data1(node)
    let arg_count = self.ast.get_data2(node)

    // Method call: callee is field_access
    if self.ast.kind(callee) == NK_FIELD_ACCESS():
        return self.check_method_call(callee, extra_start, arg_count, node)

    // Direct call: callee should be ident
    var fn_sym = 0
    if self.ast.kind(callee) == NK_IDENT():
        fn_sym = self.ast.get_data0(callee)
    else:
        self.check_expr(callee)
        var ai = 0
        while ai < arg_count:
            self.check_expr(self.ast.get_extra(extra_start + ai))
            ai = ai + 1
        return 0

    // Check all arguments
    var ai = 0
    while ai < arg_count:
        self.check_expr(self.ast.get_extra(extra_start + ai))
        ai = ai + 1

    // Mark non-Copy args as moved
    ai = 0
    while ai < arg_count:
        self.mark_moved_if_consumed(self.ast.get_extra(extra_start + ai))
        ai = ai + 1

    // Known function
    let sig_idx = self.get_sig(fn_sym)
    if sig_idx >= 0:
        let ret = self.sig_return_type(sig_idx)
        // Check arg count
        let expected = self.sig_get_param_count(sig_idx)
        let actual = arg_count
        if self.in_pipeline_rhs != 0:
            // Pipeline adds one implicit arg
            let _ = 0
        if self.sig_is_variadic(sig_idx) == 0:
            if actual != expected and (self.in_pipeline_rhs == 0 or actual + 1 != expected):
                self.emit_error("wrong argument count", node)
        return ret

    // Local variable (function pointer)
    let local_tid = self.scope_lookup(fn_sym)
    if local_tid >= 0:
        let resolved = self.resolve_alias(local_tid)
        if self.get_type_kind(resolved) == TY_FN():
            return self.get_type_d2(resolved)
        return 0

    // Generic function
    if self.generic_fn_nodes.contains(fn_sym):
        return 0

    // Enum variant constructor
    if self.variant_lookup.contains(fn_sym):
        let vi = self.variant_lookup.get(fn_sym).unwrap()
        return vi / 65536

    // Built-in function
    if self.is_builtin_fn(fn_sym):
        return self.check_builtin_call(fn_sym, node)

    0

fn Sema.check_method_call(self: Sema, callee: i32, extra_start: i32, arg_count: i32, node: i32) -> i32:
    let expr = self.ast.get_data0(callee)
    let field = self.ast.get_data1(callee)
    let obj_type = self.check_expr(expr)

    // Check all arguments
    var ai = 0
    while ai < arg_count:
        self.check_expr(self.ast.get_extra(extra_start + ai))
        ai = ai + 1

    if obj_type == 0:
        return 0

    let resolved = self.resolve_alias(obj_type)
    let type_name_sym = self.get_type_name(resolved)

    if type_name_sym != 0:
        let method_key = self.method_key(type_name_sym, field)
        let sig_idx = self.get_sig(method_key)
        if sig_idx >= 0:
            return self.sig_return_type(sig_idx)

    // Static method call
    if self.ast.kind(expr) == NK_IDENT():
        let type_sym = self.ast.get_data0(expr)
        let method_key = self.method_key(type_sym, field)
        let sig_idx = self.get_sig(method_key)
        if sig_idx >= 0:
            return self.sig_return_type(sig_idx)

    0

fn Sema.check_builtin_call(self: Sema, fn_sym: i32, node: i32) -> i32:
    let name = self.pool.resolve(fn_sym)
    if name == "println" or name == "print":
        return self.ty_void
    if name == "assert":
        return self.ty_void
    if name == "Channel":
        return self.ty_i64
    if name == "send":
        return self.ty_void
    if name == "recv":
        return self.ty_i32
    if name == "close":
        return self.ty_void
    0

// ── Helper functions ─────────────────────────────────────────────

fn Sema.infer_for_element_type(self: Sema, iter_type: i32) -> i32:
    if iter_type == 0:
        return 0
    let resolved = self.resolve_alias(iter_type)
    let tk = self.get_type_kind(resolved)
    if tk == TY_RANGE():
        return self.get_type_d0(resolved)
    if tk == TY_ARRAY():
        return self.get_type_d0(resolved)
    if tk == TY_SLICE():
        return self.get_type_d0(resolved)
    self.ty_i32

fn Sema.mark_moved_if_consumed(self: Sema, node: i32):
    if node == 0:
        return
    let kind = self.ast.kind(node)
    if kind == NK_IDENT():
        let sym = self.ast.get_data0(node)
        if self.scope_has(sym) != 0:
            let tid = self.scope_lookup(sym)
            if not self.is_copy(tid):
                self.scope_set_state(sym, VS_MOVED())
    if kind == NK_GROUPED():
        self.mark_moved_if_consumed(self.ast.get_data0(node))

fn Sema.method_key(self: Sema, type_sym: i32, method_sym: i32) -> i32:
    let type_name = self.pool.resolve(type_sym)
    let method_name = self.pool.resolve(method_sym)
    self.pool.intern(type_name ++ "." ++ method_name)

fn Sema.get_type_name(self: Sema, tid: i32) -> i32:
    let tk = self.get_type_kind(tid)
    if tk == TY_STRUCT():
        return self.get_type_d0(tid)
    if tk == TY_ENUM():
        return self.get_type_d0(tid)
    0

// ── Type compatibility ───────────────────────────────────────────

fn Sema.types_compatible(self: Sema, expected: i32, actual: i32) -> i32:
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

    // Int coercion
    if exp_k == TY_INT() and act_k == TY_INT():
        return 1
    // Float coercion
    if exp_k == TY_FLOAT() and act_k == TY_FLOAT():
        return 1
    // Int <-> Float coercion
    if exp_k == TY_FLOAT() and act_k == TY_INT():
        return 1
    if exp_k == TY_INT() and act_k == TY_FLOAT():
        return 1
    // str <-> ptr
    if (exp_k == TY_PTR() or exp_k == TY_REF()) and act_k == TY_STR():
        return 1
    if exp_k == TY_STR() and (act_k == TY_PTR() or act_k == TY_REF()):
        return 1
    // fn type compatibility
    if exp_k == TY_FN() and act_k == TY_FN():
        return 1
    if (exp_k == TY_PTR() or exp_k == TY_REF()) and act_k == TY_FN():
        return 1
    if exp_k == TY_FN() and (act_k == TY_PTR() or act_k == TY_REF()):
        return 1
    // Struct/enum by name
    if exp_k == TY_STRUCT() and act_k == TY_STRUCT():
        return if self.get_type_d0(exp_r) == self.get_type_d0(act_r): 1 else: 0
    if exp_k == TY_ENUM() and act_k == TY_ENUM():
        return if self.get_type_d0(exp_r) == self.get_type_d0(act_r): 1 else: 0
    // Auto-referencing: T → &T
    if exp_k == TY_REF():
        if self.get_type_d1(exp_r) == 0:
            if self.types_compatible(self.get_type_d0(exp_r), act_r):
                return 1
    0

fn Sema.arithmetic_result_type(self: Sema, lhs: i32, rhs: i32) -> i32:
    if lhs == 0:
        return rhs
    if rhs == 0:
        return lhs
    let lk = self.get_type_kind(self.resolve_alias(lhs))
    let rk = self.get_type_kind(self.resolve_alias(rhs))
    // Float wins over int
    if lk == TY_FLOAT() and rk == TY_FLOAT():
        let lb = self.get_type_d0(self.resolve_alias(lhs))
        let rb = self.get_type_d0(self.resolve_alias(rhs))
        if lb >= rb:
            return lhs
        return rhs
    if lk == TY_FLOAT():
        return lhs
    if rk == TY_FLOAT():
        return rhs
    // Wider int wins
    if lk == TY_INT() and rk == TY_INT():
        let lb = self.get_type_d0(self.resolve_alias(lhs))
        let rb = self.get_type_d0(self.resolve_alias(rhs))
        if lb >= rb:
            return lhs
        return rhs
    0

fn Sema.is_copy(self: Sema, tid: i32) -> i32:
    if tid == 0:
        return 1
    let resolved = self.resolve_alias(tid)
    let tk = self.get_type_kind(resolved)
    if tk == TY_ERR() or tk == TY_INT() or tk == TY_FLOAT() or tk == TY_BOOL() or tk == TY_VOID() or tk == TY_STR():
        return 1
    if tk == TY_PTR() or tk == TY_REF() or tk == TY_FN() or tk == TY_GENERIC_FN():
        return 1
    if tk == TY_STRUCT():
        let name = self.get_type_d0(resolved)
        if self.has_drop_method(name):
            return 0
        let te_start = self.get_type_d1(resolved)
        let field_count = self.get_type_d2(resolved)
        var fi = 0
        while fi < field_count:
            let ft = self.type_extra.get((te_start + fi * 3 + 1) as i64)
            if self.is_copy(ft) == 0:
                return 0
            fi = fi + 1
        return 1
    if tk == TY_ENUM():
        return 1
    if tk == TY_ARRAY():
        return self.is_copy(self.get_type_d0(resolved))
    if tk == TY_SLICE():
        return 1
    if tk == TY_TUPLE():
        let te_start = self.get_type_d0(resolved)
        let elem_count = self.get_type_d1(resolved)
        var ei = 0
        while ei < elem_count:
            if self.is_copy(self.type_extra.get((te_start + ei) as i64)) == 0:
                return 0
            ei = ei + 1
        return 1
    if tk == TY_RANGE():
        return self.is_copy(self.get_type_d0(resolved))
    1

fn Sema.has_drop_method(self: Sema, type_name: i32) -> i32:
    let drop_sym = self.pool.intern("drop")
    let key = self.method_key(type_name, drop_sym)
    if self.sig_lookup.contains(key):
        return 1
    0

fn Sema.is_builtin_fn(self: Sema, sym: i32) -> i32:
    let name = self.pool.resolve(sym)
    if name == "println" or name == "print" or name == "assert":
        return 1
    if name == "Some" or name == "Ok" or name == "Err":
        return 1
    if name == "Channel" or name == "send" or name == "recv" or name == "close":
        return 1
    if name == "Vec" or name == "HashMap" or name == "HashSet":
        return 1
    if name == "abs" or name == "min" or name == "max" or name == "clamp":
        return 1
    if name == "sqrt_f64" or name == "pow_f64" or name == "floor_f64" or name == "ceil_f64":
        return 1
    if name == "sin_f64" or name == "cos_f64" or name == "log_f64" or name == "exp_f64" or name == "fabs_f64":
        return 1
    0

fn Sema.is_builtin_value(self: Sema, sym: i32) -> i32:
    let name = self.pool.resolve(sym)
    if name == "None" or name == "TypeInfo" or name == "PI" or name == "E":
        return 1
    if name == "INFINITY" or name == "NAN" or name == "__FILE__" or name == "__LINE__":
        return 1
    0

// ── Borrow checking ──────────────────────────────────────────────

fn Sema.expire_borrows_in_scope(self: Sema, scope_start: i32):
    var i = self.bind_names.len() as i32 - 1
    while i >= scope_start:
        let sym = self.bind_names.get(i as i64)
        // Remove borrows whose ref_binding is this sym
        var bi = 0
        while bi < self.borrow_refs.len() as i32:
            if self.borrow_refs.get(bi as i64) == sym:
                // Swap-remove
                let last = self.borrow_refs.len() as i32 - 1
                if bi < last:
                    self.borrow_kinds.set_i32(bi as i64, self.borrow_kinds.get(last as i64))
                    self.borrow_places.set_i32(bi as i64, self.borrow_places.get(last as i64))
                    self.borrow_fields.set_i32(bi as i64, self.borrow_fields.get(last as i64))
                    self.borrow_refs.set_i32(bi as i64, self.borrow_refs.get(last as i64))
                self.borrow_kinds.pop()
                self.borrow_places.pop()
                self.borrow_fields.pop()
                self.borrow_refs.pop()
                bi = bi  // keep same type as else branch for phi
            else:
                bi = bi + 1
        i = i - 1

// ── Diagnostics ──────────────────────────────────────────────────

fn Sema.emit_error(self: Sema, msg: str, node: i32):
    let start = self.ast.get_start(node)
    let end = self.ast.get_end(node)
    self.diags.emit(Diagnostic.err(msg, Span { file: self.local_file_id, start: start, end: end }))

fn Sema.emit_warning(self: Sema, msg: str, node: i32):
    let start = self.ast.get_start(node)
    let end = self.ast.get_end(node)
    self.diags.emit(Diagnostic.warn(msg, Span { file: self.local_file_id, start: start, end: end }))

// ── Type name formatting ─────────────────────────────────────────

fn Sema.type_name(self: Sema, tid: i32) -> str:
    let resolved = self.resolve_alias(tid)
    let tk = self.get_type_kind(resolved)
    if tk == TY_ERR():
        return "<error>"
    if tk == TY_INT():
        let bits = self.get_type_d0(resolved)
        let signed = self.get_type_d1(resolved)
        if bits == 8:
            return if signed != 0: "i8" else: "u8"
        if bits == 16:
            return if signed != 0: "i16" else: "u16"
        if bits == 32:
            return if signed != 0: "i32" else: "u32"
        if bits == 64:
            return if signed != 0: "i64" else: "u64"
        return "<int>"
    if tk == TY_FLOAT():
        if self.get_type_d0(resolved) == 32:
            return "f32"
        return "f64"
    if tk == TY_BOOL():
        return "bool"
    if tk == TY_VOID():
        return "void"
    if tk == TY_STR():
        return "str"
    if tk == TY_STRUCT():
        return self.pool.resolve(self.get_type_d0(resolved))
    if tk == TY_ENUM():
        return self.pool.resolve(self.get_type_d0(resolved))
    if tk == TY_ARRAY():
        return "[_]T"
    if tk == TY_SLICE():
        return "[]T"
    if tk == TY_TUPLE():
        return "(_, _)"
    if tk == TY_RANGE():
        return "Range[T]"
    if tk == TY_FN():
        return "fn"
    if tk == TY_PTR():
        return "*T"
    if tk == TY_REF():
        return "&T"
    if tk == TY_ALIAS():
        return "<alias>"
    if tk == TY_GENERIC_FN():
        return "<generic>"
    "<unknown>"
