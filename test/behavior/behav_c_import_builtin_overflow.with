//! expect-stdout: 42 -1 -1 1 0
// #1877: __builtin_mul_overflow / __builtin_add_overflow in an inline body
// (SDL_size_mul_check_overflow) lower to `__with_builtin_<op>_overflow_<ty>`,
// which the import defines beside the bodies that call it — the name used
// to dangle ("undefined variable").
use c_import("#include <stddef.h>\nstatic inline long long mul_or_neg(unsigned int a, unsigned int b) { unsigned int r; if (__builtin_mul_overflow(a, b, &r)) return -1; return (long long)r; }\nstatic inline long long add_or_neg(unsigned int a, unsigned int b) { unsigned int r; if (__builtin_add_overflow(a, b, &r)) return -1; return (long long)r; }\nstatic inline int size_mul_ok(size_t a, size_t b) { size_t r; return __builtin_mul_overflow(a, b, &r) ? 0 : 1; }\n")
fn main:
    let a = mul_or_neg(6, 7)
    let b = mul_or_neg(65536, 65536)
    let c = add_or_neg(4294967295, 1)
    let d = size_mul_ok(6, 7)
    let e = size_mul_ok(4294967296, 4294967296)
    print(f"{a} {b} {c} {d} {e}")
