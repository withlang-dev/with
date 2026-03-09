use Ast
use Diagnostic
use InternPool
use Sema

extern fn int_to_string(n: i32) -> str
extern fn print(s: str) -> void

fn main:
    let pool = InternPool.new()
    let bool_sym = pool.intern("bool")
    let diags = DiagnosticList.init()
    let ast = AstPool.new()
    let sema = Sema.init(pool, diags, ast)
    let tid = sema.primitive_type_by_sym(bool_sym)
    print(int_to_string(tid))
