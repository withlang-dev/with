//! expect-stdout: ok

use c_import("#define LOG(fmt, ...) printf(fmt, __VA_ARGS__)\n", allow_untranslated: ["LOG"])

fn main:
    print("ok")
