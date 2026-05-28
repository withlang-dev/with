//! expect-error: c_import: untranslated macro 'BAD_OBJECT_MACRO'

use c_import("err_c_import_untranslated_object_macro_requires_allow.h")

fn main:
    print("unreachable")
