//! expect-stdout: 3
// §16.2: an object macro whose value is a call C re-evaluates at each use
// has no constant to import, and a unary operator in front of the call does
// not change that. SDL3's `#define SDL_MIN_SINT64 ~SDL_SINT64_C(...)` used
// to become `let SDL_MIN_SINT64 = (~SDL_SINT64_C(...))`, naming the
// function-like macro, and broke every full import of SDL.h.
use c_import("int m_runtime(int c);\n#define M_CALL(c) m_runtime(c)\n#define M_MAX M_CALL(1)\n#define M_MIN ~M_CALL(1)\n#define M_NEG -M_CALL(2)\n#define M_THREE 3\n")

fn main:
    print(f"{M_THREE}")
