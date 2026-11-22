//! check-only
// #1879: a function-like macro with no parameters whose body is a call
// (`#define SDL_Unsupported() SDL_SetError("...")`) returns what the callee
// returns — here the raw variadic prototype's `bool` — not an `i32`
// placeholder; a macro with parameters already inferred it.
use c_import("#include <stdbool.h>\nbool set_err(const char *fmt, ...);\n#define unsupported() set_err(\"That operation is not supported\")\n")
fn main:
    let failed: bool = unsafe { unsupported() }
    if failed: print("failed")
