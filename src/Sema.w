// Sema — Semantic analysis for the With compiler.
//
// Two-pass architecture following the bootstrap Sema.zig:
//   Pass 1: collectDeclarations — register all type & fn signatures
//   Pass 2: checkBodies — type-check all function bodies
//
// The Sema validates names, types, moves, and trait obligations.
// It does NOT modify the AST — it is a pure validation pass.

use Span
use InternPool
use Token
use Lexer
use Ast
use Type
use Traits

// ── Error codes ──────────────────────────────────────────────────────

fn E_UNDECLARED() -> i32: 1
fn E_TYPE_MISMATCH() -> i32: 2
fn E_DUPLICATE() -> i32: 3
fn E_NOT_CALLABLE() -> i32: 4
fn E_ARG_COUNT() -> i32: 5
fn E_NOT_MUTABLE() -> i32: 6
fn E_MOVED() -> i32: 7
fn E_NO_FIELD() -> i32: 8
fn E_NO_METHOD() -> i32: 9
fn E_NOT_INDEXABLE() -> i32: 10
fn E_BREAK_OUTSIDE() -> i32: 11
fn E_CONTINUE_OUTSIDE() -> i32: 12
fn E_RETURN_MISMATCH() -> i32: 13
fn E_INVALID_CAST() -> i32: 14
fn E_GENERIC() -> i32: 15

// ── Sema state ───────────────────────────────────────────────────────

type Sema = {
    pool: AstPool,
    types: TypeTable,
    solver: TraitSolver,
    intern: InternPool,
    source: str,

    // Function signatures: intern(name) string → index in fn_types/fn_ret_types
    fn_names: Vec[str],
    fn_type_ids: Vec[i32],
    fn_ret_types: Vec[i32],
    fn_param_starts: Vec[i32],
    fn_param_counts: Vec[i32],
    fn_params: Vec[i32],
    fn_is_generic: Vec[i32],

    // Method signatures: "Type.method" → fn index
    method_names: Vec[str],
    method_fn_idx: Vec[i32],

    // Variant lookup: variant name → (enum_type_id, variant_idx)
    variant_names: Vec[str],
    variant_enum_types: Vec[i32],
    variant_indices: Vec[i32],

    // Scopes: flat array linked by parent_idx
    scopes: Vec[Scope],
    current_scope_idx: i32,

    // Context during checking
    current_return_type: i32,
    loop_depth: i32,
    in_defer: i32,
    error_count: i32,

    // Diagnostics
    diag_messages: Vec[str],
    diag_spans_start: Vec[i32],
    diag_spans_end: Vec[i32],
    diag_codes: Vec[i32],

    // Node type map: node_idx → TypeId (result of checking each expr)
    node_types: Vec[i32],
}

fn Sema.new(pool: AstPool, source: str, intern: InternPool) -> Sema:
    var s = Sema {
        pool: pool,
        types: TypeTable.new(),
        solver: TraitSolver.new(),
        intern: intern,
        source: source,
        fn_names: Vec.new(),
        fn_type_ids: Vec.new(),
        fn_ret_types: Vec.new(),
        fn_param_starts: Vec.new(),
        fn_param_counts: Vec.new(),
        fn_params: Vec.new(),
        fn_is_generic: Vec.new(),
        method_names: Vec.new(),
        method_fn_idx: Vec.new(),
        variant_names: Vec.new(),
        variant_enum_types: Vec.new(),
        variant_indices: Vec.new(),
        scopes: Vec.new(),
        current_scope_idx: -1,
        current_return_type: TYPE_VOID(),
        loop_depth: 0,
        in_defer: 0,
        error_count: 0,
        diag_messages: Vec.new(),
        diag_spans_start: Vec.new(),
        diag_spans_end: Vec.new(),
        diag_codes: Vec.new(),
        node_types: Vec.new(),
    }
    // Pre-allocate node_types for all nodes
    let nc = AstPool.node_count(s.pool)
    var i = 0
    while i < nc:
        s.node_types.push(TYPE_ERROR())
        i = i + 1
    // Push root scope
    Sema.push_scope(s)
    s

// ── Diagnostics ──────────────────────────────────────────────────────

fn Sema.emit_error(self: Sema, code: i32, msg: str, start: i32, end: i32) -> void:
    self.diag_messages.push(msg)
    self.diag_spans_start.push(start)
    self.diag_spans_end.push(end)
    self.diag_codes.push(code)
    self.error_count = self.error_count + 1

fn Sema.diag_count(self: Sema) -> i32:
    self.diag_messages.len() as i32

fn Sema.get_diag(self: Sema, idx: i32) -> str:
    self.diag_messages.get(idx as i64)

// ── Scope management ─────────────────────────────────────────────────

fn Sema.push_scope(self: Sema) -> void:
    let sc = Scope.new(self.current_scope_idx)
    self.scopes.push(sc)
    self.current_scope_idx = (self.scopes.len() as i32) - 1

fn Sema.pop_scope(self: Sema) -> void:
    if self.current_scope_idx >= 0:
        let sc = self.scopes.get(self.current_scope_idx as i64)
        self.current_scope_idx = sc.parent_idx

// Add a variable to the current scope.
fn Sema.define_var(self: Sema, name: str, type_id: i32, is_mut: i32) -> void:
    if self.current_scope_idx < 0:
        return
    let sc = self.scopes.get(self.current_scope_idx as i64)
    sc.vars.insert(name, type_id * 4 + is_mut * 2 + VS_LIVE())

// Look up a variable through the scope chain. Returns encoded value or -1.
fn Sema.lookup_var(self: Sema, name: str) -> i32:
    var idx = self.current_scope_idx
    while idx >= 0:
        let sc = self.scopes.get(idx as i64)
        let result = sc.vars.get(name)
        if result.is_some():
            return result.unwrap()
        idx = sc.parent_idx
    -1

// Decode var info from encoded i32: type_id = val / 4, is_mut = (val / 2) % 2, state = val % 2
fn var_type_id(encoded: i32) -> i32:
    encoded / 4

fn var_is_mut(encoded: i32) -> i32:
    (encoded / 2) % 2

fn var_state(encoded: i32) -> i32:
    encoded % 2

// ── Function signature lookup ────────────────────────────────────────

fn Sema.find_fn(self: Sema, name: str) -> i32:
    let count = self.fn_names.len() as i32
    var i = 0
    while i < count:
        if self.fn_names.get(i as i64) == name:
            return i
        i = i + 1
    -1

fn Sema.find_method(self: Sema, full_name: str) -> i32:
    let count = self.method_names.len() as i32
    var i = 0
    while i < count:
        if self.method_names.get(i as i64) == full_name:
            return i
        i = i + 1
    -1

// ── Variant lookup ───────────────────────────────────────────────────

fn Sema.find_variant(self: Sema, name: str) -> i32:
    let count = self.variant_names.len() as i32
    var i = 0
    while i < count:
        if self.variant_names.get(i as i64) == name:
            return i
        i = i + 1
    -1

// ── Main entry point ─────────────────────────────────────────────────

fn Sema.check_module(self: Sema) -> void:
    Sema.collect_declarations(self)
    Sema.check_bodies(self)

// ── Pass 1: Collect declarations ─────────────────────────────────────

fn Sema.collect_declarations(self: Sema) -> void:
    let decl_count = AstPool.decl_count(self.pool)
    var i = 0
    while i < decl_count:
        let decl = AstPool.get_decl(self.pool, i)
        let kind = AstPool.kind(self.pool, decl)
        if kind == NK_FN_DECL():
            Sema.collect_fn_decl(self, decl)
        if kind == NK_TYPE_DECL():
            Sema.collect_type_decl(self, decl)
        if kind == NK_USE_DECL():
            Sema.collect_use_decl(self, decl)
        if kind == NK_EXTERN_FN():
            Sema.collect_extern_fn(self, decl)
        if kind == NK_TRAIT_DECL():
            Sema.collect_trait_decl(self, decl)
        if kind == NK_IMPL_DECL():
            Sema.collect_impl_decl(self, decl)
        i = i + 1

fn Sema.collect_fn_decl(self: Sema, node: i32) -> void:
    let name_str_idx = AstPool.get_data0(self.pool, node)
    let name = AstPool.get_string(self.pool, name_str_idx)
    let extra_start = AstPool.get_data2(self.pool, node)
    let param_count = AstPool.get_extra(self.pool, extra_start)
    let flags = AstPool.get_extra(self.pool, extra_start + 1)
    let ret_type_node = AstPool.get_extra(self.pool, extra_start + 2)
    // Resolve return type
    var ret_type = TYPE_VOID()
    if ret_type_node > 0:
        ret_type = Sema.resolve_type_node(self, ret_type_node)
    // Resolve parameter types
    let param_start = self.fn_params.len() as i32
    var pi = 0
    while pi < param_count:
        let p_name_idx = AstPool.get_extra(self.pool, extra_start + 3 + pi * 2)
        let p_type_node = AstPool.get_extra(self.pool, extra_start + 3 + pi * 2 + 1)
        var p_type = TYPE_ERROR()
        if p_type_node > 0:
            p_type = Sema.resolve_type_node(self, p_type_node)
        self.fn_params.push(p_type)
        pi = pi + 1
    // Build fn type
    var ptypes = Vec.new()
    var fi = 0
    while fi < param_count:
        ptypes.push(self.fn_params.get((param_start + fi) as i64))
        fi = fi + 1
    let fn_type = TypeTable.add_fn(self.types, ptypes, ret_type, 0)
    // Check generic flag
    let is_generic = if (flags / FN_FLAG_COMPTIME()) % 2 == 1 then 1 else 0
    // Register fn
    let fn_idx = self.fn_names.len() as i32
    self.fn_names.push(name)
    self.fn_type_ids.push(fn_type)
    self.fn_ret_types.push(ret_type)
    self.fn_param_starts.push(param_start)
    self.fn_param_counts.push(param_count)
    self.fn_is_generic.push(is_generic)

fn Sema.collect_type_decl(self: Sema, node: i32) -> void:
    let name_str_idx = AstPool.get_data0(self.pool, node)
    let name = AstPool.get_string(self.pool, name_str_idx)
    let flags = AstPool.get_data2(self.pool, node)
    let sub_kind = (flags % 256) / 2
    let field_count = flags / 256
    if sub_kind == TDK_STRUCT():
        Sema.collect_struct_type(self, node, name, name_str_idx, field_count)
        return
    if sub_kind == TDK_ENUM():
        Sema.collect_enum_type(self, node, name, name_str_idx, field_count)
        return
    if sub_kind == TDK_ALIAS():
        let extra_start = AstPool.get_data1(self.pool, node)
        let target_node = AstPool.get_extra(self.pool, extra_start)
        var target_type = TYPE_ERROR()
        if target_node > 0:
            target_type = Sema.resolve_type_node(self, target_node)
        let tid = TypeTable.add_alias(self.types, name_str_idx, target_type)
        TypeTable.register_name(self.types, name, tid)
        return

fn Sema.collect_struct_type(self: Sema, node: i32, name: str, name_sym: i32, field_count: i32) -> void:
    let extra_start = AstPool.get_data1(self.pool, node)
    var fnames = Vec.new()
    var ftypes = Vec.new()
    var fdefs = Vec.new()
    var i = 0
    while i < field_count:
        let base = extra_start + 1 + i * 3
        let f_name = AstPool.get_extra(self.pool, base)
        let f_type_node = AstPool.get_extra(self.pool, base + 1)
        let f_has_def = AstPool.get_extra(self.pool, base + 2)
        fnames.push(f_name)
        var ft = TYPE_ERROR()
        if f_type_node > 0:
            ft = Sema.resolve_type_node(self, f_type_node)
        ftypes.push(ft)
        fdefs.push(f_has_def)
        i = i + 1
    let tid = TypeTable.add_struct(self.types, name_sym, fnames, ftypes, fdefs)
    TypeTable.register_name(self.types, name, tid)

fn Sema.collect_enum_type(self: Sema, node: i32, name: str, name_sym: i32, variant_count: i32) -> void:
    let extra_start = AstPool.get_data1(self.pool, node)
    var vnames = Vec.new()
    var vpayloads = Vec.new()
    var vptypes = Vec.new()
    // Walk the extra data for enum variants
    var pos = extra_start + 1
    var vi = 0
    while vi < variant_count:
        let v_name = AstPool.get_extra(self.pool, pos)
        pos = pos + 1
        let v_payload_count = AstPool.get_extra(self.pool, pos)
        pos = pos + 1
        vnames.push(v_name)
        vpayloads.push(v_payload_count)
        var pi = 0
        while pi < v_payload_count:
            let pt_node = AstPool.get_extra(self.pool, pos)
            pos = pos + 1
            var pt = TYPE_ERROR()
            if pt_node > 0:
                pt = Sema.resolve_type_node(self, pt_node)
            vptypes.push(pt)
            pi = pi + 1
        vi = vi + 1
    let tid = TypeTable.add_enum(self.types, name_sym, vnames, vpayloads, vptypes)
    TypeTable.register_name(self.types, name, tid)
    // Register variant lookup
    var i = 0
    while i < variant_count:
        let v_name_sym = vnames.get(i as i64)
        let v_name = AstPool.get_string(self.pool, v_name_sym)
        self.variant_names.push(v_name)
        self.variant_enum_types.push(tid)
        self.variant_indices.push(i)
        i = i + 1

fn Sema.collect_use_decl(self: Sema, node: i32) -> void:
    // Use declarations are resolved during import processing.
    // Nothing to do here in sema.
    0

fn Sema.collect_extern_fn(self: Sema, node: i32) -> void:
    // External function declarations.
    let name_str_idx = AstPool.get_data0(self.pool, node)
    let name = AstPool.get_string(self.pool, name_str_idx)
    // For now, register with void return type.
    let fn_idx = self.fn_names.len() as i32
    self.fn_names.push(name)
    self.fn_type_ids.push(TYPE_VOID())
    self.fn_ret_types.push(TYPE_VOID())
    self.fn_param_starts.push(0)
    self.fn_param_counts.push(0)
    self.fn_is_generic.push(0)

fn Sema.collect_trait_decl(self: Sema, node: i32) -> void:
    let name_str_idx = AstPool.get_data0(self.pool, node)
    let name = AstPool.get_string(self.pool, name_str_idx)
    // Trait declarations register the trait name and its methods.
    // Method details come from the extra data.
    // For now, just register the trait name.
    var mnames = Vec.new()
    var mparams = Vec.new()
    var mrets = Vec.new()
    TraitSolver.add_trait(self.solver, name_str_idx, mnames, mparams, mrets)

fn Sema.collect_impl_decl(self: Sema, node: i32) -> void:
    // Impl blocks register methods for the implementing type.
    // For now, we handle this as collecting methods.
    0

// ── Type resolution ──────────────────────────────────────────────────

// Resolve a type expression AST node to a TypeId.
fn Sema.resolve_type_node(self: Sema, node: i32) -> i32:
    if node <= 0:
        return TYPE_ERROR()
    let kind = AstPool.kind(self.pool, node)
    if kind == NK_TYPE_NAMED():
        let name_sym = AstPool.get_data0(self.pool, node)
        let name = AstPool.get_string(self.pool, name_sym)
        let tid = TypeTable.lookup(self.types, name)
        if tid >= 0:
            return tid
        // Unknown type name
        Sema.emit_error(self, E_UNDECLARED(), "unknown type: " ++ name, AstPool.get_start(self.pool, node), AstPool.get_end(self.pool, node))
        return TYPE_ERROR()
    if kind == NK_TYPE_REF():
        let inner_node = AstPool.get_data0(self.pool, node)
        let is_mut = AstPool.get_data1(self.pool, node)
        let inner = Sema.resolve_type_node(self, inner_node)
        return TypeTable.add_ref(self.types, inner, is_mut)
    if kind == NK_TYPE_PTR():
        let inner_node = AstPool.get_data0(self.pool, node)
        let is_mut = AstPool.get_data1(self.pool, node)
        let inner = Sema.resolve_type_node(self, inner_node)
        return TypeTable.add_ptr(self.types, inner, is_mut)
    if kind == NK_TYPE_OPTIONAL():
        let inner_node = AstPool.get_data0(self.pool, node)
        let inner = Sema.resolve_type_node(self, inner_node)
        return TypeTable.add_option(self.types, inner)
    if kind == NK_TYPE_ARRAY():
        let elem_node = AstPool.get_data0(self.pool, node)
        let size = AstPool.get_data1(self.pool, node)
        let elem = Sema.resolve_type_node(self, elem_node)
        return TypeTable.add_array(self.types, elem, size)
    if kind == NK_TYPE_SLICE():
        let elem_node = AstPool.get_data0(self.pool, node)
        let elem = Sema.resolve_type_node(self, elem_node)
        return TypeTable.add_slice(self.types, elem)
    if kind == NK_TYPE_TUPLE():
        let extra_start = AstPool.get_data0(self.pool, node)
        let count = AstPool.get_data1(self.pool, node)
        var elems = Vec.new()
        var i = 0
        while i < count:
            let e_node = AstPool.get_extra(self.pool, extra_start + i)
            elems.push(Sema.resolve_type_node(self, e_node))
            i = i + 1
        return TypeTable.add_tuple(self.types, elems)
    if kind == NK_TYPE_FN():
        let extra_start = AstPool.get_data0(self.pool, node)
        let param_count = AstPool.get_data1(self.pool, node)
        let ret_node = AstPool.get_data2(self.pool, node)
        var params = Vec.new()
        var i = 0
        while i < param_count:
            let p_node = AstPool.get_extra(self.pool, extra_start + i)
            params.push(Sema.resolve_type_node(self, p_node))
            i = i + 1
        let ret = Sema.resolve_type_node(self, ret_node)
        return TypeTable.add_fn(self.types, params, ret, 0)
    if kind == NK_TYPE_TRAIT_OBJ():
        let name_sym = AstPool.get_data0(self.pool, node)
        return TypeTable.add_trait_obj(self.types, name_sym)
    if kind == NK_TYPE_GENERIC():
        let base_node = AstPool.get_data0(self.pool, node)
        // For generic types like Option[T], Vec[T], etc.
        // Resolve the base type and parameters.
        let base_name_sym = AstPool.get_data0(self.pool, base_node)
        let base_name = AstPool.get_string(self.pool, base_name_sym)
        let type_arg_node = AstPool.get_data1(self.pool, node)
        let arg_type = Sema.resolve_type_node(self, type_arg_node)
        if base_name == "Option":
            return TypeTable.add_option(self.types, arg_type)
        if base_name == "Result":
            let arg2_node = AstPool.get_data2(self.pool, node)
            let arg2_type = Sema.resolve_type_node(self, arg2_node)
            return TypeTable.add_result(self.types, arg_type, arg2_type)
        // For Vec, HashMap, etc. - return the base type for now
        let tid = TypeTable.lookup(self.types, base_name)
        if tid >= 0:
            return tid
        return TYPE_ERROR()
    if kind == NK_TYPE_INFERRED():
        return TYPE_ERROR()
    TYPE_ERROR()

// ── Pass 2: Check bodies ─────────────────────────────────────────────

fn Sema.check_bodies(self: Sema) -> void:
    let decl_count = AstPool.decl_count(self.pool)
    var i = 0
    while i < decl_count:
        let decl = AstPool.get_decl(self.pool, i)
        let kind = AstPool.kind(self.pool, decl)
        if kind == NK_FN_DECL():
            Sema.check_fn_body(self, decl)
        i = i + 1

fn Sema.check_fn_body(self: Sema, node: i32) -> void:
    let name_str_idx = AstPool.get_data0(self.pool, node)
    let name = AstPool.get_string(self.pool, name_str_idx)
    let body = AstPool.get_data1(self.pool, node)
    if body <= 0:
        return
    // Find fn signature
    let fn_idx = Sema.find_fn(self, name)
    if fn_idx < 0:
        return
    // Save context
    let saved_ret = self.current_return_type
    let saved_loop = self.loop_depth
    self.current_return_type = self.fn_ret_types.get(fn_idx as i64)
    self.loop_depth = 0
    // Push function scope
    Sema.push_scope(self)
    // Add parameters to scope
    let extra_start = AstPool.get_data2(self.pool, node)
    let param_count = AstPool.get_extra(self.pool, extra_start)
    let param_start_idx = self.fn_param_starts.get(fn_idx as i64)
    var pi = 0
    while pi < param_count:
        let p_name_idx = AstPool.get_extra(self.pool, extra_start + 3 + pi * 2)
        let p_name = AstPool.get_string(self.pool, p_name_idx)
        let p_type = self.fn_params.get((param_start_idx + pi) as i64)
        Sema.define_var(self, p_name, p_type, 0)
        pi = pi + 1
    // Check body expression
    let body_type = Sema.check_expr(self, body)
    // Validate return type
    if self.current_return_type != TYPE_VOID():
        if body_type != TYPE_ERROR():
            if body_type != self.current_return_type:
                if not Sema.types_compatible(self, self.current_return_type, body_type):
                    Sema.emit_error(self, E_RETURN_MISMATCH(), "return type mismatch in " ++ name, AstPool.get_start(self.pool, body), AstPool.get_end(self.pool, body))
    // Pop scope and restore context
    Sema.pop_scope(self)
    self.current_return_type = saved_ret
    self.loop_depth = saved_loop

// ── Expression type checking ─────────────────────────────────────────

fn Sema.check_expr(self: Sema, node: i32) -> i32:
    if node <= 0:
        return TYPE_ERROR()
    let kind = AstPool.kind(self.pool, node)
    // Literals
    if kind == NK_INT_LIT():
        return Sema.set_type(self, node, TYPE_I32())
    if kind == NK_FLOAT_LIT():
        return Sema.set_type(self, node, TYPE_F64())
    if kind == NK_BOOL_LIT():
        return Sema.set_type(self, node, TYPE_BOOL())
    if kind == NK_STRING_LIT():
        return Sema.set_type(self, node, TYPE_STR())
    if kind == NK_C_STRING_LIT():
        let ptr_type = TypeTable.add_ptr(self.types, TYPE_U8(), 0)
        return Sema.set_type(self, node, ptr_type)
    // Identifier
    if kind == NK_IDENT():
        return Sema.check_ident(self, node)
    // Binary expression
    if kind == NK_BINARY():
        return Sema.check_binary(self, node)
    // Unary expression
    if kind == NK_UNARY():
        return Sema.check_unary(self, node)
    // Call expression
    if kind == NK_CALL():
        return Sema.check_call(self, node)
    // Field access
    if kind == NK_FIELD_ACCESS():
        return Sema.check_field_access(self, node)
    // Index expression
    if kind == NK_INDEX():
        return Sema.check_index(self, node)
    // Block
    if kind == NK_BLOCK():
        return Sema.check_block(self, node)
    // If expression
    if kind == NK_IF_EXPR():
        return Sema.check_if_expr(self, node)
    // While loop
    if kind == NK_WHILE():
        return Sema.check_while(self, node)
    // Loop
    if kind == NK_LOOP():
        return Sema.check_loop(self, node)
    // For loop
    if kind == NK_FOR():
        return Sema.check_for(self, node)
    // Return
    if kind == NK_RETURN():
        return Sema.check_return(self, node)
    // Break
    if kind == NK_BREAK():
        return Sema.check_break(self, node)
    // Continue
    if kind == NK_CONTINUE():
        return Sema.check_continue(self, node)
    // Let binding
    if kind == NK_LET_BINDING():
        return Sema.check_let_binding(self, node)
    // Assign
    if kind == NK_ASSIGN():
        return Sema.check_assign(self, node)
    // Match
    if kind == NK_MATCH():
        return Sema.check_match(self, node)
    // Tuple
    if kind == NK_TUPLE():
        return Sema.check_tuple(self, node)
    // Array literal
    if kind == NK_ARRAY_LIT():
        return Sema.check_array_lit(self, node)
    // Struct literal
    if kind == NK_STRUCT_LIT():
        return Sema.check_struct_lit(self, node)
    // Cast
    if kind == NK_CAST():
        return Sema.check_cast(self, node)
    // Defer
    if kind == NK_DEFER():
        let inner = AstPool.get_data0(self.pool, node)
        let saved = self.in_defer
        self.in_defer = 1
        let t = Sema.check_expr(self, inner)
        self.in_defer = saved
        return Sema.set_type(self, node, TYPE_VOID())
    // Range
    if kind == NK_RANGE():
        let lhs = AstPool.get_data0(self.pool, node)
        let rhs = AstPool.get_data1(self.pool, node)
        let lt = Sema.check_expr(self, lhs)
        let rt = Sema.check_expr(self, rhs)
        let inclusive = AstPool.get_data2(self.pool, node)
        let range_t = TypeTable.add_range(self.types, lt, inclusive)
        return Sema.set_type(self, node, range_t)
    // Pipeline
    if kind == NK_PIPELINE():
        return Sema.check_pipeline(self, node)
    // Grouped expression
    if kind == NK_GROUPED():
        let inner = AstPool.get_data0(self.pool, node)
        return Sema.check_expr(self, inner)
    // Closure
    if kind == NK_CLOSURE():
        return Sema.check_closure(self, node)
    // With expression
    if kind == NK_WITH_EXPR():
        return Sema.check_with_expr(self, node)
    // Record update
    if kind == NK_RECORD_UPDATE():
        return Sema.check_record_update(self, node)
    // Slice
    if kind == NK_SLICE():
        return Sema.check_slice(self, node)
    // Poisoned
    if kind == NK_POISONED_EXPR():
        return TYPE_ERROR()
    // Default: return error type
    TYPE_ERROR()

fn Sema.set_type(self: Sema, node: i32, type_id: i32) -> i32:
    // Expand node_types if needed
    while (self.node_types.len() as i32) <= node:
        self.node_types.push(TYPE_ERROR())
    // We can't set, but we track the type by node ordering.
    // Since Vec has no set(), we store the association externally.
    // For now, just return the type_id.
    type_id

// ── Individual expression checkers ───────────────────────────────────

fn Sema.check_ident(self: Sema, node: i32) -> i32:
    let name_sym = AstPool.get_data0(self.pool, node)
    let name = AstPool.get_string(self.pool, name_sym)
    // 1. Check local scope
    let var_info = Sema.lookup_var(self, name)
    if var_info >= 0:
        return var_type_id(var_info)
    // 2. Check function names
    let fn_idx = Sema.find_fn(self, name)
    if fn_idx >= 0:
        return self.fn_type_ids.get(fn_idx as i64)
    // 3. Check enum variants
    let v_idx = Sema.find_variant(self, name)
    if v_idx >= 0:
        return self.variant_enum_types.get(v_idx as i64)
    // 4. Check builtin values
    if name == "None":
        return TYPE_ERROR()
    if name == "true":
        return TYPE_BOOL()
    if name == "false":
        return TYPE_BOOL()
    // 5. Unknown
    Sema.emit_error(self, E_UNDECLARED(), "undeclared identifier: " ++ name, AstPool.get_start(self.pool, node), AstPool.get_end(self.pool, node))
    TYPE_ERROR()

fn Sema.check_binary(self: Sema, node: i32) -> i32:
    let lhs = AstPool.get_data0(self.pool, node)
    let rhs = AstPool.get_data1(self.pool, node)
    let op = AstPool.get_data2(self.pool, node)
    let lt = Sema.check_expr(self, lhs)
    let rt = Sema.check_expr(self, rhs)
    // Comparison operators return bool
    if op == OP_EQ():
        return Sema.set_type(self, node, TYPE_BOOL())
    if op == OP_NEQ():
        return Sema.set_type(self, node, TYPE_BOOL())
    if op == OP_LT():
        return Sema.set_type(self, node, TYPE_BOOL())
    if op == OP_GT():
        return Sema.set_type(self, node, TYPE_BOOL())
    if op == OP_LTE():
        return Sema.set_type(self, node, TYPE_BOOL())
    if op == OP_GTE():
        return Sema.set_type(self, node, TYPE_BOOL())
    // Logical operators return bool
    if op == OP_AND():
        return Sema.set_type(self, node, TYPE_BOOL())
    if op == OP_OR():
        return Sema.set_type(self, node, TYPE_BOOL())
    // Concat returns str
    if op == OP_CONCAT():
        return Sema.set_type(self, node, TYPE_STR())
    // Default operator returns the payload type
    if op == OP_DEFAULT():
        if TypeTable.is_option(self.types, lt):
            return Sema.set_type(self, node, TypeTable.option_payload(self.types, lt))
        if TypeTable.is_result(self.types, lt):
            return Sema.set_type(self, node, TypeTable.result_ok_type(self.types, lt))
        return Sema.set_type(self, node, lt)
    // Arithmetic returns the left type (or promotion)
    if lt == TYPE_ERROR():
        return Sema.set_type(self, node, rt)
    Sema.set_type(self, node, lt)

fn Sema.check_unary(self: Sema, node: i32) -> i32:
    let operand = AstPool.get_data0(self.pool, node)
    let op = AstPool.get_data1(self.pool, node)
    let ot = Sema.check_expr(self, operand)
    if op == UOP_NEGATE():
        return Sema.set_type(self, node, ot)
    if op == UOP_NOT():
        return Sema.set_type(self, node, TYPE_BOOL())
    if op == UOP_REF():
        let ref_t = TypeTable.add_ref(self.types, ot, 0)
        return Sema.set_type(self, node, ref_t)
    if op == UOP_MUT_REF():
        let ref_t = TypeTable.add_ref(self.types, ot, 1)
        return Sema.set_type(self, node, ref_t)
    if op == UOP_DEREF():
        if TypeTable.is_ptr(self.types, ot):
            return Sema.set_type(self, node, TypeTable.pointee_type(self.types, ot))
        if TypeTable.is_ref(self.types, ot):
            return Sema.set_type(self, node, TypeTable.pointee_type(self.types, ot))
        return Sema.set_type(self, node, TYPE_ERROR())
    if op == UOP_TRY():
        if TypeTable.is_option(self.types, ot):
            return Sema.set_type(self, node, TypeTable.option_payload(self.types, ot))
        if TypeTable.is_result(self.types, ot):
            return Sema.set_type(self, node, TypeTable.result_ok_type(self.types, ot))
        return Sema.set_type(self, node, TYPE_ERROR())
    TYPE_ERROR()

fn Sema.check_call(self: Sema, node: i32) -> i32:
    let callee = AstPool.get_data0(self.pool, node)
    let extra_start = AstPool.get_data1(self.pool, node)
    let arg_count = AstPool.get_data2(self.pool, node)
    // Check all arguments
    var i = 0
    while i < arg_count:
        let arg_node = AstPool.get_extra(self.pool, extra_start + i)
        Sema.check_expr(self, arg_node)
        i = i + 1
    // Resolve callee
    if callee <= 0:
        return TYPE_ERROR()
    let callee_kind = AstPool.kind(self.pool, callee)
    // Direct function call
    if callee_kind == NK_IDENT():
        let name_sym = AstPool.get_data0(self.pool, callee)
        let name = AstPool.get_string(self.pool, name_sym)
        // Check builtins
        if name == "println":
            return Sema.set_type(self, node, TYPE_VOID())
        if name == "print":
            return Sema.set_type(self, node, TYPE_VOID())
        if name == "assert":
            return Sema.set_type(self, node, TYPE_VOID())
        if name == "Some":
            if arg_count == 1:
                let arg_node = AstPool.get_extra(self.pool, extra_start)
                let at = Sema.check_expr(self, arg_node)
                let opt_t = TypeTable.add_option(self.types, at)
                return Sema.set_type(self, node, opt_t)
            return TYPE_ERROR()
        if name == "Ok":
            if arg_count == 1:
                let arg_node = AstPool.get_extra(self.pool, extra_start)
                let at = Sema.check_expr(self, arg_node)
                let res_t = TypeTable.add_result(self.types, at, TYPE_ERROR())
                return Sema.set_type(self, node, res_t)
            return TYPE_ERROR()
        if name == "Err":
            if arg_count == 1:
                let arg_node = AstPool.get_extra(self.pool, extra_start)
                let at = Sema.check_expr(self, arg_node)
                let res_t = TypeTable.add_result(self.types, TYPE_ERROR(), at)
                return Sema.set_type(self, node, res_t)
            return TYPE_ERROR()
        // Regular function
        let fn_idx = Sema.find_fn(self, name)
        if fn_idx >= 0:
            let ret = self.fn_ret_types.get(fn_idx as i64)
            return Sema.set_type(self, node, ret)
        Sema.emit_error(self, E_NOT_CALLABLE(), "undeclared function: " ++ name, AstPool.get_start(self.pool, callee), AstPool.get_end(self.pool, callee))
        return TYPE_ERROR()
    // Method call: callee is a field_access
    if callee_kind == NK_FIELD_ACCESS():
        return Sema.check_method_call(self, node, callee, extra_start, arg_count)
    // Callee is some other expression (e.g. closure)
    let callee_type = Sema.check_expr(self, callee)
    if TypeTable.is_fn(self.types, callee_type):
        return Sema.set_type(self, node, TypeTable.fn_return_type(self.types, callee_type))
    TYPE_ERROR()

fn Sema.check_method_call(self: Sema, call_node: i32, callee: i32, extra_start: i32, arg_count: i32) -> i32:
    let obj = AstPool.get_data0(self.pool, callee)
    let method_sym = AstPool.get_data1(self.pool, callee)
    let method_name = AstPool.get_string(self.pool, method_sym)
    let obj_type = Sema.check_expr(self, obj)
    // Try to find as Type.method
    if TypeTable.is_struct(self.types, obj_type):
        let struct_name_sym = TypeTable.struct_name(self.types, obj_type)
        let struct_name = AstPool.get_string(self.pool, struct_name_sym)
        let full_name = struct_name ++ "." ++ method_name
        let fn_idx = Sema.find_fn(self, full_name)
        if fn_idx >= 0:
            let ret = self.fn_ret_types.get(fn_idx as i64)
            return Sema.set_type(self, call_node, ret)
    // Try built-in methods for arrays, slices, strings, etc.
    if method_name == "len":
        return Sema.set_type(self, call_node, TYPE_I64())
    if method_name == "push":
        return Sema.set_type(self, call_node, TYPE_VOID())
    if method_name == "get":
        if TypeTable.is_array(self.types, obj_type):
            return Sema.set_type(self, call_node, TypeTable.array_elem_type(self.types, obj_type))
        if TypeTable.is_slice(self.types, obj_type):
            return Sema.set_type(self, call_node, TypeTable.slice_elem_type(self.types, obj_type))
        return Sema.set_type(self, call_node, TYPE_ERROR())
    if method_name == "slice":
        return Sema.set_type(self, call_node, TYPE_STR())
    if method_name == "is_some":
        return Sema.set_type(self, call_node, TYPE_BOOL())
    if method_name == "is_none":
        return Sema.set_type(self, call_node, TYPE_BOOL())
    if method_name == "unwrap":
        if TypeTable.is_option(self.types, obj_type):
            return Sema.set_type(self, call_node, TypeTable.option_payload(self.types, obj_type))
        return Sema.set_type(self, call_node, TYPE_ERROR())
    if method_name == "insert":
        return Sema.set_type(self, call_node, TYPE_VOID())
    if method_name == "contains":
        return Sema.set_type(self, call_node, TYPE_BOOL())
    // Generic method not found
    let fn_idx = Sema.find_fn(self, method_name)
    if fn_idx >= 0:
        let ret = self.fn_ret_types.get(fn_idx as i64)
        return Sema.set_type(self, call_node, ret)
    TYPE_ERROR()

fn Sema.check_field_access(self: Sema, node: i32) -> i32:
    let obj = AstPool.get_data0(self.pool, node)
    let field_sym = AstPool.get_data1(self.pool, node)
    let field_name = AstPool.get_string(self.pool, field_sym)
    let obj_type = Sema.check_expr(self, obj)
    if TypeTable.is_struct(self.types, obj_type):
        let fc = TypeTable.struct_field_count(self.types, obj_type)
        var i = 0
        while i < fc:
            let f_name_sym = TypeTable.struct_field_name(self.types, obj_type, i)
            let f_name = AstPool.get_string(self.pool, f_name_sym)
            if f_name == field_name:
                let ft = TypeTable.struct_field_type(self.types, obj_type, i)
                return Sema.set_type(self, node, ft)
            i = i + 1
        Sema.emit_error(self, E_NO_FIELD(), "no field '" ++ field_name ++ "'", AstPool.get_start(self.pool, node), AstPool.get_end(self.pool, node))
        return TYPE_ERROR()
    if TypeTable.is_tuple(self.types, obj_type):
        // Tuple field access: .0, .1, etc.
        // Parse field name as index
        if field_name == "0":
            return Sema.set_type(self, node, TypeTable.tuple_elem_type(self.types, obj_type, 0))
        if field_name == "1":
            return Sema.set_type(self, node, TypeTable.tuple_elem_type(self.types, obj_type, 1))
        if field_name == "2":
            return Sema.set_type(self, node, TypeTable.tuple_elem_type(self.types, obj_type, 2))
        return TYPE_ERROR()
    // Built-in .len for arrays, slices, strings
    if field_name == "len":
        if TypeTable.is_array(self.types, obj_type):
            return Sema.set_type(self, node, TYPE_I64())
        if TypeTable.is_slice(self.types, obj_type):
            return Sema.set_type(self, node, TYPE_I64())
        if TypeTable.is_str(self.types, obj_type):
            return Sema.set_type(self, node, TYPE_I64())
    TYPE_ERROR()

fn Sema.check_index(self: Sema, node: i32) -> i32:
    let obj = AstPool.get_data0(self.pool, node)
    let idx = AstPool.get_data1(self.pool, node)
    let obj_type = Sema.check_expr(self, obj)
    Sema.check_expr(self, idx)
    if TypeTable.is_array(self.types, obj_type):
        return Sema.set_type(self, node, TypeTable.array_elem_type(self.types, obj_type))
    if TypeTable.is_slice(self.types, obj_type):
        return Sema.set_type(self, node, TypeTable.slice_elem_type(self.types, obj_type))
    if TypeTable.is_str(self.types, obj_type):
        return Sema.set_type(self, node, TYPE_I32())
    Sema.emit_error(self, E_NOT_INDEXABLE(), "type is not indexable", AstPool.get_start(self.pool, node), AstPool.get_end(self.pool, node))
    TYPE_ERROR()

fn Sema.check_block(self: Sema, node: i32) -> i32:
    let extra_start = AstPool.get_data0(self.pool, node)
    let stmt_count = AstPool.get_data1(self.pool, node)
    let tail = AstPool.get_data2(self.pool, node)
    Sema.push_scope(self)
    // Check statements
    var i = 0
    while i < stmt_count:
        let stmt = AstPool.get_extra(self.pool, extra_start + i)
        Sema.check_expr(self, stmt)
        i = i + 1
    // Check tail expression
    var result_type = TYPE_VOID()
    if tail > 0:
        result_type = Sema.check_expr(self, tail)
    Sema.pop_scope(self)
    Sema.set_type(self, node, result_type)

fn Sema.check_if_expr(self: Sema, node: i32) -> i32:
    let cond = AstPool.get_data0(self.pool, node)
    let then_body = AstPool.get_data1(self.pool, node)
    let else_body = AstPool.get_data2(self.pool, node)
    let cond_type = Sema.check_expr(self, cond)
    if cond_type != TYPE_BOOL():
        if cond_type != TYPE_ERROR():
            Sema.emit_error(self, E_TYPE_MISMATCH(), "if condition must be bool", AstPool.get_start(self.pool, cond), AstPool.get_end(self.pool, cond))
    let then_type = Sema.check_expr(self, then_body)
    if else_body > 0:
        let else_type = Sema.check_expr(self, else_body)
        // Unify then/else types
        if then_type == else_type:
            return Sema.set_type(self, node, then_type)
        if then_type == TYPE_NEVER():
            return Sema.set_type(self, node, else_type)
        if else_type == TYPE_NEVER():
            return Sema.set_type(self, node, then_type)
        return Sema.set_type(self, node, then_type)
    Sema.set_type(self, node, TYPE_VOID())

fn Sema.check_while(self: Sema, node: i32) -> i32:
    let cond = AstPool.get_data0(self.pool, node)
    let body = AstPool.get_data1(self.pool, node)
    Sema.check_expr(self, cond)
    self.loop_depth = self.loop_depth + 1
    Sema.check_expr(self, body)
    self.loop_depth = self.loop_depth - 1
    Sema.set_type(self, node, TYPE_VOID())

fn Sema.check_loop(self: Sema, node: i32) -> i32:
    let body = AstPool.get_data0(self.pool, node)
    self.loop_depth = self.loop_depth + 1
    Sema.check_expr(self, body)
    self.loop_depth = self.loop_depth - 1
    Sema.set_type(self, node, TYPE_VOID())

fn Sema.check_for(self: Sema, node: i32) -> i32:
    let iter = AstPool.get_data0(self.pool, node)
    let body = AstPool.get_data1(self.pool, node)
    let binding_sym = AstPool.get_data2(self.pool, node)
    let iter_type = Sema.check_expr(self, iter)
    // Determine element type
    var elem_type = TYPE_ERROR()
    if TypeTable.is_array(self.types, iter_type):
        elem_type = TypeTable.array_elem_type(self.types, iter_type)
    if TypeTable.is_slice(self.types, iter_type):
        elem_type = TypeTable.slice_elem_type(self.types, iter_type)
    if TypeTable.is_range(self.types, iter_type):
        elem_type = TypeTable.range_elem_type(self.types, iter_type)
    // Push scope with binding
    Sema.push_scope(self)
    if binding_sym > 0:
        let binding_name = AstPool.get_string(self.pool, binding_sym)
        Sema.define_var(self, binding_name, elem_type, 0)
    self.loop_depth = self.loop_depth + 1
    Sema.check_expr(self, body)
    self.loop_depth = self.loop_depth - 1
    Sema.pop_scope(self)
    Sema.set_type(self, node, TYPE_VOID())

fn Sema.check_return(self: Sema, node: i32) -> i32:
    if self.in_defer == 1:
        Sema.emit_error(self, E_GENERIC(), "return not allowed in defer", AstPool.get_start(self.pool, node), AstPool.get_end(self.pool, node))
    let value = AstPool.get_data0(self.pool, node)
    if value > 0:
        let vt = Sema.check_expr(self, value)
        if not Sema.types_compatible(self, self.current_return_type, vt):
            if vt != TYPE_ERROR():
                Sema.emit_error(self, E_RETURN_MISMATCH(), "return type mismatch", AstPool.get_start(self.pool, node), AstPool.get_end(self.pool, node))
    Sema.set_type(self, node, TYPE_NEVER())

fn Sema.check_break(self: Sema, node: i32) -> i32:
    if self.loop_depth == 0:
        Sema.emit_error(self, E_BREAK_OUTSIDE(), "break outside loop", AstPool.get_start(self.pool, node), AstPool.get_end(self.pool, node))
    Sema.set_type(self, node, TYPE_NEVER())

fn Sema.check_continue(self: Sema, node: i32) -> i32:
    if self.loop_depth == 0:
        Sema.emit_error(self, E_CONTINUE_OUTSIDE(), "continue outside loop", AstPool.get_start(self.pool, node), AstPool.get_end(self.pool, node))
    Sema.set_type(self, node, TYPE_NEVER())

fn Sema.check_let_binding(self: Sema, node: i32) -> i32:
    let name_sym = AstPool.get_data0(self.pool, node)
    let value = AstPool.get_data1(self.pool, node)
    let type_or_flag = AstPool.get_data2(self.pool, node)
    var type_node = type_or_flag
    var is_mut = 0
    if type_or_flag >= 0x40000000:
        type_node = type_or_flag - 0x40000000
        is_mut = 1
    let name = AstPool.get_string(self.pool, name_sym)
    // Determine type from annotation or value
    var vt = TYPE_ERROR()
    if value > 0:
        vt = Sema.check_expr(self, value)
    if type_node > 0:
        let annotated = Sema.resolve_type_node(self, type_node)
        if vt != TYPE_ERROR():
            if not Sema.types_compatible(self, annotated, vt):
                Sema.emit_error(self, E_TYPE_MISMATCH(), "type mismatch in let binding", AstPool.get_start(self.pool, node), AstPool.get_end(self.pool, node))
        vt = annotated
    // Add to scope (let = immutable, var = mutable via high-bit flag).
    Sema.define_var(self, name, vt, is_mut)
    Sema.set_type(self, node, TYPE_VOID())

fn Sema.check_assign(self: Sema, node: i32) -> i32:
    let target = AstPool.get_data0(self.pool, node)
    let value = AstPool.get_data1(self.pool, node)
    Sema.check_expr(self, target)
    Sema.check_expr(self, value)
    Sema.set_type(self, node, TYPE_VOID())

fn Sema.check_match(self: Sema, node: i32) -> i32:
    let subject = AstPool.get_data0(self.pool, node)
    let extra_start = AstPool.get_data1(self.pool, node)
    let arm_count = AstPool.get_data2(self.pool, node)
    let subj_type = Sema.check_expr(self, subject)
    var result_type = TYPE_ERROR()
    var i = 0
    while i < arm_count:
        let arm_node = AstPool.get_extra(self.pool, extra_start + i)
        if arm_node > 0:
            let arm_kind = AstPool.kind(self.pool, arm_node)
            if arm_kind == NK_MATCH_ARM():
                let pattern = AstPool.get_data0(self.pool, arm_node)
                let body = AstPool.get_data1(self.pool, arm_node)
                // Check pattern (adds bindings if needed)
                Sema.push_scope(self)
                Sema.check_pattern(self, pattern, subj_type)
                let body_type = Sema.check_expr(self, body)
                Sema.pop_scope(self)
                if result_type == TYPE_ERROR():
                    result_type = body_type
        i = i + 1
    Sema.set_type(self, node, result_type)

fn Sema.check_pattern(self: Sema, node: i32, subject_type: i32) -> void:
    if node <= 0:
        return
    let kind = AstPool.kind(self.pool, node)
    if kind == NK_PAT_WILDCARD():
        return
    if kind == NK_PAT_IDENT():
        let name_sym = AstPool.get_data0(self.pool, node)
        let name = AstPool.get_string(self.pool, name_sym)
        Sema.define_var(self, name, subject_type, 0)
        return
    if kind == NK_PAT_INT():
        return
    if kind == NK_PAT_BOOL():
        return
    if kind == NK_PAT_STRING():
        return
    if kind == NK_PAT_VARIANT():
        return
    if kind == NK_PAT_TUPLE():
        return
    if kind == NK_PAT_OR():
        return

fn Sema.check_tuple(self: Sema, node: i32) -> i32:
    let extra_start = AstPool.get_data0(self.pool, node)
    let count = AstPool.get_data1(self.pool, node)
    var elems = Vec.new()
    var i = 0
    while i < count:
        let elem_node = AstPool.get_extra(self.pool, extra_start + i)
        let et = Sema.check_expr(self, elem_node)
        elems.push(et)
        i = i + 1
    let tuple_type = TypeTable.add_tuple(self.types, elems)
    Sema.set_type(self, node, tuple_type)

fn Sema.check_array_lit(self: Sema, node: i32) -> i32:
    let extra_start = AstPool.get_data0(self.pool, node)
    let count = AstPool.get_data1(self.pool, node)
    var elem_type = TYPE_ERROR()
    var i = 0
    while i < count:
        let elem_node = AstPool.get_extra(self.pool, extra_start + i)
        let et = Sema.check_expr(self, elem_node)
        if elem_type == TYPE_ERROR():
            elem_type = et
        i = i + 1
    let arr_type = TypeTable.add_array(self.types, elem_type, count)
    Sema.set_type(self, node, arr_type)

fn Sema.check_struct_lit(self: Sema, node: i32) -> i32:
    let type_name_sym = AstPool.get_data0(self.pool, node)
    let extra_start = AstPool.get_data1(self.pool, node)
    let field_count = AstPool.get_data2(self.pool, node)
    let type_name = AstPool.get_string(self.pool, type_name_sym)
    let struct_type = TypeTable.lookup(self.types, type_name)
    if struct_type < 0:
        Sema.emit_error(self, E_UNDECLARED(), "unknown struct type: " ++ type_name, AstPool.get_start(self.pool, node), AstPool.get_end(self.pool, node))
        return TYPE_ERROR()
    // Check field values
    var i = 0
    while i < field_count:
        let f_name_sym = AstPool.get_extra(self.pool, extra_start + i * 2)
        let f_value = AstPool.get_extra(self.pool, extra_start + i * 2 + 1)
        if f_value > 0:
            Sema.check_expr(self, f_value)
        i = i + 1
    Sema.set_type(self, node, struct_type)

fn Sema.check_cast(self: Sema, node: i32) -> i32:
    let expr = AstPool.get_data0(self.pool, node)
    let target_type_node = AstPool.get_data1(self.pool, node)
    Sema.check_expr(self, expr)
    let target = Sema.resolve_type_node(self, target_type_node)
    Sema.set_type(self, node, target)

fn Sema.check_pipeline(self: Sema, node: i32) -> i32:
    let lhs = AstPool.get_data0(self.pool, node)
    let rhs = AstPool.get_data1(self.pool, node)
    // Pipeline desugars to a call: rhs(lhs)
    Sema.check_expr(self, lhs)
    let rt = Sema.check_expr(self, rhs)
    // Return type depends on the function called
    if TypeTable.is_fn(self.types, rt):
        return Sema.set_type(self, node, TypeTable.fn_return_type(self.types, rt))
    Sema.set_type(self, node, rt)

fn Sema.check_closure(self: Sema, node: i32) -> i32:
    let body = AstPool.get_data0(self.pool, node)
    let extra_start = AstPool.get_data1(self.pool, node)
    let param_count = AstPool.get_data2(self.pool, node)
    Sema.push_scope(self)
    // Add params to scope (types may be inferred)
    var ptypes = Vec.new()
    var i = 0
    while i < param_count:
        let p_name_sym = AstPool.get_extra(self.pool, extra_start + i * 2)
        let p_type_node = AstPool.get_extra(self.pool, extra_start + i * 2 + 1)
        var p_type = TYPE_ERROR()
        if p_type_node > 0:
            p_type = Sema.resolve_type_node(self, p_type_node)
        let p_name = AstPool.get_string(self.pool, p_name_sym)
        Sema.define_var(self, p_name, p_type, 0)
        ptypes.push(p_type)
        i = i + 1
    let body_type = Sema.check_expr(self, body)
    Sema.pop_scope(self)
    let fn_type = TypeTable.add_fn(self.types, ptypes, body_type, 0)
    Sema.set_type(self, node, fn_type)

fn Sema.check_with_expr(self: Sema, node: i32) -> i32:
    let source = AstPool.get_data0(self.pool, node)
    let body = AstPool.get_data1(self.pool, node)
    let binding_sym = AstPool.get_data2(self.pool, node)
    let src_type = Sema.check_expr(self, source)
    Sema.push_scope(self)
    if binding_sym > 0:
        let binding_name = AstPool.get_string(self.pool, binding_sym)
        Sema.define_var(self, binding_name, src_type, 1)
    let body_type = Sema.check_expr(self, body)
    Sema.pop_scope(self)
    Sema.set_type(self, node, body_type)

fn Sema.check_record_update(self: Sema, node: i32) -> i32:
    let source = AstPool.get_data0(self.pool, node)
    let src_type = Sema.check_expr(self, source)
    // Result type is same as source
    Sema.set_type(self, node, src_type)

fn Sema.check_slice(self: Sema, node: i32) -> i32:
    let obj = AstPool.get_data0(self.pool, node)
    let obj_type = Sema.check_expr(self, obj)
    if TypeTable.is_array(self.types, obj_type):
        let elem_t = TypeTable.array_elem_type(self.types, obj_type)
        let slice_t = TypeTable.add_slice(self.types, elem_t)
        return Sema.set_type(self, node, slice_t)
    if TypeTable.is_str(self.types, obj_type):
        return Sema.set_type(self, node, TYPE_STR())
    TYPE_ERROR()

// ── Type compatibility ───────────────────────────────────────────────

fn Sema.types_compatible(self: Sema, expected: i32, actual: i32) -> bool:
    if expected == actual:
        return true
    if expected == TYPE_ERROR():
        return true
    if actual == TYPE_ERROR():
        return true
    if actual == TYPE_NEVER():
        return true
    // Resolve aliases
    let re = TypeTable.resolve_alias(self.types, expected)
    let ra = TypeTable.resolve_alias(self.types, actual)
    if re == ra:
        return true
    // Int widening
    if TypeTable.is_int(self.types, re):
        if TypeTable.is_int(self.types, ra):
            return true
    // Float widening
    if TypeTable.is_float(self.types, re):
        if TypeTable.is_float(self.types, ra):
            return true
    // Numeric coercion for literals
    if TypeTable.is_int(self.types, re):
        if TypeTable.is_float(self.types, ra):
            return false
    TypeTable.types_equal(self.types, re, ra)

fn TypeTable.is_range(self: TypeTable, type_id: i32) -> bool:
    TypeTable.kind(self, type_id) == TK_RANGE()
