// Compilation config mirrors Zig's `Compilation.Config` role:
// a normalized, concrete set of driver options owned by `Compilation`.

type CompilationConfig = {
    opt_level: i32,
    no_std: bool,
    alloc_mode: bool,
    emit_ir: bool,
    emit_bin: bool,
    is_test: bool,
}

fn compilation_config_default -> CompilationConfig:
    CompilationConfig {
        opt_level: 0,
        no_std: false,
        alloc_mode: false,
        emit_ir: false,
        emit_bin: true,
        is_test: false,
    }

fn compilation_config_from_cli(opt_level: i32, no_std: bool, alloc_mode: bool) -> CompilationConfig:
    var cfg = compilation_config_default()
    cfg.opt_level = opt_level
    cfg.no_std = no_std
    cfg.alloc_mode = alloc_mode
    cfg
