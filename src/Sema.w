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
fn TY_TRAIT_OBJ -> i32: 17
fn TY_NEVER -> i32: 18

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
    // Trait obligations + deterministic selection cache
    obligation_trait_syms: Vec[i32],
    obligation_type_syms: Vec[i32],
    obligation_nodes: Vec[i32],
    selection_cache: HashMap[str, i32],

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
    bind_is_scoped_task: Vec[i32],
    bind_is_ephemeral_task: Vec[i32],
    scope_starts: Vec[i32],
    async_scope_names: Vec[i32],

    // Borrow tracking
    borrow_kinds: Vec[i32],
    borrow_places: Vec[i32],
    borrow_fields: Vec[i32],
    borrow_refs: Vec[i32],

    // Typed dump sidecar maps (keyed by span start byte offset)
    typed_expr_types: HashMap[i32, i32],
    typed_binding_types: HashMap[i32, i32],
    typed_binding_names: HashMap[i32, i32],
    typed_binding_muts: HashMap[i32, i32],
    // Generic substitution map + specialization cache
    generic_subst_param_syms: Vec[i32],
    generic_subst_type_ids: Vec[i32],
    generic_specialization_cache: HashMap[str, i32],

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
    ty_never: i32,
    ty_str: i32,
    ty_str_view: i32,
}

fn Sema.init(pool: InternPool, diags: DiagnosticList, ast: AstPool) -> Sema:
    var s = Sema {
        pool,
        diags,
        ast,
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
        obligation_trait_syms: Vec.new(),
        obligation_type_syms: Vec.new(),
        obligation_nodes: Vec.new(),
        selection_cache: HashMap.new(),
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
        bind_is_scoped_task: Vec.new(),
        bind_is_ephemeral_task: Vec.new(),
        scope_starts: Vec.new(),
        async_scope_names: Vec.new(),
        borrow_kinds: Vec.new(),
        borrow_places: Vec.new(),
        borrow_fields: Vec.new(),
        borrow_refs: Vec.new(),
        typed_expr_types: HashMap.new(),
        typed_binding_types: HashMap.new(),
        typed_binding_names: HashMap.new(),
        typed_binding_muts: HashMap.new(),
        generic_subst_param_syms: Vec.new(),
        generic_subst_type_ids: Vec.new(),
        generic_specialization_cache: HashMap.new(),
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
        ty_never: 0, ty_str: 0, ty_str_view: 0,
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
    s.ty_never = s.add_type(TY_NEVER(), 0, 0, 0)
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
    s.register_prim("Never", s.ty_never)
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
    for depth in 0..32:
        if self.get_type_kind(current) == TY_ALIAS():
            current = self.get_type_d0(current)
        else:
            return current
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
        self.bind_is_scoped_task.pop()
        self.bind_is_ephemeral_task.pop()
    self.scope_starts.pop()

fn Sema.is_discard_binding_symbol(self: Sema, sym: i32) -> i32:
    if sym == 0:
        return 1
    let name = self.pool.resolve(sym)
    if name == "_":
        return 1
    0

fn Sema.scope_put(self: Sema, sym: i32, tid: i32, is_mut: i32):
    self.scope_put_at(sym, tid, is_mut, 0)

fn Sema.scope_put_at(self: Sema, sym: i32, tid: i32, is_mut: i32, node: i32):
    if self.is_discard_binding_symbol(sym) != 0:
        return
    if self.scope_has(sym) != 0:
        if node != 0:
            self.emit_error("shadowing is not allowed", node)
        else:
            self.diags.emit(Diagnostic.err("shadowing is not allowed", Span { file: self.local_file_id, start: 0, end: 0 }))
        return
    self.bind_names.push(sym)
    self.bind_types.push(tid)
    self.bind_muts.push(is_mut)
    self.bind_states.push(VS_LIVE())
    self.bind_is_task.push(0)
    self.bind_is_scoped_task.push(0)
    self.bind_is_ephemeral_task.push(0)

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

fn Sema.scope_lookup_is_task(self: Sema, sym: i32) -> i32:
    var i = self.bind_names.len() as i32 - 1
    while i >= 0:
        if self.bind_names.get(i as i64) == sym:
            return self.bind_is_task.get(i as i64)
        i = i - 1
    0

fn Sema.scope_set_is_task(self: Sema, sym: i32, is_task: i32):
    var i = self.bind_names.len() as i32 - 1
    while i >= 0:
        if self.bind_names.get(i as i64) == sym:
            self.bind_is_task.set_i32(i as i64, is_task)
            return
        i = i - 1

fn Sema.scope_lookup_is_scoped_task(self: Sema, sym: i32) -> i32:
    var i = self.bind_names.len() as i32 - 1
    while i >= 0:
        if self.bind_names.get(i as i64) == sym:
            return self.bind_is_scoped_task.get(i as i64)
        i = i - 1
    0

fn Sema.scope_set_is_scoped_task(self: Sema, sym: i32, is_scoped_task: i32):
    var i = self.bind_names.len() as i32 - 1
    while i >= 0:
        if self.bind_names.get(i as i64) == sym:
            self.bind_is_scoped_task.set_i32(i as i64, is_scoped_task)
            return
        i = i - 1

fn Sema.scope_lookup_is_ephemeral_task(self: Sema, sym: i32) -> i32:
    var i = self.bind_names.len() as i32 - 1
    while i >= 0:
        if self.bind_names.get(i as i64) == sym:
            return self.bind_is_ephemeral_task.get(i as i64)
        i = i - 1
    0

fn Sema.scope_set_is_ephemeral_task(self: Sema, sym: i32, is_ephemeral_task: i32):
    var i = self.bind_names.len() as i32 - 1
    while i >= 0:
        if self.bind_names.get(i as i64) == sym:
            self.bind_is_ephemeral_task.set_i32(i as i64, is_ephemeral_task)
            return
        i = i - 1

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

fn Sema.is_active_async_scope_symbol(self: Sema, sym: i32) -> i32:
    var i = self.async_scope_names.len() as i32 - 1
    while i >= 0:
        if self.async_scope_names.get(i as i64) == sym:
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
    for di in 0..self.ast.decl_count():
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

    // Top-level method syntax
    for di in 0..self.ast.decl_count():
        let decl = self.ast.get_decl(di)
        if self.ast.kind(decl) == NK_FN_DECL():
            let fn_name = self.ast.get_data0(decl)
            if self.is_method_symbol(fn_name):
                if not self.method_decl_origins.contains(di):
                    self.method_has_inherent.insert(fn_name, 1)

fn Sema.is_method_symbol(self: Sema, sym: i32) -> i32:
    let name = self.pool.resolve(sym)
    for i in 0..name.len() as i32:
        if name[i] == 46:
            return 1
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
    for di in 0..self.ast.decl_count():
        let decl = self.ast.get_decl(di)
        let kind = self.ast.kind(decl)
        if kind == NK_TYPE_DECL():
            self.collect_type_decl(decl)
        if kind == NK_TRAIT_DECL():
            self.collect_trait_decl(decl)

    // Pass 2: collect impl declarations once trait/type tables exist.
    for di in 0..self.ast.decl_count():
        let decl = self.ast.get_decl(di)
        if self.ast.kind(decl) == NK_IMPL_DECL():
            self.collect_impl_decl(decl)

    self.collecting_types = 0

    // Pass 3: collect function signatures and top-level let decls.
    for di in 0..self.ast.decl_count():
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

fn Sema.collect_type_decl(self: Sema, node: i32):
    let name = self.ast.get_data0(node)
    let extra_start = self.ast.get_data1(node)
    let packed_kind = self.ast.get_data2(node)
    let sub_kind = type_decl_sub_kind(packed_kind)
    let is_ephemeral = type_decl_is_ephemeral(packed_kind)

    if sub_kind == TDK_STRUCT():
        let field_count = self.ast.get_extra(extra_start)
        let te_start = self.type_extra.len() as i32
        for fi in 0..field_count:
            let base = extra_start + 1 + fi * 3
            let f_name = self.ast.get_extra(base)
            let f_type_node = self.ast.get_extra(base + 1)
            let f_default = self.ast.get_extra(base + 2)
            if self.type_expr_contains_ref(f_type_node) != 0:
                self.emit_error("ephemeral references cannot be stored in structs", f_type_node)
            if self.type_expr_is_collection_with_ref(f_type_node) != 0:
                self.emit_error("ephemeral references cannot be stored in collections", f_type_node)
            let f_tid = self.resolve_type_expr(f_type_node)
            self.type_extra.push(f_name)
            self.type_extra.push(f_tid)
            self.type_extra.push(f_default)
        let tid = self.add_type(TY_STRUCT(), name, te_start, field_count)
        self.named_types.insert(name, tid)

    if sub_kind == TDK_ENUM():
        let variant_count = self.ast.get_extra(extra_start)
        let te_start = self.type_extra.len() as i32
        var epos = extra_start + 1
        for vi in 0..variant_count:
            let v_name = self.ast.get_extra(epos)
            epos = epos + 1
            let payload_count = self.ast.get_extra(epos)
            epos = epos + 1
            self.type_extra.push(v_name)
            self.type_extra.push(payload_count)
            for pi in 0..payload_count:
                let pt_node = self.ast.get_extra(epos)
                epos = epos + 1
                let pt_tid = self.resolve_type_expr(pt_node)
                self.type_extra.push(pt_tid)
            // Register variant lookup
            self.variant_lookup.insert(v_name, vi)
        let tid = self.add_type(TY_ENUM(), name, te_start, variant_count)
        self.named_types.insert(name, tid)
        // Re-register variants with actual enum TypeId
        var vpos = te_start
        for vi in 0..variant_count:
            let v_name = self.type_extra.get(vpos as i64)
            self.variant_lookup.insert(v_name, tid * 65536 + vi)
            let pc = self.type_extra.get((vpos + 1) as i64)
            vpos = vpos + 2 + pc

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

    if is_ephemeral != 0:
        self.ephemeral_types.insert(name, 1)

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
    for pi in 0..param_count:
        let p_type_node = self.ast.get_extra(param_start + pi * 2 + 1)
        let p_tid = self.resolve_type_expr(p_type_node)
        self.sig_params.push(p_tid)

    let ret_type = self.resolve_type_expr(ret_node)
    if ret_node != 0:
        if self.type_expr_contains_ref(ret_node) != 0:
            self.emit_error("ephemeral references cannot be returned from functions", ret_node)
        let ret_kind = self.ast.kind(ret_node)
        if ret_kind == NK_TYPE_NAMED():
            let ret_sym = self.ast.get_data0(ret_node)
            if self.ephemeral_types.contains(ret_sym):
                self.emit_error("ephemeral types cannot be returned from functions", ret_node)
    let actual_ret = ret_type
    if actual_ret == 0 and ret_node == 0:
        // no return type annotation → void
        let _ = 0

    // Build fn type
    let fn_extra_start = self.type_extra.len() as i32
    for pi in 0..param_count:
        self.type_extra.push(self.sig_params.get((sig_param_start + pi) as i64))
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
    for pi in 0..param_count:
        // extern params use the same parser extra layout as regular fns: [name, type]*
        let p_type_node = self.ast.get_extra(param_start + pi * 2 + 1)
        let p_tid = self.resolve_type_expr(p_type_node)
        self.sig_params.push(p_tid)

    let ret_type = self.resolve_type_expr(ret_node)

    let fn_extra_start = self.type_extra.len() as i32
    for pi in 0..param_count:
        self.type_extra.push(self.sig_params.get((sig_param_start + pi) as i64))
    let fn_tid = self.add_type(TY_FN(), fn_extra_start, param_count, ret_type)

    self.add_sig(name, fn_tid, ret_type, sig_param_start, param_count, is_variadic)
    self.extern_fn_names.insert(name, 1)

fn Sema.top_level_let_type_ann_extra(self: Sema, flags: i32) -> i32:
    let packed = flags / 4
    if packed <= 0:
        return -1
    packed - 1

fn Sema.local_let_type_ann_extra(self: Sema, flags: i32) -> i32:
    let packed = flags / 2
    if packed <= 0:
        return -1
    packed - 1

fn Sema.collect_let_decl(self: Sema, node: i32):
    let name = self.ast.get_data0(node)
    let flags = self.ast.get_data2(node)
    let is_mut = flags % 2
    var bind_ty = 0
    let type_extra = self.top_level_let_type_ann_extra(flags)
    if type_extra >= 0:
        let type_node = self.ast.get_extra(type_extra)
        bind_ty = self.resolve_type_expr(type_node)
        if self.type_expr_is_collection_with_ref(type_node) != 0:
            self.emit_error("ephemeral references cannot be stored in collections", node)
    self.scope_put(name, bind_ty, is_mut)
    let span_start = self.ast.get_start(node)
    self.typed_binding_types.insert(span_start, bind_ty)
    self.typed_binding_names.insert(span_start, name)
    self.typed_binding_muts.insert(span_start, is_mut)

fn Sema.collect_trait_decl(self: Sema, node: i32):
    let name = self.ast.get_data0(node)
    let extra_start = self.ast.get_data1(node)
    // Store trait info
    let trait_idx = self.trait_name_syms.len() as i32
    self.trait_name_syms.push(name)
    self.trait_method_starts.push(self.trait_method_names.len() as i32)
    // Trait extra layout:
    // [assoc_count,
    //   [assoc_name, bound_count, bounds..., default_type]*,
    //  method_count,
    //   [method_name, method_flags, param_start, param_count, ret_type]*]
    var pos = extra_start
    let assoc_count = self.ast.get_extra(pos)
    pos = pos + 1
    for ai in 0..assoc_count:
        let bound_count = self.ast.get_extra(pos + 1)
        pos = pos + 2 + bound_count + 1

    let method_count = self.ast.get_extra(pos)
    pos = pos + 1
    for i in 0..method_count:
        self.trait_method_names.push(self.ast.get_extra(pos))
        pos = pos + 5
    self.trait_method_counts.push(method_count)
    self.trait_lookup.insert(name, trait_idx)
    self.local_trait_names.insert(name, 1)

fn sema_is_builtin_trait_name(name: str) -> bool:
    name == "Drop" or
    name == "Scoped" or
    name == "ScopedMut" or
    name == "Debug" or
    name == "Display" or
    name == "Default" or
    name == "Iter" or
    name == "IntoIter" or
    name == "Eq" or
    name == "Hash" or
    name == "Ord"

fn Sema.collect_impl_decl(self: Sema, node: i32):
    let type_name = self.ast.get_data0(node)
    let trait_sym = self.ast.get_data2(node)
    if trait_sym == 0:
        return

    let trait_name = self.pool.resolve(trait_sym)
    let is_builtin_trait = sema_is_builtin_trait_name(trait_name)
    if not is_builtin_trait and not self.trait_lookup.contains(trait_sym):
        self.emit_error("unknown trait", node)
        return

    let trait_is_local = self.local_trait_names.contains(trait_sym) or is_builtin_trait
    let type_is_local = self.local_type_names.contains(type_name)
    if not trait_is_local and not type_is_local:
        self.emit_error("orphan rule violation: impl requires a local trait or local type", node)
        return

    // Record impl
    if self.impl_lookup.contains(type_name):
        let idx = self.impl_lookup.get(type_name).unwrap()
        let start = self.impl_starts.get(idx as i64)
        let count = self.impl_counts.get(idx as i64)
        for i in 0..count:
            if self.impl_extra.get((start + i) as i64) == trait_sym:
                self.emit_error("duplicate implementation of trait for type", node)
                return
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
        for pi in 0..param_count:
            let p_node = self.ast.get_extra(extra_start + pi)
            self.type_extra.push(self.resolve_type_expr(p_node))
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
        for ei in 0..elem_count:
            let e_node = self.ast.get_extra(extra_start + ei)
            self.type_extra.push(self.resolve_type_expr(e_node))
        return self.add_type(TY_TUPLE(), te_start, elem_count, 0)

    if kind == NK_TYPE_OPTIONAL():
        let inner = self.resolve_type_expr(self.ast.get_data0(node))
        // Optional lowering remains deferred in bootstrap sema path.
        return 0

    if kind == NK_TYPE_TRAIT_OBJ():
        let trait_sym = self.ast.get_data0(node)
        let trait_name = self.pool.resolve(trait_sym)
        let is_builtin_trait = sema_is_builtin_trait_name(trait_name)
        if not is_builtin_trait and not self.trait_lookup.contains(trait_sym):
            self.emit_error("unknown trait", node)
            return 0
        return self.add_type(TY_TRAIT_OBJ(), trait_sym, 0, 0)

    if kind == NK_TYPE_GENERIC():
        // Generic type applications are resolved by codegen/later waves.
        return 0

    if kind == NK_TYPE_INFERRED():
        return 0

    0

// ── Pass 2: Check function bodies ────────────────────────────────

fn Sema.check_bodies(self: Sema):
    for di in 0..self.ast.decl_count():
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

fn Sema.check_fn_body(self: Sema, node: i32):
    let fn_name = self.ast.get_data0(node)
    let body = self.ast.get_data1(node)
    let flags = self.ast.get_data2(node)

    let sig_idx = self.get_sig(fn_name)
    if sig_idx < 0:
        return

    let ret_type = self.sig_return_type(sig_idx)

    // Active borrows are per-function state.
    while self.borrow_kinds.len() > 0:
        self.borrow_kinds.pop()
        self.borrow_places.pop()
        self.borrow_fields.pop()
        self.borrow_refs.pop()

    // Push function scope
    self.push_scope()

    // Add parameters to scope
    let meta = self.ast.find_fn_meta(node)
    if meta >= 0:
        let param_start = self.ast.fn_meta_param_start(meta)
        let param_count = self.ast.fn_meta_param_count(meta)
        for pi in 0..param_count:
            let p_name = self.ast.get_extra(param_start + pi * 2)
            let p_tid = self.sig_param_type(sig_idx, pi)
            self.scope_put(p_name, p_tid, 0)

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
    let body_ty = self.check_expr(body)
    self.typed_expr_types.insert(self.ast.get_start(body), body_ty)

    // Restore state
    self.current_return_type = saved_ret
    self.in_comptime_fn = saved_comptime
    self.pop_scope()

// ── Expression type checking ─────────────────────────────────────

fn Sema.is_call_expr_task(self: Sema, node: i32) -> i32:
    if node == 0 or self.ast.kind(node) != NK_CALL():
        return 0
    let callee = self.ast.get_data0(node)
    if self.ast.kind(callee) == NK_IDENT():
        let fn_sym = self.ast.get_data0(callee)
        if self.task_fns.contains(fn_sym):
            return 1
    if self.ast.kind(callee) == NK_FIELD_ACCESS():
        let recv = self.ast.get_data0(callee)
        let method = self.ast.get_data1(callee)
        if self.ast.kind(recv) == NK_IDENT() and self.is_active_async_scope_symbol(self.ast.get_data0(recv)) != 0 and self.pool.resolve(method) == "track":
            return 1
    0

fn Sema.expr_is_tuple_of_tasks(self: Sema, node: i32) -> i32:
    if node == 0 or self.ast.kind(node) != NK_TUPLE():
        return 0
    let extra_start = self.ast.get_data0(node)
    let elem_count = self.ast.get_data1(node)
    if elem_count < 2 or elem_count > 12:
        return 0
    for ei in 0..elem_count:
        if self.expr_is_task_value(self.ast.get_extra(extra_start + ei)) == 0:
            return 0
    1

fn Sema.expr_is_task_value(self: Sema, node: i32) -> i32:
    if node == 0:
        return 0
    let kind = self.ast.kind(node)
    if kind == NK_GROUPED():
        return self.expr_is_task_value(self.ast.get_data0(node))
    if kind == NK_ASYNC_BLOCK():
        return 1
    if kind == NK_CALL():
        return self.is_call_expr_task(node)
    if kind == NK_IDENT():
        return self.scope_lookup_is_task(self.ast.get_data0(node))
    if kind == NK_INDEX() or kind == NK_FIELD_ACCESS() or kind == NK_OPTIONAL_CHAIN():
        // Conservative task-container handling.
        return 1
    if kind == NK_TUPLE():
        return self.expr_is_tuple_of_tasks(node)
    0

fn Sema.expr_is_scoped_task_value(self: Sema, node: i32) -> i32:
    if node == 0:
        return 0
    let kind = self.ast.kind(node)
    if kind == NK_GROUPED():
        return self.expr_is_scoped_task_value(self.ast.get_data0(node))
    if kind == NK_IDENT():
        return self.scope_lookup_is_scoped_task(self.ast.get_data0(node))
    if kind == NK_CALL():
        let callee = self.ast.get_data0(node)
        if self.ast.kind(callee) == NK_FIELD_ACCESS():
            let recv = self.ast.get_data0(callee)
            let method = self.ast.get_data1(callee)
            if self.ast.kind(recv) == NK_IDENT() and self.is_active_async_scope_symbol(self.ast.get_data0(recv)) != 0 and self.pool.resolve(method) == "track":
                return 1
    0

fn Sema.has_live_await_guard(self: Sema) -> i32:
    var i = self.bind_names.len() as i32 - 1
    while i >= 0:
        if self.bind_states.get(i as i64) == VS_LIVE():
            let name = self.pool.resolve(self.bind_names.get(i as i64))
            if name.ends_with("_guard"):
                return 1
        i = i - 1
    0

fn Sema.param_is_by_reference(self: Sema, tid: i32) -> i32:
    if tid == 0:
        return 0
    let resolved = self.resolve_alias(tid)
    let tk = self.get_type_kind(resolved)
    if tk == TY_REF() or tk == TY_PTR():
        return 1
    0

fn Sema.expr_is_ephemeral_task(self: Sema, node: i32) -> i32:
    if node == 0:
        return 0
    let kind = self.ast.kind(node)
    if kind == NK_GROUPED():
        return self.expr_is_ephemeral_task(self.ast.get_data0(node))
    if kind == NK_IDENT():
        return self.scope_lookup_is_ephemeral_task(self.ast.get_data0(node))
    if kind == NK_CALL():
        let callee = self.ast.get_data0(node)
        if self.ast.kind(callee) == NK_IDENT():
            let fn_sym = self.ast.get_data0(callee)
            if self.task_fns.contains(fn_sym):
                let args_start = self.ast.get_data1(node)
                let arg_count = self.ast.get_data2(node)
                for ai in 0..arg_count:
                    if self.expr_is_ephemeral_value(self.ast.get_extra(args_start + ai)) != 0:
                        return 1
        return 0
    0

fn Sema.expr_is_ephemeral_value(self: Sema, node: i32) -> i32:
    if node == 0:
        return 0
    let kind = self.ast.kind(node)
    if kind == NK_GROUPED():
        return self.expr_is_ephemeral_value(self.ast.get_data0(node))
    if kind == NK_IDENT():
        let sym = self.ast.get_data0(node)
        if self.scope_lookup_is_ephemeral_task(sym) != 0:
            return 1
        let tid = self.scope_lookup(sym)
        if tid >= 0:
            return self.type_is_ephemeral_value(tid)
        return 0
    if kind == NK_UNARY():
        let op = self.ast.get_data0(node)
        if op == UOP_REF() or op == UOP_MUT_REF():
            return 1
        return self.expr_is_ephemeral_value(self.ast.get_data1(node))
    if kind == NK_SLICE():
        return 1
    if kind == NK_CALL():
        return self.expr_is_ephemeral_task(node)
    0

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
        if self.has_live_await_guard() != 0:
            self.emit_error("E0701: may_suspend call while no_await_guard value is live", node)
        let inner = self.ast.get_data0(node)
        let inner_ty = self.check_expr(inner)
        if self.ast.kind(inner) == NK_TUPLE():
            let elem_count = self.ast.get_data1(inner)
            if elem_count < 2 or elem_count > 12:
                self.emit_error("await tuple requires between 2 and 12 tasks", node)
                return inner_ty
            if self.expr_is_tuple_of_tasks(inner) == 0:
                self.emit_error("await tuple requires Task values", node)
                return inner_ty
            return inner_ty
        if self.expr_is_task_value(inner) == 0:
            self.emit_error("await requires a Task value", node)
        return inner_ty

    if kind == NK_ASYNC_BLOCK():
        return self.check_expr(self.ast.get_data0(node))

    if kind == NK_SPAWN():
        let inner = self.ast.get_data0(node)
        self.check_expr(inner)
        if self.expr_is_task_value(inner) == 0:
            self.emit_error("spawn requires a Task value", node)
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
        self.async_scope_names.push(name)
        let result = self.check_expr(body)
        self.async_scope_names.pop()
        self.pop_scope()
        return result

    if kind == NK_SELECT_AWAIT():
        if self.has_live_await_guard() != 0:
            self.emit_error("E0701: may_suspend call while no_await_guard value is live", node)
        let extra_start = self.ast.get_data0(node)
        let arm_count = self.ast.get_data1(node)
        if arm_count <= 0:
            self.emit_error("select await requires at least one arm", node)
            return self.ty_void
        var result = self.ty_void
        for ai in 0..arm_count:
            // Each select arm is encoded as: name_sym, task_node, body_node.
            let arm_name = self.ast.get_extra(extra_start + ai * 3)
            let task = self.ast.get_extra(extra_start + ai * 3 + 1)
            let arm_body = self.ast.get_extra(extra_start + ai * 3 + 2)
            let task_ty = self.check_expr(task)
            if self.expr_is_task_value(task) == 0:
                self.emit_error("select await arm requires a Task value", task)
            self.push_scope()
            self.scope_put(arm_name, task_ty, 0)
            self.scope_set_is_task(arm_name, 0)
            result = self.check_expr(arm_body)
            self.pop_scope()
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
    let operand_node = self.ast.get_data1(node)
    let operand = self.check_expr(operand_node)
    if operand == 0:
        return 0

    if op == UOP_NEGATE():
        return operand
    if op == UOP_NOT():
        return self.ty_bool
    if op == UOP_REF():
        self.check_borrow_create(operand_node, BK_SHARED(), node)
        return self.add_type(TY_REF(), operand, 0, 0)
    if op == UOP_MUT_REF():
        self.check_borrow_create(operand_node, BK_EXCLUSIVE(), node)
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

    for i in 0..stmt_count:
        let stmt = self.ast.get_extra(extra_start + i)
        let stmt_ty = self.check_expr(stmt)
        self.typed_expr_types.insert(self.ast.get_start(stmt), stmt_ty)
        let stmt_kind = self.ast.kind(stmt)
        let can_discard_task = stmt_kind == NK_CALL() or stmt_kind == NK_IDENT() or stmt_kind == NK_GROUPED() or stmt_kind == NK_ASYNC_BLOCK() or stmt_kind == NK_TUPLE()
        let is_discarded_task = can_discard_task and stmt_kind != NK_SPAWN() and self.expr_is_task_value(stmt) != 0 and self.expr_is_scoped_task_value(stmt) == 0
        if is_discarded_task:
            self.emit_warning("E0801: unused Task value", stmt)
        self.expire_dead_borrows_in_block(extra_start, stmt_count, i + 1, tail)

    var result = self.ty_void
    if tail != 0:
        result = self.check_expr(tail)
        self.typed_expr_types.insert(self.ast.get_start(tail), result)
    self.expire_dead_borrows_in_block(extra_start, stmt_count, stmt_count, 0)

    self.pop_scope()
    result

fn Sema.check_let_binding(self: Sema, node: i32) -> i32:
    let name = self.ast.get_data0(node)
    let value = self.ast.get_data1(node)
    let flags = self.ast.get_data2(node)
    let is_mut = flags % 2

    let ann_extra = self.local_let_type_ann_extra(flags)
    var ann_type = 0
    var ann_type_node = 0
    if ann_extra >= 0:
        ann_type_node = self.ast.get_extra(ann_extra)
        ann_type = self.resolve_type_expr(ann_type_node)

    let val_type = self.check_expr(value)
    var bind_type = val_type
    if ann_type != 0:
        bind_type = ann_type
        if val_type != 0:
            if not self.types_compatible(ann_type, val_type):
                if self.arithmetic_result_type(ann_type, val_type) == 0:
                    self.emit_error("type mismatch in binding", node)

    // Move semantics
    self.mark_moved_if_consumed(value)

    if ann_type_node != 0 and self.type_expr_is_collection_with_ref(ann_type_node) != 0:
        self.emit_error("ephemeral references cannot be stored in collections", node)

    self.scope_put(name, bind_type, is_mut)
    let span_start = self.ast.get_start(node)
    self.typed_binding_types.insert(span_start, bind_type)
    self.typed_binding_names.insert(span_start, name)
    self.typed_binding_muts.insert(span_start, is_mut)
    self.scope_set_is_task(name, self.expr_is_task_value(value))
    self.scope_set_is_scoped_task(name, self.expr_is_scoped_task_value(value))
    self.scope_set_is_ephemeral_task(name, self.expr_is_ephemeral_task(value))

    // If this let binds a borrow, tie the newest active borrow to this binding.
    if self.ast.kind(value) == NK_UNARY():
        let uop = self.ast.get_data0(value)
        if uop == UOP_REF() or uop == UOP_MUT_REF():
            let blen = self.borrow_refs.len() as i32
            if blen > 0:
                self.borrow_refs.set_i32((blen - 1) as i64, name)

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
        self.scope_set_is_task(target_sym, self.expr_is_task_value(value))
        self.scope_set_is_scoped_task(target_sym, self.expr_is_scoped_task_value(value))
        self.scope_set_is_ephemeral_task(target_sym, self.expr_is_ephemeral_task(value))

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
        for fi in 0..field_count:
            let f_name = self.type_extra.get((te_start + fi * 3) as i64)
            if f_name == field:
                return self.type_extra.get((te_start + fi * 3 + 1) as i64)
        return 0

    if ftk == TY_TUPLE():
        let te_start = self.get_type_d0(field_base)
        let elem_count = self.get_type_d1(field_base)
        let field_name = self.pool.resolve(field)
        // Parse field index
        var idx = 0
        for vi in 0..field_name.len() as i32:
            let ch = field_name[vi]
            if ch >= 48 and ch <= 57:
                idx = idx * 10 + ch - 48
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
    for i in 0..elem_count:
        let elem = self.ast.get_extra(extra_start + i)
        let et = self.check_expr(elem)
        if elem_type == 0:
            elem_type = et

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
            for fi in 0..field_count:
                let f_name = self.ast.get_extra(extra_start + fi * 2)
                let f_value = self.ast.get_extra(extra_start + fi * 2 + 1)
                self.check_expr(f_value)
            return resolved
    0

fn Sema.check_match_expr(self: Sema, node: i32) -> i32:
    let subject = self.ast.get_data0(node)
    let extra_start = self.ast.get_data1(node)
    let arm_count = self.ast.get_data2(node)

    let subject_type = self.check_expr(subject)
    var result_type = 0

    for ai in 0..arm_count:
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
        else if result_type == self.ty_never and arm_type != 0:
            // Bottom-type merge: allow concrete arm types after Never arms.
            result_type = arm_type

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
        // Recursively check each payload pattern (extra stores pattern nodes, not symbols).
        for bi in 0..bind_count:
            let inner_pat = self.ast.get_extra(v_extra + bi)
            self.check_pattern(inner_pat, 0)
        return

    if kind == NK_PAT_OR():
        let p_extra = self.ast.get_data0(node)
        let p_count = self.ast.get_data1(node)
        for pi in 0..p_count:
            self.check_pattern(self.ast.get_extra(p_extra + pi), subject_type)
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
        for ti in 0..t_count:
            self.check_pattern(self.ast.get_extra(t_extra + ti), 0)
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
        for hi in 0..head_count:
            let h_sym = self.ast.get_extra(s_extra + 1 + hi)
            if h_sym != 0:
                self.scope_put(h_sym, elem_type, 0)
        if has_rest != 0 and rest_sym != 0:
            self.scope_put(rest_sym, self.ty_i64, 0)
        let tail_count = self.ast.get_extra(s_extra + 1 + head_count)
        for ti in 0..tail_count:
            let t_sym = self.ast.get_extra(s_extra + 2 + head_count + ti)
            if t_sym != 0:
                self.scope_put(t_sym, elem_type, 0)
        return

    if kind == NK_PAT_STRUCT():
        let sp_extra = self.ast.get_data1(node)
        let sp_count = self.ast.get_data2(node)
        let has_rest = self.ast.get_extra(sp_extra)
        for spi in 0..sp_count:
            let f_name = self.ast.get_extra(sp_extra + 1 + spi * 2)
            let f_pat = self.ast.get_extra(sp_extra + 1 + spi * 2 + 1)
            if f_pat != 0:
                self.check_pattern(f_pat, 0)
            else:
                self.scope_put(f_name, 0, 0)
        return

fn Sema.check_enum_variant(self: Sema, node: i32) -> i32:
    let type_name = self.ast.get_data0(node)
    let variant_name = self.ast.get_data1(node)
    let extra_start = self.ast.get_data2(node)
    let arg_count = self.ast.get_extra(extra_start)
    for ai in 0..arg_count:
        self.check_expr(self.ast.get_extra(extra_start + 1 + ai))
    if self.named_types.contains(type_name):
        return self.resolve_alias(self.named_types.get(type_name).unwrap())
    0

fn Sema.check_closure(self: Sema, node: i32) -> i32:
    let body = self.ast.get_data0(node)
    let extra_start = self.ast.get_data1(node)
    let param_count = self.ast.get_data2(node)
    let outer_count = self.bind_names.len() as i32

    self.push_scope()
    let te_start = self.type_extra.len() as i32
    for pi in 0..param_count:
        let p_sym = self.ast.get_extra(extra_start + pi)
        self.scope_put(p_sym, self.ty_i32, 0)
        self.type_extra.push(self.ty_i32)
    self.check_expr(body)

    // Phase 1 ephemerality rule: closures cannot capture ephemeral refs/values.
    var bi = 0
    while bi < outer_count:
        let cap_sym = self.bind_names.get(bi as i64)
        if self.expr_uses_symbol(body, cap_sym) != 0:
            let cap_ty = self.bind_types.get(bi as i64)
            if self.type_is_ephemeral_value(cap_ty) != 0:
                self.emit_error("closures cannot capture ephemeral references", node)
                break
        bi = bi + 1
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
    for ei in 0..elem_count:
        let elem = self.ast.get_extra(extra_start + ei)
        let et = self.check_expr(elem)
        self.type_extra.push(et)
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
    for fi in 0..field_count:
        let f_name = self.ast.get_extra(extra_start + fi * 2)
        let f_value = self.ast.get_extra(extra_start + fi * 2 + 1)
        self.check_expr(f_value)
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
    let resolved = self.resolve_alias(val_type)
    let is_tuple = self.get_type_kind(resolved) == TY_TUPLE()
    if is_tuple == 0:
        self.emit_error("tuple destructuring requires tuple type", node)
    let elem_start = if is_tuple != 0: self.get_type_d0(resolved) else: 0
    let elem_count = if is_tuple != 0: self.get_type_d1(resolved) else: 0
    var emitted_arity_error = 0
    for ni in 0..name_count:
        let n_sym = self.ast.get_extra(extra_start + ni)
        var bind_ty = 0
        if ni < elem_count:
            bind_ty = self.type_extra.get((elem_start + ni) as i64)
        else:
            if emitted_arity_error == 0 and is_tuple != 0:
                self.emit_error("tuple destructuring arity mismatch", node)
                emitted_arity_error = 1
        self.scope_put(n_sym, bind_ty, 0)
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
        for ai in 0..arg_count:
            self.check_expr(self.ast.get_extra(extra_start + ai))
        return 0

    // Check all arguments
    let arg_types: Vec[i32] = Vec.new()
    for ai in 0..arg_count:
        let arg_ty = self.check_expr(self.ast.get_extra(extra_start + ai))
        arg_types.push(arg_ty)

    // Mark non-Copy args as moved
    for ai in 0..arg_count:
        self.mark_moved_if_consumed(self.ast.get_extra(extra_start + ai))

    let param_offset = if self.in_pipeline_rhs != 0: 1 else: 0

    // Known function
    let sig_idx = self.get_sig(fn_sym)
    if sig_idx >= 0:
        let ret = self.sig_return_type(sig_idx)
        // Check arg count
        let expected = self.sig_get_param_count(sig_idx)
        let actual = arg_count + param_offset
        if self.sig_is_variadic(sig_idx) == 0:
            if actual != expected:
                self.emit_error("wrong argument count", node)

        for ai in 0..arg_count:
            let param_i = ai + param_offset
            if param_i >= expected:
                break
            let expected_ty = self.sig_param_type(sig_idx, param_i)
            let arg_ty = arg_types.get(ai as i64)
            if expected_ty != 0 and arg_ty != 0:
                let exp_resolved = self.resolve_alias(expected_ty)
                if self.get_type_kind(exp_resolved) != TY_TRAIT_OBJ():
                    if not self.types_compatible(expected_ty, arg_ty):
                        if self.arithmetic_result_type(expected_ty, arg_ty) == 0:
                            self.emit_error("wrong argument type", self.ast.get_extra(extra_start + ai))
            let arg_node = self.ast.get_extra(extra_start + ai)
            if self.expr_is_ephemeral_task(arg_node) != 0 and self.param_is_by_reference(expected_ty) == 0:
                self.emit_warning("ephemeral Task passed by value may escape", arg_node)

        self.check_dyn_trait_call_compat(fn_sym, extra_start, arg_types, arg_count, param_offset)
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
        let fn_node = self.generic_fn_nodes.get(fn_sym).unwrap()
        return self.check_generic_call(fn_sym, fn_node, arg_types, arg_count, node)

    // Enum variant constructor
    if self.variant_lookup.contains(fn_sym):
        let vi = self.variant_lookup.get(fn_sym).unwrap()
        return vi / 65536

    // Built-in function
    if self.is_builtin_fn(fn_sym):
        return self.check_builtin_call(fn_sym, node, arg_types, arg_count)

    0

fn Sema.check_dyn_trait_call_compat(self: Sema, fn_sym: i32, call_extra_start: i32, arg_types: Vec[i32], arg_count: i32, param_offset: i32):
    if not self.fn_decl_nodes.contains(fn_sym):
        return
    let fn_node = self.fn_decl_nodes.get(fn_sym).unwrap()
    let meta = self.ast.find_fn_meta(fn_node)
    if meta < 0:
        return

    let param_start = self.ast.fn_meta_param_start(meta)
    let param_count = self.ast.fn_meta_param_count(meta)
    for ai in 0..arg_count:
        let param_i = ai + param_offset
        if param_i >= param_count:
            break

        let p_type_node = self.ast.get_extra(param_start + param_i * 2 + 1)
        let trait_sym = self.trait_object_from_type_node(p_type_node)
        if trait_sym == 0:
            continue

        let arg_ty = arg_types.get(ai as i64)
        let concrete_sym = self.dyn_arg_concrete_type_symbol(arg_ty)
        if concrete_sym == 0:
            self.emit_error("argument cannot be converted to dyn trait object", self.ast.get_extra(call_extra_start + ai))
            continue

        if self.select_trait_impl(concrete_sym, trait_sym) == 0:
            let type_str = self.pool.resolve(concrete_sym)
            let trait_str = self.pool.resolve(trait_sym)
            self.emit_error("type '" ++ type_str ++ "' does not implement trait '" ++ trait_str ++ "' required for dyn parameter", self.ast.get_extra(call_extra_start + ai))
            continue

        self.obligation_trait_syms.push(trait_sym)
        self.obligation_type_syms.push(concrete_sym)
        self.obligation_nodes.push(self.ast.get_extra(call_extra_start + ai))

fn Sema.check_generic_call(self: Sema, fn_sym: i32, fn_node: i32, arg_types: Vec[i32], arg_count: i32, call_node: i32) -> i32:
    let meta = self.ast.find_fn_meta(fn_node)
    if meta < 0:
        if arg_count > 0:
            return arg_types.get(0)
        return 0

    let param_start = self.ast.fn_meta_param_start(meta)
    let param_count = self.ast.fn_meta_param_count(meta)
    let tp_start = self.ast.fn_meta_tp_start(meta)
    let tp_count = self.ast.fn_meta_tp_count(meta)
    let ret_node = self.ast.fn_meta_ret(meta)

    if arg_count != param_count:
        self.emit_error("wrong argument count", call_node)

    self.clear_generic_substitution()

    // Infer type parameter substitutions from call argument types.
    for pi in 0..param_count:
        if pi >= arg_count:
            break
        let p_type_node = self.ast.get_extra(param_start + pi * 2 + 1)
        let arg_ty = arg_types.get(pi as i64)
        self.bind_type_params_from_type_expr(p_type_node, arg_ty, tp_start, tp_count, call_node)

    // Obligation model: collect and solve trait bounds for each bound type parameter.
    self.check_generic_trait_bounds(tp_start, tp_count, call_node)

    let spec_key = self.generic_specialization_key(fn_sym, tp_start, tp_count)
    if self.generic_specialization_cache.contains(spec_key):
        return self.generic_specialization_cache.get(spec_key).unwrap()

    let resolved_ret = self.resolve_generic_return_type_node(ret_node, tp_start, tp_count)
    self.generic_specialization_cache.insert(spec_key, resolved_ret)
    resolved_ret

fn Sema.clear_generic_substitution(self: Sema):
    while self.generic_subst_param_syms.len() > 0:
        self.generic_subst_param_syms.pop()
        self.generic_subst_type_ids.pop()

fn Sema.lookup_generic_subst(self: Sema, param_sym: i32) -> i32:
    var i = self.generic_subst_param_syms.len() as i32 - 1
    while i >= 0:
        if self.generic_subst_param_syms.get(i as i64) == param_sym:
            return self.generic_subst_type_ids.get(i as i64)
        i = i - 1
    0

fn Sema.put_generic_subst(self: Sema, param_sym: i32, tid: i32, node: i32):
    if tid == 0:
        return
    let existing = self.lookup_generic_subst(param_sym)
    if existing != 0:
        if not self.types_compatible(existing, tid):
            if self.arithmetic_result_type(existing, tid) == 0:
                let tp_name = self.pool.resolve(param_sym)
                let a = self.type_name(existing)
                let b = self.type_name(tid)
                self.emit_error("cannot infer a single type for '" ++ tp_name ++ "': saw '" ++ a ++ "' and '" ++ b ++ "'", node)
        return

    self.generic_subst_param_syms.push(param_sym)
    self.generic_subst_type_ids.push(tid)

fn Sema.type_param_exists(self: Sema, tp_start: i32, tp_count: i32, sym: i32) -> i32:
    var pos = tp_start
    for ti in 0..tp_count:
        let tp_name = self.ast.get_extra(pos)
        let bound_count = self.ast.get_extra(pos + 1)
        if tp_name == sym:
            return 1
        pos = pos + 2 + bound_count
    0

fn Sema.bind_type_params_from_type_expr(self: Sema, type_node: i32, arg_tid: i32, tp_start: i32, tp_count: i32, err_node: i32):
    if type_node == 0 or arg_tid == 0:
        return

    let kind = self.ast.kind(type_node)

    if kind == NK_TYPE_NAMED():
        let sym = self.ast.get_data0(type_node)
        if self.type_param_exists(tp_start, tp_count, sym) != 0:
            self.put_generic_subst(sym, arg_tid, err_node)
        return

    if kind == NK_TYPE_REF():
        let inner_node = self.ast.get_data0(type_node)
        let resolved = self.resolve_alias(arg_tid)
        if self.get_type_kind(resolved) == TY_REF():
            self.bind_type_params_from_type_expr(inner_node, self.get_type_d0(resolved), tp_start, tp_count, err_node)
        return

    if kind == NK_TYPE_PTR():
        let inner_node = self.ast.get_data0(type_node)
        let resolved = self.resolve_alias(arg_tid)
        if self.get_type_kind(resolved) == TY_PTR():
            self.bind_type_params_from_type_expr(inner_node, self.get_type_d0(resolved), tp_start, tp_count, err_node)
        return

    if kind == NK_TYPE_ARRAY():
        let inner_node = self.ast.get_data0(type_node)
        let resolved = self.resolve_alias(arg_tid)
        if self.get_type_kind(resolved) == TY_ARRAY():
            self.bind_type_params_from_type_expr(inner_node, self.get_type_d0(resolved), tp_start, tp_count, err_node)
        return

    if kind == NK_TYPE_SLICE():
        let inner_node = self.ast.get_data0(type_node)
        let resolved = self.resolve_alias(arg_tid)
        if self.get_type_kind(resolved) == TY_SLICE():
            self.bind_type_params_from_type_expr(inner_node, self.get_type_d0(resolved), tp_start, tp_count, err_node)
        return

    if kind == NK_TYPE_TUPLE():
        let inner_start = self.ast.get_data0(type_node)
        let inner_count = self.ast.get_data1(type_node)
        let resolved = self.resolve_alias(arg_tid)
        if self.get_type_kind(resolved) != TY_TUPLE():
            return
        let te_start = self.get_type_d0(resolved)
        let elem_count = self.get_type_d1(resolved)
        let pair_count = if inner_count < elem_count: inner_count else: elem_count
        for ei in 0..pair_count:
            let inner_node = self.ast.get_extra(inner_start + ei)
            let arg_elem = self.type_extra.get((te_start + ei) as i64)
            self.bind_type_params_from_type_expr(inner_node, arg_elem, tp_start, tp_count, err_node)
        return

fn Sema.generic_specialization_key(self: Sema, fn_sym: i32, tp_start: i32, tp_count: i32) -> str:
    var key = int_to_string(fn_sym)
    var pos = tp_start
    for ti in 0..tp_count:
        let tp_name = self.ast.get_extra(pos)
        let bound_count = self.ast.get_extra(pos + 1)
        key = key ++ ":" ++ int_to_string(tp_name) ++ "=" ++ int_to_string(self.lookup_generic_subst(tp_name))
        pos = pos + 2 + bound_count
    key

fn Sema.check_generic_trait_bounds(self: Sema, tp_start: i32, tp_count: i32, call_node: i32):
    var pos = tp_start
    for ti in 0..tp_count:
        let tp_name = self.ast.get_extra(pos)
        let bound_count = self.ast.get_extra(pos + 1)
        let concrete_tid = self.lookup_generic_subst(tp_name)
        for bi in 0..bound_count:
            let trait_sym = self.ast.get_extra(pos + 2 + bi)
            let trait_name = self.pool.resolve(trait_sym)
            if trait_name == "type":
                continue
            if concrete_tid == 0:
                continue
            let concrete_sym = self.type_symbol_for_bounds(concrete_tid)
            if concrete_sym == 0:
                continue
            self.obligation_trait_syms.push(trait_sym)
            self.obligation_type_syms.push(concrete_sym)
            self.obligation_nodes.push(call_node)
            if self.select_trait_impl(concrete_sym, trait_sym) == 0:
                let type_str = self.pool.resolve(concrete_sym)
                let tp_str = self.pool.resolve(tp_name)
                self.emit_error("type '" ++ type_str ++ "' does not implement trait '" ++ trait_name ++ "' required by bound '" ++ tp_str ++ ": " ++ trait_name ++ "'", call_node)
        pos = pos + 2 + bound_count

fn Sema.resolve_generic_return_type_node(self: Sema, ret_node: i32, tp_start: i32, tp_count: i32) -> i32:
    if ret_node == 0:
        return self.ty_void

    let kind = self.ast.kind(ret_node)

    if kind == NK_TYPE_NAMED():
        let sym = self.ast.get_data0(ret_node)
        if self.type_param_exists(tp_start, tp_count, sym) != 0:
            return self.lookup_generic_subst(sym)
        return self.resolve_type_expr(ret_node)

    if kind == NK_TYPE_REF():
        let pointee = self.resolve_generic_return_type_node(self.ast.get_data0(ret_node), tp_start, tp_count)
        let is_mut = self.ast.get_data1(ret_node)
        return self.add_type(TY_REF(), pointee, is_mut, 0)

    if kind == NK_TYPE_PTR():
        let pointee = self.resolve_generic_return_type_node(self.ast.get_data0(ret_node), tp_start, tp_count)
        let is_mut = self.ast.get_data1(ret_node)
        return self.add_type(TY_PTR(), pointee, is_mut, 0)

    if kind == NK_TYPE_ARRAY():
        let elem = self.resolve_generic_return_type_node(self.ast.get_data0(ret_node), tp_start, tp_count)
        let size = self.ast.get_data1(ret_node)
        return self.add_type(TY_ARRAY(), elem, size, 0)

    if kind == NK_TYPE_SLICE():
        let elem = self.resolve_generic_return_type_node(self.ast.get_data0(ret_node), tp_start, tp_count)
        return self.add_type(TY_SLICE(), elem, 0, 0)

    if kind == NK_TYPE_TUPLE():
        let extra_start = self.ast.get_data0(ret_node)
        let elem_count = self.ast.get_data1(ret_node)
        let te_start = self.type_extra.len() as i32
        for ei in 0..elem_count:
            let e_node = self.ast.get_extra(extra_start + ei)
            self.type_extra.push(self.resolve_generic_return_type_node(e_node, tp_start, tp_count))
        return self.add_type(TY_TUPLE(), te_start, elem_count, 0)

    self.resolve_type_expr(ret_node)

fn Sema.selection_cache_key(self: Sema, type_sym: i32, trait_sym: i32) -> str:
    int_to_string(type_sym) ++ ":" ++ int_to_string(trait_sym)

fn Sema.select_trait_impl(self: Sema, type_sym: i32, trait_sym: i32) -> i32:
    let key = self.selection_cache_key(type_sym, trait_sym)
    if self.selection_cache.contains(key):
        return self.selection_cache.get(key).unwrap()

    var found = 0
    if self.impl_lookup.contains(type_sym):
        let idx = self.impl_lookup.get(type_sym).unwrap()
        let start = self.impl_starts.get(idx as i64)
        let count = self.impl_counts.get(idx as i64)
        for i in 0..count:
            if self.impl_extra.get((start + i) as i64) == trait_sym:
                found = 1
    self.selection_cache.insert(key, found)
    found

fn Sema.type_symbol_for_bounds(self: Sema, tid: i32) -> i32:
    let resolved = self.resolve_alias(tid)
    let tk = self.get_type_kind(resolved)
    if tk == TY_STRUCT() or tk == TY_ENUM():
        return self.get_type_d0(resolved)
    if tk == TY_INT():
        let bits = self.get_type_d0(resolved)
        let signed = self.get_type_d1(resolved)
        if bits == 8:
            if signed != 0:
                return self.pool.intern("i8")
            return self.pool.intern("u8")
        if bits == 16:
            if signed != 0:
                return self.pool.intern("i16")
            return self.pool.intern("u16")
        if bits == 32:
            if signed != 0:
                return self.pool.intern("i32")
            return self.pool.intern("u32")
        if bits == 64:
            if signed != 0:
                return self.pool.intern("i64")
            return self.pool.intern("u64")
        return 0
    if tk == TY_FLOAT():
        if self.get_type_d0(resolved) == 32:
            return self.pool.intern("f32")
        return self.pool.intern("f64")
    if tk == TY_BOOL():
        return self.pool.intern("bool")
    if tk == TY_STR():
        return self.pool.intern("str")
    0

fn Sema.trait_object_from_type_node(self: Sema, type_node: i32) -> i32:
    if type_node == 0:
        return 0
    let kind = self.ast.kind(type_node)
    if kind == NK_TYPE_TRAIT_OBJ():
        return self.ast.get_data0(type_node)
    if kind == NK_TYPE_REF() or kind == NK_TYPE_PTR():
        return self.trait_object_from_type_node(self.ast.get_data0(type_node))
    if kind == NK_TYPE_GENERIC():
        let base = self.ast.get_data0(type_node)
        if self.pool.resolve(base) != "Box":
            return 0
        let extra_start = self.ast.get_data1(type_node)
        let arg_count = self.ast.get_data2(type_node)
        if arg_count != 1:
            return 0
        return self.trait_object_from_type_node(self.ast.get_extra(extra_start))
    0

fn Sema.dyn_arg_concrete_type_symbol(self: Sema, tid: i32) -> i32:
    let resolved = self.resolve_alias(tid)
    let tk = self.get_type_kind(resolved)
    if tk == TY_REF() or tk == TY_PTR():
        return self.type_symbol_for_bounds(self.get_type_d0(resolved))
    self.type_symbol_for_bounds(resolved)

fn Sema.check_method_call(self: Sema, callee: i32, extra_start: i32, arg_count: i32, node: i32) -> i32:
    let expr = self.ast.get_data0(callee)
    let field = self.ast.get_data1(callee)
    let obj_type = self.check_expr(expr)

    // Check all arguments
    let arg_types: Vec[i32] = Vec.new()
    for ai in 0..arg_count:
        arg_types.push(self.check_expr(self.ast.get_extra(extra_start + ai)))

    let field_name = self.pool.resolve(field)
    if field_name == "track":
        if self.ast.kind(expr) != NK_IDENT() or self.is_active_async_scope_symbol(self.ast.get_data0(expr)) == 0:
            self.emit_error("track() is only available inside async scope", node)
            return 0
        if arg_count <= 0:
            self.emit_error("track() requires a Task value", node)
            return 0
        let task_arg = self.ast.get_extra(extra_start)
        if self.expr_is_task_value(task_arg) == 0:
            self.emit_error("track() requires a Task value", task_arg)
        return arg_types.get(0)

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

fn Sema.check_builtin_call(self: Sema, fn_sym: i32, node: i32, arg_types: Vec[i32], arg_count: i32) -> i32:
    let name = self.pool.resolve(fn_sym)
    let args_start = self.ast.get_data1(node)
    if name == "println" or name == "print":
        return self.ty_void
    if name == "assert":
        if arg_count != 1:
            self.emit_error("assert() expects exactly one argument", node)
            return 0
        return self.ty_void
    if name == "Channel":
        if arg_count > 1:
            self.emit_error("Channel() expects zero or one capacity argument", node)
            return 0
        if arg_count == 1:
            let cap_ty = arg_types.get(0)
            if cap_ty != 0:
                let cap_kind = self.get_type_kind(self.resolve_alias(cap_ty))
                if cap_kind != TY_INT():
                    self.emit_error("Channel() capacity must be an integer", self.ast.get_extra(args_start))
                    return 0
        return self.ty_i64
    if name == "send":
        if arg_count != 2:
            self.emit_error("send() expects exactly two arguments", node)
            return 0
        let ch_ty = arg_types.get(0)
        if ch_ty != 0:
            let ch_kind = self.get_type_kind(self.resolve_alias(ch_ty))
            if ch_kind != TY_INT():
                self.emit_error("send() expects channel handle as integer value", self.ast.get_extra(args_start))
                return 0
        let payload_node = self.ast.get_extra(args_start + 1)
        if self.expr_is_ephemeral_value(payload_node) != 0 or self.expr_is_ephemeral_task(payload_node) != 0:
            self.emit_error("channel send requires Send value", payload_node)
            return 0
        let payload_ty = arg_types.get(1)
        if payload_ty != 0:
            let payload_kind = self.get_type_kind(self.resolve_alias(payload_ty))
            if payload_kind != TY_INT():
                self.emit_error("send() currently supports integer payloads", payload_node)
                return 0
        return self.ty_void
    if name == "recv":
        if arg_count != 1:
            self.emit_error("recv() expects exactly one argument", node)
            return 0
        let ch_ty = arg_types.get(0)
        if ch_ty != 0:
            let ch_kind = self.get_type_kind(self.resolve_alias(ch_ty))
            if ch_kind != TY_INT():
                self.emit_error("recv() expects channel handle as integer value", self.ast.get_extra(args_start))
                return 0
        return self.ty_i32
    if name == "close":
        if arg_count != 1:
            self.emit_error("close() expects exactly one argument", node)
            return 0
        let ch_ty = arg_types.get(0)
        if ch_ty != 0:
            let ch_kind = self.get_type_kind(self.resolve_alias(ch_ty))
            if ch_kind != TY_INT():
                self.emit_error("close() expects channel handle as integer value", self.ast.get_extra(args_start))
                return 0
        return self.ty_void
    if name == "todo" or name == "unreachable":
        if arg_count > 1:
            self.emit_error("todo()/unreachable() expect zero or one message argument", node)
            return 0
        if arg_count == 1:
            let msg_ty = arg_types.get(0)
            if msg_ty != 0:
                if not self.types_compatible(self.ty_str, msg_ty):
                    self.emit_error("todo()/unreachable() message must be str-compatible", self.ast.get_extra(self.ast.get_data1(node)))
                    return 0
        return self.ty_never
    0

fn Sema.is_collection_type_name(self: Sema, sym: i32) -> i32:
    let name = self.pool.resolve(sym)
    if name == "Vec" or name == "HashMap" or name == "HashSet" or name == "BTreeMap" or name == "SlotMap":
        return 1
    0

fn Sema.type_expr_contains_ref(self: Sema, node: i32) -> i32:
    if node == 0:
        return 0
    let kind = self.ast.kind(node)
    if kind == NK_TYPE_REF():
        return 1
    if kind == NK_TYPE_GENERIC():
        let extra_start = self.ast.get_data1(node)
        let arg_count = self.ast.get_data2(node)
        for ai in 0..arg_count:
            if self.type_expr_contains_ref(self.ast.get_extra(extra_start + ai)) != 0:
                return 1
        return 0
    if kind == NK_TYPE_PTR() or kind == NK_TYPE_OPTIONAL():
        return self.type_expr_contains_ref(self.ast.get_data0(node))
    if kind == NK_TYPE_FN():
        let extra_start = self.ast.get_data0(node)
        let param_count = self.ast.get_data1(node)
        for pi in 0..param_count:
            if self.type_expr_contains_ref(self.ast.get_extra(extra_start + pi)) != 0:
                return 1
        return self.type_expr_contains_ref(self.ast.get_data2(node))
    if kind == NK_TYPE_TUPLE():
        let extra_start = self.ast.get_data0(node)
        let elem_count = self.ast.get_data1(node)
        for ei in 0..elem_count:
            if self.type_expr_contains_ref(self.ast.get_extra(extra_start + ei)) != 0:
                return 1
        return 0
    if kind == NK_TYPE_ARRAY() or kind == NK_TYPE_SLICE():
        return self.type_expr_contains_ref(self.ast.get_data0(node))
    0

fn Sema.type_expr_is_collection_with_ref(self: Sema, node: i32) -> i32:
    if node == 0:
        return 0
    let kind = self.ast.kind(node)
    if kind == NK_TYPE_GENERIC():
        let base = self.ast.get_data0(node)
        let extra_start = self.ast.get_data1(node)
        let arg_count = self.ast.get_data2(node)
        if self.is_collection_type_name(base) != 0:
            for ai in 0..arg_count:
                if self.type_expr_contains_ref(self.ast.get_extra(extra_start + ai)) != 0:
                    return 1
        for ai in 0..arg_count:
            if self.type_expr_is_collection_with_ref(self.ast.get_extra(extra_start + ai)) != 0:
                return 1
        return 0
    if kind == NK_TYPE_PTR() or kind == NK_TYPE_OPTIONAL():
        return self.type_expr_is_collection_with_ref(self.ast.get_data0(node))
    if kind == NK_TYPE_FN():
        let extra_start = self.ast.get_data0(node)
        let param_count = self.ast.get_data1(node)
        for pi in 0..param_count:
            if self.type_expr_is_collection_with_ref(self.ast.get_extra(extra_start + pi)) != 0:
                return 1
        return self.type_expr_is_collection_with_ref(self.ast.get_data2(node))
    if kind == NK_TYPE_TUPLE():
        let extra_start = self.ast.get_data0(node)
        let elem_count = self.ast.get_data1(node)
        for ei in 0..elem_count:
            if self.type_expr_is_collection_with_ref(self.ast.get_extra(extra_start + ei)) != 0:
                return 1
        return 0
    if kind == NK_TYPE_ARRAY() or kind == NK_TYPE_SLICE():
        return self.type_expr_is_collection_with_ref(self.ast.get_data0(node))
    0

fn Sema.borrow_root_place(self: Sema, node: i32) -> i32:
    if node == 0:
        return 0
    let kind = self.ast.kind(node)
    if kind == NK_IDENT():
        return self.ast.get_data0(node)
    if kind == NK_FIELD_ACCESS():
        let base = self.ast.get_data0(node)
        if self.ast.kind(base) == NK_IDENT():
            return self.ast.get_data0(base)
        return 0
    if kind == NK_INDEX():
        let base = self.ast.get_data0(node)
        if self.ast.kind(base) == NK_IDENT():
            return self.ast.get_data0(base)
        return 0
    if kind == NK_GROUPED():
        return self.borrow_root_place(self.ast.get_data0(node))
    0

fn Sema.borrow_field(self: Sema, node: i32) -> i32:
    if node == 0:
        return 0
    if self.ast.kind(node) == NK_FIELD_ACCESS():
        return self.ast.get_data1(node)
    0

fn Sema.are_borrows_disjoint(self: Sema, new_field: i32, existing_field: i32) -> i32:
    let _ = self
    if new_field == 0 or existing_field == 0:
        return 0
    if new_field != existing_field:
        return 1
    0

fn Sema.check_borrow_create(self: Sema, operand_node: i32, kind: i32, err_node: i32):
    let place = self.borrow_root_place(operand_node)
    if place == 0:
        return
    let new_field = self.borrow_field(operand_node)

    var i = 0
    while i < self.borrow_kinds.len() as i32:
        let existing_place = self.borrow_places.get(i as i64)
        if existing_place != place:
            i = i + 1
            continue

        let existing_field = self.borrow_fields.get(i as i64)
        if self.are_borrows_disjoint(new_field, existing_field) != 0:
            i = i + 1
            continue

        let existing_kind = self.borrow_kinds.get(i as i64)
        if kind == BK_SHARED():
            if existing_kind == BK_EXCLUSIVE():
                self.emit_error("cannot borrow: already mutably borrowed", err_node)
                return
            i = i + 1
            continue

        // New exclusive borrow conflicts with any existing borrow.
        if existing_kind == BK_EXCLUSIVE():
            self.emit_error("cannot borrow mutably: already mutably borrowed", err_node)
        else:
            self.emit_error("cannot borrow mutably: already borrowed", err_node)
        return

    self.borrow_kinds.push(kind)
    self.borrow_places.push(place)
    self.borrow_fields.push(new_field)
    self.borrow_refs.push(0)

fn Sema.remove_borrow_at(self: Sema, idx: i32):
    let last = self.borrow_refs.len() as i32 - 1
    if idx < 0 or idx > last:
        return
    if idx < last:
        self.borrow_kinds.set_i32(idx as i64, self.borrow_kinds.get(last as i64))
        self.borrow_places.set_i32(idx as i64, self.borrow_places.get(last as i64))
        self.borrow_fields.set_i32(idx as i64, self.borrow_fields.get(last as i64))
        self.borrow_refs.set_i32(idx as i64, self.borrow_refs.get(last as i64))
    self.borrow_kinds.pop()
    self.borrow_places.pop()
    self.borrow_fields.pop()
    self.borrow_refs.pop()

fn Sema.expr_uses_symbol(self: Sema, node: i32, sym: i32) -> i32:
    if node == 0:
        return 0
    let kind = self.ast.kind(node)
    if kind == NK_IDENT():
        if self.ast.get_data0(node) == sym:
            return 1
        return 0
    if kind == NK_BINARY():
        if self.expr_uses_symbol(self.ast.get_data1(node), sym) != 0:
            return 1
        return self.expr_uses_symbol(self.ast.get_data2(node), sym)
    if kind == NK_UNARY():
        return self.expr_uses_symbol(self.ast.get_data1(node), sym)
    if kind == NK_GROUPED() or kind == NK_AWAIT() or kind == NK_ASYNC_BLOCK() or kind == NK_SPAWN() or kind == NK_DEFER() or kind == NK_YIELD() or kind == NK_COMPTIME():
        return self.expr_uses_symbol(self.ast.get_data0(node), sym)
    if kind == NK_CALL():
        if self.expr_uses_symbol(self.ast.get_data0(node), sym) != 0:
            return 1
        let extra_start = self.ast.get_data1(node)
        let arg_count = self.ast.get_data2(node)
        for ai in 0..arg_count:
            if self.expr_uses_symbol(self.ast.get_extra(extra_start + ai), sym) != 0:
                return 1
        return 0
    if kind == NK_FIELD_ACCESS():
        return self.expr_uses_symbol(self.ast.get_data0(node), sym)
    if kind == NK_OPTIONAL_CHAIN():
        if self.expr_uses_symbol(self.ast.get_data0(node), sym) != 0:
            return 1
        let extra_start = self.ast.get_data2(node)
        if extra_start != 0:
            let has_args = self.ast.get_extra(extra_start)
            if has_args != 0:
                let arg_count = self.ast.get_extra(extra_start + 1)
                for ai in 0..arg_count:
                    if self.expr_uses_symbol(self.ast.get_extra(extra_start + 2 + ai), sym) != 0:
                        return 1
        return 0
    if kind == NK_INDEX():
        if self.expr_uses_symbol(self.ast.get_data0(node), sym) != 0:
            return 1
        return self.expr_uses_symbol(self.ast.get_data1(node), sym)
    if kind == NK_SLICE():
        if self.expr_uses_symbol(self.ast.get_data0(node), sym) != 0:
            return 1
        if self.expr_uses_symbol(self.ast.get_data1(node), sym) != 0:
            return 1
        return self.expr_uses_symbol(self.ast.get_data2(node), sym)
    if kind == NK_BLOCK():
        let extra_start = self.ast.get_data0(node)
        let stmt_count = self.ast.get_data1(node)
        let tail = self.ast.get_data2(node)
        for si in 0..stmt_count:
            if self.expr_uses_symbol(self.ast.get_extra(extra_start + si), sym) != 0:
                return 1
        return self.expr_uses_symbol(tail, sym)
    if kind == NK_IF_EXPR():
        if self.expr_uses_symbol(self.ast.get_data0(node), sym) != 0:
            return 1
        if self.expr_uses_symbol(self.ast.get_data1(node), sym) != 0:
            return 1
        return self.expr_uses_symbol(self.ast.get_data2(node), sym)
    if kind == NK_RETURN():
        return self.expr_uses_symbol(self.ast.get_data0(node), sym)
    if kind == NK_LET_BINDING():
        return self.expr_uses_symbol(self.ast.get_data1(node), sym)
    if kind == NK_LET_ELSE():
        if self.expr_uses_symbol(self.ast.get_data1(node), sym) != 0:
            return 1
        return self.expr_uses_symbol(self.ast.get_data2(node), sym)
    if kind == NK_TUPLE_DESTRUCTURE():
        return self.expr_uses_symbol(self.ast.get_data2(node), sym)
    if kind == NK_ASSIGN():
        if self.expr_uses_symbol(self.ast.get_data0(node), sym) != 0:
            return 1
        return self.expr_uses_symbol(self.ast.get_data1(node), sym)
    if kind == NK_TUPLE() or kind == NK_ARRAY_LIT():
        let extra_start = self.ast.get_data0(node)
        let elem_count = self.ast.get_data1(node)
        for ei in 0..elem_count:
            if self.expr_uses_symbol(self.ast.get_extra(extra_start + ei), sym) != 0:
                return 1
        return 0
    if kind == NK_RANGE():
        if self.expr_uses_symbol(self.ast.get_data0(node), sym) != 0:
            return 1
        return self.expr_uses_symbol(self.ast.get_data1(node), sym)
    if kind == NK_MATCH():
        if self.expr_uses_symbol(self.ast.get_data0(node), sym) != 0:
            return 1
        let extra_start = self.ast.get_data1(node)
        let arm_count = self.ast.get_data2(node)
        for ai in 0..arm_count:
            let arm = self.ast.get_extra(extra_start + ai)
            let guard = self.ast.get_data2(arm)
            if self.expr_uses_symbol(guard, sym) != 0:
                return 1
            if self.expr_uses_symbol(self.ast.get_data1(arm), sym) != 0:
                return 1
        return 0
    if kind == NK_STRUCT_LIT():
        let extra_start = self.ast.get_data1(node)
        let field_count = self.ast.get_data2(node)
        for fi in 0..field_count:
            if self.expr_uses_symbol(self.ast.get_extra(extra_start + fi * 2 + 1), sym) != 0:
                return 1
        return 0
    if kind == NK_FOR():
        if self.expr_uses_symbol(self.ast.get_data1(node), sym) != 0:
            return 1
        return self.expr_uses_symbol(self.ast.get_data2(node), sym)
    if kind == NK_WHILE():
        if self.expr_uses_symbol(self.ast.get_data0(node), sym) != 0:
            return 1
        return self.expr_uses_symbol(self.ast.get_data1(node), sym)
    if kind == NK_LOOP():
        return self.expr_uses_symbol(self.ast.get_data0(node), sym)
    if kind == NK_BREAK():
        return self.expr_uses_symbol(self.ast.get_data0(node), sym)
    if kind == NK_PIPELINE():
        if self.expr_uses_symbol(self.ast.get_data0(node), sym) != 0:
            return 1
        return self.expr_uses_symbol(self.ast.get_data1(node), sym)
    if kind == NK_WITH_EXPR():
        if self.expr_uses_symbol(self.ast.get_data0(node), sym) != 0:
            return 1
        return self.expr_uses_symbol(self.ast.get_data1(node), sym)
    if kind == NK_RECORD_UPDATE():
        if self.expr_uses_symbol(self.ast.get_data0(node), sym) != 0:
            return 1
        let extra_start = self.ast.get_data1(node)
        let field_count = self.ast.get_data2(node)
        for fi in 0..field_count:
            if self.expr_uses_symbol(self.ast.get_extra(extra_start + fi * 2 + 1), sym) != 0:
                return 1
        return 0
    if kind == NK_ENUM_VARIANT():
        let extra_start = self.ast.get_data2(node)
        let arg_count = self.ast.get_extra(extra_start)
        for ai in 0..arg_count:
            if self.expr_uses_symbol(self.ast.get_extra(extra_start + 1 + ai), sym) != 0:
                return 1
        return 0
    if kind == NK_CLOSURE() or kind == NK_CAST():
        return self.expr_uses_symbol(self.ast.get_data0(node), sym)
    if kind == NK_ARRAY_COMPREHENSION():
        if self.expr_uses_symbol(self.ast.get_data0(node), sym) != 0:
            return 1
        if self.expr_uses_symbol(self.ast.get_data2(node), sym) != 0:
            return 1
        return 0
    if kind == NK_ASYNC_SCOPE():
        return self.expr_uses_symbol(self.ast.get_data1(node), sym)
    if kind == NK_SELECT_AWAIT():
        let extra_start = self.ast.get_data0(node)
        let arm_count = self.ast.get_data1(node)
        for ai in 0..arm_count:
            if self.expr_uses_symbol(self.ast.get_extra(extra_start + ai * 3 + 1), sym) != 0:
                return 1
            if self.expr_uses_symbol(self.ast.get_extra(extra_start + ai * 3 + 2), sym) != 0:
                return 1
        return 0
    0

fn Sema.expire_dead_borrows_in_block(self: Sema, block_extra_start: i32, stmt_count: i32, next_stmt_index: i32, tail_node: i32):
    var bi = 0
    while bi < self.borrow_refs.len() as i32:
        let ref_sym = self.borrow_refs.get(bi as i64)
        if ref_sym == 0:
            bi = bi + 1
            continue

        var live = 0
        var si = next_stmt_index
        while si < stmt_count:
            if self.expr_uses_symbol(self.ast.get_extra(block_extra_start + si), ref_sym) != 0:
                live = 1
                break
            si = si + 1

        if live == 0 and tail_node != 0:
            if self.expr_uses_symbol(tail_node, ref_sym) != 0:
                live = 1

        if live == 0:
            self.remove_borrow_at(bi)
        else:
            bi = bi + 1

fn Sema.type_is_ephemeral_value(self: Sema, tid: i32) -> i32:
    if tid == 0:
        return 0
    let resolved = self.resolve_alias(tid)
    let tk = self.get_type_kind(resolved)
    if tk == TY_REF() or tk == TY_SLICE():
        return 1
    if tk == TY_ARRAY():
        return self.type_is_ephemeral_value(self.get_type_d0(resolved))
    if tk == TY_TUPLE():
        let te_start = self.get_type_d0(resolved)
        let elem_count = self.get_type_d1(resolved)
        for ei in 0..elem_count:
            if self.type_is_ephemeral_value(self.type_extra.get((te_start + ei) as i64)) != 0:
                return 1
        return 0
    if tk == TY_STRUCT():
        let st_name = self.get_type_d0(resolved)
        if self.ephemeral_types.contains(st_name):
            return 1
        let te_start = self.get_type_d1(resolved)
        let field_count = self.get_type_d2(resolved)
        for fi in 0..field_count:
            let ft = self.type_extra.get((te_start + fi * 3 + 1) as i64)
            if self.type_is_ephemeral_value(ft) != 0:
                return 1
        return 0
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

    // Never is the bottom type: actual Never is compatible with any expected type.
    if act_k == TY_NEVER():
        return 1

    // Structural compatibility for non-interned compound types.
    if exp_k == TY_PTR() and act_k == TY_PTR():
        let exp_mut = self.get_type_d1(exp_r)
        let act_mut = self.get_type_d1(act_r)
        if exp_mut != 0 and act_mut == 0:
            return 0
        return self.types_compatible(self.get_type_d0(exp_r), self.get_type_d0(act_r))
    if exp_k == TY_REF() and act_k == TY_REF():
        let exp_mut = self.get_type_d1(exp_r)
        let act_mut = self.get_type_d1(act_r)
        if exp_mut != 0 and act_mut == 0:
            return 0
        return self.types_compatible(self.get_type_d0(exp_r), self.get_type_d0(act_r))
    if exp_k == TY_SLICE() and act_k == TY_SLICE():
        return self.types_compatible(self.get_type_d0(exp_r), self.get_type_d0(act_r))
    if exp_k == TY_ARRAY() and act_k == TY_ARRAY():
        if self.get_type_d1(exp_r) != self.get_type_d1(act_r):
            return 0
        return self.types_compatible(self.get_type_d0(exp_r), self.get_type_d0(act_r))

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
    if lk == TY_NEVER():
        return rhs
    if rk == TY_NEVER():
        return lhs
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
    if tk == TY_ERR() or tk == TY_INT() or tk == TY_FLOAT() or tk == TY_BOOL() or tk == TY_VOID() or tk == TY_NEVER() or tk == TY_STR():
        return 1
    if tk == TY_PTR() or tk == TY_REF() or tk == TY_FN() or tk == TY_GENERIC_FN():
        return 1
    if tk == TY_STRUCT():
        let name = self.get_type_d0(resolved)
        if self.has_drop_method(name):
            return 0
        let te_start = self.get_type_d1(resolved)
        let field_count = self.get_type_d2(resolved)
        for fi in 0..field_count:
            let ft = self.type_extra.get((te_start + fi * 3 + 1) as i64)
            if self.is_copy(ft) == 0:
                return 0
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
        for ei in 0..elem_count:
            if self.is_copy(self.type_extra.get((te_start + ei) as i64)) == 0:
                return 0
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
    if name == "todo" or name == "unreachable":
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

// ── Typed dump rendering ────────────────────────────────────────

fn typed_decl_kind_name(kind: i32) -> str:
    if kind == NK_FN_DECL(): return "function"
    if kind == NK_TYPE_DECL(): return "type_decl"
    if kind == NK_USE_DECL(): return "use_decl"
    if kind == NK_LET_DECL(): return "let_decl"
    if kind == NK_EXTERN_FN(): return "extern_fn"
    if kind == NK_C_IMPORT(): return "c_import"
    if kind == NK_TRAIT_DECL(): return "trait_decl"
    if kind == NK_IMPL_DECL(): return "impl_decl"
    if kind == NK_POISONED_DECL(): return "poisoned"
    "unknown"

fn typed_expr_kind_name(kind: i32) -> str:
    if kind == NK_INT_LIT(): return "int_literal"
    if kind == NK_FLOAT_LIT(): return "float_literal"
    if kind == NK_STRING_LIT(): return "string_literal"
    if kind == NK_C_STRING_LIT(): return "c_string_literal"
    if kind == NK_BOOL_LIT(): return "bool_literal"
    if kind == NK_IDENT(): return "ident"
    if kind == NK_BINARY(): return "binary"
    if kind == NK_UNARY(): return "unary"
    if kind == NK_CALL(): return "call"
    if kind == NK_FIELD_ACCESS(): return "field_access"
    if kind == NK_INDEX(): return "index"
    if kind == NK_SLICE(): return "slice"
    if kind == NK_BLOCK(): return "block"
    if kind == NK_IF_EXPR(): return "if_expr"
    if kind == NK_RETURN(): return "return_expr"
    if kind == NK_LET_BINDING(): return "let_binding"
    if kind == NK_LET_ELSE(): return "let_else"
    if kind == NK_TUPLE_DESTRUCTURE(): return "tuple_destructure"
    if kind == NK_ASSIGN(): return "assign"
    if kind == NK_TUPLE(): return "tuple"
    if kind == NK_RANGE(): return "range"
    if kind == NK_VARIANT_SHORTHAND(): return "variant_shorthand"
    if kind == NK_AWAIT(): return "await_expr"
    if kind == NK_ASYNC_BLOCK(): return "async_block"
    if kind == NK_SPAWN(): return "spawn_expr"
    if kind == NK_PIPELINE(): return "pipeline"
    if kind == NK_GROUPED(): return "grouped"
    if kind == NK_WHILE(): return "while_expr"
    if kind == NK_LOOP(): return "loop_expr"
    if kind == NK_FOR(): return "for_expr"
    if kind == NK_BREAK(): return "break_expr"
    if kind == NK_CONTINUE(): return "continue_expr"
    if kind == NK_ARRAY_LIT(): return "array_literal"
    if kind == NK_ARRAY_COMPREHENSION(): return "array_comprehension"
    if kind == NK_STRUCT_LIT(): return "struct_literal"
    if kind == NK_MATCH(): return "match_expr"
    if kind == NK_ENUM_VARIANT(): return "enum_variant"
    if kind == NK_CLOSURE(): return "closure"
    if kind == NK_CAST(): return "cast"
    if kind == NK_DEFER(): return "defer_expr"
    if kind == NK_WITH_EXPR(): return "with_expr"
    if kind == NK_RECORD_UPDATE(): return "record_update"
    if kind == NK_YIELD(): return "yield_expr"
    if kind == NK_COMPTIME(): return "comptime_expr"
    if kind == NK_ASYNC_SCOPE(): return "async_scope"
    if kind == NK_SELECT_AWAIT(): return "select_await"
    if kind == NK_OPTIONAL_CHAIN(): return "optional_chain"
    if kind == NK_POISONED_EXPR(): return "poisoned"
    "unknown"

fn typed_indent(indent: i32) -> str:
    var out = ""
    for i in 0..indent:
        out = out ++ "  "
    out

fn Sema.dump_typed_module(self: Sema) -> str:
    var out = ""
    out = out ++ "typed module decls=" ++ int_to_string(self.ast.decl_count()) ++ "\n"

    for di in 0..self.ast.decl_count():
        let decl = self.ast.get_decl(di)
        let kind = self.ast.kind(decl)
        let start = self.ast.get_start(decl)
        let end = self.ast.get_end(decl)

        out = out ++ "decl[" ++ int_to_string(di) ++ "] kind=" ++ typed_decl_kind_name(kind) ++ " span=" ++ int_to_string(start) ++ ".." ++ int_to_string(end) ++ "\n"

        if kind == NK_FN_DECL():
            let fn_name_sym = self.ast.get_data0(decl)
            let fn_name = self.pool.resolve(fn_name_sym)
            let sig_idx = self.get_sig(fn_name_sym)
            if sig_idx >= 0:
                out = out ++ "  fn " ++ fn_name ++ "("
                let meta = self.ast.find_fn_meta(decl)
                var param_start = 0
                if meta >= 0:
                    param_start = self.ast.fn_meta_param_start(meta)
                let param_count = self.sig_get_param_count(sig_idx)
                for pi in 0..param_count:
                    if pi > 0:
                        out = out ++ ", "
                    let p_name_sym = if meta >= 0: self.ast.get_extra(param_start + pi * 2) else: 0
                    let p_name = if p_name_sym != 0: self.pool.resolve(p_name_sym) else: "_"
                    out = out ++ p_name ++ ": " ++ self.type_name(self.sig_param_type(sig_idx, pi))
                out = out ++ ") -> " ++ self.type_name(self.sig_return_type(sig_idx)) ++ "\n"
            else:
                out = out ++ "  fn " ++ fn_name ++ "(<unknown>)\n"
            out = out ++ self.dump_typed_expr_tree(self.ast.get_data1(decl), 2)
            continue

        if kind == NK_EXTERN_FN():
            let ext_name_sym = self.ast.get_data0(decl)
            let ext_name = self.pool.resolve(ext_name_sym)
            let sig_idx = self.get_sig(ext_name_sym)
            if sig_idx >= 0:
                out = out ++ "  extern fn " ++ ext_name ++ "("
                let meta = self.ast.find_fn_meta(decl)
                var param_start = 0
                if meta >= 0:
                    param_start = self.ast.fn_meta_param_start(meta)
                let param_count = self.sig_get_param_count(sig_idx)
                for pi in 0..param_count:
                    if pi > 0:
                        out = out ++ ", "
                    let p_name_sym = if meta >= 0: self.ast.get_extra(param_start + pi * 2) else: 0
                    let p_name = if p_name_sym != 0: self.pool.resolve(p_name_sym) else: "_"
                    out = out ++ p_name ++ ": " ++ self.type_name(self.sig_param_type(sig_idx, pi))
                out = out ++ ") -> " ++ self.type_name(self.sig_return_type(sig_idx)) ++ "\n"
            else:
                out = out ++ "  extern fn " ++ ext_name ++ "(<unknown>)\n"
            continue

        if kind == NK_LET_DECL():
            let name = self.pool.resolve(self.ast.get_data0(decl))
            let has_resolved = self.typed_binding_types.contains(start) and self.typed_binding_types.get(start).unwrap() != 0
            if has_resolved:
                let ty = self.typed_binding_types.get(start).unwrap()
                let is_mut = if self.typed_binding_muts.contains(start): self.typed_binding_muts.get(start).unwrap() else: 0
                out = out ++ "  let " ++ name
                if is_mut != 0:
                    out = out ++ " (mut)"
                out = out ++ ": " ++ self.type_name(ty) ++ "\n"
            else:
                // Stage0 parity: emit <annotated> when type expr present but unresolved,
                // <inferred> when no annotation at all.
                let flags = self.ast.get_data2(decl)
                let has_ann = self.top_level_let_type_ann_extra(flags) >= 0
                out = out ++ "  let " ++ name ++ ": " ++ (if has_ann: "<annotated>" else: "<inferred>") ++ "\n"
            continue

        if kind == NK_TYPE_DECL():
            out = out ++ "  type " ++ self.pool.resolve(self.ast.get_data0(decl)) ++ "\n"
            continue

        if kind == NK_TRAIT_DECL():
            out = out ++ "  trait " ++ self.pool.resolve(self.ast.get_data0(decl)) ++ "\n"
            continue

        if kind == NK_IMPL_DECL():
            let type_name = self.pool.resolve(self.ast.get_data0(decl))
            let trait_sym = self.ast.get_data2(decl)
            if trait_sym != 0:
                out = out ++ "  impl " ++ self.pool.resolve(trait_sym) ++ " for " ++ type_name ++ "\n"
            else:
                out = out ++ "  impl " ++ type_name ++ "\n"
            continue

        if kind == NK_USE_DECL():
            let extra_start = self.ast.get_data0(decl)
            let path_count = self.ast.get_data1(decl)
            out = out ++ "  use "
            for pi in 0..path_count:
                if pi > 0:
                    out = out ++ "."
                out = out ++ self.pool.resolve(self.ast.get_extra(extra_start + pi))
            out = out ++ "\n"
            continue

        if kind == NK_C_IMPORT():
            out = out ++ "  c_import \"" ++ self.pool.resolve(self.ast.get_data0(decl)) ++ "\"\n"
            continue

        if kind == NK_POISONED_DECL():
            out = out ++ "  <poisoned>\n"

    out

fn Sema.dump_typed_expr_tree(self: Sema, node: i32, indent: i32) -> str:
    if node == 0:
        return ""

    var out = ""
    let kind = self.ast.kind(node)
    let start = self.ast.get_start(node)
    let end = self.ast.get_end(node)

    if self.typed_expr_types.contains(start):
        let tid = self.typed_expr_types.get(start).unwrap()
        out = out ++ typed_indent(indent) ++ "expr " ++ typed_expr_kind_name(kind) ++ " span=" ++ int_to_string(start) ++ ".." ++ int_to_string(end) ++ " : " ++ self.type_name(tid) ++ "\n"

    if kind == NK_LET_BINDING():
        if self.typed_binding_types.contains(start):
            let name_sym = if self.typed_binding_names.contains(start): self.typed_binding_names.get(start).unwrap() else: self.ast.get_data0(node)
            let is_mut = if self.typed_binding_muts.contains(start): self.typed_binding_muts.get(start).unwrap() else: (self.ast.get_data2(node) % 2)
            out = out ++ typed_indent(indent + 1) ++ "bind " ++ self.pool.resolve(name_sym)
            if is_mut != 0:
                out = out ++ " (mut)"
            out = out ++ ": " ++ self.type_name(self.typed_binding_types.get(start).unwrap()) ++ "\n"

    if kind == NK_BINARY():
        out = out ++ self.dump_typed_expr_tree(self.ast.get_data1(node), indent + 1)
        out = out ++ self.dump_typed_expr_tree(self.ast.get_data2(node), indent + 1)
        return out

    if kind == NK_UNARY():
        out = out ++ self.dump_typed_expr_tree(self.ast.get_data1(node), indent + 1)
        return out

    if kind == NK_CALL():
        let extra_start = self.ast.get_data1(node)
        let arg_count = self.ast.get_data2(node)
        out = out ++ self.dump_typed_expr_tree(self.ast.get_data0(node), indent + 1)
        for ai in 0..arg_count:
            out = out ++ self.dump_typed_expr_tree(self.ast.get_extra(extra_start + ai), indent + 1)
        return out

    if kind == NK_FIELD_ACCESS():
        out = out ++ self.dump_typed_expr_tree(self.ast.get_data0(node), indent + 1)
        return out

    if kind == NK_OPTIONAL_CHAIN():
        let extra_start = self.ast.get_data2(node)
        let arg_count = self.ast.get_extra(extra_start)
        out = out ++ self.dump_typed_expr_tree(self.ast.get_data0(node), indent + 1)
        for ai in 0..arg_count:
            out = out ++ self.dump_typed_expr_tree(self.ast.get_extra(extra_start + 1 + ai), indent + 1)
        return out

    if kind == NK_INDEX():
        out = out ++ self.dump_typed_expr_tree(self.ast.get_data0(node), indent + 1)
        out = out ++ self.dump_typed_expr_tree(self.ast.get_data1(node), indent + 1)
        return out

    if kind == NK_SLICE():
        out = out ++ self.dump_typed_expr_tree(self.ast.get_data0(node), indent + 1)
        out = out ++ self.dump_typed_expr_tree(self.ast.get_data1(node), indent + 1)
        out = out ++ self.dump_typed_expr_tree(self.ast.get_data2(node), indent + 1)
        return out

    if kind == NK_BLOCK():
        let extra_start = self.ast.get_data0(node)
        let stmt_count = self.ast.get_data1(node)
        let tail = self.ast.get_data2(node)
        for si in 0..stmt_count:
            out = out ++ self.dump_typed_expr_tree(self.ast.get_extra(extra_start + si), indent + 1)
        out = out ++ self.dump_typed_expr_tree(tail, indent + 1)
        return out

    if kind == NK_IF_EXPR():
        out = out ++ self.dump_typed_expr_tree(self.ast.get_data0(node), indent + 1)
        out = out ++ self.dump_typed_expr_tree(self.ast.get_data1(node), indent + 1)
        out = out ++ self.dump_typed_expr_tree(self.ast.get_data2(node), indent + 1)
        return out

    if kind == NK_RETURN():
        out = out ++ self.dump_typed_expr_tree(self.ast.get_data0(node), indent + 1)
        return out

    if kind == NK_LET_BINDING():
        out = out ++ self.dump_typed_expr_tree(self.ast.get_data1(node), indent + 1)
        return out

    if kind == NK_LET_ELSE():
        out = out ++ self.dump_typed_expr_tree(self.ast.get_data1(node), indent + 1)
        out = out ++ self.dump_typed_expr_tree(self.ast.get_data2(node), indent + 1)
        return out

    if kind == NK_TUPLE_DESTRUCTURE():
        out = out ++ self.dump_typed_expr_tree(self.ast.get_data2(node), indent + 1)
        return out

    if kind == NK_ASSIGN():
        out = out ++ self.dump_typed_expr_tree(self.ast.get_data0(node), indent + 1)
        out = out ++ self.dump_typed_expr_tree(self.ast.get_data1(node), indent + 1)
        return out

    if kind == NK_TUPLE():
        let extra_start = self.ast.get_data0(node)
        let count = self.ast.get_data1(node)
        for i in 0..count:
            out = out ++ self.dump_typed_expr_tree(self.ast.get_extra(extra_start + i), indent + 1)
        return out

    if kind == NK_RANGE():
        out = out ++ self.dump_typed_expr_tree(self.ast.get_data0(node), indent + 1)
        out = out ++ self.dump_typed_expr_tree(self.ast.get_data1(node), indent + 1)
        return out

    if kind == NK_VARIANT_SHORTHAND():
        let extra_start = self.ast.get_data1(node)
        let arg_count = self.ast.get_data2(node)
        for i in 0..arg_count:
            out = out ++ self.dump_typed_expr_tree(self.ast.get_extra(extra_start + i), indent + 1)
        return out

    if kind == NK_AWAIT() or kind == NK_ASYNC_BLOCK() or kind == NK_SPAWN() or kind == NK_GROUPED() or kind == NK_DEFER() or kind == NK_YIELD() or kind == NK_COMPTIME():
        out = out ++ self.dump_typed_expr_tree(self.ast.get_data0(node), indent + 1)
        return out

    if kind == NK_PIPELINE():
        out = out ++ self.dump_typed_expr_tree(self.ast.get_data0(node), indent + 1)
        out = out ++ self.dump_typed_expr_tree(self.ast.get_data1(node), indent + 1)
        return out

    if kind == NK_WHILE():
        out = out ++ self.dump_typed_expr_tree(self.ast.get_data0(node), indent + 1)
        out = out ++ self.dump_typed_expr_tree(self.ast.get_data1(node), indent + 1)
        return out

    if kind == NK_LOOP():
        out = out ++ self.dump_typed_expr_tree(self.ast.get_data0(node), indent + 1)
        return out

    if kind == NK_FOR():
        out = out ++ self.dump_typed_expr_tree(self.ast.get_data1(node), indent + 1)
        out = out ++ self.dump_typed_expr_tree(self.ast.get_data2(node), indent + 1)
        return out

    if kind == NK_BREAK():
        out = out ++ self.dump_typed_expr_tree(self.ast.get_data0(node), indent + 1)
        return out

    if kind == NK_ARRAY_LIT():
        let extra_start = self.ast.get_data0(node)
        let count = self.ast.get_data1(node)
        for i in 0..count:
            out = out ++ self.dump_typed_expr_tree(self.ast.get_extra(extra_start + i), indent + 1)
        return out

    if kind == NK_ARRAY_COMPREHENSION():
        out = out ++ self.dump_typed_expr_tree(self.ast.get_data0(node), indent + 1)
        out = out ++ self.dump_typed_expr_tree(self.ast.get_data2(node), indent + 1)
        return out

    if kind == NK_STRUCT_LIT():
        let extra_start = self.ast.get_data1(node)
        let field_count = self.ast.get_data2(node)
        for i in 0..field_count:
            out = out ++ self.dump_typed_expr_tree(self.ast.get_extra(extra_start + i * 2 + 1), indent + 1)
        return out

    if kind == NK_MATCH():
        let extra_start = self.ast.get_data1(node)
        let arm_count = self.ast.get_data2(node)
        out = out ++ self.dump_typed_expr_tree(self.ast.get_data0(node), indent + 1)
        for i in 0..arm_count:
            let arm = self.ast.get_extra(extra_start + i)
            let guard = self.ast.get_data2(arm)
            if guard != 0:
                out = out ++ self.dump_typed_expr_tree(guard, indent + 1)
            out = out ++ self.dump_typed_expr_tree(self.ast.get_data1(arm), indent + 1)
        return out

    if kind == NK_ENUM_VARIANT():
        let extra_start = self.ast.get_data2(node)
        let arg_count = self.ast.get_extra(extra_start)
        for i in 0..arg_count:
            out = out ++ self.dump_typed_expr_tree(self.ast.get_extra(extra_start + 1 + i), indent + 1)
        return out

    if kind == NK_CLOSURE():
        out = out ++ self.dump_typed_expr_tree(self.ast.get_data0(node), indent + 1)
        return out

    if kind == NK_CAST():
        out = out ++ self.dump_typed_expr_tree(self.ast.get_data0(node), indent + 1)
        return out

    if kind == NK_WITH_EXPR():
        out = out ++ self.dump_typed_expr_tree(self.ast.get_data0(node), indent + 1)
        out = out ++ self.dump_typed_expr_tree(self.ast.get_data1(node), indent + 1)
        return out

    if kind == NK_RECORD_UPDATE():
        let extra_start = self.ast.get_data1(node)
        let field_count = self.ast.get_data2(node)
        out = out ++ self.dump_typed_expr_tree(self.ast.get_data0(node), indent + 1)
        for i in 0..field_count:
            out = out ++ self.dump_typed_expr_tree(self.ast.get_extra(extra_start + i * 2 + 1), indent + 1)
        return out

    if kind == NK_ASYNC_SCOPE():
        out = out ++ self.dump_typed_expr_tree(self.ast.get_data1(node), indent + 1)
        return out

    if kind == NK_SELECT_AWAIT():
        let extra_start = self.ast.get_data0(node)
        let arm_count = self.ast.get_data1(node)
        for i in 0..arm_count:
            out = out ++ self.dump_typed_expr_tree(self.ast.get_extra(extra_start + i * 3 + 1), indent + 1)
            out = out ++ self.dump_typed_expr_tree(self.ast.get_extra(extra_start + i * 3 + 2), indent + 1)
        return out

    out

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
    if tk == TY_NEVER():
        return "Never"
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
        if self.get_type_d1(resolved) != 0:
            return "RangeInclusive[T]"
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
    if tk == TY_TRAIT_OBJ():
        // Stage0 parity: dyn trait-object type expressions currently print as <error>.
        return "<error>"
    "<unknown>"
