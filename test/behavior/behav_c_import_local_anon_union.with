//! expect-stdout: ok
// #1878: a record with no tag that an inline body's local declares
// (SDL_SwapFloat's `union { float f; Uint32 ui32; } swapper;`) is a With
// union with the record's fields, declared beside the function (§16.1); it
// was imported opaque, so every field access and the local itself failed.
use c_import("#include <stdint.h>\nstatic inline uint32_t float_bits(float x) { union { float f; uint32_t u; } bits; bits.f = x; return bits.u; }\nstatic inline float swap_float(float x) { union { float f; uint32_t ui32; } swapper; swapper.f = x; swapper.ui32 = __builtin_bswap32(swapper.ui32); return swapper.f; }\n")
fn main:
    if float_bits(1.0) == 0x3f800000 and swap_float(swap_float(1.5)) == 1.5: print("ok")
    else: print("bad")
