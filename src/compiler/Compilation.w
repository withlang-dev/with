use Ast
use compiler.Compilation.Config
use compiler.Zcu
use compiler.Frontend
use compiler.Backend
use compiler.Link

extern fn with_eprintln(s: str) -> void
extern fn with_system(cmd: str) -> i32

// Zig-shaped orchestration root for the With compiler pipeline.
type Compilation = {
    zcu: Zcu,
    config: CompilationConfig,
}

fn Compilation.init -> Compilation:
    Compilation {
        zcu: Zcu.init(),
        config: compilation_config_default(),
    }

fn Compilation.configure(self: Compilation, opt_level: i32, no_std: bool, alloc_mode: bool):
    self.config = compilation_config_from_cli(opt_level, no_std, alloc_mode)

fn Compilation.compile_file(self: Compilation, path: str) -> AstPool:
    self.zcu.compile_file_frontend(path)

fn Compilation.emit_ir(self: Compilation, pool: AstPool) -> bool:
    self.zcu.emit_ir_backend(pool)

fn Compilation.build_binary(self: Compilation, source_path: str) -> str:
    let dir = compilation_dirname(source_path)
    self.build_binary_at(source_path, dir)

fn Compilation.build_binary_at(self: Compilation, source_path: str, output_dir: str) -> str:
    let pool = self.compile_file(source_path)
    if pool.decl_count() == 0:
        return ""

    let stem = compilation_source_stem(source_path)
    let obj_path = output_dir ++ "/" ++ stem ++ ".o"
    let bin_path = output_dir ++ "/" ++ stem

    let result = self.zcu.compile_to_object_backend(pool, self.config.opt_level, obj_path)
    if result != 0:
        return ""

    var link_ok = false
    if link_stage_should_link_llvm_bridge(source_path):
        let bridge_path = link_stage_find_llvm_bridge_path()
        if bridge_path.len() == 0:
            with_eprintln("error: missing runtime/libwith_llvm_bridge.dylib")
            return ""
        let extras: Vec[str] = Vec.new()
        extras.push(bridge_path)
        link_ok = link_stage_link_with_extras(obj_path, bin_path, extras)
    else:
        link_ok = link_stage_link(obj_path, bin_path)
    if not link_ok:
        with_eprintln("error: linking failed")
        return ""

    with_system("rm -f " ++ obj_path)
    bin_path

fn Compilation.print_warnings(self: Compilation):
    self.zcu.print_warnings()

fn compilation_dirname(path: str) -> str:
    var last_slash = -1
    for i in 0..path.len():
        if path[i] == 47: // '/'
            last_slash = i as i32
    if last_slash < 0:
        return "."
    path.slice(0, last_slash as i64)

fn compilation_source_stem(source_path: str) -> str:
    // Extract basename and remove .w extension.
    var last_slash = -1
    for i in 0..source_path.len():
        if source_path[i] == 47: // '/'
            last_slash = i as i32
    let base = if last_slash >= 0:
        source_path.slice((last_slash + 1) as i64, source_path.len() as i64)
    else:
        source_path
    if base.len() > 2 and base.ends_with(".w"):
        return base.slice(0, (base.len() - 2) as i64)
    base
