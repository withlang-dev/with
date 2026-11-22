//! expect-check-fail: 'freed by release_text' names no imported function
//! expect-check-fail: = help: name the library's release function for this text, declared in the imported header: 'text return, owned, freed by sqlite3_free'

// #3129 (§16.2b.8): `freed by` names the function that releases the text.
use c_import("char *make_text(void);\n")

c contract texts:
    fn make_text
        text return, owned, freed by release_text

fn main:
    print("unreachable")
