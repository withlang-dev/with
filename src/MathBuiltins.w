// MathBuiltins — the single source of truth for the compiler-recognized
// floating-point math functions (specification §17.6a, numeric builtins).
//
// Each entry is callable as a free function (`cos(x)`) and as a method
// (`x.cos()`), is width-generic over f32 and f64 (the result type is the
// argument type, and every operand shares it), and carries no width suffix.
// `cos_f64` is the Go tax; With does not pay it.
//
// One table, read by every phase, so the surface cannot drift (the D6 FnAbi
// rule applied to builtins):
//   Sema      types the call and rejects a wrong arity or a non-float operand.
//   MirLower  tags the call MirIntrinsic.MATH_FN with the entry's id.
//   codegen   lowers from the row: the LLVM intrinsic where one exists
//             (`llvm.cos.f64`), otherwise the width-correct libm symbol
//             (`tan` for f64, `tanf` for f32). The split is invisible to the
//             caller. The intrinsic set is the one LLVM defines (the same
//             list Swift's tgmath keys on); everything else has no intrinsic
//             and goes to libm.
//
// Order is append-only: the id is the row index and is carried on MIR calls.

type MathFnRow { name: str, arity: i32, llvm: str, libm: str }

fn math_row(name: str, arity: i32, llvm: str, libm: str) -> MathFnRow:
    MathFnRow { name, arity, llvm, libm }

fn math_fn_table() -> Vec[MathFnRow]:
    var t: Vec[MathFnRow] = Vec.new()
    // Unary, LLVM intrinsic.
    t.push(math_row("sqrt", 1, "llvm.sqrt", "sqrt"))
    t.push(math_row("sin", 1, "llvm.sin", "sin"))
    t.push(math_row("cos", 1, "llvm.cos", "cos"))
    t.push(math_row("exp", 1, "llvm.exp", "exp"))
    t.push(math_row("exp2", 1, "llvm.exp2", "exp2"))
    t.push(math_row("log", 1, "llvm.log", "log"))
    t.push(math_row("log2", 1, "llvm.log2", "log2"))
    t.push(math_row("log10", 1, "llvm.log10", "log10"))
    t.push(math_row("floor", 1, "llvm.floor", "floor"))
    t.push(math_row("ceil", 1, "llvm.ceil", "ceil"))
    t.push(math_row("trunc", 1, "llvm.trunc", "trunc"))
    t.push(math_row("round", 1, "llvm.round", "round"))
    t.push(math_row("rint", 1, "llvm.rint", "rint"))
    t.push(math_row("nearbyint", 1, "llvm.nearbyint", "nearbyint"))
    t.push(math_row("fabs", 1, "llvm.fabs", "fabs"))
    // Binary, LLVM intrinsic.
    t.push(math_row("pow", 2, "llvm.pow", "pow"))
    t.push(math_row("copysign", 2, "llvm.copysign", "copysign"))
    // Unary, libm only (no LLVM intrinsic).
    t.push(math_row("tan", 1, "", "tan"))
    t.push(math_row("asin", 1, "", "asin"))
    t.push(math_row("acos", 1, "", "acos"))
    t.push(math_row("atan", 1, "", "atan"))
    t.push(math_row("sinh", 1, "", "sinh"))
    t.push(math_row("cosh", 1, "", "cosh"))
    t.push(math_row("tanh", 1, "", "tanh"))
    t.push(math_row("cbrt", 1, "", "cbrt"))
    t.push(math_row("expm1", 1, "", "expm1"))
    t.push(math_row("log1p", 1, "", "log1p"))
    t.push(math_row("erf", 1, "", "erf"))
    t.push(math_row("erfc", 1, "", "erfc"))
    t.push(math_row("tgamma", 1, "", "tgamma"))
    t.push(math_row("lgamma", 1, "", "lgamma"))
    // Binary, libm only.
    t.push(math_row("atan2", 2, "", "atan2"))
    t.push(math_row("fmod", 2, "", "fmod"))
    t.push(math_row("hypot", 2, "", "hypot"))
    t

/// The row id for `name`, or -1 when `name` is not a math builtin.
pub fn math_fn_lookup(name: &str) -> i32:
    let t = math_fn_table()
    for i in 0..t.len() as i32:
        if t.get(i).name == name: return i
    -1

/// Operand count: 1 or 2. Every operand shares the argument's float type.
pub fn math_fn_arity(id: i32) -> i32:
    let t = math_fn_table()
    t.get(id).arity

pub fn math_fn_name(id: i32) -> str:
    let t = math_fn_table()
    t.get(id).name.clone()

/// LLVM intrinsic base name (`llvm.cos`), or "" when the function is libm-only.
pub fn math_fn_llvm(id: i32) -> str:
    let t = math_fn_table()
    t.get(id).llvm.clone()

/// libm base symbol; the f32 spelling appends `f` (`cos` -> `cosf`).
pub fn math_fn_libm(id: i32) -> str:
    let t = math_fn_table()
    t.get(id).libm.clone()
