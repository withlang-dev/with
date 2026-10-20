//! env: WITH_RT_IN_UNIT=1
//! expect-stdout: 0.5
//! expect-stdout: ok

// D30 R2c: a c_import program links and runs with the runtime compiled
// in-unit. The translation declares `extern fn with_alloc` (and free,
// memcpy, memset) for its helpers; that extern names the runtime's own
// symbol, so the in-unit definition stands and the extern binds to it.
// The definition was displaced and dropped instead, and every c_import
// program failed to link ("undefined symbol: _with_alloc").
use c_import("#define HALF 0.5f\n")

fn main:
    print(f"{HALF}")
    var parts: List[str] = List.new()
    parts.push("o" ++ "k")
    print(parts.join(""))
