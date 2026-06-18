//! expect-stdout: ok

// #379: getenv is curated -- `cstr_in` name parameter, borrowed nullable
// pointer return. Calling is safe; the return is a raw, natively-nullable
// pointer, so a missing variable compares equal to None.

use c_import("char *getenv(const char *name);\n")

fn main:
    let v = getenv("WITH_DEFINITELY_ABSENT_VAR_XYZZY_379")
    if v == None:
        print("ok")
    else:
        print("bad")
