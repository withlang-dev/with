// Resolve — Wave 4 module graph + name-resolution scaffolding.
//
// This pass builds deterministic module/import/def/binding/use tables from AST.
// It does not replace Sema yet; it provides a stable resolved artifact for Wave 4.

use Ast
use Lexer
use Parser
use InternPool
use Diagnostic
use Span
use compiler.EmbeddedStdlib

extern fn with_fs_read_file(path: str) -> str
extern fn with_write(s: str) -> void

enum ImportKind: i32:
    IK_USE = 1
    IK_C_IMPORT = 2

enum DefKind: i32:
    DK_FN = 1
    DK_TYPE = 2
    DK_LET = 3
    DK_EXTERN_FN = 4
    DK_TRAIT = 5
    DK_IMPL = 6
    DK_C_IMPORT = 7
    DK_PARAM = 8
    DK_LOCAL = 9

enum ScopeKind: i32:
    SK_MODULE = 1
    SK_FN = 2
    SK_BLOCK = 3
    SK_MATCH_ARM = 4
    SK_LOOP = 5
    SK_CLOSURE = 6
    SK_COMPREHENSION = 7

// Module metadata used by --dump-resolved.
type ResolvedModule {
    module_id: i32,
    file_id: i32,
    path: str,
    import_start: i32,
    import_count: i32,
    decl_count: i32,
}

type ResolvedImport {
    module_id: i32,
    index_in_module: i32,
    kind: i32,
    path_text: str,
    target_module: i32,
    span_start: i32,
    span_end: i32,
}

type ResolvedDef {
    def_id: i32,
    module_id: i32,
    parent_def: i32,
    kind: i32,
    name_sym: i32,
    span_start: i32,
    span_end: i32,
}

type ResolvedScope {
    scope_id: i32,
    module_id: i32,
    parent_scope: i32,
    owner_def: i32,
    kind: i32,
}

type ResolvedBinding {
    scope_id: i32,
    symbol: i32,
    def_id: i32,
}

type ResolvedUse {
    module_id: i32,
    node_id: i32,
    symbol: i32,
    def_id: i32,
    span_start: i32,
    span_end: i32,
}

type ResolveResult {
    modules: Vec[ResolvedModule],
    imports: Vec[ResolvedImport],
    defs: Vec[ResolvedDef],
    scopes: Vec[ResolvedScope],
    bindings: Vec[ResolvedBinding],
    uses: Vec[ResolvedUse],
    link_libs: Vec[i32],
}

fn ResolveResult.init -> ResolveResult:
    ResolveResult {
        modules: Vec.new(),
        imports: Vec.new(),
        defs: Vec.new(),
        scopes: Vec.new(),
        bindings: Vec.new(),
        uses: Vec.new(),
        link_libs: Vec.new(),
    }

type ResolveArtifacts {
    pool: InternPool,
    diags: DiagnosticList,
    result: ResolveResult,
}

type ResolveState {
    pool: InternPool,
    diags: DiagnosticList,
    result: ResolveResult,

    module_paths: Vec[str],
    module_dirs: Vec[str],
    module_file_ids: Vec[i32],
    module_decl_counts: Vec[i32],
    module_import_starts: Vec[i32],
    module_import_counts: Vec[i32],
    module_scope_ids: Vec[i32],
    module_processed: Vec[i32],

    module_map: HashMap[str, i32],
    link_lib_set: HashMap[i32, i32],
    binding_map: HashMap[i64, i32],
    root_source_dir: str,

    next_file_id: i32,
    emit_resolve_diags: bool,
}

fn resolve_from_root_pool(root_path: str, root_text: str, root_file_id: i32, root_pool: AstPool, pool: InternPool, diags: DiagnosticList, emit_resolve_diags: bool) -> ResolveArtifacts:
    var state = ResolveState.init(pool, diags, emit_resolve_diags)
    let root_dir = resolve_dirname(root_path)
    state.root_source_dir = root_dir
    let root_module = state.reserve_module(root_path, root_dir, root_file_id)

    var work = 0
    while work < state.module_paths.len() as i32:
        if state.module_processed.get(work as i64) != 0:
            work = work + 1
            continue

        if work == root_module:
            state.process_module_with_pool(work, root_text, root_pool)
        else:
            let path = state.module_paths.get(work as i64)
            let embedded_rel = embedded_std_rel_path(path)
            let text = if embedded_rel.len() > 0: embedded_std_source(embedded_rel) else: with_fs_read_file(path)
            if text.len() == 0:
                state.emit_import_error(work, "failed to read imported module")
                state.module_processed.set_i32(work as i64, 1)
                work = work + 1
                continue

            let file_id = state.module_file_ids.get(work as i64)
            var lexer = Lexer.init(text, file_id)
            let tokens = lexer.tokenize()
            var parser = Parser.init(tokens, text, file_id, state.pool, state.diags)
            let parsed = parser.parse_module()
            state.pool = parser.intern
            state.diags = parser.diags
            state.process_module_with_pool(work, text, parsed)

        work = work + 1

    let modules = state.build_module_table()
    ResolveArtifacts {
        pool: state.pool,
        diags: state.diags,
        result: ResolveResult {
            modules,
            imports: state.result.imports,
            defs: state.result.defs,
            scopes: state.result.scopes,
            bindings: state.result.bindings,
            uses: state.result.uses,
            link_libs: state.result.link_libs,
        },
    }

fn ResolveState.init(pool: InternPool, diags: DiagnosticList, emit_resolve_diags: bool) -> ResolveState:
    ResolveState {
        pool,
        diags,
        result: ResolveResult.init(),
        module_paths: Vec.new(),
        module_dirs: Vec.new(),
        module_file_ids: Vec.new(),
        module_decl_counts: Vec.new(),
        module_import_starts: Vec.new(),
        module_import_counts: Vec.new(),
        module_scope_ids: Vec.new(),
        module_processed: Vec.new(),
        module_map: HashMap.new(),
        link_lib_set: HashMap.new(),
        binding_map: HashMap.new(),
        root_source_dir: ".",
        next_file_id: 1,
        emit_resolve_diags,
    }

fn resolve_node_valid(pool: AstPool, node: i32) -> bool:
    node > 0 and node < pool.node_count()

fn resolve_extra_valid(pool: AstPool, idx: i32) -> bool:
    idx >= 0 and idx < pool.extra_len()

fn resolve_extra_or_zero(pool: AstPool, idx: i32) -> i32:
    if not resolve_extra_valid(pool, idx):
        return 0
    pool.get_extra(idx)

fn resolve_binding_key(scope_id: i32, symbol: i32) -> i64:
    (scope_id as i64) * 4294967296 + (symbol as i64)

fn ResolveState.reserve_module(self: ResolveState, path: str, source_dir: str, file_id_hint: i32) -> i32:
    let canon = resolve_normalize_path(path)
    let existing = self.module_map.get(canon)
    if existing.is_some():
        return existing.unwrap()

    let id = self.module_paths.len() as i32
    self.module_map.insert(canon, id)

    self.module_paths.push(canon)
    self.module_dirs.push(source_dir)
    if file_id_hint >= 0:
        self.module_file_ids.push(file_id_hint)
    else:
        self.module_file_ids.push(self.next_file_id)
        self.next_file_id = self.next_file_id + 1
    self.module_decl_counts.push(0)
    self.module_import_starts.push(0)
    self.module_import_counts.push(0)
    self.module_scope_ids.push(-1)
    self.module_processed.push(0)
    id

fn ResolveState.build_module_table(self: ResolveState) -> Vec[ResolvedModule]:
    var out: Vec[ResolvedModule] = Vec.new()
    for mid in 0..self.module_paths.len() as i32:
        out.push(ResolvedModule {
            module_id: mid,
            file_id: self.module_file_ids.get(mid as i64),
            path: self.module_paths.get(mid as i64),
            import_start: self.module_import_starts.get(mid as i64),
            import_count: self.module_import_counts.get(mid as i64),
            decl_count: self.module_decl_counts.get(mid as i64),
        })
    out

fn ResolveState.process_module_with_pool(self: ResolveState, module_id: i32, source_text: str, pool: AstPool):
    self.module_processed.set_i32(module_id as i64, 1)
    self.module_decl_counts.set_i32(module_id as i64, pool.decl_count())
    self.module_import_starts.set_i32(module_id as i64, self.result.imports.len() as i32)

    let module_scope = self.add_scope(module_id, -1, -1, ScopeKind.SK_MODULE)
    self.module_scope_ids.set_i32(module_id as i64, module_scope)

    var pending_fn_nodes: Vec[i32] = Vec.new()
    var pending_fn_defs: Vec[i32] = Vec.new()

    var import_index = 0

    // Pass 1: reserve imports + top-level defs/bindings.
    for di in 0..pool.decl_count():
        let decl = pool.get_decl(di)
        let kind = pool.kind(decl)
        let start = pool.get_start(decl)
        let end = pool.get_end(decl)

        if kind == NodeKind.NK_USE_DECL:
            let path_start = pool.get_data0(decl)
            let path_count = pool.get_data1(decl)
            let dotted = self.use_path_dotted(pool, path_start, path_count)
            let resolved_path = self.resolve_use_file(module_id, pool, path_start, path_count)
            var target_module = -1
            if resolved_path.len() > 0:
                target_module = self.reserve_module(resolved_path, resolve_dirname(resolved_path), -1)
            else:
                self.emit_import_decl_error(module_id, start, end, "import module not found")
            self.result.imports.push(ResolvedImport {
                module_id,
                index_in_module: import_index,
                kind: ImportKind.IK_USE,
                path_text: dotted,
                target_module,
                span_start: start,
                span_end: end,
            })
            import_index = import_index + 1
            continue

        if kind == NodeKind.NK_C_IMPORT:
            let header_sym = pool.get_data0(decl)
            let header = self.pool.resolve(header_sym)
            self.result.imports.push(ResolvedImport {
                module_id,
                index_in_module: import_index,
                kind: ImportKind.IK_C_IMPORT,
                path_text: header,
                target_module: -1,
                span_start: start,
                span_end: end,
            })
            import_index = import_index + 1

            let link_start = pool.get_data1(decl)
            let link_count = pool.get_data2(decl)
            for li in 0..link_count:
                let lib_sym = resolve_extra_or_zero(pool, link_start + li)
                self.record_link_lib(lib_sym)

            let cdef = self.add_def(module_id, -1, DefKind.DK_C_IMPORT, header_sym, start, end)
            self.add_binding(module_scope, header_sym, cdef)
            continue

        let def_kind = resolve_decl_def_kind(kind)
        if def_kind < 0:
            continue

        let name_sym = resolve_decl_name(pool, decl)
        let did = self.add_def(module_id, -1, def_kind, name_sym, start, end)
        if name_sym > 0:
            self.add_binding(module_scope, name_sym, did)

        if kind == NodeKind.NK_FN_DECL:
            pending_fn_nodes.push(decl as i32)
            pending_fn_defs.push(did)

    self.module_import_counts.set_i32(module_id as i64, import_index)

    // Pass 2: register function parameter defs/bindings.
    let walk_bodies = module_id == 0
    for fi in 0..pending_fn_nodes.len() as i32:
        let fn_node = pending_fn_nodes.get(fi as i64)
        let fn_def = pending_fn_defs.get(fi as i64)
        self.resolve_fn_body(pool, module_id, module_scope, fn_node, fn_def, walk_bodies)

fn ResolveState.record_link_lib(self: ResolveState, lib_sym: i32):
    if lib_sym <= 0:
        return
    if self.link_lib_set.contains(lib_sym):
        return
    self.link_lib_set.insert(lib_sym, 1)
    self.result.link_libs.push(lib_sym)

fn resolve_decl_def_kind(kind: i32) -> i32:
    if kind == NodeKind.NK_FN_DECL: return DefKind.DK_FN
    if kind == NodeKind.NK_TYPE_DECL: return DefKind.DK_TYPE
    if kind == NodeKind.NK_LET_DECL: return DefKind.DK_LET
    if kind == NodeKind.NK_EXTERN_FN: return DefKind.DK_EXTERN_FN
    if kind == NodeKind.NK_TRAIT_DECL: return DefKind.DK_TRAIT
    if kind == NodeKind.NK_IMPL_DECL: return DefKind.DK_IMPL
    -1

fn resolve_decl_name(pool: AstPool, decl: NodeId) -> i32:
    let kind = pool.kind(decl)
    if kind == NodeKind.NK_FN_DECL: return pool.get_data0(decl)
    if kind == NodeKind.NK_TYPE_DECL: return pool.get_data0(decl)
    if kind == NodeKind.NK_LET_DECL: return pool.get_data0(decl)
    if kind == NodeKind.NK_EXTERN_FN: return pool.get_data0(decl)
    if kind == NodeKind.NK_TRAIT_DECL: return pool.get_data0(decl)
    if kind == NodeKind.NK_IMPL_DECL: return pool.get_data0(decl)
    if kind == NodeKind.NK_C_IMPORT: return pool.get_data0(decl)
    0

fn ResolveState.add_def(self: ResolveState, module_id: i32, parent_def: i32, kind: i32, name_sym: i32, span_start: i32, span_end: i32) -> i32:
    let did = self.result.defs.len() as i32
    self.result.defs.push(ResolvedDef {
        def_id: did,
        module_id,
        parent_def,
        kind,
        name_sym,
        span_start,
        span_end,
    })
    did

fn ResolveState.add_scope(self: ResolveState, module_id: i32, parent_scope: i32, owner_def: i32, kind: i32) -> i32:
    let sid = self.result.scopes.len() as i32
    self.result.scopes.push(ResolvedScope {
        scope_id: sid,
        module_id,
        parent_scope,
        owner_def,
        kind,
    })
    sid

fn ResolveState.add_binding(self: ResolveState, scope_id: i32, symbol: i32, def_id: i32):
    if scope_id < 0 or symbol <= 0 or def_id < 0:
        return
    self.result.bindings.push(ResolvedBinding {
        scope_id,
        symbol,
        def_id,
    })
    self.binding_map.insert(resolve_binding_key(scope_id, symbol), def_id)

fn ResolveState.resolve_fn_body(self: ResolveState, pool: AstPool, module_id: i32, module_scope: i32, fn_node: i32, fn_def: i32, walk_body: bool):
    let fn_scope = self.add_scope(module_id, module_scope, fn_def, ScopeKind.SK_FN)

    // Register parameters as defs/bindings in function scope.
    let meta = pool.find_fn_meta(fn_node)
    if meta >= 0:
        let param_start = pool.fn_meta_param_start(meta)
        let param_count = pool.fn_meta_param_count(meta)
        for pi in 0..param_count:
            let name_sym = pool.fn_param_name(param_start, pi)
            let pdef = self.add_def(module_id, fn_def, DefKind.DK_PARAM, name_sym, pool.get_start(fn_node), pool.get_end(fn_node))
            self.add_binding(fn_scope, name_sym, pdef)

            let ty_node = pool.fn_param_type(param_start, pi)
            if resolve_node_valid(pool, ty_node):
                self.walk_type_expr(pool, module_id, fn_scope, ty_node)

        let ret_ty = pool.fn_meta_ret(meta)
        if resolve_node_valid(pool, ret_ty):
            self.walk_type_expr(pool, module_id, fn_scope, ret_ty)

    let body = pool.get_data1(fn_node)
    if walk_body and resolve_node_valid(pool, body):
        self.walk_expr(pool, module_id, fn_def, fn_scope, body)

fn ResolveState.walk_type_expr(self: ResolveState, pool: AstPool, module_id: i32, current_scope: i32, node: i32):
    if not resolve_node_valid(pool, node):
        return
    let kind = pool.kind(node)

    if kind == NodeKind.NK_TYPE_NAMED or kind == NodeKind.NK_TYPE_TRAIT_OBJ:
        let sym = pool.get_data0(node)
        self.record_identifier_use(pool, module_id, current_scope, node, sym)
        return

    if kind == NodeKind.NK_TYPE_GENERIC:
        let sym = pool.get_data0(node)
        self.record_identifier_use(pool, module_id, current_scope, node, sym)
        let start = pool.get_data1(node)
        let count = pool.get_data2(node)
        for i in 0..count:
            let arg = resolve_extra_or_zero(pool, start + i)
            self.walk_type_expr(pool, module_id, current_scope, arg)
        return

    if kind == NodeKind.NK_TYPE_REF or kind == NodeKind.NK_TYPE_PTR or kind == NodeKind.NK_TYPE_OPTIONAL or kind == NodeKind.NK_TYPE_SLICE:
        self.walk_type_expr(pool, module_id, current_scope, pool.get_data0(node))
        return

    if kind == NodeKind.NK_TYPE_ARRAY:
        self.walk_type_expr(pool, module_id, current_scope, pool.get_data0(node))
        return

    if kind == NodeKind.NK_TYPE_TUPLE:
        let start = pool.get_data0(node)
        let count = pool.get_data1(node)
        for i in 0..count:
            let child = resolve_extra_or_zero(pool, start + i)
            self.walk_type_expr(pool, module_id, current_scope, child)
        return

    if kind == NodeKind.NK_TYPE_FN:
        let start = pool.get_data0(node)
        let count = pool.get_data1(node)
        for i in 0..count:
            let p = resolve_extra_or_zero(pool, start + i)
            self.walk_type_expr(pool, module_id, current_scope, p)
        self.walk_type_expr(pool, module_id, current_scope, pool.get_data2(node))
        return

fn ResolveState.walk_expr(self: ResolveState, pool: AstPool, module_id: i32, parent_def: i32, current_scope: i32, node: i32):
    if not resolve_node_valid(pool, node):
        return

    let kind = pool.kind(node)

    if kind == NodeKind.NK_IDENT:
        let sym = pool.get_data0(node)
        self.record_identifier_use(pool, module_id, current_scope, node, sym)
        return

    if kind == NodeKind.NK_INT_LIT or kind == NodeKind.NK_FLOAT_LIT or kind == NodeKind.NK_STRING_LIT or kind == NodeKind.NK_BOOL_LIT or kind == NodeKind.NK_C_STRING_LIT:
        return

    if kind == NodeKind.NK_GROUPED:
        self.walk_expr(pool, module_id, parent_def, current_scope, pool.get_data0(node))
        return

    if kind == NodeKind.NK_UNARY:
        self.walk_expr(pool, module_id, parent_def, current_scope, pool.get_data1(node))
        return

    if kind == NodeKind.NK_BINARY:
        self.walk_expr(pool, module_id, parent_def, current_scope, pool.get_data1(node))
        self.walk_expr(pool, module_id, parent_def, current_scope, pool.get_data2(node))
        return

    if kind == NodeKind.NK_ASSIGN:
        self.walk_expr(pool, module_id, parent_def, current_scope, pool.get_data0(node))
        self.walk_expr(pool, module_id, parent_def, current_scope, pool.get_data1(node))
        return

    if kind == NodeKind.NK_CALL:
        self.walk_expr(pool, module_id, parent_def, current_scope, pool.get_data0(node))
        let arg_start = pool.get_data1(node)
        let arg_count = pool.get_data2(node)
        for ai in 0..arg_count:
            self.walk_expr(pool, module_id, parent_def, current_scope, resolve_extra_or_zero(pool, arg_start + ai))
        return

    if kind == NodeKind.NK_FIELD_ACCESS:
        self.walk_expr(pool, module_id, parent_def, current_scope, pool.get_data0(node))
        return

    if kind == NodeKind.NK_COMPUTED_FIELD_ACCESS:
        self.walk_expr(pool, module_id, parent_def, current_scope, pool.get_data0(node))
        self.walk_expr(pool, module_id, parent_def, current_scope, pool.get_data1(node))
        return

    if kind == NodeKind.NK_INDEX:
        self.walk_expr(pool, module_id, parent_def, current_scope, pool.get_data0(node))
        self.walk_expr(pool, module_id, parent_def, current_scope, pool.get_data1(node))
        return

    if kind == NodeKind.NK_SLICE:
        self.walk_expr(pool, module_id, parent_def, current_scope, pool.get_data0(node))
        self.walk_expr(pool, module_id, parent_def, current_scope, pool.get_data1(node))
        self.walk_expr(pool, module_id, parent_def, current_scope, pool.get_data2(node))
        return

    if kind == NodeKind.NK_CAST:
        self.walk_expr(pool, module_id, parent_def, current_scope, pool.get_data0(node))
        self.walk_type_expr(pool, module_id, current_scope, pool.get_data1(node))
        return

    if kind == NodeKind.NK_RETURN or kind == NodeKind.NK_DEFER or kind == NodeKind.NK_ERRDEFER or kind == NodeKind.NK_AWAIT or kind == NodeKind.NK_SPAWN or kind == NodeKind.NK_YIELD or kind == NodeKind.NK_COMPTIME:
        self.walk_expr(pool, module_id, parent_def, current_scope, pool.get_data0(node))
        return

    if kind == NodeKind.NK_IF_EXPR:
        self.walk_expr(pool, module_id, parent_def, current_scope, pool.get_data0(node))
        self.walk_expr(pool, module_id, parent_def, current_scope, pool.get_data1(node))
        self.walk_expr(pool, module_id, parent_def, current_scope, pool.get_data2(node))
        return

    if kind == NodeKind.NK_BLOCK:
        let block_scope = self.add_scope(module_id, current_scope, parent_def, ScopeKind.SK_BLOCK)
        let stmt_start = pool.get_data0(node)
        let stmt_count = pool.get_data1(node)
        for si in 0..stmt_count:
            let stmt = resolve_extra_or_zero(pool, stmt_start + si)
            self.walk_expr(pool, module_id, parent_def, block_scope, stmt)
        self.walk_expr(pool, module_id, parent_def, block_scope, pool.get_data2(node))
        return

    if kind == NodeKind.NK_LET_BINDING:
        self.walk_expr(pool, module_id, parent_def, current_scope, pool.get_data1(node))

        let name_sym = pool.get_data0(node)
        let did = self.add_def(module_id, parent_def, DefKind.DK_LOCAL, name_sym, pool.get_start(node), pool.get_end(node))
        self.add_binding(current_scope, name_sym, did)

        let flags = pool.get_data2(node)
        let encoded = flags / 2
        if encoded > 0:
            let ty_node = resolve_extra_or_zero(pool, encoded - 1)
            self.walk_type_expr(pool, module_id, current_scope, ty_node)
        return

    if kind == NodeKind.NK_LET_ELSE:
        // let-else: walk value, bind pattern into current scope (visible after).
        self.walk_expr(pool, module_id, parent_def, current_scope, pool.get_data1(node))
        self.bind_pattern(pool, module_id, parent_def, current_scope, pool.get_data0(node))
        self.walk_expr(pool, module_id, parent_def, current_scope, pool.get_data2(node))
        return

    if kind == NodeKind.NK_TUPLE_DESTRUCTURE:
        let names_start = pool.get_data0(node)
        let names_count = pool.get_data1(node)
        for ni in 0..names_count:
            let sym = resolve_extra_or_zero(pool, names_start + ni)
            if sym > 0:
                let d = self.add_def(module_id, parent_def, DefKind.DK_LOCAL, sym, pool.get_start(node), pool.get_end(node))
                self.add_binding(current_scope, sym, d)
        self.walk_expr(pool, module_id, parent_def, current_scope, pool.get_data2(node))
        return

    if kind == NodeKind.NK_WHILE:
        self.walk_expr(pool, module_id, parent_def, current_scope, pool.get_data0(node))
        let loop_scope = self.add_scope(module_id, current_scope, parent_def, ScopeKind.SK_LOOP)
        self.walk_expr(pool, module_id, parent_def, loop_scope, pool.get_data1(node))
        return

    if kind == NodeKind.NK_LOOP:
        let loop_scope = self.add_scope(module_id, current_scope, parent_def, ScopeKind.SK_LOOP)
        self.walk_expr(pool, module_id, parent_def, loop_scope, pool.get_data0(node))
        return

    if kind == NodeKind.NK_FOR:
        self.walk_expr(pool, module_id, parent_def, current_scope, pool.get_data1(node))
        let loop_scope = self.add_scope(module_id, current_scope, parent_def, ScopeKind.SK_LOOP)

        let binding = pool.get_data0(node)
        if pool.for_binding_is_pattern(node):
            self.bind_pattern(pool, module_id, parent_def, loop_scope, binding)
        else if binding > 0:
            let did = self.add_def(module_id, parent_def, DefKind.DK_LOCAL, binding, pool.get_start(node), pool.get_end(node))
            self.add_binding(loop_scope, binding, did)

        self.walk_expr(pool, module_id, parent_def, loop_scope, pool.get_data2(node))
        return

    if kind == NodeKind.NK_MATCH:
        self.walk_expr(pool, module_id, parent_def, current_scope, pool.get_data0(node))
        let arm_start = pool.get_data1(node)
        let arm_count = pool.get_data2(node)
        for ai in 0..arm_count:
            self.walk_expr(pool, module_id, parent_def, current_scope, resolve_extra_or_zero(pool, arm_start + ai))
        return

    if kind == NodeKind.NK_MATCH_ARM:
        let arm_scope = self.add_scope(module_id, current_scope, parent_def, ScopeKind.SK_MATCH_ARM)
        self.bind_pattern(pool, module_id, parent_def, arm_scope, pool.get_data0(node))
        self.walk_expr(pool, module_id, parent_def, arm_scope, pool.get_data2(node))
        self.walk_expr(pool, module_id, parent_def, arm_scope, pool.get_data1(node))
        return

    if kind == NodeKind.NK_TUPLE or kind == NodeKind.NK_ARRAY_LIT:
        let start = pool.get_data0(node)
        let count = pool.get_data1(node)
        for i in 0..count:
            self.walk_expr(pool, module_id, parent_def, current_scope, resolve_extra_or_zero(pool, start + i))
        return

    if kind == NodeKind.NK_ARRAY_COMPREHENSION:
        self.walk_expr(pool, module_id, parent_def, current_scope, pool.get_data2(node))
        let comp_scope = self.add_scope(module_id, current_scope, parent_def, ScopeKind.SK_COMPREHENSION)
        let binding = pool.get_data1(node)
        let bdef = self.add_def(module_id, parent_def, DefKind.DK_LOCAL, binding, pool.get_start(node), pool.get_end(node))
        self.add_binding(comp_scope, binding, bdef)
        self.walk_expr(pool, module_id, parent_def, comp_scope, pool.get_data0(node))
        return

    if kind == NodeKind.NK_STRUCT_LIT:
        let field_start = pool.get_data1(node)
        let field_count = pool.get_data2(node)
        for fi in 0..field_count:
            let val = resolve_extra_or_zero(pool, field_start + fi * 2 + 1)
            self.walk_expr(pool, module_id, parent_def, current_scope, val)
        return

    if kind == NodeKind.NK_RECORD_UPDATE:
        self.walk_expr(pool, module_id, parent_def, current_scope, pool.get_data0(node))
        let field_start = pool.get_data1(node)
        let field_count = pool.get_data2(node)
        for fi in 0..field_count:
            let val = resolve_extra_or_zero(pool, field_start + fi * 2 + 1)
            self.walk_expr(pool, module_id, parent_def, current_scope, val)
        return

    if kind == NodeKind.NK_CLOSURE:
        let closure_scope = self.add_scope(module_id, current_scope, parent_def, ScopeKind.SK_CLOSURE)
        let param_start = pool.get_data1(node)
        let param_count = pool.get_data2(node)
        for pi in 0..param_count:
            let name_sym = resolve_extra_or_zero(pool, param_start + pi * 2)
            let pdef = self.add_def(module_id, parent_def, DefKind.DK_PARAM, name_sym, pool.get_start(node), pool.get_end(node))
            self.add_binding(closure_scope, name_sym, pdef)
            let ty = resolve_extra_or_zero(pool, param_start + pi * 2 + 1)
            self.walk_type_expr(pool, module_id, closure_scope, ty)
        self.walk_expr(pool, module_id, parent_def, closure_scope, pool.get_data0(node))
        return

    if kind == NodeKind.NK_OPTIONAL_CHAIN:
        self.walk_expr(pool, module_id, parent_def, current_scope, pool.get_data0(node))
        let extra_start = pool.get_data2(node)
        let arg_count = resolve_extra_or_zero(pool, extra_start)
        for ai in 0..arg_count:
            self.walk_expr(pool, module_id, parent_def, current_scope, resolve_extra_or_zero(pool, extra_start + 1 + ai))
        return

    if kind == NodeKind.NK_PIPELINE:
        self.walk_expr(pool, module_id, parent_def, current_scope, pool.get_data0(node))
        self.walk_expr(pool, module_id, parent_def, current_scope, pool.get_data1(node))
        return

    if kind == NodeKind.NK_RANGE:
        self.walk_expr(pool, module_id, parent_def, current_scope, pool.get_data0(node))
        self.walk_expr(pool, module_id, parent_def, current_scope, pool.get_data1(node))
        return

    if kind == NodeKind.NK_VARIANT_SHORTHAND:
        let start = pool.get_data1(node)
        let count = pool.get_data2(node)
        for i in 0..count:
            self.walk_expr(pool, module_id, parent_def, current_scope, resolve_extra_or_zero(pool, start + i))
        return

    if kind == NodeKind.NK_ENUM_VARIANT:
        let extra_start = pool.get_data2(node)
        let count = resolve_extra_or_zero(pool, extra_start)
        for i in 0..count:
            self.walk_expr(pool, module_id, parent_def, current_scope, resolve_extra_or_zero(pool, extra_start + 1 + i))
        return

    if kind == NodeKind.NK_WITH_EXPR:
        self.walk_expr(pool, module_id, parent_def, current_scope, pool.get_data0(node))
        let with_scope = self.add_scope(module_id, current_scope, parent_def, ScopeKind.SK_BLOCK)
        let name_sym = decode_with_binding_sym(pool.get_data2(node))
        let bdef = self.add_def(module_id, parent_def, DefKind.DK_LOCAL, name_sym, pool.get_start(node), pool.get_end(node))
        self.add_binding(with_scope, name_sym, bdef)
        self.walk_expr(pool, module_id, parent_def, with_scope, pool.get_data1(node))
        return

    if kind == NodeKind.NK_WITH_IMPLICIT:
        self.walk_expr(pool, module_id, parent_def, current_scope, pool.get_data0(node))
        let wi_scope = self.add_scope(module_id, current_scope, parent_def, ScopeKind.SK_BLOCK)
        let wi_name_sym = pool.get_data2(node)
        let wi_def = self.add_def(module_id, parent_def, DefKind.DK_LOCAL, wi_name_sym, pool.get_start(node), pool.get_end(node))
        self.add_binding(wi_scope, wi_name_sym, wi_def)
        self.walk_expr(pool, module_id, parent_def, wi_scope, pool.get_data1(node))
        return

    if kind == NodeKind.NK_ASYNC_BLOCK:
        self.walk_expr(pool, module_id, parent_def, current_scope, pool.get_data0(node))
        return

    if kind == NodeKind.NK_ASYNC_SCOPE:
        let async_scope = self.add_scope(module_id, current_scope, parent_def, ScopeKind.SK_BLOCK)
        let name_sym = pool.get_data0(node)
        let sdef = self.add_def(module_id, parent_def, DefKind.DK_LOCAL, name_sym, pool.get_start(node), pool.get_end(node))
        self.add_binding(async_scope, name_sym, sdef)
        self.walk_expr(pool, module_id, parent_def, async_scope, pool.get_data1(node))
        return

    if kind == NodeKind.NK_SELECT_AWAIT:
        let arm_start = pool.get_data0(node)
        let arm_count = pool.get_data1(node)
        for ai in 0..arm_count:
            let name_sym = resolve_extra_or_zero(pool, arm_start + ai * 3)
            let task_expr = resolve_extra_or_zero(pool, arm_start + ai * 3 + 1)
            let arm_body = resolve_extra_or_zero(pool, arm_start + ai * 3 + 2)
            self.walk_expr(pool, module_id, parent_def, current_scope, task_expr)
            let arm_scope = self.add_scope(module_id, current_scope, parent_def, ScopeKind.SK_MATCH_ARM)
            let d = self.add_def(module_id, parent_def, DefKind.DK_LOCAL, name_sym, pool.get_start(node), pool.get_end(node))
            self.add_binding(arm_scope, name_sym, d)
            self.walk_expr(pool, module_id, parent_def, arm_scope, arm_body)
        return

fn ResolveState.bind_pattern(self: ResolveState, pool: AstPool, module_id: i32, parent_def: i32, current_scope: i32, pat: i32):
    if not resolve_node_valid(pool, pat):
        return

    let kind = pool.kind(pat)

    if kind == NodeKind.NK_PAT_IDENT:
        let name_sym = pool.get_data0(pat)
        let d = self.add_def(module_id, parent_def, DefKind.DK_LOCAL, name_sym, pool.get_start(pat), pool.get_end(pat))
        self.add_binding(current_scope, name_sym, d)
        return

    if kind == NodeKind.NK_PAT_AT_BINDING:
        let name_sym = pool.get_data0(pat)
        let d = self.add_def(module_id, parent_def, DefKind.DK_LOCAL, name_sym, pool.get_start(pat), pool.get_end(pat))
        self.add_binding(current_scope, name_sym, d)
        self.bind_pattern(pool, module_id, parent_def, current_scope, pool.get_data1(pat))
        return

    if kind == NodeKind.NK_PAT_VARIANT or kind == NodeKind.NK_PAT_ENUM_SHORTHAND:
        let start = pool.get_data1(pat)
        let count = pool.get_data2(pat)
        let pat_start = pool.get_start(pat)
        let pat_end = pool.get_end(pat)
        for i in 0..count:
            let inner = resolve_extra_or_zero(pool, start + i)
            if inner != pat and resolve_node_valid(pool, inner) and pool.kind(inner) >= NodeKind.NK_PAT_WILDCARD and pool.kind(inner) <= NodeKind.NK_PAT_SLICE and pool.get_start(inner) >= pat_start and pool.get_end(inner) <= pat_end:
                self.bind_pattern(pool, module_id, parent_def, current_scope, inner)
            else if inner > 0:
                let d = self.add_def(module_id, parent_def, DefKind.DK_LOCAL, inner, pool.get_start(pat), pool.get_end(pat))
                self.add_binding(current_scope, inner, d)
        return

    if kind == NodeKind.NK_PAT_TUPLE or kind == NodeKind.NK_PAT_OR:
        let start = pool.get_data0(pat)
        let count = pool.get_data1(pat)
        for i in 0..count:
            self.bind_pattern(pool, module_id, parent_def, current_scope, resolve_extra_or_zero(pool, start + i))
        return

    if kind == NodeKind.NK_PAT_STRUCT:
        let start = pool.get_data1(pat)
        let count = pool.get_data2(pat)
        for i in 0..count:
            let fpat = resolve_extra_or_zero(pool, start + i * 2 + 1)
            if fpat != 0:
                self.bind_pattern(pool, module_id, parent_def, current_scope, fpat)
            else:
                let fname = resolve_extra_or_zero(pool, start + i * 2)
                let d = self.add_def(module_id, parent_def, DefKind.DK_LOCAL, fname, pool.get_start(pat), pool.get_end(pat))
                self.add_binding(current_scope, fname, d)
        return

    if kind == NodeKind.NK_PAT_SLICE:
        let start = pool.get_data0(pat)
        let head_count = pool.get_data1(pat)
        for i in 0..head_count:
            let sym = resolve_extra_or_zero(pool, start + 1 + i)
            let d = self.add_def(module_id, parent_def, DefKind.DK_LOCAL, sym, pool.get_start(pat), pool.get_end(pat))
            self.add_binding(current_scope, sym, d)

        let rest_sym = pool.get_data2(pat)
        if rest_sym != 0:
            let d = self.add_def(module_id, parent_def, DefKind.DK_LOCAL, rest_sym, pool.get_start(pat), pool.get_end(pat))
            self.add_binding(current_scope, rest_sym, d)
        return

fn ResolveState.record_identifier_use(self: ResolveState, pool: AstPool, module_id: i32, current_scope: i32, node: i32, sym: i32):
    if sym <= 0 or (not resolve_node_valid(pool, node)):
        return

    let target = self.lookup_binding(current_scope, sym)
    self.result.uses.push(ResolvedUse {
        module_id,
        node_id: node,
        symbol: sym,
        def_id: target,
        span_start: pool.get_start(node),
        span_end: pool.get_end(node),
    })

fn ResolveState.lookup_binding(self: ResolveState, current_scope: i32, sym: i32) -> i32:
    var sid = current_scope
    while sid >= 0:
        let key = resolve_binding_key(sid, sym)
        let found = self.binding_map.get(key)
        if found.is_some():
            return found.unwrap()

        if sid >= self.result.scopes.len() as i32:
            return -1
        let scope = self.result.scopes.get(sid as i64)
        sid = scope.parent_scope

    -1

fn ResolveState.use_path_dotted(self: ResolveState, pool: AstPool, path_start: i32, path_count: i32) -> str:
    var out = ""
    for i in 0..path_count:
        if i > 0:
            out = out ++ "."
        let seg = resolve_extra_or_zero(pool, path_start + i)
        out = out ++ self.pool.resolve(seg)
    out

fn ResolveState.resolve_use_file(self: ResolveState, module_id: i32, pool: AstPool, path_start: i32, path_count: i32) -> str:
    if path_count <= 0:
        return ""

    let module_dir = self.module_dirs.get(module_id as i64)
    let has_root_fallback = module_dir != self.root_source_dir

    var rel_primary = ""
    for i in 0..path_count:
        if i > 0:
            rel_primary = rel_primary ++ "/"
        let seg = resolve_extra_or_zero(pool, path_start + i)
        rel_primary = rel_primary ++ self.pool.resolve(seg)
    rel_primary = rel_primary ++ ".w"

    // Try embedded stdlib first (fast path for built-in modules).
    // If not found, fall through to normal filesystem resolution.
    // This decouples the std/ namespace from the embedded storage —
    // modules like std.re can live on the filesystem without embedding.
    if rel_primary.starts_with("std/"):
        let embedded_primary = embedded_std_resolve_path(rel_primary)
        if embedded_primary.len() > 0:
            return embedded_primary
        if path_count > 1:
            var rel_fallback_embedded = ""
            for i in 0..(path_count - 1):
                if i > 0:
                    rel_fallback_embedded = rel_fallback_embedded ++ "/"
                let seg = resolve_extra_or_zero(pool, path_start + i)
                rel_fallback_embedded = rel_fallback_embedded ++ self.pool.resolve(seg)
            rel_fallback_embedded = rel_fallback_embedded ++ ".w"
            let embedded_fallback = embedded_std_resolve_path(rel_fallback_embedded)
            if embedded_fallback.len() > 0:
                return embedded_fallback
        // Not embedded — fall through to filesystem resolution

    let path1 = self.resolve_module_rel(module_dir, rel_primary)
    if path1.len() > 0:
        return path1
    if has_root_fallback:
        let path_root = self.resolve_module_rel(self.root_source_dir, rel_primary)
        if path_root.len() > 0:
            return path_root

    if path_count > 1:
        var rel_fallback = ""
        for i in 0..(path_count - 1):
            if i > 0:
                rel_fallback = rel_fallback ++ "/"
            let seg = resolve_extra_or_zero(pool, path_start + i)
            rel_fallback = rel_fallback ++ self.pool.resolve(seg)
        rel_fallback = rel_fallback ++ ".w"
        let path2 = self.resolve_module_rel(module_dir, rel_fallback)
        if path2.len() > 0:
            return path2
        if has_root_fallback:
            let path2_root = self.resolve_module_rel(self.root_source_dir, rel_fallback)
            if path2_root.len() > 0:
                return path2_root

    ""

fn ResolveState.resolve_module_rel(self: ResolveState, module_dir: str, rel_path: str) -> str:
    // Strategy 1: relative to current module's directory.
    let cand1 = resolve_join(module_dir, rel_path)
    if resolve_file_exists(cand1):
        return cand1

    // Strategy 2: walk parent directories and check lib/<rel_path>.
    let parent_walk = resolve_parent_lib_candidate(module_dir, rel_path)
    if parent_walk.len() > 0:
        return parent_walk

    // Strategy 3/4: project root (directory containing build.zig), then lib/ and src/.
    let rooted = resolve_project_root_candidate(module_dir, rel_path)
    if rooted.len() > 0:
        return rooted

    // Strategy 5: src/<rel_path> from cwd.
    let cand5 = resolve_join("src", rel_path)
    if resolve_file_exists(cand5):
        return cand5

    // Strategy 6: lib/<rel_path> from cwd.
    let cand6 = resolve_join("lib", rel_path)
    if resolve_file_exists(cand6):
        return cand6

    ""

fn resolve_file_exists(path: str) -> bool:
    with_fs_read_file(path).len() > 0

fn resolve_parent_lib_candidate(module_dir: str, rel_path: str) -> str:
    var cur = module_dir
    while true:
        let lib_dir = resolve_join(cur, "lib")
        let cand = resolve_join(lib_dir, rel_path)
        if resolve_file_exists(cand):
            return cand
        let parent = resolve_dirname(cur)
        if parent == cur:
            break
        cur = parent
    ""

fn resolve_project_root_candidate(module_dir: str, rel_path: str) -> str:
    let root = resolve_find_project_root(module_dir)
    if root.len() == 0:
        return ""

    let lib_cand = resolve_join(resolve_join(root, "lib"), rel_path)
    if resolve_file_exists(lib_cand):
        return lib_cand

    let src_cand = resolve_join(resolve_join(root, "src"), rel_path)
    if resolve_file_exists(src_cand):
        return src_cand

    ""

fn resolve_join(a: str, b: str) -> str:
    if a.len() == 0:
        return b
    if b.len() == 0:
        return a
    if a == ".":
        return b
    if a.ends_with("/"):
        return resolve_normalize_path(a ++ b)
    resolve_normalize_path(a ++ "/" ++ b)

fn resolve_dirname(path: str) -> str:
    var last = -1
    for i in 0..path.len():
        if path[i] == 47:
            last = i as i32
    if last < 0:
        return "."
    if last == 0:
        return "/"
    path.slice(0, last as i64)

fn resolve_normalize_path(path: str) -> str:
    if path.len() == 0:
        return path

    var out = ""
    var i = 0
    while i < path.len() as i32:
        let ch = path[i as i64]
        if ch == 92:
            out = out ++ "/"
            i = i + 1
            continue

        if ch == 47 and i + 1 < path.len() as i32 and path[(i + 1) as i64] == 47:
            i = i + 1
            continue

        if ch == 47 and i + 2 < path.len() as i32 and path[(i + 1) as i64] == 46 and path[(i + 2) as i64] == 47:
            i = i + 2
            continue

        out = out ++ path.slice(i as i64, (i + 1) as i64)
        i = i + 1

    if out.len() == 0:
        return "."
    out

fn resolve_find_project_root(start_dir: str) -> str:
    var cur = start_dir
    while true:
        let build_file = resolve_join(cur, "build.zig")
        if resolve_file_exists(build_file):
            return cur
        let parent = resolve_dirname(cur)
        if parent == cur:
            break
        cur = parent
    ""

fn ResolveState.emit_import_error(self: ResolveState, module_id: i32, message: str):
    if not self.emit_resolve_diags:
        return
    let span = Span {
        file: self.module_file_ids.get(module_id as i64),
        start: 0,
        end: 0,
    }
    self.diags.emit(Diagnostic.err(message, span))

fn ResolveState.emit_import_decl_error(self: ResolveState, module_id: i32, start: i32, end: i32, message: str):
    if not self.emit_resolve_diags:
        return
    let span = Span {
        file: self.module_file_ids.get(module_id as i64),
        start,
        end,
    }
    self.diags.emit(Diagnostic.err(message, span))

fn resolved_import_kind_name(kind: i32) -> str:
    if kind == ImportKind.IK_USE:
        return "use"
    if kind == ImportKind.IK_C_IMPORT:
        return "c_import"
    "unknown"

fn resolved_def_kind_name(kind: i32) -> str:
    if kind == DefKind.DK_FN: return "fn"
    if kind == DefKind.DK_TYPE: return "type"
    if kind == DefKind.DK_LET: return "let"
    if kind == DefKind.DK_EXTERN_FN: return "extern_fn"
    if kind == DefKind.DK_TRAIT: return "trait"
    if kind == DefKind.DK_IMPL: return "impl"
    if kind == DefKind.DK_C_IMPORT: return "c_import"
    if kind == DefKind.DK_PARAM: return "param"
    if kind == DefKind.DK_LOCAL: return "local"
    "unknown"

fn resolved_scope_kind_name(kind: i32) -> str:
    if kind == ScopeKind.SK_MODULE: return "module"
    if kind == ScopeKind.SK_FN: return "fn"
    if kind == ScopeKind.SK_BLOCK: return "block"
    if kind == ScopeKind.SK_MATCH_ARM: return "match_arm"
    if kind == ScopeKind.SK_LOOP: return "loop"
    if kind == ScopeKind.SK_CLOSURE: return "closure"
    if kind == ScopeKind.SK_COMPREHENSION: return "comprehension"
    "unknown"

fn print_resolved(result: ResolveResult, pool: InternPool, root_path: str):
    with_write(f"resolved root={root_path} modules={result.modules.len() as i32} defs={result.defs.len() as i32}\n")

    for mi in 0..result.modules.len() as i32:
        let m = result.modules.get(mi as i64)
        with_write(f"module[{m.module_id}] file={m.file_id} path={m.path} imports={m.import_count} decls={m.decl_count}\n")

        for ii in 0..m.import_count:
            let imp = result.imports.get((m.import_start + ii) as i64)
            if imp.kind == ImportKind.IK_USE:
                with_write(f"import[{m.module_id}:{ii}] kind=use path={imp.path_text} target={imp.target_module}\n")
            else:
                with_write(f"import[{m.module_id}:{ii}] kind=c_import header=\"{imp.path_text}\" target={imp.target_module}\n")

    for di in 0..result.defs.len() as i32:
        let d = result.defs.get(di as i64)
        let name = if d.name_sym > 0: pool.resolve(d.name_sym) else: ""
        with_write(f"def[{d.def_id}] module={d.module_id} parent={d.parent_def} kind={resolved_def_kind_name(d.kind)} name={name} span={d.span_start}..{d.span_end}\n")

    for bi in 0..result.bindings.len() as i32:
        let b = result.bindings.get(bi as i64)
        let sym = pool.resolve(b.symbol)
        with_write(f"bind[{b.scope_id}:{sym}] def={b.def_id}\n")

    for ui in 0..result.uses.len() as i32:
        let u = result.uses.get(ui as i64)
        let sym = pool.resolve(u.symbol)
        with_write(f"use[{ui}] module={u.module_id} node={u.node_id} sym={sym} def={u.def_id} span={u.span_start}..{u.span_end}\n")

    if result.link_libs.len() > 0:
        var line = "link_libs="
        for li in 0..result.link_libs.len() as i32:
            if li > 0:
                line = line ++ ","
            line = line ++ pool.resolve(result.link_libs.get(li as i64))
        with_write(line ++ "\n")

fn dump_resolved(result: ResolveResult, pool: InternPool, root_path: str) -> str:
    var out = ""
    out = out ++ f"resolved root={root_path} modules={result.modules.len() as i32} defs={result.defs.len() as i32}\n"

    for mi in 0..result.modules.len() as i32:
        let m = result.modules.get(mi as i64)
        out = out ++ f"module[{m.module_id}] file={m.file_id} path={m.path} imports={m.import_count} decls={m.decl_count}\n"

        for ii in 0..m.import_count:
            let imp = result.imports.get((m.import_start + ii) as i64)
            if imp.kind == ImportKind.IK_USE:
                out = out ++ f"import[{m.module_id}:{ii}] kind=use path={imp.path_text} target={imp.target_module}\n"
            else:
                out = out ++ f"import[{m.module_id}:{ii}] kind=c_import header=\"{imp.path_text}\" target={imp.target_module}\n"

    for di in 0..result.defs.len() as i32:
        let d = result.defs.get(di as i64)
        let name = if d.name_sym > 0: pool.resolve(d.name_sym) else: ""
        out = out ++ f"def[{d.def_id}] module={d.module_id} parent={d.parent_def} kind={resolved_def_kind_name(d.kind)} name={name} span={d.span_start}..{d.span_end}\n"

    for bi in 0..result.bindings.len() as i32:
        let b = result.bindings.get(bi as i64)
        let sym = pool.resolve(b.symbol)
        out = out ++ f"bind[{b.scope_id}:{sym}] def={b.def_id}\n"

    for ui in 0..result.uses.len() as i32:
        let u = result.uses.get(ui as i64)
        let sym = pool.resolve(u.symbol)
        out = out ++ f"use[{ui}] module={u.module_id} node={u.node_id} sym={sym} def={u.def_id} span={u.span_start}..{u.span_end}\n"

    if result.link_libs.len() > 0:
        out = out ++ "link_libs="
        for li in 0..result.link_libs.len() as i32:
            if li > 0:
                out = out ++ ","
            out = out ++ pool.resolve(result.link_libs.get(li as i64))
        out = out ++ "\n"

    out
