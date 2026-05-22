use Ast
use Diagnostic
use Resolve
use InternPool
use Sema
use Span
use Mir
use MirLower
use AsyncMir
use AsyncLower
use CCodegen
use render
use compiler.Compilation.Config
use compiler.Backend
use compiler.Frontend
use compiler.Link
use compiler.ProjectConfig
use compiler.DriverOptions
use compiler.Zcu

extern fn with_eprint(s: str) -> void
extern fn with_exec_binary(path: str) -> i32
extern fn with_fs_write_file(path: str, data: str) -> i32
extern fn with_fs_read_file(path: str) -> str
extern fn with_fs_remove_file(path: str) -> i32
extern fn with_fs_remove_dir(path: str) -> i32
extern fn with_fs_mkdir_p(path: str) -> i32
extern fn with_getenv_str(name: str) -> str
extern fn with_setenv_str(name: str, value: str) -> i32
extern fn with_system(cmd: str) -> i32
extern fn with_clock_nanos() -> i64
extern fn with_getpid() -> i32

fn profile_enabled() -> bool:
    with_getenv_str("WITH_PROFILE").len() > 0

fn profile_now() -> i64:
    with_clock_nanos()

fn profile_emit(name: str, start: i64, counters: str):
    let elapsed_ns = with_clock_nanos() - start
    let ms_whole = elapsed_ns / 1000000
    let ms_frac = (elapsed_ns % 1000000) / 1000
    if counters.len() > 0:
        with_eprint(f"[profile] {name}  {ms_whole}.{ms_frac} ms  {counters}")
    else:
        with_eprint(f"[profile] {name}  {ms_whole}.{ms_frac} ms")

fn compilation_debug_init_enabled() -> i32:
    let raw = with_getenv_str("WITH_DEBUG_STAGE1_TRACE")
    if raw.len() == 0:
        return 0
    1

fn compilation_debug_init(msg: str):
    if compilation_debug_init_enabled() == 0:
        return
    with_eprint("[comp-init] " ++ msg)

fn compilation_debug_pool_flow_enabled() -> i32:
    let raw = with_getenv_str("WITH_DEBUG_POOL_FLOW")
    if raw.len() == 0:
        return 0
    1

fn compilation_debug_pool_flow(label: str, pool: InternPool, typed_pool: AstPool, sema: Sema):
    if compilation_debug_pool_flow_enabled() == 0:
        return
    with_eprint(f"[comp] {label} pool.symbols={pool.state.symbol_texts.len() as i32} typed.decls={typed_pool.decl_count()} sema.pool.symbols={sema.pool.state.symbol_texts.len() as i32} sema.ast.decls={sema.ast.decl_count()}")

fn compilation_debug_type_names_enabled() -> i32:
    let raw = with_getenv_str("WITH_DEBUG_TYPE_NAMES")
    if raw.len() == 0:
        return 0
    if raw == "0":
        return 0
    1

fn compilation_dump_type_names(stage: str, pool: AstPool, intern: InternPool):
    if compilation_debug_type_names_enabled() == 0:
        return
    with_eprint(f"[type-names] stage={stage} decls={pool.decl_count()}")
    for di in 0..pool.decl_count():
        let decl = pool.get_decl(di)
        if pool.kind(decl) != NodeKind.NK_TYPE_DECL:
            continue
        let sub_kind = type_decl_sub_kind(pool.get_data2(decl))
        var kind_name = "alias"
        if sub_kind == TypeDeclKind.Struct:
            kind_name = "struct"
        else if sub_kind == TypeDeclKind.Enum:
            kind_name = "enum"
        else if sub_kind == TypeDeclKind.DiscEnum:
            kind_name = "disc_enum"
        else if sub_kind == TypeDeclKind.Distinct:
            kind_name = "distinct"
        let name_sym = pool.get_data0(decl)
        let name = intern.resolve(name_sym)
        let msg = f"[type-names] {stage} decl={di} node={decl as i32} kind={kind_name} name_sym={name_sym} name={name}"
        with_eprint(msg)

fn compilation_find_fn_decl_index(pool: AstPool, fn_sym: i32) -> i32:
    for di in 0..pool.decl_count():
        let decl = pool.get_decl(di)
        if pool.kind(decl) != NodeKind.NK_FN_DECL:
            continue
        if pool.get_data0(decl) == fn_sym:
            return di
    -1

fn compilation_mir_error_span(zcu: Zcu, pool: AstPool, fn_sym: i32, raw_span: i32) -> Span:
    let decl_index = compilation_find_fn_decl_index(pool, fn_sym)
    if decl_index >= 0:
        let decl = pool.get_decl(decl_index)
        let file_id = zcu.decl_source_file_id_frontend(decl_index)
        let start = if raw_span > 0: raw_span else: pool.get_start(decl)
        var end = if raw_span > 0: raw_span + 1 else: pool.get_end(decl)
        if end <= start:
            end = start + 1
        return Span { file: file_id, start: start, end: end }
    let start = if raw_span > 0: raw_span else: 0
    Span { file: 0, start: start, end: start + 1 }

fn compilation_bool_digit(value: bool) -> str:
    if value: "1" else: "0"

fn compilation_escape_with_string(value: str) -> str:
    var out = ""
    for i in 0..value.len() as i32:
        let ch = value.byte_at(i as i64)
        if ch == 92:
            out = out ++ "\\\\"
        else if ch == 34:
            out = out ++ "\\\""
        else if ch == 10:
            out = out ++ "\\n"
        else if ch == 13:
            out = out ++ "\\r"
        else if ch == 9:
            out = out ++ "\\t"
        else:
            out = out ++ value.slice(i as i64, (i + 1) as i64)
    out

fn compilation_split_escaped_fields(line: str) -> Vec[str]:
    let fields: Vec[str] = Vec.new()
    var cur = ""
    var escaped = false
    for i in 0..line.len() as i32:
        let ch = line.byte_at(i as i64)
        if escaped:
            if ch == 110:
                cur = cur ++ "\n"
            else if ch == 116:
                cur = cur ++ "\t"
            else if ch == 114:
                cur = cur ++ "\r"
            else:
                cur = cur ++ line.slice(i as i64, (i + 1) as i64)
            escaped = false
        else if ch == 92:
            escaped = true
        else if ch == 9:
            fields.push(cur)
            cur = ""
        else:
            cur = cur ++ line.slice(i as i64, (i + 1) as i64)
    fields.push(cur)
    fields

fn compilation_split_nonempty_lines(text: str) -> Vec[str]:
    let lines: Vec[str] = Vec.new()
    var start = 0
    for i in 0..text.len() as i32:
        if text.byte_at(i as i64) == 10:
            if i > start:
                lines.push(text.slice(start as i64, i as i64))
            start = i + 1
    if start < text.len() as i32:
        lines.push(text.slice(start as i64, text.len()))
    lines

fn compilation_parse_i32(text: str) -> i32:
    var sign = 1
    var i = 0
    if text.len() > 0 and text.byte_at(0) == 45:
        sign = -1
        i = 1
    var value = 0
    while i < text.len() as i32:
        let ch = text.byte_at(i as i64)
        if ch < 48 or ch > 57:
            break
        value = value * 10 + (ch - 48)
        i = i + 1
    value * sign

fn compilation_decl_index_for_node(pool: AstPool, node: NodeId) -> i32:
    for di in 0..pool.decl_count():
        if pool.get_decl(di) == node:
            return di
    -1

fn compilation_relative_source_path(root: str, path: str) -> str:
    if root.len() == 0:
        return path
    let prefix = if root.ends_with("/"): root else: root ++ "/"
    if path.starts_with(prefix):
        return path.slice(prefix.len(), path.len())
    path

fn compilation_module_import_name(root: str, path: str) -> str:
    var rel = compilation_relative_source_path(root, path)
    if rel.ends_with(".w"):
        rel = rel.slice(0, rel.len() - 2)
    var out = ""
    for i in 0..rel.len() as i32:
        let ch = rel.byte_at(i as i64)
        if ch == 47:
            out = out ++ "."
        else:
            out = out ++ rel.slice(i as i64, (i + 1) as i64)
    out

fn compilation_span_file_id_for_path(zcu: Zcu, path: str) -> i32:
    if path == zcu.current_source_path:
        return 0
    for di in 0..zcu.last_sema.ast.decl_count():
        if zcu.decl_source_path_frontend(di) == path:
            return zcu.decl_source_file_id_frontend(di)
    0

fn compilation_type_decl_is_pub(pool: AstPool, extra_start: i32, sub_kind: i32) -> bool:
    if sub_kind == TypeDeclKind.Struct or sub_kind == TypeDeclKind.Union:
        let field_count = pool.get_extra(extra_start)
        let vis_idx = extra_start + 1 + field_count * 4
        return pool.get_extra(vis_idx) == Visibility.Public
    if sub_kind == TypeDeclKind.Enum:
        var ep = extra_start + 1
        let variant_count = pool.get_extra(extra_start)
        for _ in 0..variant_count:
            ep = ep + 1
            let payload_count = pool.get_extra(ep)
            ep = ep + 1 + payload_count
        return pool.get_extra(ep) == Visibility.Public
    if sub_kind == TypeDeclKind.DiscEnum:
        var ep = extra_start + 2
        let variant_count = pool.get_extra(extra_start + 1)
        for _ in 0..variant_count:
            ep = ep + 1
            ep = ep + 1
            let payload_count = pool.get_extra(ep)
            ep = ep + 1 + payload_count
        return pool.get_extra(ep) == Visibility.Public
    pool.get_extra(extra_start + 1) == Visibility.Public

fn compilation_type_decl_kind_name(sub_kind: i32) -> str:
    if sub_kind == TypeDeclKind.Struct:
        return "struct"
    if sub_kind == TypeDeclKind.Enum:
        return "enum"
    if sub_kind == TypeDeclKind.DiscEnum:
        return "disc_enum"
    if sub_kind == TypeDeclKind.Alias:
        return "alias"
    if sub_kind == TypeDeclKind.Distinct:
        return "distinct"
    if sub_kind == TypeDeclKind.Opaque:
        return "opaque"
    if sub_kind == TypeDeclKind.Union:
        return "union"
    "unknown"

// Transitional orchestration root:
// owns compiler-facing config/Zcu state while reusing Driver execution per call.
// This removes long-lived Driver field ownership from Compilation.
type Compilation {
    zcu: Zcu,
    config: CompilationConfig,
    cli_diag_gen_starts: Vec[i32],
    cli_diag_gen_ends: Vec[i32],
    cli_diag_source_names: Vec[str],
    cli_diag_source_texts: Vec[str],
    compiler_hook_emitted_source: str,
    last_link_command_available: i32,
    last_link_command: LinkStageCommand,
    last_link_rc: i32,
}

type CompilationBinaryLinkPlan {
    ok: bool,
    obj_path: str,
    bin_path: str,
    command: LinkStageCommand,
}

fn Compilation.init -> Compilation:
    compilation_debug_init("Compilation.init:start")
    let zcu: Zcu = Zcu.init()
    compilation_debug_init("Compilation.init:zcu_ready")
    Compilation {
        zcu: zcu,
        config: compilation_config_default(),
        cli_diag_gen_starts: Vec.new(),
        cli_diag_gen_ends: Vec.new(),
        cli_diag_source_names: Vec.new(),
        cli_diag_source_texts: Vec.new(),
        compiler_hook_emitted_source: "",
        last_link_command_available: 0,
        last_link_command: link_stage_empty_command(),
        last_link_rc: 0,
    }

fn Compilation.configure(self: Compilation, opt_level: i32, no_std: bool, alloc_mode: bool):
    self.config = compilation_config_from_cli(opt_level, no_std, alloc_mode, self.config.prelude_mode)
    var zcu = self.zcu
    zcu.set_prelude_mode(self.config.prelude_mode)
    self.zcu = zcu

fn Compilation.configure_options(self: Compilation, options: BuildCommandOptions):
    self.configure(options.opt_level, options.no_std, options.alloc_mode)
    self.set_prelude_mode(options.prelude_mode)
    self.set_debug_info(options.debug_info)
    self.set_compiler_hooks_enabled(options.compiler_hooks_enabled)

fn Compilation.set_prelude_mode(self: Compilation, mode: i32):
    var cfg = self.config
    cfg.prelude_mode = compilation_normalize_prelude_mode(mode)
    self.config = cfg
    var zcu = self.zcu
    zcu.set_prelude_mode(cfg.prelude_mode)
    self.zcu = zcu

fn Compilation.set_debug_info(self: Compilation, enabled: bool):
    var cfg = self.config
    cfg.debug_info = enabled
    self.config = cfg

fn Compilation.set_compiler_hooks_enabled(self: Compilation, enabled: bool):
    var cfg = self.config
    cfg.compiler_hooks_enabled = enabled
    self.config = cfg

fn Compilation.set_tool_mode_entry_path(self: Compilation, path: str):
    var cfg = self.config
    cfg.tool_mode_entry_path = path
    self.config = cfg
    var zcu = self.zcu
    zcu.tool_mode_entry_path = path
    self.zcu = zcu

fn Compilation.add_cli_diag_mapping(self: Compilation, gen_start: i32, gen_end: i32, source_name: str, source_text: str) -> void:
    self.cli_diag_gen_starts.push(gen_start)
    self.cli_diag_gen_ends.push(gen_end)
    self.cli_diag_source_names.push(source_name)
    self.cli_diag_source_texts.push(source_text)

fn Compilation.apply_cli_diag_mappings(self: Compilation, zcu: Zcu) -> Zcu:
    zcu.clear_cli_diag_mappings()
    for i in 0..self.cli_diag_gen_starts.len() as i32:
        zcu.add_cli_diag_mapping(
            self.cli_diag_gen_starts.get(i as i64),
            self.cli_diag_gen_ends.get(i as i64),
            self.cli_diag_source_names.get(i as i64),
            self.cli_diag_source_texts.get(i as i64),
        )
    zcu

fn Compilation.compile_file(self: Compilation, path: str) -> AstPool:
    compilation_debug_init("Compilation.compile_file:start " ++ path)
    var zcu = self.zcu
    let pool = zcu.compile_file_frontend(path)
    self.zcu = zcu
    compilation_debug_init(f"Compilation.compile_file:done decls={pool.decl_count()}")
    pool

fn Compilation.compile_file_with_config(self: Compilation, path: str, cfg: ProjectConfig) -> AstPool:
    compilation_debug_init("Compilation.compile_file_with_config:start " ++ path)
    var zcu = self.zcu
    let pool = zcu.compile_file_frontend_with_config(path, cfg)
    self.zcu = zcu
    compilation_debug_init(f"Compilation.compile_file_with_config:done decls={pool.decl_count()}")
    pool

fn Compilation.compile_entry_file(self: Compilation, path: str) -> AstPool:
    compilation_debug_init("Compilation.compile_entry_file:start " ++ path)
    var zcu = self.zcu
    let pool = zcu.compile_file_frontend_entry(path)
    self.zcu = zcu
    compilation_debug_init(f"Compilation.compile_entry_file:done decls={pool.decl_count()}")
    pool

fn Compilation.compile_entry_file_with_config(self: Compilation, path: str, cfg: ProjectConfig) -> AstPool:
    compilation_debug_init("Compilation.compile_entry_file_with_config:start " ++ path)
    var zcu = self.zcu
    let pool = zcu.compile_file_frontend_entry_with_config(path, cfg)
    self.zcu = zcu
    compilation_debug_init(f"Compilation.compile_entry_file_with_config:done decls={pool.decl_count()}")
    pool

fn Compilation.resolve_file(self: Compilation, path: str, emit_resolve_diags: bool) -> ResolveResult:
    let _ = emit_resolve_diags
    let _ = self.compile_file(path)
    self.zcu.last_resolved

fn Compilation.dump_project_info_file(self: Compilation, source_path: str) -> str:
    let pool = self.compile_file(source_path)
    if pool.decl_count() == 0:
        return ""
    self.dump_project_info(pool)

fn Compilation.dump_project_info(self: Compilation, pool: AstPool) -> str:
    let zcu = self.zcu
    var function_count = 0
    var type_count = 0
    for di in 0..pool.decl_count():
        let decl = pool.get_decl(di)
        let kind = pool.kind(decl)
        if kind == NodeKind.NK_FN_DECL:
            function_count = function_count + 1
        else if kind == NodeKind.NK_TYPE_DECL:
            type_count = type_count + 1

    var out = f"project_info modules={zcu.last_resolved.modules.len() as i32} functions={function_count} types={type_count}\n"
    for mi in 0..zcu.last_resolved.modules.len() as i32:
        let mod = zcu.last_resolved.modules.get(mi as i64)
        out = out ++ f"module path={mod.path} file={mod.file_id} decls={mod.decl_count}\n"

    for di in 0..pool.decl_count():
        let decl = pool.get_decl(di)
        let kind = pool.kind(decl)
        let path = zcu.decl_source_path_frontend(di)
        if kind == NodeKind.NK_FN_DECL:
            let name = zcu.pool.resolve(pool.get_data0(decl))
            let flags = pool.get_data2(decl)
            let is_pub = (flags / FnFlags.PUB) % 2 == 1
            let meta = pool.find_fn_meta(decl)
            var param_count = 0
            var return_type = "void"
            if meta >= 0:
                param_count = pool.fn_meta_param_count(meta)
                let ret_node = pool.fn_meta_ret(meta)
                if ret_node != 0:
                    return_type = render_type_expr(pool, zcu.pool, ret_node as NodeId)
            out = out ++ f"function path={path} name={name} pub={compilation_bool_digit(is_pub)} params={param_count} return={return_type} span={pool.get_start(decl)}..{pool.get_end(decl)}\n"
        else if kind == NodeKind.NK_TYPE_DECL:
            let name = zcu.pool.resolve(pool.get_data0(decl))
            let packed = pool.get_data2(decl)
            let sub_kind = type_decl_sub_kind(packed)
            let is_pub = compilation_type_decl_is_pub(pool, pool.get_data1(decl), sub_kind)
            let kind_name = compilation_type_decl_kind_name(sub_kind)
            out = out ++ f"type path={path} name={name} pub={compilation_bool_digit(is_pub)} kind={kind_name} span={pool.get_start(decl)}..{pool.get_end(decl)}\n"
    out

fn Compilation.project_info_source(self: Compilation, pool: AstPool) -> str:
    let zcu = self.zcu
    var out = "fn __with_compiler_hook_project_info() -> ProjectInfo:\n"
    out = out ++ "    var project = ProjectInfo.new()\n"
    for mi in 0..zcu.last_resolved.modules.len() as i32:
        let mod = zcu.last_resolved.modules.get(mi as i64)
        let module_name = compilation_module_import_name(zcu.project_config.root_dir, mod.path)
        out = out ++ "    project = project.add_module(ModuleInfo.new(\"" ++ compilation_escape_with_string(module_name) ++ "\", \"" ++ compilation_escape_with_string(mod.path) ++ "\"))\n"

    for di in 0..pool.decl_count():
        let decl = pool.get_decl(di)
        let kind = pool.kind(decl)
        let path = zcu.decl_source_path_frontend(di)
        let module_name = compilation_module_import_name(zcu.project_config.root_dir, path)
        let loc = "SourceLocation.new(\"" ++ compilation_escape_with_string(path) ++ "\", " ++ f"{pool.get_start(decl)}" ++ ", " ++ f"{pool.get_end(decl)}" ++ ")"
        if kind == NodeKind.NK_FN_DECL:
            let name = zcu.pool.resolve(pool.get_data0(decl))
            let flags = pool.get_data2(decl)
            let is_pub = (flags / FnFlags.PUB) % 2 == 1
            let meta = pool.find_fn_meta(decl)
            var param_count = 0
            var return_type = "void"
            if meta >= 0:
                param_count = pool.fn_meta_param_count(meta)
                let ret_node = pool.fn_meta_ret(meta)
                if ret_node != 0:
                    return_type = render_type_expr(pool, zcu.pool, ret_node as NodeId)
            out = out ++ "    project = project.add_function(FunctionInfo.new(\"" ++ compilation_escape_with_string(module_name) ++ "\", \"" ++ compilation_escape_with_string(name) ++ "\", " ++ (if is_pub: "true" else: "false") ++ ", false, " ++ f"{param_count}" ++ ", \"" ++ compilation_escape_with_string(return_type) ++ "\", " ++ loc ++ "))\n"
        else if kind == NodeKind.NK_TYPE_DECL:
            let name = zcu.pool.resolve(pool.get_data0(decl))
            let packed = pool.get_data2(decl)
            let sub_kind = type_decl_sub_kind(packed)
            let is_pub = compilation_type_decl_is_pub(pool, pool.get_data1(decl), sub_kind)
            let kind_name = compilation_type_decl_kind_name(sub_kind)
            out = out ++ "    project = project.add_type(TypeInfo.new(\"" ++ compilation_escape_with_string(module_name) ++ "\", \"" ++ compilation_escape_with_string(name) ++ "\", " ++ (if is_pub: "true" else: "false") ++ ", false, \"" ++ kind_name ++ "\", " ++ loc ++ "))\n"
    out ++ "    project\n"

fn compilation_compiler_hook_arg_for_type(pool: AstPool, intern: InternPool, type_node: i32) -> str:
    let rendered = render_type_expr(pool, intern, type_node as NodeId)
    if rendered == "ProjectInfo":
        return "project"
    if rendered == "Diagnostics":
        return "diagnostics"
    if rendered == "SourceEmitter":
        return "source_emitter"
    ""

fn compilation_compiler_hook_call_args(pool: AstPool, intern: InternPool, hook_node: NodeId) -> str:
    let meta = pool.find_fn_meta(hook_node)
    if meta < 0:
        return ""
    let param_start = pool.fn_meta_param_start(meta)
    let param_count = pool.fn_meta_param_count(meta)
    var out = ""
    for pi in 0..param_count:
        if pi > 0:
            out = out ++ ", "
        let type_node = pool.fn_param_type(param_start, pi)
        let arg_name = compilation_compiler_hook_arg_for_type(pool, intern, type_node)
        if arg_name.len() == 0:
            return ""
        out = out ++ arg_name
    out

fn Compilation.compiler_hook_runner_source(self: Compilation, pool: AstPool, source_path: str, diag_path: str, emitted_source_path: str, token: str) -> str:
    let zcu = self.zcu
    let root = if zcu.project_config.root_dir.len() > 0: zcu.project_config.root_dir else: frontend_dirname(source_path)
    let hook_count = pool.compiler_hook_count()
    var out = "use std.compiler\n"
    let imported: HashMap[str, i32] = HashMap.new()
    for hi in 0..hook_count:
        let hook_node = pool.compiler_hook_node(hi)
        let di = compilation_decl_index_for_node(pool, hook_node)
        if di < 0:
            continue
        let path = zcu.decl_source_path_frontend(di)
        let import_name = compilation_module_import_name(root, path)
        if import_name.len() > 0 and not imported.contains(import_name):
            imported.insert(import_name, 1)
            out = out ++ "use " ++ import_name ++ ".*\n"
    out = out ++ "\n"
    out = out ++ self.project_info_source(pool)
    out = out ++ "\nfn main:\n"
    out = out ++ "    let project = __with_compiler_hook_project_info()\n"
    out = out ++ "    let diagnostics = Diagnostics.__driver_new(\"" ++ compilation_escape_with_string(token) ++ "\", \"" ++ compilation_escape_with_string(diag_path) ++ "\")\n"
    out = out ++ "    let source_emitter = SourceEmitter.__driver_new(\"" ++ compilation_escape_with_string(token) ++ "\", \"" ++ compilation_escape_with_string(emitted_source_path) ++ "\")\n"
    for hi2 in 0..hook_count:
        let hook_node = pool.compiler_hook_node(hi2)
        let phase_name = zcu.pool.resolve(pool.compiler_hook_phase_at(hi2))
        if phase_name != "after_typecheck":
            continue
        let hook_name = zcu.pool.resolve(pool.get_data0(hook_node))
        let call_args = compilation_compiler_hook_call_args(pool, zcu.pool, hook_node)
        out = out ++ "    " ++ hook_name ++ "(" ++ call_args ++ ")\n"
    out

fn Compilation.emit_compiler_hook_diagnostics(self: Compilation, diag_text: str) -> i32:
    if diag_text.len() == 0:
        return 0
    var emitted = 0
    var zcu = self.zcu
    let lines = compilation_split_nonempty_lines(diag_text)
    for li in 0..lines.len() as i32:
        let fields = compilation_split_escaped_fields(lines.get(li as i64))
        if fields.len() != 5:
            continue
        if fields.get(0) != "error":
            continue
        let path = fields.get(1)
        let start = compilation_parse_i32(fields.get(2))
        let end = compilation_parse_i32(fields.get(3))
        let message = fields.get(4)
        let file_id = compilation_span_file_id_for_path(zcu, path)
        zcu.diagnostics.emit(Diagnostic.err(message, Span { file: file_id, start, end }))
        emitted = emitted + 1
    self.zcu = zcu
    if emitted > 0:
        self.zcu.render_all_diagnostics_frontend()
    emitted

fn Compilation.run_after_typecheck_hooks(self: Compilation, pool: AstPool, source_path: str) -> bool:
    self.compiler_hook_emitted_source = ""
    if pool.compiler_hook_count() == 0:
        return true
    if not self.config.compiler_hooks_enabled:
        return true
    let zcu = self.zcu
    let root = if zcu.project_config.root_dir.len() > 0: zcu.project_config.root_dir else: frontend_dirname(source_path)
    let tmp_dir = root ++ "/out/tmp"
    if with_fs_mkdir_p(tmp_dir) != 0:
        with_eprint("error: could not create compiler hook temp directory: " ++ tmp_dir)
        return false
    let stamp = f"{with_getpid()}.{with_clock_nanos()}"
    let runner_path = root ++ "/__with_compiler_hook_runner." ++ stamp ++ ".w"
    let runner_bin = tmp_dir ++ "/compiler-hook-runner." ++ stamp
    let diag_path = tmp_dir ++ "/compiler-hook-diags." ++ stamp ++ ".txt"
    let emitted_source_path = tmp_dir ++ "/compiler-hook-source." ++ stamp ++ ".w"
    let capability_token = "with-compiler-hook:" ++ stamp
    if with_fs_write_file(diag_path, "") != 0:
        with_eprint("error: could not initialize compiler hook diagnostics")
        return false
    if with_fs_write_file(emitted_source_path, "") != 0:
        let _remove_diag_init = with_fs_remove_file(diag_path)
        with_eprint("error: could not initialize compiler hook emitted source")
        return false
    let runner_source = self.compiler_hook_runner_source(pool, source_path, diag_path, emitted_source_path, capability_token)
    if with_fs_write_file(runner_path, runner_source) != 0:
        let _ = with_fs_remove_file(diag_path)
        let _remove_emitted_init = with_fs_remove_file(emitted_source_path)
        with_eprint("error: could not write compiler hook runner")
        return false
    var runner_comp = Compilation.init()
    runner_comp.configure(self.config.opt_level, self.config.no_std, self.config.alloc_mode)
    runner_comp.set_prelude_mode(self.config.prelude_mode)
    runner_comp.set_debug_info(self.config.debug_info)
    runner_comp.set_compiler_hooks_enabled(false)
    runner_comp.set_tool_mode_entry_path(runner_path)
    let built_runner = runner_comp.build_binary_to_path(runner_path, runner_bin)
    let _remove_runner_source = with_fs_remove_file(runner_path)
    if built_runner == "":
        let _remove_diag = with_fs_remove_file(diag_path)
        let _remove_emitted = with_fs_remove_file(emitted_source_path)
        with_eprint("error: compiler hook runner compilation failed")
        return false
    let old_capability_token = with_getenv_str("WITH_TOOL_CAPABILITY_TOKEN")
    let _set_capability_token = with_setenv_str("WITH_TOOL_CAPABILITY_TOKEN", capability_token)
    let rc = with_exec_binary(built_runner)
    let _restore_capability_token = with_setenv_str("WITH_TOOL_CAPABILITY_TOKEN", old_capability_token)
    let diag_text = with_fs_read_file(diag_path)
    let emitted_source = with_fs_read_file(emitted_source_path)
    let _remove_diag_after = with_fs_remove_file(diag_path)
    let _remove_emitted_after = with_fs_remove_file(emitted_source_path)
    let _remove_runner_bin = with_fs_remove_file(built_runner)
    let _remove_runner_obj = with_fs_remove_file(built_runner ++ ".o")
    let _remove_runner_dsym = with_fs_remove_dir(built_runner ++ ".dSYM")
    let emitted = self.emit_compiler_hook_diagnostics(diag_text)
    if emitted > 0:
        return false
    if rc != 0:
        with_eprint(f"error: compiler hook execution failed with exit code {rc}")
        return false
    self.compiler_hook_emitted_source = emitted_source
    true

fn Compilation.prepare_pool_after_typecheck_hooks(self: Compilation, pool: AstPool, source_path: str) -> AstPool:
    if pool.decl_count() == 0:
        return pool
    if not self.run_after_typecheck_hooks(pool, source_path):
        return AstPool.new()
    if self.compiler_hook_emitted_source.len() == 0:
        return pool
    let base_source = if self.zcu.current_source_text.len() > 0: self.zcu.current_source_text else: with_fs_read_file(source_path)
    let cfg = self.zcu.project_config
    let combined = base_source ++ "\n\n// <with compiler hook emitted source>\n" ++ self.compiler_hook_emitted_source
    self.compiler_hook_emitted_source = ""
    self.compile_source_text_with_config(source_path, combined, cfg)

fn Compilation.has_errors(self: Compilation) -> bool:
    self.zcu.diagnostics.has_errors()

fn Compilation.get_pool(self: Compilation) -> InternPool:
    self.zcu.pool

fn Compilation.emit_ir(self: Compilation, pool: AstPool) -> bool:
    let prepared_pool = self.prepare_pool_after_typecheck_hooks(pool, self.zcu.current_source_path)
    if prepared_pool.decl_count() == 0:
        return false
    if not self.ensure_codegen_mir(prepared_pool):
        return false
    self.zcu.emit_ir_backend(self.active_pool(prepared_pool), self.config.opt_level)

fn compilation_cleanup_build_products(obj_path: str, bin_path: str):
    if obj_path.len() > 0:
        let _ = ("rm -f " ++ obj_path) |> with_system
    if bin_path.len() > 0:
        let _ = ("rm -f " ++ bin_path) |> with_system
        let _ = ("rm -rf " ++ bin_path ++ ".dSYM") |> with_system

fn compilation_binary_link_plan_fail() -> CompilationBinaryLinkPlan:
    CompilationBinaryLinkPlan {
        ok: false,
        obj_path: "",
        bin_path: "",
        command: link_stage_empty_command(),
    }

fn Compilation.build_binary(self: Compilation, source_path: str) -> str:
    self.build_binary_to_path(source_path, link_stage_output_path_for_source(source_path))

fn Compilation.build_binary_from_source(self: Compilation, source_path: str, source_text: str) -> str:
    self.build_binary_from_source_to_path(source_path, source_text, link_stage_output_path_for_source(source_path))

fn Compilation.build_binary_at(self: Compilation, source_path: str, output_dir: str) -> str:
    let stem = link_stage_source_stem(source_path)
    self.build_binary_to_path(source_path, output_dir ++ "/" ++ stem)

fn Compilation.compile_source_text(self: Compilation, source_path: str, source_text: str) -> AstPool:
    var zcu = self.zcu
    let source_dir = frontend_dirname(source_path)
    zcu.reset_for_new_invocation(source_dir, source_path, "")
    zcu.project_config = project_config_load_for_source(source_path)
    if zcu.project_config.manifest_error.len() > 0:
        with_eprint("error: invalid with.toml: " ++ zcu.project_config.manifest_error)
        self.zcu = zcu
        return AstPool.new()
    zcu.set_current_source(source_dir, source_path, source_text)
    let pool = zcu.compile_source_frontend(source_text, source_path, 0)
    self.zcu = zcu
    pool

fn Compilation.compile_source_text_with_config(self: Compilation, source_path: str, source_text: str, cfg: ProjectConfig) -> AstPool:
    var zcu = self.zcu
    let source_dir = frontend_dirname(source_path)
    zcu.reset_for_new_invocation(source_dir, source_path, "")
    zcu.project_config = cfg
    if zcu.project_config.manifest_error.len() > 0:
        with_eprint("error: invalid with.toml: " ++ zcu.project_config.manifest_error)
        self.zcu = zcu
        return AstPool.new()
    zcu.set_current_source(source_dir, source_path, source_text)
    let pool = zcu.compile_source_frontend(source_text, source_path, 0)
    self.zcu = zcu
    pool

fn Compilation.compile_entry_source_text(self: Compilation, source_path: str, source_text: str) -> AstPool:
    var zcu = self.zcu
    let source_dir = frontend_dirname(source_path)
    zcu.reset_for_new_invocation(source_dir, source_path, "")
    zcu.project_config = project_config_load_for_source(source_path)
    if zcu.project_config.manifest_error.len() > 0:
        with_eprint("error: invalid with.toml: " ++ zcu.project_config.manifest_error)
        self.zcu = zcu
        return AstPool.new()
    zcu.set_current_source(source_dir, source_path, source_text)
    zcu = self.apply_cli_diag_mappings(zcu)
    let pool = zcu.compile_source_frontend_mode(source_text, source_path, 0, 1)
    self.zcu = zcu
    pool

fn Compilation.prepare_binary_link_from_pool(self: Compilation, pool: AstPool, source_path: str, obj_path: str, bin_path: str) -> CompilationBinaryLinkPlan:
    self.last_link_command_available = 0
    self.last_link_command = link_stage_empty_command()
    self.last_link_rc = 0
    compilation_debug_init(f"build_binary_to_path:compiled {source_path} decls={pool.decl_count()}")
    if pool.decl_count() == 0:
        return compilation_binary_link_plan_fail()
    let prepared_pool = self.prepare_pool_after_typecheck_hooks(pool, source_path)
    if prepared_pool.decl_count() == 0:
        compilation_cleanup_build_products(obj_path, bin_path)
        return compilation_binary_link_plan_fail()
    if not self.ensure_codegen_mir(prepared_pool):
        compilation_debug_init("build_binary_to_path:ensure_codegen_mir FAILED")
        compilation_cleanup_build_products(obj_path, bin_path)
        return compilation_binary_link_plan_fail()
    let active_pool: AstPool = self.active_pool(prepared_pool)
    let opt_level = self.config.opt_level
    let requires_async_runtime = self.zcu.last_async_mir_module.requires_async_runtime()
    compilation_debug_pool_flow("build_binary_to_path:after_codegen", self.zcu.pool, active_pool, self.zcu.last_sema)
    compilation_debug_init("build_binary_to_path:compile_to_object_backend")
    let backend_rc = self.zcu.compile_to_object_backend(active_pool, opt_level, obj_path, self.config.debug_info, false)
    if backend_rc != 0:
        compilation_debug_init(f"build_binary_to_path:backend FAILED rc={backend_rc}")
        compilation_cleanup_build_products(obj_path, bin_path)
        return compilation_binary_link_plan_fail()
    compilation_debug_init("build_binary_to_path:linking")
    // Merge dep_link_libs from project config into link libs
    var all_link_libs = self.zcu.last_link_lib_names
    for dli in 0..self.zcu.project_config.dep_link_libs.len() as i32:
        all_link_libs.push(self.zcu.project_config.dep_link_libs.get(dli as i64))
    let link_plan = link_stage_link_object_to_binary_plan(obj_path, bin_path, all_link_libs, self.zcu.project_config.link_search_paths, requires_async_runtime)
    if not link_plan.ok:
        compilation_cleanup_build_products(obj_path, bin_path)
        return compilation_binary_link_plan_fail()
    CompilationBinaryLinkPlan {
        ok: true,
        obj_path,
        bin_path,
        command: link_plan.command,
    }

fn Compilation.execute_binary_link_plan(self: Compilation, plan: CompilationBinaryLinkPlan) -> str:
    if not plan.ok:
        return ""
    let link_result = compilation_execute_binary_link_plan(self.config.debug_info, plan)
    self.last_link_command_available = 1
    self.last_link_command = link_result.command
    self.last_link_rc = link_result.rc
    if not link_result.ok:
        return ""
    plan.bin_path

fn compilation_execute_binary_link_plan(debug_info: bool, plan: CompilationBinaryLinkPlan) -> LinkStageResult:
    if not plan.ok:
        return link_stage_result_fail()
    let t_link = profile_now()
    let link_result = link_stage_result_for_command(plan.command)
    if not link_result.ok:
        compilation_debug_init("build_binary_to_path:link FAILED")
        compilation_cleanup_build_products(plan.obj_path, plan.bin_path)
        return link_result
    if profile_enabled():
        profile_emit("link", t_link, "")
    if debug_info:
        let t_dsym = profile_now()
        let _ = ("dsymutil " ++ plan.bin_path ++ " 2>/dev/null") |> with_system
        if profile_enabled():
            profile_emit("dsymutil", t_dsym, "")
    let _ = ("rm -f " ++ plan.obj_path) |> with_system
    link_result

fn Compilation.finish_binary_from_pool(self: Compilation, pool: AstPool, source_path: str, obj_path: str, bin_path: str) -> str:
    let link_plan = self.prepare_binary_link_from_pool(pool, source_path, obj_path, bin_path)
    self.execute_binary_link_plan(link_plan)

fn Compilation.emit_object_to_path(self: Compilation, source_path: str, obj_path: str) -> str:
    let output_dir = link_stage_dirname(obj_path)
    let _ = ("mkdir -p " ++ output_dir) |> with_system

    let pool = self.compile_file(source_path)
    if pool.decl_count() == 0:
        return ""
    let prepared_pool = self.prepare_pool_after_typecheck_hooks(pool, source_path)
    if prepared_pool.decl_count() == 0:
        return ""
    if not self.ensure_codegen_mir(prepared_pool):
        return ""
    let active_pool: AstPool = self.active_pool(prepared_pool)
    let opt_level = self.config.opt_level
    let backend_rc = self.zcu.compile_to_object_backend(active_pool, opt_level, obj_path, self.config.debug_info, true)
    if backend_rc != 0:
        let _ = ("rm -f " ++ obj_path) |> with_system
        return ""
    obj_path

fn Compilation.emit_object_to_path_with_build_settings(self: Compilation, source_path: str, obj_path: str, include_paths: Vec[str], defines: Vec[str], link_libs: Vec[str]) -> str:
    let output_dir = link_stage_dirname(obj_path)
    let _ = ("mkdir -p " ++ output_dir) |> with_system

    var cfg = project_config_load_for_source(source_path)
    for ii in 0..include_paths.len() as i32:
        cfg.c_import_include_paths.push(include_paths.get(ii as i64))
    for di in 0..defines.len() as i32:
        cfg.c_import_defines.push(defines.get(di as i64))
    for li in 0..link_libs.len() as i32:
        cfg.dep_link_libs.push(link_libs.get(li as i64))
    let pool = self.compile_file_with_config(source_path, cfg)
    if pool.decl_count() == 0:
        return ""
    if not self.ensure_codegen_mir(pool):
        return ""
    let active_pool: AstPool = self.active_pool(pool)
    let opt_level = self.config.opt_level
    let backend_rc = self.zcu.compile_to_object_backend(active_pool, opt_level, obj_path, self.config.debug_info, true)
    if backend_rc != 0:
        let _ = ("rm -f " ++ obj_path) |> with_system
        return ""
    obj_path

fn Compilation.emit_archive_to_path_with_build_settings(self: Compilation, source_path: str, ar_path: str, include_paths: Vec[str], defines: Vec[str], link_libs: Vec[str]) -> str:
    if ar_path.len() == 0:
        return ""
    let output_dir = link_stage_dirname(ar_path)
    let _ = ("mkdir -p " ++ output_dir) |> with_system
    let obj_path = ar_path ++ ".o"
    let obj = self.emit_object_to_path_with_build_settings(source_path, obj_path, include_paths, defines, link_libs)
    if obj == "":
        return ""
    let ar = link_stage_make_archive_to_path(obj, ar_path)
    let _ = ("rm -f " ++ obj) |> with_system
    ar

fn Compilation.build_binary_to_path(self: Compilation, source_path: str, bin_path: str) -> str:
    if bin_path.len() == 0:
        return self.build_binary(source_path)
    let obj_path = bin_path ++ ".o"
    let output_dir = link_stage_dirname(bin_path)
    let _ = ("mkdir -p " ++ output_dir) |> with_system
    let _ = ("rm -rf " ++ bin_path ++ ".dSYM") |> with_system

    let pool = self.compile_entry_file(source_path)
    self.finish_binary_from_pool(pool, source_path, obj_path, bin_path)

fn Compilation.build_binary_to_path_with_build_settings(self: Compilation, source_path: str, bin_path: str, include_paths: Vec[str], defines: Vec[str], link_libs: Vec[str]) -> str:
    if bin_path.len() == 0:
        return self.build_binary_to_path(source_path, bin_path)
    let obj_path = bin_path ++ ".o"
    let output_dir = link_stage_dirname(bin_path)
    let _ = ("mkdir -p " ++ output_dir) |> with_system
    let _ = ("rm -rf " ++ bin_path ++ ".dSYM") |> with_system

    var cfg = project_config_load_for_source(source_path)
    for ii in 0..include_paths.len() as i32:
        cfg.c_import_include_paths.push(include_paths.get(ii as i64))
    for di in 0..defines.len() as i32:
        cfg.c_import_defines.push(defines.get(di as i64))
    for li in 0..link_libs.len() as i32:
        cfg.dep_link_libs.push(link_libs.get(li as i64))
    let pool = self.compile_entry_file_with_config(source_path, cfg)
    self.finish_binary_from_pool(pool, source_path, obj_path, bin_path)

fn Compilation.build_binary_to_path_with_link_libs(self: Compilation, source_path: str, bin_path: str, link_libs: Vec[str]) -> str:
    let include_paths: Vec[str] = Vec.new()
    let defines: Vec[str] = Vec.new()
    self.build_binary_to_path_with_build_settings(source_path, bin_path, include_paths, defines, link_libs)

fn Compilation.build_binary_from_source_to_path(self: Compilation, source_path: str, source_text: str, bin_path: str) -> str:
    if bin_path.len() == 0:
        return self.build_binary_from_source(source_path, source_text)
    let obj_path = bin_path ++ ".o"
    let output_dir = link_stage_dirname(bin_path)
    let _ = ("mkdir -p " ++ output_dir) |> with_system
    let _ = ("rm -rf " ++ bin_path ++ ".dSYM") |> with_system

    let pool = self.compile_source_text(source_path, source_text)
    self.finish_binary_from_pool(pool, source_path, obj_path, bin_path)

fn Compilation.build_binary_from_source_to_path_with_build_settings(self: Compilation, source_path: str, source_text: str, bin_path: str, include_paths: Vec[str], defines: Vec[str], link_libs: Vec[str]) -> str:
    if bin_path.len() == 0:
        return self.build_binary_from_source_to_path(source_path, source_text, bin_path)
    let obj_path = bin_path ++ ".o"
    let output_dir = link_stage_dirname(bin_path)
    let _ = ("mkdir -p " ++ output_dir) |> with_system
    let _ = ("rm -rf " ++ bin_path ++ ".dSYM") |> with_system

    var cfg = project_config_load_for_source(source_path)
    for ii in 0..include_paths.len() as i32:
        cfg.c_import_include_paths.push(include_paths.get(ii as i64))
    for di in 0..defines.len() as i32:
        cfg.c_import_defines.push(defines.get(di as i64))
    for li in 0..link_libs.len() as i32:
        cfg.dep_link_libs.push(link_libs.get(li as i64))
    let pool = self.compile_source_text_with_config(source_path, source_text, cfg)
    self.finish_binary_from_pool(pool, source_path, obj_path, bin_path)

fn Compilation.build_entry_binary_from_source_to_path(self: Compilation, source_path: str, source_text: str, bin_path: str) -> str:
    if bin_path.len() == 0:
        return self.build_binary_from_source(source_path, source_text)
    let obj_path = bin_path ++ ".o"
    let output_dir = link_stage_dirname(bin_path)
    let _ = ("mkdir -p " ++ output_dir) |> with_system
    let _ = ("rm -rf " ++ bin_path ++ ".dSYM") |> with_system

    let pool = self.compile_entry_source_text(source_path, source_text)
    self.finish_binary_from_pool(pool, source_path, obj_path, bin_path)

fn Compilation.emit_c(self: Compilation, source_path: str, output_path: str) -> str:
    let pool = self.compile_file(source_path)
    if pool.decl_count() == 0:
        return ""
    let prepared_pool = self.prepare_pool_after_typecheck_hooks(pool, source_path)
    if prepared_pool.decl_count() == 0:
        return ""
    if not self.ensure_codegen_mir(prepared_pool):
        with_eprint("error: C emission failed during MIR lowering")
        return ""
    let typed_pool: AstPool = self.active_pool(prepared_pool)

    var final_output = output_path
    if final_output.len() == 0:
        final_output = link_stage_output_path_for_source(source_path) ++ ".c"
    let _ = ("mkdir -p " ++ link_stage_dirname(final_output)) |> with_system

    let emitted = c_emit_module(self.zcu.last_mir_module, typed_pool, self.zcu.pool, self.zcu.last_sema, self.zcu.current_source_path, self.zcu.current_source_text)
    if emitted.ok == 0:
        with_eprint("error: C emission failed: " ++ emitted.err_msg)
        return ""

    let write_rc = with_fs_write_file(final_output, emitted.source)
    if write_rc != 0:
        with_eprint("error: failed to write '" ++ final_output ++ "'")
        return ""

    final_output

fn Compilation.emit_typed(self: Compilation, pool: AstPool) -> bool:
    var zcu = self.zcu
    let typed_pool = pool
    if typed_pool.decl_count() == 0:
        with_eprint("error: no source loaded for typed emission")
        return false
    if zcu.last_sema.ast.decl_count() == typed_pool.decl_count() and typed_pool.decl_count() > 0:
        zcu.last_sema.emit_typed_module(0)
        self.zcu = zcu
        return true

    var sema = Sema.init(zcu.pool, zcu.diagnostics, typed_pool)
    sema.source_text = zcu.current_source_text
    sema.tool_mode_entry_path = zcu.tool_mode_entry_path
    if self.config.no_std:
        sema.no_std = 1
    if self.config.alloc_mode:
        sema.alloc = 1
    sema.check_module()

    zcu.sync_from_sema(sema)
    zcu.set_typed_snapshot("", typed_pool)
    zcu.set_codegen_snapshot(MirModule.init(), "", AsyncMirModule.init(), "")

    if zcu.diagnostics.has_errors():
        zcu.render_current_diagnostics()
        self.zcu = zcu
        return false

    zcu.last_sema.emit_typed_module(0)
    self.zcu = zcu
    true

fn Compilation.emit_typed_file(self: Compilation, source_path: str) -> bool:
    let pool = self.compile_file(source_path)
    if pool.decl_count() == 0:
        return false
    self.emit_typed(pool)

fn Compilation.print_mir(self: Compilation, pool: AstPool) -> bool:
    if self.zcu.last_mir_module.body_count() == 0:
        let _ = self.run_mir_lower(pool)
    if self.zcu.last_mir_module.body_count() == 0:
        return false
    print_mir_module(self.zcu.last_mir_module, self.zcu.pool, self.zcu.last_sema)
    true

fn Compilation.print_mir_file(self: Compilation, source_path: str) -> bool:
    let pool = self.compile_file(source_path)
    if pool.decl_count() == 0:
        return false
    self.print_mir(pool)

fn Compilation.dump_async_mir(self: Compilation, pool: AstPool) -> str:
    if self.zcu.last_async_mir_module.body_count() == 0:
        let _ = self.run_async_mir_lower(pool)
    if self.zcu.last_async_mir_module.body_count() == 0:
        return ""
    let text: str = dump_async_mir_module(self.zcu.last_async_mir_module, self.zcu.pool)
    self.zcu.set_codegen_snapshot(self.zcu.last_mir_module, self.zcu.last_mir_dump, self.zcu.last_async_mir_module, text)
    text

fn Compilation.dump_async_mir_file(self: Compilation, source_path: str) -> str:
    let pool = self.compile_file(source_path)
    if pool.decl_count() == 0:
        return ""
    self.dump_async_mir(pool)

fn Compilation.print_warnings(self: Compilation):
    self.zcu.print_warnings()

fn Compilation.active_pool(self: Compilation, pool: AstPool) -> AstPool:
    if self.zcu.typed_pool_cache.decl_count() > 0:
        return self.zcu.typed_pool_cache
    pool

fn Compilation.run_mir_lower(self: Compilation, pool: AstPool) -> MirModule:
    let do_profile = profile_enabled()
    var zcu = self.zcu
    let active_pool = pool
    compilation_debug_pool_flow("run_mir_lower:start", zcu.pool, active_pool, zcu.last_sema)
    var sema = Sema.init(zcu.pool, zcu.diagnostics, active_pool)
    compilation_debug_pool_flow("run_mir_lower:after_init", zcu.pool, active_pool, sema)
    sema.source_text = zcu.current_source_text
    sema.decl_source_paths = zcu.decl_source_paths
    sema.decl_source_file_ids = zcu.decl_source_file_ids
    sema.decl_is_c_import = zcu.decl_is_c_import
    sema.tool_mode_entry_path = zcu.tool_mode_entry_path
    sema.init_module_graph(&zcu.last_resolved)
    if self.config.no_std:
        sema.no_std = 1
    if self.config.alloc_mode:
        sema.alloc = 1
    let t_sema = profile_now()
    sema.check_module()
    sema.preregister_mir_types()
    sema.freeze_symbols()
    sema.freeze_types()
    if do_profile:
        profile_emit("sema", t_sema, f"types={sema.type_kinds.len() as i32}")
    compilation_debug_pool_flow("run_mir_lower:after_check", zcu.pool, active_pool, sema)

    // Check for sema errors before lowering
    if sema.diags.has_errors():
        zcu.sync_from_sema(sema)
        compilation_debug_pool_flow("run_mir_lower:after_sync", zcu.pool, active_pool, zcu.last_sema)
        zcu.render_current_diagnostics()
        zcu.set_codegen_snapshot(MirModule.init(), "", AsyncMirModule.init(), "")
        self.zcu = zcu
        return self.zcu.last_mir_module

    let t_mir = profile_now()
    let mir_mod: MirModule = lower_module(sema, active_pool, zcu.pool)
    let tailrec_syms = collect_tailrec_fn_syms(active_pool)
    if tailrec_syms.len() > 0:
        let tailrec_violations = mir_mod.verify_tailrec_contracts(sema, active_pool, tailrec_syms)
        if tailrec_violations.len() > 0:
            zcu.sync_from_sema(sema)
            compilation_debug_pool_flow("run_mir_lower:after_sync", zcu.pool, active_pool, zcu.last_sema)
            for vi in 0..tailrec_violations.len() as i32:
                let violation = tailrec_violations.get(vi as i64)
                let start = active_pool.get_start(violation.node)
                let end_raw = active_pool.get_end(violation.node)
                let end = if end_raw > start: end_raw else: start + 1
                let span = Span { file: sema.local_file_id, start, end }
                zcu.diagnostics.emit(Diagnostic.err(violation.message, span))
            zcu.render_all_diagnostics_frontend()
            zcu.set_codegen_snapshot(MirModule.init(), "", AsyncMirModule.init(), "")
            self.zcu = zcu
            return self.zcu.last_mir_module
    if sema.diags.has_errors():
        zcu.sync_from_sema(sema)
        compilation_debug_pool_flow("run_mir_lower:after_sync", zcu.pool, active_pool, zcu.last_sema)
        zcu.render_all_diagnostics_frontend()
        zcu.set_codegen_snapshot(MirModule.init(), "", AsyncMirModule.init(), "")
        self.zcu = zcu
        return self.zcu.last_mir_module
    if do_profile:
        profile_emit("mir.lower", t_mir, f"bodies={mir_mod.body_count()}")
    let t_mir_validate = profile_now()
    let mir_err = validate_typed_mir_module(mir_mod)
    if do_profile:
        profile_emit("mir.validate", t_mir_validate, "")
    if mir_validation_has_error(mir_err):
        let diag_span = compilation_mir_error_span(zcu, active_pool, mir_err.fn_sym, mir_err.span)
        sema.diags.emit(Diagnostic.err("invalid MIR before codegen: " ++ mir_err.message, diag_span))
        zcu.sync_from_sema(sema)
        compilation_debug_pool_flow("run_mir_lower:after_sync", zcu.pool, active_pool, zcu.last_sema)
        zcu.render_all_diagnostics_frontend()
        zcu.set_codegen_snapshot(MirModule.init(), "", AsyncMirModule.init(), "")
        self.zcu = zcu
        return self.zcu.last_mir_module
    let t_async = profile_now()
    let async_artifacts: AsyncLowerResult = lower_async_module(mir_mod, active_pool, zcu.pool, sema, zcu.diagnostics)
    if do_profile:
        profile_emit("async.lower", t_async, "")
    zcu.diagnostics = async_artifacts.diags
    compilation_dump_type_names("post-mir-lower", active_pool, zcu.pool)

    // Sync sema AFTER MIR lowering — type tables are frozen but other
    // sema state (e.g. diagnostics) may have been updated.
    zcu.sync_from_sema(sema)
    compilation_debug_pool_flow("run_mir_lower:after_sync", zcu.pool, active_pool, zcu.last_sema)
    zcu.set_codegen_snapshot(mir_mod, "", async_artifacts.out_mod, "")
    self.zcu = zcu
    self.zcu.last_mir_module

fn Compilation.run_async_mir_lower(self: Compilation, pool: AstPool) -> AsyncMirModule:
    let _ = self.run_mir_lower(pool)
    if self.zcu.diagnostics.has_errors():
        self.zcu.set_codegen_snapshot(self.zcu.last_mir_module, self.zcu.last_mir_dump, AsyncMirModule.init(), "")
        return self.zcu.last_async_mir_module
    self.zcu.last_async_mir_module

fn Compilation.ensure_codegen_mir(self: Compilation, pool: AstPool) -> bool:
    if self.zcu.last_mir_module.body_count() == 0:
        let _ = self.run_mir_lower(pool)
    if self.zcu.diagnostics.has_errors():
        return false
    self.zcu.last_mir_module.body_count() > 0

let _compiler_compilation_eof_guard = 0
