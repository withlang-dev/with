//! expect-stdout: ok

use c_import("#define MAX(a,b) ((a) > (b) ? (a) : (b))\n", allow_untranslated: ["MAX"])

fn main:
    print("ok")
