use Ast
use Codegen
use compiler.Zcu

extern fn with_eprintln(s: str) -> void

// Backend stage wrapper over existing LLVM codegen.

fn Zcu.compile_to_object_backend(self: Zcu, pool: AstPool, opt_level: i32, output_path: str) -> i32:
    var cg = Codegen.init("with_module")
    cg.source_file = self.current_source_path
    cg.source_text = self.current_source_text
    let result = cg.gen_module(pool, self.pool)
    if result != 0:
        with_eprintln("error: code generation failed")
        return 1
    if opt_level > 0:
        cg.optimize(opt_level)
    let emit_result = cg.emit_object_file(output_path)
    if emit_result != 0:
        with_eprintln("error: failed to emit object file")
        return 1
    0

fn Zcu.emit_ir_backend(self: Zcu, pool: AstPool) -> bool:
    var cg = Codegen.init("with_module")
    cg.source_file = self.current_source_path
    cg.source_text = self.current_source_text
    let result = cg.gen_module(pool, self.pool)
    if result != 0:
        with_eprintln("error: code generation failed")
        return false
    cg.print_ir()
    true
