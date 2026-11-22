//! expect-stdout: 3 5 7 11
// glibc declares abs, labs and llabs with a literal `__attribute__ ((__const__))`
// beside __THROW's `__attribute__ ((__nothrow__))`. c_import's noreturn probe
// matched any `__attribute__` token, so on linux every such function became
// `-> Never`, lowered to `void`, and abs(-3) printed -3. A real noreturn
// declaration (exit: `__attribute__ ((__noreturn__))` in glibc, `__dead2` in
// the macOS SDK) must still be one.
use c_import("<stdlib.h>")

fn stop(code: i32) -> Never:
    exit(code)

fn main:
    let x: i32 = -3
    if x > 0: stop(1)
    print(f"{abs(x)} {labs(-5)} {llabs(-7)} {abs(-11)}")
