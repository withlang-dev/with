// Driver compatibility adapter.
//
// Legacy tests and modules still import `Driver`, but the production
// compilation pipeline now lives under `src/compiler/*`. Keep the old
// surface stable while delegating all real work to `compiler.Compilation`.

use Ast
use Resolve
use InternPool
use compiler.Compilation
use compiler.Link

extern fn with_system(cmd: str) -> i32

const MODE_CHECK: i32 = 1
const MODE_BUILD: i32 = 2
const MODE_RUN: i32 = 3

const CR_OK: i32 = 0
const CR_LEX_ERROR: i32 = 1
const CR_PARSE_ERROR: i32 = 2
const CR_SEMA_ERROR: i32 = 3
const CR_BORROW_ERROR: i32 = 4
const CR_CODEGEN_ERROR: i32 = 5
const CR_LINK_ERROR: i32 = 6

type Driver {
    comp: Compilation,
    mode: i32,
    source_path: str,
    output_path: str,
    opt_level: i32,
    no_std: bool,
    alloc: bool,
    last_error_count: i32,
}

fn Driver.init -> Driver:
    Driver {
        comp: Compilation.init(),
        mode: MODE_CHECK,
        source_path: "",
        output_path: "",
        opt_level: 0,
        no_std: false,
        alloc: false,
        last_error_count: 0,
    }

fn Driver.new(mode: i32, source_path: str) -> Driver:
    var d = Driver.init()
    d.mode = mode
    d.source_path = source_path
    d

fn Driver.deinit(self: Driver):
    let _ = self
    return

fn Driver.configure(self: Driver, opt_level: i32, no_std: bool, alloc_mode: bool) -> void:
    self.opt_level = opt_level
    self.no_std = no_std
    self.alloc = alloc_mode
    var comp = self.comp
    comp.configure(opt_level, no_std, alloc_mode)
    self.comp = comp

fn Driver.set_prelude_mode(self: Driver, mode: i32):
    var comp = self.comp
    comp.set_prelude_mode(mode)
    self.comp = comp

fn Driver.refresh_error_count(self: Driver):
    self.last_error_count = self.comp.zcu.diagnostics.count()

fn Driver.error_count(self: Driver) -> i32:
    self.last_error_count

fn Driver.has_errors(self: Driver) -> bool:
    self.last_error_count > 0

fn Driver.get_pool(self: Driver) -> InternPool:
    self.comp.get_pool()

fn Driver.compile_file(self: Driver, path: str) -> AstPool:
    self.source_path = path
    var comp = self.comp
    let pool = comp.compile_file(path)
    self.comp = comp
    self.refresh_error_count()
    pool

fn Driver.resolve_file(self: Driver, path: str, emit_resolve_diags: bool) -> ResolveResult:
    self.source_path = path
    var comp = self.comp
    let result = comp.resolve_file(path, emit_resolve_diags)
    self.comp = comp
    self.refresh_error_count()
    result

fn Driver.dump_typed(self: Driver, pool: AstPool) -> str:
    if pool.decl_count() == 0:
        return ""
    var comp = self.comp
    let ok = comp.emit_typed(pool)
    self.comp = comp
    self.refresh_error_count()
    if not ok:
        return ""
    self.comp.zcu.last_sema.dump_typed_module()

fn Driver.emit_typed(self: Driver, pool: AstPool) -> i32:
    var comp = self.comp
    let ok = comp.emit_typed(pool)
    self.comp = comp
    self.refresh_error_count()
    if ok: return 0
    1

fn Driver.print_mir(self: Driver, pool: AstPool) -> bool:
    var comp = self.comp
    let ok = comp.print_mir(pool)
    self.comp = comp
    self.refresh_error_count()
    ok

fn Driver.dump_async_mir(self: Driver, pool: AstPool) -> str:
    var comp = self.comp
    let text = comp.dump_async_mir(pool)
    self.comp = comp
    self.refresh_error_count()
    text

fn Driver.emit_ir(self: Driver, pool: AstPool) -> bool:
    var comp = self.comp
    let ok = comp.emit_ir(pool)
    self.comp = comp
    self.refresh_error_count()
    ok

fn Driver.build_binary(self: Driver, source_path: str) -> str:
    self.source_path = source_path
    var comp = self.comp
    let out = comp.build_binary(source_path)
    self.comp = comp
    self.refresh_error_count()
    out

fn Driver.build_binary_at(self: Driver, source_path: str, output_dir: str) -> str:
    self.source_path = source_path
    var comp = self.comp
    let out = comp.build_binary_at(source_path, output_dir)
    self.comp = comp
    self.refresh_error_count()
    out

fn Driver.print_warnings(self: Driver):
    let comp = self.comp
    comp.print_warnings()

fn Driver.failure_result(self: Driver) -> i32:
    if self.last_error_count > 0:
        return CR_SEMA_ERROR
    CR_LINK_ERROR

fn Driver.rename_binary(self: Driver, built_path: str, output_path: str) -> i32:
    let _ = self
    if output_path.len() == 0 or built_path == output_path:
        return 0
    let mv_rc = ("mv -f " ++ built_path ++ " " ++ output_path) |> with_system
    if mv_rc != 0:
        return 1
    0

fn Driver.run_pipeline(self: Driver) -> i32:
    if self.mode == MODE_CHECK:
        let pool = self.compile_file(self.source_path)
        if pool.decl_count() == 0 or self.last_error_count > 0:
            return self.failure_result()
        return CR_OK
    if self.mode == MODE_BUILD:
        return self.compile_to_c(self.output_path)
    if self.mode == MODE_RUN:
        return self.compile_and_run()
    CR_CODEGEN_ERROR

fn Driver.compile_to_c(self: Driver, output_path: str) -> i32:
    self.output_path = output_path
    let target_dir = if output_path.len() > 0: link_stage_dirname(output_path) else: link_stage_dirname(self.source_path)
    let built = self.build_binary_at(self.source_path, target_dir)
    if built.len() == 0:
        return self.failure_result()
    if self.rename_binary(built, output_path) != 0:
        return CR_LINK_ERROR
    CR_OK

fn Driver.compile_and_run(self: Driver) -> i32:
    let built = self.build_binary(self.source_path)
    if built.len() == 0:
        return self.failure_result()
    let rc = built |> with_system
    if rc == 0:
        return CR_OK
    CR_CODEGEN_ERROR
