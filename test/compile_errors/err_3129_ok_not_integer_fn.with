//! expect-check-fail: compares an integer status, but the function returns
//! expect-check-fail: = help: delete 'ok': it applies to a function that returns an integer status

// #3129 (§16.2b.4): `ok` compares an integer the function returns.
use c_import("enum st { ST_OK = 0 };\nconst char *label(int a);\n")

c contract labels:
    fn label
        ok ST_OK

fn main:
    print("unreachable")
