use Ast
use Resolve
use InternPool
use Sema
use Mir
use MirLower
use AsyncMir
use AsyncLower
use CCodegen
use compiler.Compilation.Config
use compiler.Backend
use compiler.Frontend
use compiler.Link
use compiler.Zcu

extern fn with_eprintln(s: str) -> void
extern fn with_fs_write_file(path: str, data: str) -> i32
extern fn with_getenv_str(name: str) -> str
extern fn int_to_string(n: i32) -> str
extern fn with_system(cmd: str) -> i32

fn compilation_debug_init_enabled() -> i32:
    let raw = with_getenv_str("WITH_DEBUG_STAGE1_TRACE")
    if raw.len() == 0:
        return 0
    1

fn compilation_debug_init(msg: str):
    if compilation_debug_init_enabled() == 0:
        return
    with_eprintln("[comp-init] " ++ msg)

fn compilation_debug_pool_flow_enabled() -> i32:
    let raw = with_getenv_str("WITH_DEBUG_POOL_FLOW")
    if raw.len() == 0:
        return 0
    1

fn compilation_debug_pool_flow(label: str, pool: InternPool, typed_pool: AstPool, sema: Sema):
    if compilation_debug_pool_flow_enabled() == 0:
        return
    with_eprintln("[comp] " ++ label ++ " pool.symbols=" ++ int_to_string(pool.symbol_texts.len() as i32) ++
        " typed.decls=" ++ int_to_string(typed_pool.decl_count()) ++
        " sema.pool.symbols=" ++ int_to_string(sema.pool.symbol_texts.len() as i32) ++
        " sema.ast.decls=" ++ int_to_string(sema.ast.decl_count()))

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
    with_eprintln("[type-names] stage=" ++ stage ++ " decls=" ++ int_to_string(pool.decl_count()))
    for di in 0..pool.decl_count():
        let decl = pool.get_decl(di)
        if pool.kind(decl) != NK_TYPE_DECL:
            continue
        let sub_kind = type_decl_sub_kind(pool.get_data2(decl))
        var kind_name = "alias"
        if sub_kind == TDK_STRUCT:
            kind_name = "struct"
        else if sub_kind == TDK_ENUM:
            kind_name = "enum"
        else if sub_kind == TDK_DISC_ENUM:
            kind_name = "disc_enum"
        else if sub_kind == TDK_DISTINCT:
            kind_name = "distinct"
        let name_sym = pool.get_data0(decl)
        let name = intern.resolve(name_sym)
        let msg = "[type-names] " ++ stage ++
            " decl=" ++ int_to_string(di) ++
            " node=" ++ int_to_string(decl) ++
            " kind=" ++ kind_name ++
            " name_sym=" ++ int_to_string(name_sym) ++
            " name=" ++ name
        with_eprintln(msg)

// Transitional orchestration root:
// owns compiler-facing config/Zcu state while reusing Driver execution per call.
// This removes long-lived Driver field ownership from Compilation.
type Compilation = {
    zcu: Zcu,
    config: CompilationConfig,
}

fn Compilation.init -> Compilation:
    compilation_debug_init("Compilation.init:start")
    let zcu: Zcu = Zcu.init()
    compilation_debug_init("Compilation.init:zcu_ready")
    Compilation {
        zcu: zcu,
        config: compilation_config_default(),
    }

fn Compilation.configure(self: Compilation, opt_level: i32, no_std: bool, alloc_mode: bool):
    self.config = compilation_config_from_cli(opt_level, no_std, alloc_mode, self.config.prelude_mode)
    var zcu = self.zcu
    zcu.set_prelude_mode(self.config.prelude_mode)
    self.zcu = zcu

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

fn Compilation.compile_file(self: Compilation, path: str) -> AstPool:
    compilation_debug_init("Compilation.compile_file:start " ++ path)
    var zcu = self.zcu
    let pool = zcu.compile_file_frontend(path)
    self.zcu = zcu
    compilation_debug_init("Compilation.compile_file:done decls=" ++ int_to_string(pool.decl_count()))
    pool

fn Compilation.resolve_file(self: Compilation, path: str, emit_resolve_diags: bool) -> ResolveResult:
    let _ = emit_resolve_diags
    let _ = self.compile_file(path)
    self.zcu.last_resolved

fn Compilation.has_errors(self: Compilation) -> bool:
    self.zcu.diagnostics.has_errors()

fn Compilation.get_pool(self: Compilation) -> InternPool:
    self.zcu.pool

fn Compilation.emit_ir(self: Compilation, pool: AstPool) -> bool:
    if not self.ensure_codegen_mir(pool):
        return false
    self.zcu.emit_ir_backend(self.active_pool(pool), self.config.opt_level)

fn Compilation.build_binary(self: Compilation, source_path: str) -> str:
    let dir = link_stage_dirname(source_path)
    self.build_binary_at(source_path, dir)

fn Compilation.build_binary_at(self: Compilation, source_path: str, output_dir: str) -> str:
    let stem = link_stage_source_stem(source_path)
    let obj_path = output_dir ++ "/" ++ stem ++ ".o"
    let bin_path = output_dir ++ "/" ++ stem

    let pool = self.compile_file(source_path)
    compilation_debug_init("build_binary_at:compile_file done decls=" ++ int_to_string(pool.decl_count()))
    if pool.decl_count() == 0:
        return ""
    if not self.ensure_codegen_mir(pool):
        compilation_debug_init("build_binary_at:ensure_codegen_mir FAILED")
        let _ = ("rm -f " ++ obj_path) |> with_system
        return ""
    let active_pool: AstPool = self.active_pool(pool)
    let opt_level = self.config.opt_level
    let requires_async_runtime = self.zcu.last_async_mir_module.requires_async_runtime()
    compilation_debug_pool_flow("build_binary_at:after_codegen", self.zcu.pool, active_pool, self.zcu.last_sema)
    compilation_debug_init("build_binary_at:compile_to_object_backend")
    let backend_rc = self.zcu.compile_to_object_backend(active_pool, opt_level, obj_path, self.config.debug_info)
    if backend_rc != 0:
        compilation_debug_init("build_binary_at:backend FAILED rc=" ++ int_to_string(backend_rc))
        let _ = ("rm -f " ++ obj_path) |> with_system
        return ""
    compilation_debug_init("build_binary_at:linking")
    if not link_stage_link_object_to_binary(obj_path, bin_path, self.zcu.last_link_lib_names, requires_async_runtime):
        compilation_debug_init("build_binary_at:link FAILED")
        let _ = ("rm -f " ++ obj_path) |> with_system
        return ""
    // Generate .dSYM bundle for macOS debug info (DWARF stays in .o until dsymutil runs)
    if self.config.debug_info:
        let _ = ("dsymutil " ++ bin_path ++ " 2>/dev/null") |> with_system
    let _ = ("rm -f " ++ obj_path) |> with_system
    bin_path

fn Compilation.emit_c(self: Compilation, source_path: str, output_path: str) -> str:
    let pool = self.compile_file(source_path)
    if pool.decl_count() == 0:
        return ""
    if not self.ensure_codegen_mir(pool):
        with_eprintln("error: C emission failed during MIR lowering")
        return ""
    let typed_pool: AstPool = self.active_pool(pool)

    var final_output = output_path
    if final_output.len() == 0:
        final_output = "out/" ++ link_stage_source_stem(source_path) ++ ".c"

    let emitted = c_emit_module(self.zcu.last_mir_module, typed_pool, self.zcu.pool, self.zcu.last_sema, self.zcu.current_source_path, self.zcu.current_source_text)
    if emitted.ok == 0:
        with_eprintln("error: C emission failed: " ++ emitted.err_msg)
        return ""

    let write_rc = with_fs_write_file(final_output, emitted.source)
    if write_rc != 0:
        with_eprintln("error: failed to write '" ++ final_output ++ "'")
        return ""

    final_output

fn Compilation.emit_typed(self: Compilation, pool: AstPool) -> bool:
    var zcu = self.zcu
    let typed_pool = pool
    if typed_pool.decl_count() == 0:
        with_eprintln("error: no source loaded for typed emission")
        return false
    if zcu.last_sema.ast.decl_count() == typed_pool.decl_count() and typed_pool.decl_count() > 0:
        zcu.last_sema.emit_typed_module(0)
        self.zcu = zcu
        return true

    var sema = Sema.init(zcu.pool, zcu.diagnostics, typed_pool)
    sema.source_text = zcu.current_source_text
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
    var zcu = self.zcu
    let active_pool = pool
    compilation_debug_pool_flow("run_mir_lower:start", zcu.pool, active_pool, zcu.last_sema)
    var sema = Sema.init(zcu.pool, zcu.diagnostics, active_pool)
    compilation_debug_pool_flow("run_mir_lower:after_init", zcu.pool, active_pool, sema)
    sema.source_text = zcu.current_source_text
    if self.config.no_std:
        sema.no_std = 1
    if self.config.alloc_mode:
        sema.alloc = 1
    sema.check_module()
    compilation_debug_pool_flow("run_mir_lower:after_check", zcu.pool, active_pool, sema)

    zcu.sync_from_sema(sema)
    compilation_debug_pool_flow("run_mir_lower:after_sync", zcu.pool, active_pool, zcu.last_sema)
    if zcu.diagnostics.has_errors():
        zcu.render_current_diagnostics()
        zcu.set_codegen_snapshot(MirModule.init(), "", AsyncMirModule.init(), "")
        self.zcu = zcu
        return zcu.last_mir_module

    let mir_mod: MirModule = lower_module(sema, active_pool, zcu.pool)
    let async_artifacts: AsyncLowerResult = lower_async_module(mir_mod, active_pool, zcu.pool, sema, zcu.diagnostics)
    zcu.diagnostics = async_artifacts.diags
    compilation_dump_type_names("post-mir-lower", active_pool, zcu.pool)
    zcu.set_codegen_snapshot(mir_mod, "", async_artifacts.out_mod, "")
    self.zcu = zcu
    zcu.last_mir_module

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
