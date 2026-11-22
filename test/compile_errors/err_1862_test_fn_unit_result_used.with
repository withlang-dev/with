//! expect-error: `test_label` returns Unit
// #1862 (D43, functions.md): `test_*` functions do not infer a return; their
// tail is statement position, so `test_label` returns Unit. Using that Unit
// as an operand is a Sema error naming the rule — never `ok` from check
// and a codegen failure later (D65).

fn test_label(k: i32): "a"

fn main:
    print("x " ++ test_label(0))
