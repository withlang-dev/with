//! expect-error: c_import: untranslated macro 'MAX'

use c_import("#define MAX(a,b) ((a) > (b) ? (a) : (b))\n")

fn main:
    print("unreachable")
