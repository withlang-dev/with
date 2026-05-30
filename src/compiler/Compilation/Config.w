// Compilation config mirrors Zig's `Compilation.Config` role:
// a normalized, concrete set of driver options owned by `Compilation`.

type CompilationConfig {
    opt_level: i32,
    no_std: bool,
    alloc_mode: bool,
    runtime_available: bool,
    emit_ir: bool,
    emit_bin: bool,
    is_test: bool,
    prelude_mode: i32,
    debug_info: bool,
    compiler_hooks_enabled: bool,
    tool_mode_entry_path: str,
}
impl Copy for CompilationConfig

fn PRELUDE_FULL -> i32: 0
fn PRELUDE_CORE -> i32: 1
fn PRELUDE_NONE -> i32: 2

fn compilation_normalize_prelude_mode(mode: i32) -> i32:
    if mode == PRELUDE_CORE():
        return PRELUDE_CORE()
    if mode == PRELUDE_NONE():
        return PRELUDE_NONE()
    PRELUDE_FULL()

fn compilation_config_default -> CompilationConfig:
    CompilationConfig {
        opt_level: 0,
        no_std: false,
        alloc_mode: false,
        runtime_available: true,
        emit_ir: false,
        emit_bin: true,
        is_test: false,
        prelude_mode: PRELUDE_FULL(),
        debug_info: true,
        compiler_hooks_enabled: true,
        tool_mode_entry_path: "",
    }

fn compilation_config_from_cli(opt_level: i32, no_std: bool, alloc_mode: bool, runtime_available: bool, prelude_mode: i32) -> CompilationConfig:
    var cfg = compilation_config_default()
    cfg.opt_level = opt_level
    cfg.no_std = no_std
    cfg.alloc_mode = alloc_mode
    cfg.runtime_available = runtime_available
    cfg.prelude_mode = compilation_normalize_prelude_mode(prelude_mode)
    cfg
