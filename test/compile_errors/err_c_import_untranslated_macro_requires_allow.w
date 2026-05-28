//! expect-error: c_import: untranslated macro 'LOG'

use c_import("#define LOG(fmt, ...) printf(fmt, __VA_ARGS__)\n")

fn main:
    print("unreachable")
