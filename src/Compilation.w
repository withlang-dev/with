// Stage-compat facade for self-host bootstrap:
// keep `use Compilation` stable while routing through the existing Driver.
//
// Note: the Zig-shaped architecture modules under `src/compiler/` remain
// in-tree for incremental migration, but bootstrap-stage import resolution
// cannot yet compile that nested module graph reliably.

use Driver
use Ast

type Compilation = {
    driver: Driver,
}

fn Compilation.init -> Compilation:
    Compilation {
        driver: Driver.init(),
    }

fn Compilation.configure(self: Compilation, opt_level: i32, no_std: bool, alloc_mode: bool) -> void:
    self.driver.configure(opt_level, no_std, alloc_mode)

fn Compilation.compile_file(self: Compilation, path: str) -> AstPool:
    self.driver.compile_file(path)

fn Compilation.emit_ir(self: Compilation, pool: AstPool) -> bool:
    self.driver.emit_ir(pool)

fn Compilation.build_binary(self: Compilation, source_path: str) -> str:
    self.driver.build_binary(source_path)

fn Compilation.print_warnings(self: Compilation):
    self.driver.print_warnings()
