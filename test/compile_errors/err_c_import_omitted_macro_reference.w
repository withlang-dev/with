//! expect-error: c_import symbol 'LOG' was omitted

use c_import("#define LOG(fmt, ...) printf(fmt, __VA_ARGS__)\n")

fn main:
    LOG(c"no".ptr)
