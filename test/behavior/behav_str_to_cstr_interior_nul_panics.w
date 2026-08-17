//! expect-exit: 1
//! expect-stderr: interior NUL

// §16.3c: a dynamically-built str carrying an interior NUL fails loudly at the
// safe C-string boundary rather than being silently truncated.

use c_import("unsigned long strlen(const char *s);\n")

fn main:
    let nul = "\0"
    let poisoned = "abc" ++ nul ++ "def"
    let n = strlen(poisoned)
    print(f"{n}")
